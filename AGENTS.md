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
- **Cloud:** Google Cloud Platform (gcloud)
- **OS:** macOS (Apple Silicon), with two external monitors when at desk

---

## What this repo is

A personal dotfiles repository for a brand new Mac setup. It was built by reviewing
the dotfiles of **linkarzu** (https://github.com/linkarzu/dotfiles-latest) and
selectively adopting what made sense for this developer's stack.

The repo lives at: `~/code/personal/my-shell-my-rules`

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
zshrc/zshrc-linux.sh       ← Linux equivalent
zshrc/modules/
  symlinks.sh              ← creates all symlinks on every shell start
  autocompletion.sh        ← zsh completion system config
  history.sh               ← HISTFILE, HISTSIZE, setopt flags
  alias-common.sh          ← aliases shared across platforms
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
| **Kitty** | Terminal emulator | GPU-accelerated, invented the Kitty Graphics Protocol (needed for image previews in Yazi/Neovim) |
| **Starship** | Shell prompt | Fast, highly configurable, language-version aware |
| **AeroSpace** | Window manager | No SIP disabling required, built-in shortcuts, TOML config, works great on macOS Sequoia |
| **Sketchybar** | Custom macOS menu bar | Replaces default menu bar, shows workspaces, battery, wifi, CPU, brew, etc. |
| **atuin** | Shell history | Replaces default history, fuzzy searchable, cross-machine sync via `Ctrl+R` |
| **uv** | Python version + package manager | Replaces pyenv + pip entirely, reads `.python-version` auto, downloads missing versions |
| **fnm** | Node.js version manager | Like nvm but fast, reads `.nvmrc` on `cd`, auto-downloads missing versions |
| **fzf** | Fuzzy finder | Powers `Ctrl+R` history (before atuin), `Ctrl+T` file search, `::` completion trigger |
| **zoxide** | Smart cd | Replaces `cd`, learns frequently visited dirs, aliased as `cd` |
| **eza** | ls replacement | Colors, icons, git status in file listings |
| **bat** | cat replacement | Syntax highlighting, aliased as `cat` |
| **lazygit** | Git TUI | Visual git interface, aliased as `lg` |
| **yazi** | Terminal file manager | Navigate dirs visually, image previews via Kitty Graphics Protocol |
| **kanata** | Keyboard remapper | App switcher layer (hold Enter), AirPods connect chord (a+i+r) |
| **btop** | System monitor | Beautiful terminal system monitor with custom theme |
| **fastfetch** | System info on shell start | Shows hardware/software info with image on every new terminal |

---

## Important decisions already made — do not reverse without asking

- **No tmux** — developer works locally only, MacOS sleep preserves sessions perfectly
- **No Neovim vi-mode in zsh** — removed deliberately, developer not yet familiar with vim
- **uv only for Python** — pyenv was considered then dropped, uv handles everything
- **No Prettier** — developer does not use Prettier
- **AeroSpace over yabai** — no SIP required, simpler config
- **Kitty over Rio** — stability and ecosystem maturity (Rio is promising but pre-1.0)
- **No tmux or sesh** — not needed for local-only workflow
- **Bash upgraded via Homebrew** — macOS ships bash 3.2 (GPL licensing issue), Homebrew installs 5.x

---

## Workspace layout (AeroSpace)

```
Monitor 1 (main):      workspace 1 → Kitty (floating) + Slack (tiled)
                       workspace 2 → overflow
Monitor 2 (secondary): workspace 3 → VS Code + Chrome (tiled 50/50)
                       workspace 4 → Figma (100%)
Laptop only:           all workspaces fall back to built-in screen
```

---

## Sketchybar bar layout

```
Left:  [ Apple menu ] [ 1 ] [ 2 ] [ 3 ] [ 4 ] [ App icon ]
Right: [ Monday 3 January 14:22 ] [ brew ] [ DND ] [ WiFi ] [ Battery ] [ Volume ] [ CPU ]
```

- AeroSpace workspace numbers highlight green when active
- WiFi click toggles showing/hiding the IP address
- Volume slider appears briefly when volume changes, right-click to pick audio device
- Brew count updates automatically after any brew command (wired in zshrc)

---

## Kanata app switcher

Hold `Enter` to activate apps layer, then press:

| Key | App |
|-----|-----|
| `k` | Kitty |
| `c` | Chrome |
| `z` | Zen Browser |
| `s` | Slack |
| `v` | VS Code |
| `f` (space) | Figma |
| `d` | Discord |
| `o` | Obsidian |
| `w` | Windows App |
| `p` | Postman |
| `a` | System Settings |

Chord `a+i+r` simultaneously → connect AirPods Pro.
Update `'AirPods Pro'` in `kanata/kanata.kbd` if the device name differs.

---

## Configs that are still placeholders

- `kitty/kitty.conf` — placeholder, not yet configured
- `fastfetch/images/link-green.png` — using original author's image, replace with your own

---

## Configs that need manual setup (cannot be symlinked)

- **BetterTouchTool** — import `betterTouchTool/preset.bttpreset` via File → Import Preset
- **Kanata** — needs accessibility permissions + `sudo brew services start kanata`
- **Sketchybar** — needs `brew services start sketchybar`
- **bash** — needs `sudo bash -c 'echo /opt/homebrew/bin/bash >> /etc/shells'` once
- **fzf** — needs `echo -e "y\ny\nn" | /opt/homebrew/opt/fzf/install` after brew install
- **atuin** — optionally `atuin login` or `atuin register` for cross-machine sync

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
