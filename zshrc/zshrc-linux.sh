# ~/code/my-shell-my-rules/zshrc/zshrc-linux.sh
# Linux / WSL2 specific configuration
# $DOTFILES is exported by zshrc-file.sh

# 1Password SSH agent bridge (WSL2 → Windows named pipe). Sourced early so
# $SSH_AUTH_SOCK is set before any tool that uses SSH (git, gh, fnm clones, …).
source "$DOTFILES/zshrc/modules/1password-wsl.sh"

# Print system info on every new terminal
if command -v fastfetch &>/dev/null; then
  fastfetch
fi

#############################################################################
#                              Homebrew (Linuxbrew)
#############################################################################

# Linuxbrew — set up PATH, MANPATH, INFOPATH
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Homebrew completions
if command -v brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
  FPATH="$(brew --prefix)/share/zsh-completions:${FPATH}"
  autoload -Uz compinit
  compinit
fi

#############################################################################
#                              PATH additions
#############################################################################

# Go binaries
if [ -d "$HOME/go/bin" ]; then
  export PATH="$PATH:$HOME/go/bin"
fi

# pnpm — global bin directory
if command -v pnpm &>/dev/null; then
  export PNPM_HOME="$HOME/.local/share/pnpm"
  export PATH="$PNPM_HOME:$PATH"
fi

# Claude Code CLI
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

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

  export FZF_COMPLETION_TRIGGER='::'
fi

# eza — ls replacement
if command -v eza &>/dev/null; then
  alias ls='eza'
  alias ll='eza -lhg'
  alias lla='eza -alhg'
  alias tree='eza --tree'
else
  alias ls='ls --color=auto'
fi

# bat — cat replacement (on Ubuntu apt installs as batcat)
if command -v bat &>/dev/null; then
  alias cat='bat --paging=never --style=plain'
  alias catt='bat'
  alias cata='bat --show-all --paging=never --style=plain'
elif command -v batcat &>/dev/null; then
  alias bat='batcat'
  alias cat='batcat --paging=never --style=plain'
  alias catt='batcat'
  alias cata='batcat --show-all --paging=never --style=plain'
fi

# fd — fast find (on Ubuntu apt installs as fdfind)
if ! command -v fd &>/dev/null && command -v fdfind &>/dev/null; then
  alias fd='fdfind'
fi

# neovim
if command -v nvim &>/dev/null; then
  alias v='nvim'
  export MANPAGER='nvim +Man!'
  export MANWIDTH=999
fi

# yazi — terminal file manager
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

# zsh-autosuggestions (try brew path first, then apt path, then manual clone)
if command -v brew &>/dev/null && [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [ -f "$HOME/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$HOME/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# pgenv — postgres version manager
export PGENV_ROOT="$HOME/.pgenv"
if [ -d "$PGENV_ROOT" ]; then
  export PATH="$PGENV_ROOT/bin:$PGENV_ROOT/pgsql/bin:$PATH"
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

# Google Cloud SDK
if [ -f /usr/share/google-cloud-sdk/path.zsh.inc ]; then
  source /usr/share/google-cloud-sdk/path.zsh.inc
fi
if [ -f /usr/share/google-cloud-sdk/completion.zsh.inc ]; then
  source /usr/share/google-cloud-sdk/completion.zsh.inc
fi

# Starship prompt
if command -v starship &>/dev/null; then
  type starship_zle-keymap-select >/dev/null ||
    {
      export STARSHIP_CONFIG="$DOTFILES/starship/starship.toml"
      eval "$(starship init zsh)" >/dev/null 2>&1
    }
fi

#############################################################################
#                              VSCode sync (WSL2)
#############################################################################

# VSCode runs on Windows and stores user settings under %APPDATA%\Code\User.
# A WSL symlink into /mnt/c/... doesn't survive VSCode's save path, so we copy
# on demand. `vscode-sync` pushes repo → Windows (default). `vscode-sync pull`
# grabs whatever Windows has back into the repo for commit. `--diff` previews.
#
# Override the Windows user via $VSCODE_WIN_USER if auto-detection picks wrong.
function vscode-sync() {
  local win_user="${VSCODE_WIN_USER:-}"
  if [[ -z "$win_user" ]]; then
    for candidate in /mnt/c/Users/*/AppData/Roaming/Code/User; do
      [[ -d "$candidate" ]] || continue
      win_user="${${candidate#/mnt/c/Users/}%%/*}"
      break
    done
  fi
  if [[ -z "$win_user" ]]; then
    echo "vscode-sync: couldn't find a Windows VSCode install under /mnt/c/Users/*/AppData/Roaming/Code/User" >&2
    echo "vscode-sync: set VSCODE_WIN_USER=<your-windows-username> to override" >&2
    return 1
  fi

  local win_dir="/mnt/c/Users/$win_user/AppData/Roaming/Code/User"
  local repo_file="$DOTFILES/vscode/settings.json"
  local win_file="$win_dir/settings.json"

  case "${1:-push}" in
    push)
      if cmp -s "$repo_file" "$win_file" 2>/dev/null; then
        echo "vscode-sync: already in sync ($win_file)"
        return 0
      fi
      cp "$win_file" "$win_file.bak-$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
      cp "$repo_file" "$win_file" && echo "vscode-sync: pushed repo → $win_file"
      ;;
    pull)
      if cmp -s "$repo_file" "$win_file" 2>/dev/null; then
        echo "vscode-sync: already in sync ($repo_file)"
        return 0
      fi
      cp "$win_file" "$repo_file" && echo "vscode-sync: pulled $win_file → repo (review + commit)"
      ;;
    diff)
      diff -u "$repo_file" "$win_file" || true
      ;;
    *)
      echo "usage: vscode-sync [push|pull|diff]" >&2
      return 1
      ;;
  esac
}
