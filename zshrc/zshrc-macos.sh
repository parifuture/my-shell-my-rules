# ~/code/personal/my-shell-my-rules/zshrc/zshrc-macos.sh
# macOS-specific configuration

# Print system info on every new terminal
if command -v fastfetch &>/dev/null; then
  fastfetch
fi

# Homebrew — disable auto-update on every brew command
export HOMEBREW_NO_AUTO_UPDATE="1"

# Homebrew completions
if command -v brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  autoload -Uz compinit
  compinit
fi

#############################################################################
#                              SSH keys via 1Password
#############################################################################

# 1Password SSH agent — handles all SSH keys with Touch ID, no manual ssh-add needed
# Requires: 1Password app → Settings → Developer → "Use the SSH agent"
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

#############################################################################
#                              PATH additions
#############################################################################

# Go binaries (templ, etc.)
if [ -d "$HOME/go/bin" ]; then
  export PATH=$PATH:$HOME/go/bin
fi

#############################################################################
#                              Colorscheme
#############################################################################

# TODO: add colorscheme system here once set up

#############################################################################
#                              CLI tools
#############################################################################

# fzf
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh

  # Preview file content using bat
  export FZF_CTRL_T_OPTS="
    --preview 'bat -n --color=always {}'
    --bind 'ctrl-/:change-preview-window(down|hidden|)'"

  # Use :: as the trigger sequence instead of the default **
  export FZF_COMPLETION_TRIGGER='::'
fi

# eza — ls replacement
if command -v eza &>/dev/null; then
  alias ls='eza'
  alias ll='eza -lhg'
  alias lla='eza -alhg'
  alias tree='eza --tree'
fi

# bat — cat replacement
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never --style=plain'
  alias catt='bat'
  alias cata='bat --show-all --paging=never --style=plain'
fi

# neovim
if command -v nvim &>/dev/null; then
  alias v='nvim'
  export MANPAGER='nvim +Man!'
  export MANWIDTH=999
fi

# neovide (GUI neovim)
if command -v neovide &>/dev/null; then
  alias nv='neovide'
fi

# yazi — terminal file manager
# yy: launches yazi and cd's into the last directory when you quit
if command -v yazi &>/dev/null; then
  alias y='yazi'
  function yy() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
      cd -- "$cwd"
    fi
    rm -f -- "$tmp"
  }
fi

# zoxide — smart cd replacement
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
  alias cd='z'
  alias cdd='z -'
fi

# zsh-autosuggestions
if [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# pgenv — postgres version manager
# Usage: pgenv install 16.4 / pgenv use 16.4 / pgenv versions
if command -v pgenv &>/dev/null; then
  export PGENV_ROOT="$HOME/.pgenv"
  export PATH="$PGENV_ROOT/bin:$PGENV_ROOT/pgsql/bin:$PATH"
fi

# uv — python version + package manager
# reads .python-version automatically, downloads version if missing
# use `uv add <pkg>` instead of pip install
# use `uv tool install <pkg>` for global CLI tools (e.g. ruff, httpie)
if command -v uv &>/dev/null; then
  # intercept pip to prevent accidental global installs
  alias pip='echo "Use uv instead: uv add <package> (project) or uv tool install <package> (global)" && false'
  alias pip3='echo "Use uv instead: uv add <package> (project) or uv tool install <package> (global)" && false'

  # gcloud — point it to uv-managed python to avoid system python conflicts
  export CLOUDSDK_PYTHON="$(uv python find 2>/dev/null)"
fi

# fnm — fast node manager
# --use-on-cd: auto-switch node version when entering a directory
# --version-file-strategy=recursive: walks up the tree to find .nvmrc/.node-version
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

# Google Cloud SDK
if command -v brew &>/dev/null; then
  if [ -f "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc" ]; then
    source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  fi
  if [ -f "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc" ]; then
    source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
  fi
fi

# Starship prompt
if command -v starship &>/dev/null; then
  type starship_zle-keymap-select >/dev/null ||
    {
      export STARSHIP_CONFIG=$HOME/code/personal/my-shell-my-rules/starship/starship.toml
      eval "$(starship init zsh)" >/dev/null 2>&1
    }
fi
