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
git clone git@github.com:parifuture/my-shell-my-rules.git ~/code/my-shell-my-rules

# 2. Create the initial zshrc symlink (the symlinks module handles the rest after this)
ln -snf ~/code/my-shell-my-rules/zshrc/zshrc-file.sh ~/.zshrc

# 3. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 4. Install packages in order
brew bundle --file=~/code/my-shell-my-rules/brew/00-base/Brewfile
brew bundle --file=~/code/my-shell-my-rules/brew/10-essential/Brewfile
brew bundle --file=~/code/my-shell-my-rules/brew/15-nice-to-haves/Brewfile

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
  Open BTT → `File → Import Preset` → select `~/code/my-shell-my-rules/betterTouchTool/preset.bttpreset`
  When you make changes in BTT, re-export the preset back to that path to keep it in sync.

- [ ] **atuin** — Set up history sync (optional):
  ```sh
  atuin register   # create account for cross-machine sync
  # or
  atuin login      # if you already have an account
  ```

- [ ] **AeroSpace — Kitty floating window** — On first launch, manually resize and position
  the Kitty window to your preferred size. AeroSpace will remember the position after that.

- [ ] **sketchybar** — start as a background service after installation:
  ```sh
  brew services start sketchybar
  ```

- [ ] **Kanata** — requires accessibility permissions and needs to run as a background service:
  ```sh
  # Grant accessibility permissions in System Settings → Privacy & Security → Accessibility → add kanata
  # Then start it as a service
  sudo brew services start kanata
  ```
  The AirPods chord is `a+i+r` pressed simultaneously. Update `'AirPods Pro'` in `kanata/kanata.kbd` to match your exact AirPods name if different.

- [ ] **Neovim** — on first launch, install all plugins automatically:
  ```sh
  v  # opens nvim, lazy.nvim will auto-install everything on first run
  ```
  Then run `:checkhealth` inside Neovim to verify everything is working.

### Configs still needing setup

- [ ] **Kitty** — `kitty/kitty.conf` is a placeholder. Configure fonts, colors, and keybindings.
- [ ] **Starship** — `starship/starship.toml` is a placeholder. Configure the prompt.
- [ ] **fastfetch image** — Replace `fastfetch/images/link-green.png` with your own image if desired.
  Update the `source` path in `fastfetch/config.jsonc` to match.
