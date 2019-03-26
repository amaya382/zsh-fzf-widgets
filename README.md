# Zsh widgets for fzf
Zsh widgets for fzf. You can bind what you want to a key you want.

## Widgets
|name|description|bind|
|:--|:--|:--|
|`fzf-cd`|Select dir under the current working dir|`Enter: cd`<br>`Tab: Paste to buffer`|
|`fzf-cdr`|Select dir from cdr (Not existing dirs will be colored)|`Enter: cd`<br>`Tab: Paste to buffer`|
|`fzf-history`|Select cmd history|`Enter: exec`<br>`Tab: Paste to buffer`|
|`fzf-git-checkout`|Select git branch including remote|`Enter: checkout`<br>`Tab: Paste to buffer`|
|`fzf-git-log`|Show git log|`Enter: Show details`<br>`Tab: Paste to buffer`|
|`fzf-git-status`|Show git status|`Enter: Show details`<br>`Tab: Paste to buffer`|
|`fzf-kill-proc-by-list`|Select process id from list|`Enter: kill`<br>`Tab: Paste to buffer`|
|`fzf-kill-proc-by-port`|Select process id from port num (w/ sudo)|`Enter: kill`<br>`Tab: Paste to buffer`|
|`fzf-gitmoji`|Select emoji for git comment|`Enter: Paste to buffer`<br>`Tab: Paste to buffer`|

## Options
|name|description|default|
|:--|:--|:--|
|`FZF_CMD`|fzf command w/ options|`fzf --ansi`|
|`ZSH_FZF_PASTE_KEY`|Key binding for pasting to buffer|tab|
|`ZSH_FZF_EXEC_KEY`|Key binding for executing specific commands|enter|

## Usage (w/ zplug)
`.zshrc`
```zsh
zplug "amaya382/zsh-fzf-widgets"

bindkey '^R' fzf-cdr
bindkey '^H' fzf-history

# Use ctrl-t instead of tab key
export ZSH_FZF_PASTE_KEY=ctrl-t
```

