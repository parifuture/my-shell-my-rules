#!/usr/bin/env bash
# Refresh uv: update uv itself, upgrade all uv-tool-installed CLIs, prune stale uvx cache.
# Usually invoked by the brew() shell wrapper after `brew update`/`brew upgrade`.

set -euo pipefail

command -v uv >/dev/null || { echo "error: uv is not installed" >&2; exit 1; }

echo "→ uv self update..."
uv self update

echo "→ uv tool upgrade --all..."
uv tool upgrade --all

echo "→ uv cache prune..."
uv cache prune

echo "✓ uv refresh complete"
