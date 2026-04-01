# ~/code/personal/my-shell-my-rules/zshrc/modules/autocompletion.sh

zmodload zsh/complist
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
