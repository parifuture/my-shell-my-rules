# ~/code/personal/my-shell-my-rules/zshrc/modules/autocompletion.sh

zmodload zsh/complist

# zsh-completions (brew): extra completion functions (yarn, etc.)
# Must be prepended to fpath BEFORE compinit so new _* functions are picked up.
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh-completions" $fpath)
fi

# Repo-owned completions (e.g. _pnpm — pnpm has no brew completion package)
fpath=("$HOME/code/personal/my-shell-my-rules/zshrc/completions" $fpath)

# Auto-regenerate _pnpm when the pnpm binary is newer than the cached completion.
# Cheap: two stat calls per shell startup; the generator only fires after a pnpm upgrade.
if command -v pnpm &>/dev/null; then
  _pnpm_completion_file="$HOME/code/personal/my-shell-my-rules/zshrc/completions/_pnpm"
  _pnpm_bin="$(command -v pnpm)"
  if [[ ! -f "$_pnpm_completion_file" || "$_pnpm_bin" -nt "$_pnpm_completion_file" ]]; then
    pnpm completion zsh > "$_pnpm_completion_file" 2>/dev/null \
      && rm -f "$HOME/.zcompdump" "$HOME/.zcompdump-"*
  fi
  unset _pnpm_completion_file _pnpm_bin
fi

autoload -U compinit
compinit
_comp_options+=(globdots) # include hidden files in completions

# LS_COLORS — macOS ships with LSCOLORS (BSD) not LS_COLORS (GNU), which means
# zsh's completion and fzf-tab have no color info by default. Generate a rich
# palette via vivid (brew) or fall back to gdircolors (brew coreutils).
# Without this, every completion match renders in white.
if [[ -z "$LS_COLORS" ]]; then
  if command -v vivid &>/dev/null; then
    export LS_COLORS="$(vivid generate tokyonight-moon 2>/dev/null)"
  elif command -v gdircolors &>/dev/null; then
    eval "$(gdircolors -b)"
  fi
fi

# Make aliases that wrap ls/eza pick up the same completion + previews
compdef ll=ls
compdef la=ls
compdef lla=ls
compdef l=ls

setopt AUTO_LIST           # automatically list choices on ambiguous completion
setopt AUTO_MENU           # show the completion menu on successive tab press
setopt COMPLETE_IN_WORD    # complete from both ends of a word
setopt ALWAYS_TO_END       # move cursor to end of word after completion
setopt LIST_PACKED         # make list more compact
# NOTE: MENU_COMPLETE is intentionally NOT set — it conflicts with fzf-tab
# by auto-inserting the first match before fzf-tab can intercept.

zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' complete true
zstyle ':completion:*' menu select=2
zstyle ':completion:*' complete-options true
zstyle ':completion:*' file-sort modification
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-separator '→'

# Case-insensitive + fuzzy middle/suffix matching
# Lets you type `dl` → Downloads, `rdm` → README.md, `STGS` → settings, etc.
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Color file completions using LS_COLORS (dirs blue, executables green, etc.)
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
# Red highlight for PID in `kill <tab>`
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always

# Fancy section headers — bold, colored, framed with box-drawing chars
zstyle ':completion:*:descriptions' format '%B%F{blue}── %d ──%f%b'
zstyle ':completion:*:messages'     format '%B%F{magenta}── %d ──%f%b'
zstyle ':completion:*:warnings'     format '%B%F{red}── no matches: %d ──%f%b'
zstyle ':completion:*:corrections'  format '%B%F{yellow}── %d (errors: %e) ──%f%b'

# Prompts shown when the list is too big to fit or during scrolling
zstyle ':completion:*:default' list-prompt '%S%M matches — continue?%s'
zstyle ':completion:*:default' select-prompt '%Sscrolling: %p%s'

# Vi-style navigation inside the menu (hjkl) alongside the default arrow keys
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect '^[' send-break          # Esc cancels menu
bindkey -M menuselect '^M' .accept-line        # Enter accepts without running

# Map `opyarn` (alias for `op run --environment ... -- yarn` defined in alias-common.sh)
# onto the patched `_yarn` completer so `opyarn <Tab>` offers subcommands + scripts.
# Without this, zsh would try to complete using `_op` and miss the trailing `yarn` entirely.
compdef opyarn=yarn

#############################################################################
#                              fzf-tab
#############################################################################
# Replaces the native completion menu with an interactive fzf overlay that
# fuzzy-filters as you type, shows previews, and renders icons via eza.
#
# Plugin lives in ~/.local/share/zsh/plugins/fzf-tab — auto-cloned on first run.
# Docs: https://github.com/Aloxaf/fzf-tab

_FZF_TAB_DIR="$HOME/.local/share/zsh/plugins/fzf-tab"
if [[ ! -d "$_FZF_TAB_DIR" ]] && command -v git &>/dev/null; then
  git clone --depth 1 --quiet https://github.com/Aloxaf/fzf-tab "$_FZF_TAB_DIR" 2>/dev/null
fi

if [[ -f "$_FZF_TAB_DIR/fzf-tab.plugin.zsh" ]] && command -v fzf &>/dev/null; then
  # fzf-tab requirements: descriptions use [%d] format for group support,
  # and menu must be disabled so fzf-tab can capture the raw completion list.
  zstyle ':completion:*:descriptions' format '[%d]'
  zstyle ':completion:*' menu no

  source "$_FZF_TAB_DIR/fzf-tab.plugin.zsh"

  # Catch-all preview: whenever a completion has a real filesystem path,
  # show the directory contents (via eza with icons) or the file contents
  # (via bat). Applies to cd, ls, ll, la, vim, nvim, code, bat, cat, less,
  # rm, cp, mv, mkdir, any custom alias — anything that completes paths.
  if command -v eza &>/dev/null; then
    zstyle ':fzf-tab:complete:*:*' fzf-preview '
      if [[ -z $realpath ]]; then
        echo ${(P)word} 2>/dev/null
      elif [[ -d $realpath ]]; then
        eza -1 --color=always --icons=always --group-directories-first $realpath
      elif [[ -f $realpath ]]; then
        if command -v bat &>/dev/null; then
          bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null
        else
          head -200 $realpath 2>/dev/null
        fi
      else
        echo $word
      fi
    '
  fi

  # Preview for git: show commit / diff / file contents
  zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
    'git diff --color=always $word | head -200'
  zstyle ':fzf-tab:complete:git-checkout:*' fzf-preview \
    'git log --color=always --oneline --graph --decorate -20 $word 2>/dev/null || echo "branch: $word"'
  zstyle ':fzf-tab:complete:git-(log|show):*' fzf-preview \
    'git log --color=always --oneline --graph --decorate -20 $word 2>/dev/null'

  # Man page preview
  zstyle ':fzf-tab:complete:-command-:*' fzf-preview \
    '(out=$(tldr --color always "$word") 2>/dev/null && echo $out) || (out=$(MANWIDTH=$FZF_PREVIEW_COLUMNS man "$word") 2>/dev/null && echo $out) || (which "$word") || echo "${(P)word}"'

  # Process preview for kill
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
    '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
  zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

  # Switch groups with `<` and `>` (e.g. between "directory" and "file" categories)
  zstyle ':fzf-tab:*' switch-group '<' '>'

  # Accept the current match on Enter without running (same as native menu)
  zstyle ':fzf-tab:*' accept-line enter

  # Continuous drill-down: pressing `/` on a highlighted directory inserts it
  # and re-triggers completion, so you can walk `code/ → backstage/ → src/`
  # in one menu. Enter commits wherever you are.
  zstyle ':fzf-tab:*' continuous-trigger '/'

  # Make the popup bigger and more visually distinctive
  zstyle ':fzf-tab:*' popup-min-size 80 12
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup 2>/dev/null || zstyle ':fzf-tab:*' fzf-command fzf

  # Use the first matching group-name prefix as the group label
  zstyle ':fzf-tab:*' prefix ''
fi
unset _FZF_TAB_DIR

#############################################################################
#                              FZF defaults
#############################################################################
# Applies to ALL fzf invocations (Ctrl-R history, Ctrl-T file find, fzf-tab, etc.)
# Rounded border, inline info, Eldritch-friendly colors, instant preview window.
export FZF_DEFAULT_OPTS="
  --height=60%
  --layout=reverse
  --border=rounded
  --info=inline-right
  --prompt='  '
  --pointer='▶'
  --marker='✓'
  --cycle
  --scroll-off=3
  --tiebreak=index
  --preview-window='right:55%:wrap:border-rounded'
  --bind='ctrl-/:toggle-preview,ctrl-u:preview-page-up,ctrl-d:preview-page-down'
  --color=bg+:#2a2e41,bg:-1,spinner:#a48cf2,hl:#37f499,fg:#ebfafa
  --color=header:#37f499,info:#a48cf2,pointer:#f7c67f,marker:#f7c67f
  --color=fg+:#ebfafa,prompt:#7081d0,hl+:#37f499,border:#3b4261
"
