#!/usr/bin/env bash
# Sync cspell software-terms dictionary into macOS AppleSpell LocalDictionary.
# Source: https://github.com/streetsidesoftware/cspell-dicts/tree/main/dictionaries/software-terms/src
# Merges all *.txt word lists with the existing LocalDictionary (dedup, case-sensitive sort).
# Quit Mail/Notes/TextEdit/etc. and relaunch for changes to take effect.

set -euo pipefail

REPO_API="https://api.github.com/repos/streetsidesoftware/cspell-dicts/contents/dictionaries/software-terms/src"
DICT_PATH="$HOME/Library/Group Containers/group.com.apple.AppleSpell/Library/Spelling/LocalDictionary"

command -v jq >/dev/null || { echo "error: jq is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "error: curl is required" >&2; exit 1; }

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

echo "→ Listing .txt files in software-terms/src..."
listing="$tmpdir/listing.json"
curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} "$REPO_API" > "$listing"

mapfile -t urls < <(jq -r '.[]
    | select(.type=="file")
    | select(.name | endswith(".txt"))
    | select(.name | startswith("source-files-") | not)
    | .download_url' "$listing")
[[ ${#urls[@]} -gt 0 ]] || { echo "error: no .txt files found at $REPO_API" >&2; exit 1; }
echo "  found ${#urls[@]} files"

raw="$tmpdir/raw.txt"
: > "$raw"
for url in "${urls[@]}"; do
    name="${url##*/}"
    echo "  ↓ $name"
    curl -fsSL "$url" >> "$raw"
    printf '\n' >> "$raw"
done

# Clean: strip CR, trim whitespace, drop blanks, comments (#), cspell markers (!/+/*),
# and multi-word entries (AppleSpell LocalDictionary is one word per line).
cleaned="$tmpdir/cleaned.txt"
tr -d '\r' < "$raw" \
  | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
  | grep -Ev '^$|^#|^[!+*]' \
  | grep -v ' ' \
  > "$cleaned"

fetched=$(wc -l < "$cleaned" | tr -d ' ')
echo "→ Cleaned: $fetched candidate words"

# Preserve existing entries.
existing="$tmpdir/existing.txt"
if [[ -f "$DICT_PATH" ]]; then
    cp "$DICT_PATH" "$existing"
    before=$(grep -cve '^$' "$existing" || true)
else
    : > "$existing"
    before=0
fi

# Merge + dedup (case-sensitive, matches AppleSpell).
merged="$tmpdir/merged.txt"
cat "$existing" "$cleaned" | grep -v '^$' | LC_ALL=C sort -u > "$merged"
total=$(wc -l < "$merged" | tr -d ' ')
added=$(( total - before ))

if [[ -f "$DICT_PATH" ]] && ! cmp -s "$merged" "$DICT_PATH"; then
    backup="${DICT_PATH}.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$DICT_PATH" "$backup"
    echo "→ Backed up existing dictionary to: $backup"
fi

mkdir -p "$(dirname "$DICT_PATH")"
mv "$merged" "$DICT_PATH"

echo
echo "✓ LocalDictionary updated"
echo "  before: $before words"
echo "  after:  $total words  (+$added)"
echo
echo "Relaunch Mail, Notes, TextEdit, etc. for the change to take effect."
