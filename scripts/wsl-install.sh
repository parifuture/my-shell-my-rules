#!/usr/bin/env bash
# ~/code/my-shell-my-rules/scripts/wsl-install.sh
# Install CLI tools on Ubuntu WSL2 — mirrors brew/00-base + brew/10-essential
# Usage: bash ~/code/my-shell-my-rules/scripts/wsl-install.sh
#
# Requires: Ubuntu 24.04 WSL2, sudo access
# Homebrew (Linuxbrew) is used for tools not in apt or where apt versions are too old.

set -euo pipefail

# ---------------------------------------------------------------------------
#  Helpers
# ---------------------------------------------------------------------------

info()  { printf '\033[1;34m==> %s\033[0m\n' "$*"; }
warn()  { printf '\033[1;33m==> %s\033[0m\n' "$*"; }
ok()    { printf '\033[1;32m==> %s\033[0m\n' "$*"; }

need_cmd() {
  if ! command -v "$1" &>/dev/null; then
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
#  Phase 1 — apt packages (things Ubuntu ships well)
# ---------------------------------------------------------------------------

info "Updating apt package list..."
sudo apt update -qq

APT_PACKAGES=(
  # Shell
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting

  # Already in Ubuntu but pin explicitly
  git
  wget
  curl
  unzip

  # Fuzzy finder
  fzf

  # Modern CLI replacements
  bat          # cat with syntax highlighting (binary: batcat, needs alias)
  ripgrep      # fast grep
  fd-find      # fast find (binary: fdfind, needs alias)

  # JSON
  jq

  # System monitor
  btop

  # GitHub CLI
  gh

  # Python (system)
  python3
  python3-pip
  python3-venv

  # Build essentials (needed for compiling Go tools, pgvector, etc.)
  build-essential
)

info "Installing apt packages..."
sudo apt install -y -qq "${APT_PACKAGES[@]}"

# ---------------------------------------------------------------------------
#  Phase 2 — Homebrew (Linuxbrew) for tools not in apt or with stale versions
# ---------------------------------------------------------------------------

if ! need_cmd brew; then
  info "Installing Homebrew (Linuxbrew)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Make sure brew is on PATH for the rest of this script
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true

BREW_PACKAGES=(
  # Shell
  starship         # cross-shell prompt
  atuin            # shell history sync

  # Node version manager
  fnm

  # Python tooling
  uv               # fast Python package/version manager

  # Modern CLI
  zoxide           # smart cd (apt version too old)
  eza              # ls replacement (not in apt)
  yazi             # terminal file manager
  vivid            # LS_COLORS generator

  # YAML
  yq               # YAML processor (snap version differs)

  # Git
  git-delta        # beautiful diffs
  lazygit          # TUI git client

  # Languages
  go
  deno
  pnpm

  # Go tooling
  gopls
  delve
  staticcheck
  golang-migrate

  # Dev tools
  neovim           # apt version is old
  biome            # JS/TS formatter + linter
  awscli

  # System info
  fastfetch         # not in Ubuntu 24.04 apt

  # Kubernetes & DevOps
  kubernetes-cli    # kubectl — not in apt without adding Google's repo
  helm
  argo
  argocd

  # Domain inspection
  # retlehs/tap/quien — uncomment after tapping:
  #   brew tap retlehs/tap
  #   brew install quien
)

info "Installing Homebrew packages..."
brew install "${BREW_PACKAGES[@]}" 2>&1 | grep -v "already installed" || true

# ---------------------------------------------------------------------------
#  Phase 3 — Tapped formulae (need explicit tap first)
# ---------------------------------------------------------------------------

info "Installing tapped formulae..."

brew tap jesseduffield/lazygit 2>/dev/null || true
brew tap retlehs/tap 2>/dev/null || true

# lazygit is already in BREW_PACKAGES via jesseduffield tap
# quien — WHOIS/DNS/SSL/HTTP/SEO TUI
brew install retlehs/tap/quien 2>/dev/null || warn "quien install failed — check tap"

# ---------------------------------------------------------------------------
#  Phase 4 — Go tools (installed via go install)
# ---------------------------------------------------------------------------

if need_cmd go; then
  info "Installing Go tools via go install..."
  go install golang.org/x/tools/cmd/goimports@latest
  go install go.uber.org/mock/mockgen@latest
else
  warn "go not found, skipping Go tool installs"
fi

# ---------------------------------------------------------------------------
#  Phase 5 — GitLab runner (official apt repo)
# ---------------------------------------------------------------------------

if ! need_cmd gitlab-runner; then
  info "Installing gitlab-runner..."
  curl -fsSL "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash
  sudo apt install -y gitlab-runner
else
  ok "gitlab-runner already installed"
fi

# ---------------------------------------------------------------------------
#  Phase 6 — 1Password CLI (official apt repo)
# ---------------------------------------------------------------------------

if ! need_cmd op; then
  info "Installing 1Password CLI..."
  curl -fsSL https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg 2>/dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    sudo tee /etc/apt/sources.list.d/1password.list > /dev/null
  sudo apt update -qq && sudo apt install -y 1password-cli
else
  ok "1Password CLI (op) already installed"
fi

# ---------------------------------------------------------------------------
#  Phase 7 — Google Cloud SDK
# ---------------------------------------------------------------------------

if ! need_cmd gcloud; then
  info "Installing Google Cloud SDK..."
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg 2>/dev/null
  sudo apt update -qq && sudo apt install -y google-cloud-cli
else
  ok "gcloud already installed"
fi

# ---------------------------------------------------------------------------
#  Done
# ---------------------------------------------------------------------------

ok "WSL2 setup complete."
echo ""
echo "Reminders:"
echo "  - fd is installed as 'fdfind' — alias fd=fdfind in your zshrc"
echo "  - bat is installed as 'batcat' — alias bat=batcat in your zshrc"
echo "  - Run 'chsh -s \$(which zsh)' if zsh isn't your default shell"
echo "  - Fonts (MonoLisa, Symbols Nerd Font) must be installed on Windows, not WSL"
echo "  - Run scripts/winget-install.ps1 on the Windows side for GUI apps"
