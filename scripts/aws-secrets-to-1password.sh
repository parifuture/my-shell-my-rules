#!/bin/bash
# Syncs AWS Secrets Manager secrets into 1Password
# Usage:
#   ./aws-secrets-to-1password.sh              # interactive — pick secrets to sync
#   ./aws-secrets-to-1password.sh --all        # sync all secrets
#
# Environment variables (all required):
#   AWS_PROFILE   — AWS CLI profile to use
#   AWS_REGION    — AWS region to pull secrets from
#   OP_VAULT      — 1Password vault name to sync into

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

: "${AWS_PROFILE:?Set AWS_PROFILE in scripts/.env or environment}"
: "${AWS_REGION:?Set AWS_REGION in scripts/.env or environment}"
: "${OP_VAULT:?Set OP_VAULT in scripts/.env or environment}"
OP_TAG="aws-secrets-manager"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Fetching secrets from AWS Secrets Manager (${AWS_REGION})...${NC}"
SECRETS=$(aws secretsmanager list-secrets \
  --profile "$AWS_PROFILE" \
  --region "$AWS_REGION" \
  --output json \
  | python3 -c "import sys,json; [print(s['Name']) for s in json.load(sys.stdin).get('SecretList',[])]" \
  | sort)

TOTAL=$(echo "$SECRETS" | wc -l | tr -d ' ')
echo -e "${GREEN}Found ${TOTAL} secrets${NC}"
echo ""

if [[ "${1:-}" == "--all" ]]; then
  SELECTED="$SECRETS"
else
  # Display numbered list
  i=1
  while IFS= read -r name; do
    printf "  ${YELLOW}%3d${NC}  %s\n" "$i" "$name"
    ((i++))
  done <<< "$SECRETS"

  echo ""
  echo -e "${CYAN}Enter secret numbers to sync (comma-separated, ranges ok, e.g. 1,3,5-10) or 'all':${NC}"
  read -r SELECTION

  if [[ "$SELECTION" == "all" ]]; then
    SELECTED="$SECRETS"
  else
    SELECTED=""
    # Parse selection (supports: 1,3,5-10,15)
    IFS=',' read -ra PARTS <<< "$SELECTION"
    for part in "${PARTS[@]}"; do
      part=$(echo "$part" | tr -d ' ')
      if [[ "$part" == *-* ]]; then
        start=${part%-*}
        end=${part#*-}
        for ((n=start; n<=end; n++)); do
          line=$(echo "$SECRETS" | sed -n "${n}p")
          [ -n "$line" ] && SELECTED+="$line"$'\n'
        done
      else
        line=$(echo "$SECRETS" | sed -n "${part}p")
        [ -n "$line" ] && SELECTED+="$line"$'\n'
      fi
    done
    SELECTED=$(echo "$SELECTED" | sed '/^$/d')
  fi
fi

COUNT=$(echo "$SELECTED" | wc -l | tr -d ' ')
echo ""
echo -e "${CYAN}Syncing ${COUNT} secrets to 1Password vault '${OP_VAULT}'...${NC}"
echo ""

SYNCED=0
UPDATED=0
FAILED=0
SKIPPED=0

while IFS= read -r SECRET_NAME; do
  [ -z "$SECRET_NAME" ] && continue

  ITEM_EXISTS=false
  if op item get "$SECRET_NAME" --vault "$OP_VAULT" --format=json >/dev/null 2>&1; then
    ITEM_EXISTS=true
  fi

  # Fetch secret value from AWS
  SECRET_JSON=$(aws secretsmanager get-secret-value \
    --profile "$AWS_PROFILE" \
    --region "$AWS_REGION" \
    --secret-id "$SECRET_NAME" \
    --output json 2>&1) || {
    echo -e "  ${RED}✗  ${SECRET_NAME}${NC} (failed to fetch from AWS)"
    ((FAILED++))
    continue
  }

  SECRET_VALUE=$(echo "$SECRET_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['SecretString'])")

  # Build a JSON template for op item create
  # This avoids CLI arg issues with multiline values, special chars, etc.
  TEMPLATE_FILE=$(mktemp /tmp/op-template-XXXXXX.json)
  trap "rm -f '$TEMPLATE_FILE'" EXIT

  echo "$SECRET_VALUE" | python3 -c "
import sys, json

raw = sys.stdin.read()
fields = []

try:
    d = json.loads(raw)
    for k, v in d.items():
        val = json.dumps(v) if isinstance(v, (dict, list)) else str(v)
        fields.append({
            'id': k,
            'label': k,
            'type': 'CONCEALED',
            'value': val
        })
except (json.JSONDecodeError, ValueError):
    fields.append({
        'id': 'value',
        'label': 'value',
        'type': 'CONCEALED',
        'value': raw
    })

template = {
    'title': '',
    'category': 'LOGIN',
    'fields': fields
}
json.dump(template, sys.stdout)
" > "$TEMPLATE_FILE"

  if $ITEM_EXISTS; then
    # Compare with existing 1Password item to see if update is needed
    EXISTING_FIELDS=$(op item get "$SECRET_NAME" --vault "$OP_VAULT" --format=json 2>/dev/null \
      | python3 -c "
import sys, json, hashlib
item = json.load(sys.stdin)
fields = {f.get('label',''): f.get('value','') for f in item.get('fields',[]) if f.get('label')}
print(hashlib.sha256(json.dumps(fields, sort_keys=True).encode()).hexdigest())
" 2>/dev/null || echo "")

    NEW_FIELDS=$(cat "$TEMPLATE_FILE" | python3 -c "
import sys, json, hashlib
tmpl = json.load(sys.stdin)
fields = {f['label']: f['value'] for f in tmpl.get('fields',[])}
print(hashlib.sha256(json.dumps(fields, sort_keys=True).encode()).hexdigest())
" 2>/dev/null || echo "force-update")

    if [[ "$EXISTING_FIELDS" == "$NEW_FIELDS" ]]; then
      echo -e "  ${YELLOW}⏭  ${SECRET_NAME}${NC} (up to date)"
      ((SKIPPED++))
      rm -f "$TEMPLATE_FILE"
      continue
    fi

    # Delete and recreate (op doesn't support bulk field updates via template)
    if op item delete "$SECRET_NAME" --vault="$OP_VAULT" >/dev/null 2>&1 && \
       op item create \
        --template="$TEMPLATE_FILE" \
        --title="$SECRET_NAME" \
        --vault="$OP_VAULT" \
        --tags="$OP_TAG" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓  ${SECRET_NAME}${NC} (updated)"
      ((UPDATED++))
    else
      echo -e "  ${RED}✗  ${SECRET_NAME}${NC} (failed to update in 1Password)"
      ((FAILED++))
    fi
  else
    # Create new item
    if op item create \
      --template="$TEMPLATE_FILE" \
      --title="$SECRET_NAME" \
      --vault="$OP_VAULT" \
      --tags="$OP_TAG" >/dev/null 2>&1; then
      echo -e "  ${GREEN}✓  ${SECRET_NAME}${NC}"
      ((SYNCED++))
    else
      echo -e "  ${RED}✗  ${SECRET_NAME}${NC} (failed to create in 1Password)"
      ((FAILED++))
    fi
  fi

  rm -f "$TEMPLATE_FILE"

done <<< "$SELECTED"

echo ""
echo -e "${CYAN}Done!${NC}"
echo -e "  ${GREEN}Created: ${SYNCED}${NC}"
[ "$UPDATED" -gt 0 ] && echo -e "  ${GREEN}Updated: ${UPDATED}${NC}"
[ "$SKIPPED" -gt 0 ] && echo -e "  ${YELLOW}Up to date: ${SKIPPED}${NC}"
[ "$FAILED" -gt 0 ] && echo -e "  ${RED}Failed: ${FAILED}${NC}"
echo ""
echo -e "All synced items are tagged '${OP_TAG}' in the '${OP_VAULT}' vault."
