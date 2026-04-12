#!/bin/bash
# ~/code/personal/my-shell-my-rules/litellm/start-litellm.sh
# Wrapper script for launchd — loads Bedrock credentials from 1Password

set -euo pipefail

# Load AWS credentials from 1Password
export AWS_ACCESS_KEY_ID=$(op read "op://Electronic Arts/backstage-prd/bedrock_aws_access_key_id")
export AWS_SECRET_ACCESS_KEY=$(op read "op://Electronic Arts/backstage-prd/bedrock_aws_secret_access_key")
export AWS_REGION_NAME="us-west-1"

CONFIG="$HOME/code/personal/my-shell-my-rules/litellm/config.yaml"

exec "$HOME/.local/bin/litellm" --config "$CONFIG" --port 4100
