# ~/code/my-shell-my-rules/zshrc/modules/1password-wsl.sh
# Two things this module does:
#
# 1. SSH agent bridge — forwards Windows 1Password SSH agent into WSL2 via
#    npiperelay.exe + socat. Requires 1P app: Settings → Developer → "Use SSH agent".
#
# 2. op CLI session — the Linux op binary can't use Windows biometric directly.
#    We cache the session token in ~/.config/op/.session (chmod 600) so new
#    shells don't need a fresh signin. In interactive terminals, auto-signin is
#    attempted once when the cache is missing or stale.
#    Security: the token grants vault access until it expires (~30 days max).
#    Acceptable on an encrypted personal machine. Wipe it with: op-signout
#
# Skip with: export SKIP_1PASSWORD_WSL=1

[[ -n "${SKIP_1PASSWORD_WSL:-}" ]] && return
[[ -z "${WSL_DISTRO_NAME:-}" ]] && return

#############################################################################
# 1. SSH agent bridge
#############################################################################

if command -v socat >/dev/null 2>&1 && command -v npiperelay.exe >/dev/null 2>&1; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
  mkdir -p "$(dirname "$SSH_AUTH_SOCK")"

  if ! ss -lxn 2>/dev/null | grep -q "$SSH_AUTH_SOCK"; then
    rm -f "$SSH_AUTH_SOCK"
    ( setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork \
        EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork \
        >/dev/null 2>&1 & ) >/dev/null 2>&1
  fi
fi

#############################################################################
# 2. op CLI session persistence
#############################################################################

command -v op >/dev/null 2>&1 || return

_OP_SESSION_FILE="$HOME/.config/op/.session"
mkdir -p "$(dirname "$_OP_SESSION_FILE")"

# Restore cached token into the environment
if [[ -f "$_OP_SESSION_FILE" ]]; then
  export OP_SESSION_my="$(cat "$_OP_SESSION_FILE" 2>/dev/null)"
fi

# If still not signed in and we have a TTY, try interactive signin
if ! op whoami &>/dev/null 2>&1 && [[ -t 0 ]]; then
  _op_token=$(op signin --account my --raw 2>/dev/null) && {
    export OP_SESSION_my="$_op_token"
    echo "$_op_token" > "$_OP_SESSION_FILE"
    chmod 600 "$_OP_SESSION_FILE"
  }
  unset _op_token
fi

# Helpers
function op-signout() {
  op signout --account my 2>/dev/null
  rm -f "$_OP_SESSION_FILE"
  unset OP_SESSION_my
  echo "1Password signed out and session cache cleared."
}
