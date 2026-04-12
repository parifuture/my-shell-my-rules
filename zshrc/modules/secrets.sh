# ~/code/personal/my-shell-my-rules/zshrc/modules/secrets.sh
# Load API keys from 1Password into the environment.
#
# Only runs for interactive shells, and only if `op` is installed and signed in.
# Each secret is fetched once per shell startup and cached in the env, so
# subprocesses (including Claude Code and its MCP servers) inherit them.
#
# To add a new secret:
#   1. Add a line to the _SECRETS map below: VAR_NAME -> op://path
#   2. Start a new shell (or `source ~/.zshrc`)
#
# To skip secret loading (e.g. faster shell startup for non-dev sessions):
#   export SKIP_SECRETS=1

[[ $- != *i* ]] && return        # interactive shells only
[[ -n "$SKIP_SECRETS" ]] && return
command -v op &>/dev/null || return

# Only attempt if op is already signed in — avoid surprise Touch ID prompts
# during shell startup. If you're not signed in, run `op signin` manually.
op whoami &>/dev/null || return

typeset -A _SECRETS
_SECRETS=(
  LINEAR_API_KEY  "op://Personal/Linear API Full Access/api_key"
)

for var in "${(@k)_SECRETS}"; do
  # Skip if already set (e.g. by a parent shell)
  [[ -n "${(P)var}" ]] && continue
  local value
  value=$(op read "${_SECRETS[$var]}" 2>/dev/null) || continue
  export "$var=$value"
done

unset var value
