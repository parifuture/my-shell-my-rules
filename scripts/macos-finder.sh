#!/usr/bin/env bash
# ~/code/personal/my-shell-my-rules/scripts/macos-finder.sh
# Configure Finder defaults, sidebar, and custom folder icons.
# Usage: bash ~/code/personal/my-shell-my-rules/scripts/macos-finder.sh
# Requires: brew install fileicon mysides

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

echo "==> Configuring Finder defaults..."

# ── Default location ──────────────────────────────────────────────
# Open ~/code instead of Recents
defaults write com.apple.finder NewWindowTarget -string "PfLo"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/code/"

# ── View preferences ─────────────────────────────────────────────
# Default to column view (clmv = column, Nlsv = list, icnv = icon, glyv = gallery)
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Show path bar at the bottom
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar (item count + disk space)
defaults write com.apple.finder ShowStatusBar -bool true

# Show full POSIX path in Finder title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# ── File display ──────────────────────────────────────────────────
# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable warning when changing file extensions
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Search the current folder by default (not entire Mac)
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# ── Behavior ──────────────────────────────────────────────────────
# Avoid creating .DS_Store files on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Spring-loaded folders (drag-hover to open) — fast delay
defaults write NSGlobalDomain com.apple.springing.enabled -bool true
defaults write NSGlobalDomain com.apple.springing.delay -float 0.2

# ── Sidebar ───────────────────────────────────────────────────────
if command -v mysides &>/dev/null; then
  echo "==> Configuring Finder sidebar..."
  # Remove default clutter
  mysides remove "Recents" 2>/dev/null || true
  mysides remove "Documents" 2>/dev/null || true
  mysides remove "Movies" 2>/dev/null || true
  mysides remove "Music" 2>/dev/null || true
  mysides remove "Pictures" 2>/dev/null || true

  # Add dev-focused items (mysides skips duplicates)
  mysides add "Home" "file://${HOME}/" 2>/dev/null || true
  mysides add "Desktop" "file://${HOME}/Desktop/" 2>/dev/null || true
  mysides add "Downloads" "file://${HOME}/Downloads/" 2>/dev/null || true
  mysides add "code" "file://${HOME}/code/" 2>/dev/null || true
  mysides add "Applications" "file:///Applications/" 2>/dev/null || true
else
  echo "⚠  mysides not found — skipping sidebar config (brew install mysides)"
fi

# ── Custom folder icon for ~/code ─────────────────────────────────
ICON_PATH="${REPO_DIR}/assets/code-folder.icns"
if command -v fileicon &>/dev/null; then
  if [[ -f "$ICON_PATH" ]]; then
    echo "==> Setting custom icon for ~/code..."
    fileicon set "${HOME}/code" "$ICON_PATH"
  else
    echo "⚠  Icon not found at $ICON_PATH — skipping folder icon"
  fi
else
  echo "⚠  fileicon not found — skipping folder icon (brew install fileicon)"
fi

# ── Restart Finder ────────────────────────────────────────────────
echo "==> Restarting Finder..."
killall Finder

echo "✓  Finder configured!"
