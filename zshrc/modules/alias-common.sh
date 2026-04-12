# ~/code/personal/my-shell-my-rules/zshrc/modules/alias-common.sh
# Aliases shared across all platforms

alias ll='ls -lh'
alias lla='ls -alh'
alias python='python3'
alias history='history -30'
alias x='exit'

# quick directory jumps
alias C='cd ~/code'
alias B='cd ~/code/backstage'
alias A='cd ~/code/ai-toolkit'

# kubernetes
alias k='kubectl'
alias kx='kubectx'
alias ks='kubens'
alias kga='kubectl get all'
alias kgp='kubectl get pods'
alias kgpa='kubectl get pods --all-namespaces'
alias kgpo='kubectl get pods -o wide'

# golang
alias coverage='go test -coverprofile=coverage.out && go tool cover -html=coverage.out'

# lazygit
alias lg='lazygit'

# pull latest dotfiles and reload shell
alias pulldeez='echo "Pulling latest..."; (cd ~/code/personal/my-shell-my-rules && git pull >/dev/null 2>&1) || echo "Failed to pull"; source ~/.zshrc'

# 1Password-wrapped yarn for the Backstage repo.
# `opyarn` runs yarn with secrets injected from the "Backstage Local" 1P Environment.
# Defined as a function (not an alias) so `compdef opyarn=yarn` in autocompletion.sh
# can hook in without zsh pre-expanding the alias and falling back to file completion.
opyarn() {
  NODE_OPTIONS="--no-node-snapshot" op run --environment "zc4xvtog5lackxtpusktr7umli" -- yarn "$@"
}

# `who is <domain>` → route to quien (the better WHOIS/DNS/SSL TUI).
# Plain `who` (with any other argument, or no arg) still runs the real macOS
# command that lists logged-in users.
who() {
  if [[ "$1" == "is" ]]; then
    shift
    command quien "$@"
  else
    command who "$@"
  fi
}

# Guard: inside ~/code/backstage, intercept plain `yarn` and nudge toward `opyarn`.
# Uses a function (not an alias) because it needs to inspect $PWD at call time.
# Startup cost is a single function definition (microseconds); call-time cost is one
# string-prefix check, so there is no meaningful shell slowdown.
yarn() {
  case "$PWD/" in
    "$HOME/code/backstage/"*)
      print -P "%F{red}✗ use %F{yellow}opyarn%F{red} here — plain yarn won't have 1Password secrets loaded.%f" >&2
      print -P "%F{245}  (run %F{cyan}command yarn $*%F{245} to bypass this guard if you really mean it)%f" >&2
      return 1
      ;;
  esac
  command yarn "$@"
}
