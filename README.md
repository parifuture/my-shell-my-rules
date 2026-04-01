# my-shell-my-rules

Personal dotfiles. Terminal: **Kitty**.

---

## Credit

This repo was built by going through the dotfiles of **linkarzu** — a developer and educator who makes exceptional content about macOS workflows, Neovim, and terminal setups.

- GitHub: [github.com/linkarzu/dotfiles-latest](https://github.com/linkarzu/dotfiles-latest)
- YouTube: [youtube.com/@linkarzu](https://www.youtube.com/@linkarzu)

Huge tip of the hat. The quality of that repo is exceptional — well-structured, well-commented, and clearly the result of years of refinement. This repo picks and chooses what applies to my stack, but the ideas, patterns, and inspiration are entirely his.

---

## What I'm replicating

| Component |
|-----------|
| Modular structure (common + OS-specific files) |
| Starship prompt |
| zsh-autosuggestions + fzf + atuin |
| eza + bat + zoxide |
| Colorscheme system |
| Kubernetes aliases |
| Symlinks module running on every shell start |

---

## Installation order

```sh
# 1. Clone the repo
git clone git@github.com:parifuture/my-shell-my-rules.git ~/code/personal/my-shell-my-rules

# 2. Create the initial zshrc symlink (the symlinks module handles the rest after this)
ln -snf ~/code/personal/my-shell-my-rules/zshrc/zshrc-file.sh ~/.zshrc

# 3. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 4. Install packages in order
brew bundle --file=~/code/personal/my-shell-my-rules/brew/00-base/Brewfile
brew bundle --file=~/code/personal/my-shell-my-rules/brew/10-essential/Brewfile
brew bundle --file=~/code/personal/my-shell-my-rules/brew/15-nice-to-haves/Brewfile

# 5. Set up fzf shell integration
echo -e "y\ny\nn" | /opt/homebrew/opt/fzf/install

# 6. Source zshrc to apply everything
source ~/.zshrc
```

---

## Post-installation manual steps

### One-time setup

- [ ] **bash** — Register the Homebrew bash so scripts can use it:
  ```sh
  sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'
  ```

- [ ] **BetterTouchTool** — Presets cannot be symlinked, must be imported manually:
  Open BTT → `File → Import Preset` → select `~/code/personal/my-shell-my-rules/betterTouchTool/preset.bttpreset`
  When you make changes in BTT, re-export the preset back to that path to keep it in sync.

- [ ] **atuin** — Set up history sync (optional):
  ```sh
  atuin register   # create account for cross-machine sync
  # or
  atuin login      # if you already have an account
  ```

- [ ] **Touch ID for sudo** — run this once to enable fingerprint for all `sudo` commands.
  Uses `sudo_local` which survives macOS updates (unlike editing `/etc/pam.d/sudo` directly):
  ```sh
  sudo tee /etc/pam.d/sudo_local << 'EOF'
  auth       sufficient     pam_tid.so
  EOF
  ```
  After this, every `sudo` command will prompt for Touch ID instead of your password.

- [ ] **1Password** — two things to enable in 1Password app → Settings → Developer:
  1. **"Connect with 1Password CLI"** — lets `op` use Touch ID instead of master password
  2. **"Use the SSH agent"** — all SSH keys stored in 1Password vault work automatically with Touch ID, no `ssh-add` needed

- [ ] **AeroSpace — Kitty floating window** — On first launch, manually resize and position
  the Kitty window to your preferred size. AeroSpace will remember the position after that.

- [ ] **sketchybar** — custom macOS status bar replacement. Three steps:

  1. **Hide the default macOS menu bar** — this is required so both bars don't overlap:
     - **macOS Sonoma / Sequoia**: `System Settings → Control Center → "Automatically hide and show the menu bar"` → set to **Always**
     - **macOS Ventura**: `System Settings → Desktop & Dock → "Automatically hide and show the menu bar"` → set to **Always**

  2. **Enable "Displays have separate Spaces"** — required for sketchybar to work on all monitors:
     - `System Settings → Desktop & Dock → "Displays have separate Spaces"` → turn **on** (requires logout/login)

  3. **Start the service**:
     ```sh
     brew services start sketchybar
     ```

- [ ] **Kanata** — the Homebrew formula does not include the `cmd` feature needed for app switching.
  Install the `cmd_allowed` binary manually from the GitHub release:
  ```sh
  curl -L -o /tmp/kanata.zip \
    https://github.com/jtroo/kanata/releases/download/v1.11.0/macos-binaries-arm64.zip
  unzip /tmp/kanata.zip -d /tmp/kanata/
  sudo cp /tmp/kanata/kanata_macos_cmd_allowed_arm64 /opt/homebrew/bin/kanata
  sudo chmod +x /opt/homebrew/bin/kanata
  ```
  **Enable Karabiner driver** — kanata requires the Karabiner virtual keyboard driver to intercept keys.
  After installing `karabiner-elements` via Brew, activate the driver:
  ```sh
  /Applications/.Karabiner-VirtualHIDDevice-Manager.app/Contents/MacOS/Karabiner-VirtualHIDDevice-Manager activate
  ```
  Then go to `System Settings → General → Login Items & Extensions` and enable the Karabiner driver if prompted.
  **Reboot after enabling** — the driver won't fully load until you restart.

  **Launch the Karabiner VirtualHIDDevice daemon** — kanata needs the virtual HID driver but **not** the full Karabiner-Elements app.
  If Karabiner-Elements is running, it grabs exclusive access to the keyboard and blocks kanata. Kill its services first:
  ```sh
  sudo killall karabiner_console_user_server karabiner_session_monitor Karabiner-Core-Service Karabiner-Menu Karabiner-NotificationWindow
  ```
  The `Karabiner-VirtualHIDDevice-Daemon` (the only process kanata needs) stays running.
  Do **not** add Karabiner-Elements to Login Items — only the driver daemon should auto-start.

  **Bypass Gatekeeper** — macOS blocks unsigned binaries downloaded from the internet.
  Remove the quarantine flag so it can run:
  ```sh
  sudo xattr -cr /opt/homebrew/bin/kanata
  ```
  **Grant permissions** — two things needed:
  1. **Accessibility**: `System Settings → Privacy & Security → Accessibility` → click `+` → `Cmd+Shift+G` → type `/opt/homebrew/bin/` → select `kanata`
  2. **Input Monitoring**: `System Settings → Privacy & Security → Input Monitoring` → add your terminal app (Kitty)

  **Start as a LaunchDaemon** — runs kanata as root at boot, auto-restarts on crash:
  ```sh
  sudo cp ~/code/personal/my-shell-my-rules/kanata/com.kanata.daemon.plist /Library/LaunchDaemons/
  sudo launchctl load /Library/LaunchDaemons/com.kanata.daemon.plist
  ```
  Logs: `/tmp/kanata.out.log` and `/tmp/kanata.err.log`

  To stop/start manually:
  ```sh
  sudo launchctl unload /Library/LaunchDaemons/com.kanata.daemon.plist  # stop
  sudo launchctl load /Library/LaunchDaemons/com.kanata.daemon.plist    # start
  ```

  The AirPods chord is `a+i+r` pressed simultaneously. Update `'AirPods Pro'` in `kanata/kanata.kbd` to match your exact AirPods name if different.

  > **Upgrades**: `brew upgrade` won't update this. Check [github.com/jtroo/kanata/releases](https://github.com/jtroo/kanata/releases) manually and re-run the steps above with the new version.

- [ ] **Neovim** — on first launch, install all plugins automatically:
  ```sh
  v  # opens nvim, lazy.nvim will auto-install everything on first run
  ```
  Then run `:checkhealth` inside Neovim to verify everything is working.

---

## AeroSpace cheatsheet

AeroSpace is a keyboard-driven tiling window manager. It uses vim-style `hjkl` for directions. Windows are organized in a tree — containers hold windows, and each container has a layout (tiles or accordion) and orientation (horizontal or vertical).

### Concepts

- **Focus** = select a window (doesn't move anything)
- **Move** = physically reposition the focused window
- **Tiles** = windows side-by-side, all visible
- **Accordion** = windows stacked, only one visible at a time (navigate with focus)
- **Service mode** = secondary keybinding layer for less common operations

### Navigation

| Keys | Action |
|------|--------|
| `cmd-shift-h/j/k/l` | Focus window left / down / up / right |
| `alt-o` | Toggle focus between last two windows |

### Moving windows

| Keys | Action |
|------|--------|
| `ctrl-alt-arrow keys` | Move window left / down / up / right |
| `alt-shift-tab` | Move workspace to next monitor |

### Layout

| Keys | Action |
|------|--------|
| `cmd-shift-f` | Toggle fullscreen |
| `alt-/` | Cycle tile orientation (horizontal ↔ vertical) |
| `alt-,` | Cycle accordion orientation (horizontal ↔ vertical) |
| `alt-shift--` | Shrink window (50px) |
| `alt-shift-=` | Grow window (50px) |

### Workspaces

| Keys | Workspace | Default monitor | Default apps |
|------|-----------|-----------------|--------------|
| `Caps Lock + v` | 1 (comms) | Main | Outlook, Slack, Safari (EA Window) |
| `Caps Lock + b` | 2 (general) | Main | Catch all |
| `Caps Lock + n` | 3 (dev) | Secondary | Kitty (floating), VS Code, Figma |
| `Caps Lock + m` | 4 (private) | Secondary | Safari (personal), Obsidian |

On a single display, all workspaces fall back to the built-in screen.

### Service mode

Enter with `alt-shift-;` — every action auto-returns to main mode.

| Keys | Action |
|------|--------|
| `esc` | Reload config and exit service mode |
| `r` | Flatten/reset workspace layout tree |
| `f` | Toggle floating ↔ tiling for focused window |
| `backspace` | Close all windows except current |
| `alt-shift-h/j/k/l` | Join focused window with neighbor into a container |

### Common workflows

1. **Messy layout?** `alt-shift-;` then `r` to flatten the tree back to clean state
2. **Want a window floating?** `alt-shift-;` then `f` to toggle it
3. **Group two windows together?** `alt-shift-;` then `alt-shift-h/j/k/l` to join them
4. **Quick window swap?** `alt-o` toggles between your last two focused windows

Config: `aerospace/aerospace.toml`

---

### Configs still needing setup

- [ ] **fastfetch image** — Replace `fastfetch/images/link-green.png` with your own image if desired.
  Update the `source` path in `fastfetch/config.jsonc` to match.
