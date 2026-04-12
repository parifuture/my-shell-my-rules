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

setopt AUTO_LIST        # automatically list choices on ambiguous completion
setopt COMPLETE_IN_WORD # complete from both ends of a word

zstyle ':completion:*' completer _extensions _complete _approximate
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.zcompcache"
zstyle ':completion:*' complete true
zstyle ':completion:*' menu select
zstyle ':completion:*' complete-options true
zstyle ':completion:*' file-sort modification
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:*:*:*:descriptions' format '%F{blue}-- %D %d --%f'
zstyle ':completion:*:*:*:*:messages'     format '%F{purple} -- %d --%f'
zstyle ':completion:*:*:*:*:warnings'     format '%F{red}-- no matches found --%f'

# Map `opyarn` (alias for `op run --environment ... -- yarn` defined in alias-common.sh)
# onto the patched `_yarn` completer so `opyarn <Tab>` offers subcommands + scripts.
# Without this, zsh would try to complete using `_op` and miss the trailing `yarn` entirely.
compdef opyarn=yarn
