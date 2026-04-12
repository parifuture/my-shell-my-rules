# ~/code/personal/my-shell-my-rules/zshrc/modules/services.sh
# Manage launchd daemons defined in this repo
#
# Usage:
#   svc <name> status   — is it running?
#   svc <name> restart  — unload + load
#   svc <name> start    — load
#   svc <name> stop     — unload
#   svc <name> logs     — tail stderr log
#   svc <name> logs out — tail stdout log
#   svc list            — show all registered services

# Registry: name -> plist label
# Add new services here as you create them
typeset -A _SVC_LABELS
_SVC_LABELS=(
  litellm  "com.partiwari.litellm-proxy"
)

typeset -A _SVC_LOG_DIR
_SVC_LOG_DIR=(
  litellm  "$HOME/.local/log"
)

function svc() {
  local name="$1"
  local action="${2:-status}"

  if [[ "$name" == "list" || -z "$name" ]]; then
    echo "Registered services:"
    for svc_name in "${(@k)_SVC_LABELS}"; do
      local label="${_SVC_LABELS[$svc_name]}"
      local running=$(launchctl list 2>/dev/null | grep -c "$label")
      if [[ $running -gt 0 ]]; then
        echo "  $svc_name  ✓ running  ($label)"
      else
        echo "  $svc_name  ✗ stopped  ($label)"
      fi
    done
    return 0
  fi

  local label="${_SVC_LABELS[$name]}"
  if [[ -z "$label" ]]; then
    echo "Unknown service '$name'. Run 'svc list' to see available services." >&2
    return 1
  fi

  local plist="$HOME/Library/LaunchAgents/${label}.plist"
  local log_dir="${_SVC_LOG_DIR[$name]:-$HOME/.local/log}"
  local log_base="${label##*.}"  # last component: litellm-proxy

  case "$action" in
    status)
      local info=$(launchctl list 2>/dev/null | grep "$label")
      if [[ -n "$info" ]]; then
        local pid=$(echo "$info" | awk '{print $1}')
        local exit_code=$(echo "$info" | awk '{print $2}')
        if [[ "$pid" != "-" ]]; then
          echo "$name: running (pid $pid)"
        else
          echo "$name: stopped (last exit $exit_code)"
        fi
      else
        echo "$name: not loaded"
      fi
      ;;
    start)
      launchctl load "$plist" 2>&1
      echo "$name: started"
      ;;
    stop)
      launchctl unload "$plist" 2>&1
      echo "$name: stopped"
      ;;
    restart)
      launchctl unload "$plist" 2>/dev/null
      launchctl load "$plist" 2>&1
      echo "$name: restarted"
      ;;
    logs|log)
      local which="${3:-err}"
      local log_file="$log_dir/${log_base}.${which}.log"
      if [[ -f "$log_file" ]]; then
        tail -f "$log_file"
      else
        echo "No log file at $log_file" >&2
        return 1
      fi
      ;;
    *)
      echo "Usage: svc <name> {status|start|stop|restart|logs [out|err]}" >&2
      echo "       svc list" >&2
      return 1
      ;;
  esac
}
