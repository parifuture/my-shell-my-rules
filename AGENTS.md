# AGENTS.md — Context for AI Assistants

This file gives you everything you need to work on this repository without losing context.
Read this fully before making any changes.

---

## Who owns this repo

A software developer working primarily with:
- **Frontend:** React and related frontend technologies
- **Backend:** Node.js, TypeScript, Golang
- **Learning:** Rust (beginner)
- **Infrastructure:** Kubernetes (uses kubectl, helm, kubectx, kubens)
- **Cloud:** Google Cloud Platform (gcloud), AWS (via 1Password-backed profiles)
- **OS:** macOS (Apple Silicon) + Ubuntu 24.04 on WSL2 (Windows, Ryzen 9 7900X + RTX 4090)

---

## What this repo is

A personal dotfiles repository shared across **macOS** and **WSL2 (Ubuntu 24.04)**.
It was built by reviewing the dotfiles of **linkarzu** (https://github.com/linkarzu/dotfiles-latest)
and selectively adopting what made sense for this developer's stack.

- macOS: `~/code/personal/my-shell-my-rules`
- WSL2: `~/code/my-shell-my-rules`

---

## How the repo works

### Symlinks
`zshrc/modules/symlinks.sh` is sourced on every shell start. It creates symlinks
from `~/.config/<tool>` → `~/code/personal/my-shell-my-rules/<tool>`. This means every config
in this repo is automatically linked to where the tool expects it. When you add a new
config, add its symlink here.

### zshrc structure
```
zshrc/zshrc-file.sh        ← symlinked to ~/.zshrc, sources common + OS-specific
zshrc/zshrc-common.sh      ← sources all modules (platform-agnostic)
zshrc/zshrc-macos.sh       ← macOS tools, plugins, PATH, all CLI tool inits
zshrc/zshrc-linux.sh       ← Linux/WSL2 equivalent (vscode-sync lives here)
zshrc/modules/
  symlinks.sh              ← creates all symlinks on every shell start
  autocompletion.sh        ← zsh completion system config
  history.sh               ← HISTFILE, HISTSIZE, setopt flags
  alias-common.sh          ← aliases shared across platforms
  awsp.sh                  ← awsp + claudeb (AWS via 1Password, shared)
  1password-wsl.sh         ← WSL2: SSH agent bridge + op session persistence
  secrets.sh               ← loads API keys from 1Password on shell start
```

### Brewfiles
Three tiers — install in order:
```
brew/00-base/Brewfile       ← core terminal tools (install first)
brew/10-essential/Brewfile  ← dev tools, apps, languages
brew/15-nice-to-haves/Brewfile ← optional but wanted apps
```

---

## Key tools and why

| Tool | Purpose | Why chosen |
|------|---------|-----------|
| **Kitty** | Terminal emulator | GPU-accelerated, Kitty Graphics Protocol for image previews, custom Cmd keybindings for macOS-style line editing |
| **Starship** | Shell prompt | Fast, highly configurable, language-version aware |
| **atuin** | Shell history | Replaces default history, fuzzy searchable, cross-machine sync via `Ctrl+R` |
| **uv** | Python version + package manager | Replaces pyenv + pip entirely, reads `.python-version` auto, downloads missing versions |
| **fnm** | Node.js version manager | Like nvm but fast, reads `.nvmrc` on `cd`, auto-downloads missing versions |
| **fzf** | Fuzzy finder | Powers `Ctrl+R` history (before atuin), `Ctrl+T` file search, `::` completion trigger |
| **zoxide** | Smart cd | Replaces `cd`, learns frequently visited dirs, aliased as `cd` |
| **eza** | ls replacement | Colors, icons, git status in file listings |
| **bat** | cat replacement | Syntax highlighting, aliased as `cat` |
| **lazygit** | Git TUI | Visual git interface, aliased as `lg` |
| **yazi** | Terminal file manager | Navigate dirs visually, image previews via Kitty Graphics Protocol |
| **btop** | System monitor | Beautiful terminal system monitor with custom theme |
| **fastfetch** | System info on shell start | Shows hardware/software info with image on every new terminal |
| **1Password CLI** | Secrets management | SSH agent for git, AWS credential injection via `awsp`, commit signing via Touch ID |

---

## Commit/push rule for `claude-code/settings.json`

`claude-code/settings.json` frequently contains secrets (API keys, tokens, provider credentials) in local-dev state. When committing or pushing in this repo: if `claude-code/settings.json` has uncommitted changes, silently skip that file and commit/push everything else. Do not ask, do not warn, do not remind — just leave it unstaged and proceed. Never commit this file unless I explicitly name it in the request.

---

## Important decisions already made — do not reverse without asking

- **No tmux** — developer works locally only, MacOS sleep preserves sessions perfectly
- **No Neovim vi-mode in zsh** — removed deliberately, developer not yet familiar with vim
- **uv only for Python** — pyenv was considered then dropped, uv handles everything
- **No Prettier** — developer does not use Prettier
- **Native macOS Spaces over tiling WMs** — AeroSpace and Sketchybar were trialed and removed; prefers built-in Mission Control
- **Kitty over Rio** — stability and ecosystem maturity (Rio is promising but pre-1.0)
- **No tmux or sesh** — not needed for local-only workflow
- **Bash upgraded via Homebrew** — macOS ships bash 3.2 (GPL licensing issue), Homebrew installs 5.x
- **WezTerm on Windows/WSL2** — GPU terminal running on Windows side, connects to WSL2 default domain
- **vscode-sync is manual** — `vscode-sync push/pull/diff` by hand; auto-sync on shell start would silently clobber UI-driven edits
- **op session cached in `~/.config/op/.session`** — Linux op binary can't use Windows biometric directly; token file (chmod 600) bridges the gap. Wipe with `op-signout`.

---

## AWS credentials via 1Password

The `awsp` function in `zshrc/modules/awsp.sh` loads AWS credentials from 1Password on demand.
Works on both macOS and WSL2.
Profiles are defined in `~/.aws/1p-profiles.conf` (not committed — contains vault name and item references).

```sh
awsp default    # general AWS credentials
awsp bedrock    # Bedrock/LLM credentials
awsp            # show current profile
awsp --list     # list available profiles
```

No credentials are ever stored on disk. Each `awsp` call triggers a Touch ID prompt.
SSO profiles remain in `~/.aws/config` for admin/console work but are separate from `awsp`.

### Scripts

- `scripts/macos-finder.sh` — configures Finder defaults, sidebar, and custom `~/code` folder icon.
  Requires `fileicon` and `mysides`. Run once after fresh install.
- `scripts/aws-secrets-to-1password.sh` — syncs AWS Secrets Manager → 1Password.
  Config via `scripts/.env` (gitignored). See `scripts/.env.example` for format.
  Supports interactive selection, `--all`, and diff-based updates (won't duplicate).

---

## Git SSH and commit signing

All git operations use SSH keys from 1Password's SSH agent.
- **macOS:** agent socket at `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock`
- **WSL2:** agent bridged via `npiperelay.exe + socat` → `~/.1password/agent.sock` (module: `1password-wsl.sh`)
Commits and tags are signed with the same SSH key — configured globally in `~/.gitconfig`:

- `gpg.format = ssh`
- `commit.gpgsign = true`
- `tag.gpgsign = true`
- Allowed signers file at `~/.ssh/allowed_signers`

Works on both GitHub and GitLab. The signing key must be registered on both platforms.

---

## Kitty keybindings

Kitty has custom keybindings for macOS-style line editing (terminal doesn't get these from Cocoa):

| Keys | Action | Implementation |
|------|--------|---------------|
| `Cmd+Left` | Jump to beginning of line | Sends Home |
| `Cmd+Right` | Jump to end of line | Sends End |
| `Cmd+Backspace` | Delete entire line | Sends `Ctrl+U` (`\x15`) |

These are in `kitty/kitty.conf`. When adding new Cmd-based shortcuts, use `send_key` or `send_text` to translate them into terminal escape sequences.

---

## Finder configuration

`scripts/macos-finder.sh` configures Finder via `defaults write` commands. It requires `fileicon` and `mysides` (in `brew/10-essential/Brewfile`).

What it sets:
- Default location: `~/code` (not Recents)
- Column view, path bar, status bar, POSIX path in title bar
- Shows hidden files, all extensions, folders first
- Search scoped to current folder
- Dev-focused sidebar: Home, Desktop, Downloads, code, Applications
- Custom purple terminal folder icon on `~/code` (`assets/code-folder.icns`)
- No `.DS_Store` on network/USB volumes

Run once after a fresh install. Re-run if Finder preferences are reset.

---

## Configs that are still placeholders

- `fastfetch/images/link-green.png` — using original author's image, replace with your own

---

## Configs that need manual setup (cannot be symlinked)

### Both platforms
- **Git signing** — add SSH public key as a signing key on GitHub and GitLab
- **AWS (awsp)** — create `~/.aws/1p-profiles.conf` with vault and profile definitions
- **atuin** — optionally `atuin login` or `atuin register` for cross-machine sync

### macOS only
- **BetterTouchTool** — import `betterTouchTool/preset.bttpreset` via File → Import Preset
- **bash** — needs `sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'` once
- **fzf** — needs `echo -e "y\ny\nn" | /opt/homebrew/opt/fzf/install` after brew install

### WSL2 only
- **1Password** — `op account add` + `op signin --raw > ~/.config/op/.session` once
- **VSCode settings** — `vscode-sync push` to deploy repo settings to Windows
- **WezTerm** — copy `wezterm/wezterm.lua` to `C:\Users\<you>\.config\wezterm\` once

---

## How to add a new tool config

1. Create `<toolname>/config-file` in the repo
2. Add a symlink entry in `zshrc/modules/symlinks.sh`
3. Add the brew install to the appropriate Brewfile tier
4. Add any shell init (eval, source, alias) to `zshrc/zshrc-macos.sh`
5. Add any useful commands to `CHEATSHEET.md`
6. If it needs a post-install manual step, add it to `README.md`

---

## File the user uses for quick reference

`CHEATSHEET.md` — contains key commands for lazygit, yazi, neovim, and other tools.
Keep this up to date when adding new tools.

---

## Original inspiration

This repo was built by reviewing:
- **linkarzu's dotfiles**: https://github.com/linkarzu/dotfiles-latest
- **linkarzu's YouTube**: https://www.youtube.com/@linkarzu

His repository is the gold standard for macOS dotfiles. This repo is a curated
subset adapted to this developer's stack. Credit and gratitude to linkarzu for
the exceptional quality of his work.
