#!/usr/bin/env bash
# ~/code/personal/my-shell-my-rules/tools/install.sh
# General-purpose CLI tools installed globally via pnpm
# Usage: bash ~/code/personal/my-shell-my-rules/tools/install.sh

set -euo pipefail

if ! command -v pnpm &>/dev/null; then
  echo "pnpm not found. Install it first: brew install pnpm" >&2
  exit 1
fi

tools=(
  port-whisperer        # find what's running on any port
)

for tool in "${tools[@]}"; do
  echo "Installing $tool..."
  pnpm add -g "$tool"
done

echo "Done. All tools installed."
