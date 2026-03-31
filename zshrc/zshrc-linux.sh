# ~/code/my-shell-my-rules/zshrc/zshrc-linux.sh
# Linux-specific configuration

alias ls='ls --color=auto'

# Go binaries
if [ -d "$HOME/go/bin" ]; then
  export PATH=$PATH:$HOME/go/bin
fi

# zoxide
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd='z'
  alias cdd='z -'
fi

# zsh-autosuggestions
if [ -f "$HOME/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# fzf
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
  export FZF_COMPLETION_TRIGGER='::'
fi

# uv — python version + package manager
if command -v uv &>/dev/null; then
  alias pip='echo "Use uv instead: uv add <package> (project) or uv tool install <package> (global)" && false'
  alias pip3='echo "Use uv instead: uv add <package> (project) or uv tool install <package> (global)" && false'

  export CLOUDSDK_PYTHON="$(uv python find 2>/dev/null)"
fi

# fnm — fast node manager
if command -v fnm &>/dev/null; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
fi

# atuin — shell history sync and search (replaces ctrl+r)
if command -v atuin &>/dev/null; then
  eval "$(atuin init zsh)"
fi

# kubectl completion
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
fi

# Starship prompt
if command -v starship &>/dev/null; then
  type starship_zle-keymap-select >/dev/null ||
    {
      export STARSHIP_CONFIG=$HOME/code/my-shell-my-rules/starship/starship.toml
      eval "$(starship init zsh)" >/dev/null 2>&1
    }
fi
