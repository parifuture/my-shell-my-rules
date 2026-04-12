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
| AWS credentials via 1Password (awsp profile switcher) |
| Git SSH + commit signing via 1Password |

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

- [ ] **Git SSH** — ensure your SSH key in 1Password is added to both GitHub and GitLab:
  - GitHub: `https://github.com/settings/keys` — add as **Authentication key** and **Signing key**
  - GitLab: add as **Authentication & Signing** key
  - Add host keys to known_hosts:
    ```sh
    ssh-keyscan -t ed25519,rsa github.com >> ~/.ssh/known_hosts
    ssh-keyscan -t ed25519,rsa gitlab.example.com >> ~/.ssh/known_hosts  # your GitLab host
    ```
  - Git commit signing is pre-configured in `.gitconfig` — just set your signing key:
    ```sh
    git config --global user.signingkey "$(ssh-add -L | head -1)"
    ```

- [ ] **AWS credentials via 1Password** — the `awsp` shell function loads AWS credentials from 1Password on demand:
  1. Sync your AWS Secrets Manager secrets into 1Password:
     ```sh
     export AWS_PROFILE=your-sso-profile AWS_REGION=us-west-1 OP_VAULT="Your Vault"
     ./scripts/aws-secrets-to-1password.sh --all
     ```
  2. Create the profiles config at `~/.aws/1p-profiles.conf`:
     ```ini
     # Default vault for all profiles
     vault=Your Vault Name

     [default]
     op_item=your-1password-item
     key_field=aws_access_key_id
     secret_field=aws_secret_access_key
     region=us-west-1

     [bedrock]
     op_item=your-1password-item
     key_field=bedrock_aws_access_key_id
     secret_field=bedrock_aws_secret_access_key
     region=us-west-1
     ```
  3. Usage:
     ```sh
     awsp default    # load general AWS credentials (Touch ID prompt)
     awsp bedrock    # load Bedrock/LLM credentials
     awsp            # show current profile
     awsp --list     # list available profiles
     ```

- [ ] **AeroSpace — Kitty floating window** — On first launch, manually resize and position
  the Kitty window to your preferred size. AeroSpace will remember the position after that.

- [ ] **PostgreSQL via pgenv** — postgres is managed by [pgenv](https://github.com/theory/pgenv)
  rather than brew so you can hold multiple major versions side-by-side and switch per-project.
  pgenv compiles postgres from source. The repo ships a bootstrap script that handles brew
  deps, build flags, initdb, user role, and extension setup in one idempotent command:
  ```sh
  # one-time prerequisite — clone pgenv (not a brew formula)
  git clone https://github.com/theory/pgenv.git ~/.pgenv
  exec zsh                              # picks up PGENV_ROOT + PATH from zshrc-macos.sh

  # then run the bootstrap — safe to re-run anytime
  ./scripts/pgenv-setup.sh
  ```
  What the script does (so you know what's installed):
  1. Installs brew build deps (`pkg-config`, `icu4c`, `util-linux`) if missing.
  2. Seeds `~/.pgenv/config/17.9.conf` with `PGENV_CONFIGURE_OPTIONS=(--with-uuid=e2fs)`
     **before** running `pgenv build`, because pgenv auto-generates that file during build
     and overrides any `PGENV_CONFIGURE_OPTIONS` you export in the shell (we learned this
     the hard way — see the memory note for the gory details).
  3. Builds `postgres 17.9` with `--with-uuid=e2fs` so the `uuid-ossp` contrib extension
     compiles in. This is the **only macOS-compatible UUID backend**:
     - `--with-uuid=bsd` fails — macOS's libc BSD UUID API doesn't match postgres's signatures.
     - `--with-uuid=ossp` via brew's `ossp-uuid` fails — its `<ossp/uuid.h>` redefines
       `uuid_t`, which collides with the macOS SDK's own `uuid_t` typedef.
     - `--with-uuid=e2fs` via brew's `util-linux` (which ships libuuid on macOS) works cleanly.
  4. Runs `pgenv use 17.9` to activate and start the server on port 5432.
  5. Creates a login superuser role matching your macOS username (pgenv's default `initdb`
     only creates the `postgres` user, unlike brew's postgres formula).
  6. Builds `pgvector` from source against pgenv's `pg_config` and installs it into
     pgenv's extension tree. Brew's `pgvector` formula is *not* used — it builds against
     brew's postgres install, which pgenv never loads from.
  7. Enables `uuid-ossp`, `citext`, `vector`, and `pg_trgm` extensions in `template1`,
     so every future database you create inherits all four automatically — no per-project
     `CREATE EXTENSION` needed. Backstage relies on `uuid_generate_v4()` from `uuid-ossp`
     and the `gin_trgm_ops` operator class from `pg_trgm` for fuzzy-text GIN indexes.

  Day-to-day: `pgenv start` / `pgenv stop` / `pgenv restart` to control the running cluster,
  `pgenv use <version>` to switch between built versions, `pgenv versions` to see what's
  installed locally, `pgenv available` to see what's downloadable.

  To add a different major version later: `PG_VERSION=18.3 ./scripts/pgenv-setup.sh`.

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

  **F1–F12 are mapped to macOS media keys** (brightness, playback, volume) so they work
  as expected without holding `fn`. This is handled in kanata because it intercepts keys
  before macOS can apply media key behavior.

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

## Finder setup

Run the Finder configuration script to set dev-friendly defaults:

```sh
# Requires fileicon and mysides (included in 10-essential Brewfile)
bash ~/code/personal/my-shell-my-rules/scripts/macos-finder.sh
```

This configures:
- **Default location**: opens `~/code` instead of Recents
- **View**: column view, path bar, status bar, full POSIX path in title bar
- **Files**: shows hidden files, all extensions, folders sorted first
- **Search**: scopes to current folder (not entire Mac)
- **Sidebar**: Home, Desktop, Downloads, code, Applications (removes Recents, Documents, Movies, Music, Pictures)
- **Folder icon**: custom purple terminal icon on `~/code` (stored in `assets/code-folder.icns`)
- **Cleanup**: disables `.DS_Store` on network and USB volumes


## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/macos-finder.sh` | Configures Finder defaults, sidebar, and custom `~/code` folder icon. Requires `fileicon` and `mysides`. |
| `scripts/aws-secrets-to-1password.sh` | Syncs AWS Secrets Manager secrets into 1Password. Interactive selection or `--all`. Compares and updates existing items. Config via `scripts/.env` (gitignored, see `.env.example`). |
| `scripts/pgenv-setup.sh` | Builds postgres via pgenv with `--with-uuid=bsd`, creates a login role for your macOS user, and enables `uuid-ossp` + `citext` in `template1`. Idempotent. Override version with `PG_VERSION=...`. |

---

### Configs still needing setup

- [ ] **Finder** — Run `bash ~/code/personal/my-shell-my-rules/scripts/macos-finder.sh` after installing brew packages to configure Finder defaults, sidebar, and custom folder icon.
- [ ] **fastfetch image** — Replace `fastfetch/images/link-green.png` with your own image if desired.
  Update the `source` path in `fastfetch/config.jsonc` to match.
