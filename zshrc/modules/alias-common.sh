# ~/code/my-shell-my-rules/zshrc/modules/alias-common.sh
# Aliases shared across all platforms

alias ll='ls -lh'
alias lla='ls -alh'
alias python='python3'
alias history='history -30'
alias x='exit'

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
alias pulldeez='echo "Pulling latest..."; (cd ~/code/my-shell-my-rules && git pull >/dev/null 2>&1) || echo "Failed to pull"; source ~/.zshrc'
