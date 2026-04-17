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
#                         AWS credentials via 1Password
#############################################################################

# awsp: switch AWS profile by loading credentials from 1Password
# Profiles are defined in ~/.aws/1p-profiles.conf
# Usage: awsp <profile>    — switch to a profile
#        awsp               — show current profile
#        awsp --list        — list available profiles
function awsp() {
  local profiles_file="$HOME/.aws/1p-profiles.conf"

  if [[ ! -f "$profiles_file" ]]; then
    echo "Missing $profiles_file" >&2
    return 1
  fi

  # No args — show current profile
  if [[ -z "${1:-}" ]]; then
    echo "${AWSP_PROFILE:-<none>}"
    return 0
  fi

  # --list — show available profiles
  if [[ "$1" == "--list" ]]; then
    grep '^\[' "$profiles_file" | tr -d '[]'
    return 0
  fi

  local profile="$1"
  local in_section=false
  local op_item="" key_field="" secret_field="" region="" vault=""
  local default_vault=""

  while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

    if [[ "$line" == "[$profile]" ]]; then
      in_section=true
      continue
    elif [[ "$line" =~ ^\[.*\]$ ]]; then
      in_section=false
      continue
    fi

    if $in_section; then
      case "$line" in
        op_item=*)      op_item="${line#op_item=}" ;;
        key_field=*)    key_field="${line#key_field=}" ;;
        secret_field=*) secret_field="${line#secret_field=}" ;;
        region=*)       region="${line#region=}" ;;
        vault=*)        vault="${line#vault=}" ;;
      esac
    else
      # Global settings (before any section)
      case "$line" in
        vault=*) default_vault="${line#vault=}" ;;
      esac
    fi
  done < "$profiles_file"

  vault="${vault:-$default_vault}"

  if [[ -z "$op_item" ]]; then
    echo "Profile '$profile' not found. Available profiles:" >&2
    awsp --list >&2
    return 1
  fi

  if [[ -z "$vault" ]]; then
    echo "No vault configured. Set 'vault=...' in $profiles_file" >&2
    return 1
  fi

  echo "Loading AWS credentials from 1Password..."
  local access_key secret_key

  access_key=$(op item get "$op_item" --vault "$vault" --fields "$key_field" --reveal 2>/dev/null) || {
    echo "Failed to fetch access key from 1Password" >&2; return 1
  }
  secret_key=$(op item get "$op_item" --vault "$vault" --fields "$secret_field" --reveal 2>/dev/null) || {
    echo "Failed to fetch secret key from 1Password" >&2; return 1
  }

  export AWS_ACCESS_KEY_ID="$access_key"
  export AWS_SECRET_ACCESS_KEY="$secret_key"
  export AWS_DEFAULT_REGION="${region:-us-west-1}"

  # Clear vars that would conflict with static credentials
  unset AWS_PROFILE AWS_SESSION_TOKEN 2>/dev/null

  # Track active profile for display purposes
  export AWSP_PROFILE="$profile"

  echo "Switched to AWS profile: $profile (region: $AWS_DEFAULT_REGION)"
}

#############################################################################
#                              pi coding agent (Bedrock)
#############################################################################

# pi: shadow the pi binary so every invocation auto-loads the Bedrock AWS
# profile before launching. Subcommands (install/remove/update/list/config)
# pass straight through without --provider/--model flags; everything else
# gets the Bedrock defaults applied.
#
# - auto-loads the bedrock AWS profile if not already active
# - primary model us.anthropic.claude-sonnet-4-6, Ctrl+P cycles to opus-4-6
# - extension + agents loaded from ~/.pi/agent (symlinked to this dotfiles repo)
function pi() {
  # Package management / introspection subcommands — pass through untouched.
  case "${1:-}" in
    install|remove|uninstall|update|list|config)
      command pi "$@"
      return
      ;;
  esac
  if [[ "${AWSP_PROFILE:-}" != "bedrock" ]]; then
    awsp bedrock || return 1
  fi
  command pi \
    --provider amazon-bedrock \
    --model "us.anthropic.claude-sonnet-4-6" \
    --models "us.anthropic.claude-sonnet-4-6,us.anthropic.claude-opus-4-6-v1" \
    "$@"
}

#############################################################################
#                              Claude Code (Bedrock)
#############################################################################

# claudeb: launch Claude Code against Amazon Bedrock instead of the Anthropic
# API. Use when the Anthropic subscription quota is exhausted — leaves the
# plain `claude` command untouched so api.anthropic.com login still works.
#
# - auto-loads the bedrock AWS profile if not already active (via awsp)
# - bakes in --dangerously-skip-permissions to match the usual workflow
# - Sonnet 4.6 is primary; Opus 4.6 and Haiku 4.5 pinned for /model switching
# - Sonnet/Opus pinned with the [1m] suffix so the 1M context window is
#   always active; Haiku 4.5 does not support 1M so it stays at 200K
# - CLAUDE_CODE_USE_BEDROCK is set only for this subprocess, so a later
#   plain `claude` call in the same shell still talks to api.anthropic.com
# - AWS_REGION is set explicitly because Claude Code does NOT fall back to
#   the AWS config file or AWS_DEFAULT_REGION (docs: amazon-bedrock.md)
function claudeb() {
  if [[ "${AWSP_PROFILE:-}" != "bedrock" ]]; then
    awsp bedrock || return 1
  fi
  CLAUDE_CODE_USE_BEDROCK=1 \
  AWS_REGION="${AWS_DEFAULT_REGION:-us-west-1}" \
  ANTHROPIC_MODEL='us.anthropic.claude-sonnet-4-6[1m]' \
  ANTHROPIC_DEFAULT_SONNET_MODEL='us.anthropic.claude-sonnet-4-6[1m]' \
  ANTHROPIC_DEFAULT_OPUS_MODEL='us.anthropic.claude-opus-4-6-v1[1m]' \
  ANTHROPIC_DEFAULT_HAIKU_MODEL='us.anthropic.claude-haiku-4-5-20251001-v1:0' \
    command claude --dangerously-skip-permissions "$@"
}

#############################################################################
#                              PATH additions
#############################################################################

# Go binaries (templ, etc.)
if [ -d "$HOME/go/bin" ]; then
  export PATH=$PATH:$HOME/go/bin
fi

# pnpm — global bin directory
if command -v pnpm &>/dev/null; then
  export PNPM_HOME="$HOME/Library/pnpm"
  export PATH="$PNPM_HOME:$PATH"
fi

# Claude Code CLI
if [ -d "$HOME/.local/bin" ]; then
  export PATH="$HOME/.local/bin:$PATH"
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
export PGENV_ROOT="$HOME/.pgenv"
if [ -d "$PGENV_ROOT" ]; then
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
      export STARSHIP_CONFIG="$DOTFILES/starship/starship.toml"
      eval "$(starship init zsh)" >/dev/null 2>&1
    }
fi
