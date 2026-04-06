#!/usr/bin/env bash
# ~/code/personal/my-shell-my-rules/ai/install.sh
# AI-related CLI tools installed globally via pnpm
# Usage: bash ~/code/personal/my-shell-my-rules/ai/install.sh

set -euo pipefail

if ! command -v pnpm &>/dev/null; then
  echo "pnpm not found. Install it first: brew install pnpm" >&2
  exit 1
fi

tools=(
  @anthropic-ai/claude-code   # Claude Code CLI
)

for tool in "${tools[@]}"; do
  echo "Installing $tool..."
  pnpm add -g "$tool"
done

echo "Done. All AI tools installed."
