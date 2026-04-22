# ~/code/my-shell-my-rules/zshrc/modules/awsp.sh
# AWS credentials via 1Password + Bedrock helpers.
# Shared across macOS and Linux/WSL2 — requires `op` CLI to be signed in.

#############################################################################
# awsp — switch AWS profile by loading credentials from 1Password
#############################################################################
# Profiles defined in ~/.aws/1p-profiles.conf (not committed — contains vault
# name and item references).
# Usage: awsp <profile>   switch to a named profile
#        awsp             show currently active profile
#        awsp --list      list available profiles

function awsp() {
  local profiles_file="$HOME/.aws/1p-profiles.conf"

  if [[ ! -f "$profiles_file" ]]; then
    echo "Missing $profiles_file" >&2
    return 1
  fi

  if [[ -z "${1:-}" ]]; then
    echo "${AWSP_PROFILE:-<none>}"
    return 0
  fi

  if [[ "$1" == "--list" ]]; then
    grep '^\[' "$profiles_file" | tr -d '[]'
    return 0
  fi

  local profile="$1"
  local in_section=false
  local op_item="" key_field="" secret_field="" region="" vault=""
  local default_vault=""

  while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

    if [[ "$line" == "[$profile]" ]]; then
      in_section=true
      continue
    elif [[ "$line" =~ ^\[.*\]$ ]]; then
      in_section=false
      continue
    fi

    if $in_section; then
      case "$line" in
        op_item=*)      op_item="${line#op_item=}" ;;
        key_field=*)    key_field="${line#key_field=}" ;;
        secret_field=*) secret_field="${line#secret_field=}" ;;
        region=*)       region="${line#region=}" ;;
        vault=*)        vault="${line#vault=}" ;;
      esac
    else
      case "$line" in
        vault=*) default_vault="${line#vault=}" ;;
      esac
    fi
  done < "$profiles_file"

  vault="${vault:-$default_vault}"

  if [[ -z "$op_item" ]]; then
    echo "Profile '$profile' not found. Available profiles:" >&2
    awsp --list >&2
    return 1
  fi

  if [[ -z "$vault" ]]; then
    echo "No vault configured. Set 'vault=...' in $profiles_file" >&2
    return 1
  fi

  echo "Loading AWS credentials from 1Password..."
  local access_key secret_key

  access_key=$(op item get "$op_item" --vault "$vault" --fields "$key_field" --reveal 2>/dev/null) || {
    echo "Failed to fetch access key from 1Password" >&2; return 1
  }
  secret_key=$(op item get "$op_item" --vault "$vault" --fields "$secret_field" --reveal 2>/dev/null) || {
    echo "Failed to fetch secret key from 1Password" >&2; return 1
  }

  export AWS_ACCESS_KEY_ID="$access_key"
  export AWS_SECRET_ACCESS_KEY="$secret_key"
  export AWS_DEFAULT_REGION="${region:-us-west-1}"

  unset AWS_PROFILE AWS_SESSION_TOKEN 2>/dev/null

  export AWSP_PROFILE="$profile"
  echo "Switched to AWS profile: $profile (region: $AWS_DEFAULT_REGION)"
}

#############################################################################
# claudeb — Claude Code via Amazon Bedrock
#############################################################################
# Use when the Anthropic subscription quota is exhausted. Leaves the plain
# `claude` command untouched so api.anthropic.com login still works.
# Requires: awsp bedrock profile configured in ~/.aws/1p-profiles.conf

function claudeb() {
  if [[ "${AWSP_PROFILE:-}" != "bedrock" ]]; then
    awsp bedrock || return 1
  fi
  CLAUDE_CODE_USE_BEDROCK=1 \
  AWS_REGION="${AWS_DEFAULT_REGION:-us-west-2}" \
  ANTHROPIC_MODEL='us.anthropic.claude-sonnet-4-6[1m]' \
  ANTHROPIC_DEFAULT_SONNET_MODEL='us.anthropic.claude-sonnet-4-6[1m]' \
  ANTHROPIC_DEFAULT_OPUS_MODEL='us.anthropic.claude-opus-4-7[1m]' \
  ANTHROPIC_DEFAULT_HAIKU_MODEL='us.anthropic.claude-haiku-4-5-20251001-v1:0' \
    command claude --dangerously-skip-permissions "$@"
}

#############################################################################
# hermes — Hermes Agent via Amazon Bedrock
#############################################################################
# Unlike claude, hermes has no non-Bedrock path worth preserving, so the
# wrapper reuses the binary name and routes every invocation through the
# bedrock profile. Escape hatch: `command hermes ...` bypasses the wrapper.
# Requires: awsp bedrock profile configured in ~/.aws/1p-profiles.conf and
# ~/.hermes/config.yaml pointed at model.provider=bedrock.

function hermes() {
  if [[ "${AWSP_PROFILE:-}" != "bedrock" ]]; then
    awsp bedrock || return 1
  fi
  AWS_REGION="${AWS_DEFAULT_REGION:-us-west-2}" \
    command hermes "$@"
}
