#!/usr/bin/env zsh

FZF="fzf --ansi"


fzf-cd() {
  local dir=$(find -L . -mindepth 1 \
    \( -path '*/\.*' \
      -o -fstype 'sysfs' \
      -o -fstype 'devfs' \
      -o -fstype 'devtmpfs' \
      -o -fstype 'proc' \) -prune -o -type d -print 2> /dev/null | cut -b3- \
      | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
        --query=${(qqq)LBUFFER}
        --bind=\"tab:execute@echo {}@+abort\"
        --bind=\"enter:execute@echo 'cd {}'@+abort\"
        " ${=FZF})
  if [[ -n "$dir" ]]; then
    if [[ "$dir" =~ '^cd (.+)$' ]]
    then
      $dir
      zle reset-prompt
    else
      LBUFFER="$dir"
      zle redisplay
    fi
  fi
}
zle -N fzf-cd


fzf-cdr() {
  local dir=$(cdr -l \
    | sed 's/^[^ ][^ ]*  *//' \
    | while read f
      do
        f="${f/#\~/$HOME}"
        [ -d "${f}" ] \
          && echo "${f}" \
          || echo -e "\e[31m$f\e[m"
      done \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
      --query=${(qqq)LBUFFER}
      --bind=\"tab:execute@echo {}@+abort\"
      --bind=\"enter:execute@echo 'cd {}'@+abort\"
      " ${=FZF})
  if [[ -n "$dir" ]]; then
    if [[ "$dir" =~ '^cd (.+)$' ]]
    then
      $dir
      zle reset-prompt
    else
      LBUFFER="$dir"
      zle redisplay
    fi
  fi
}
zle -N fzf-cdr


fzf-history() {
  local selected=($(fc -rl 1 \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
      --query=${(qqq)LBUFFER}
      -n2..,..
      --tiebreak=index
      --bind=ctrl-r:toggle-sort
      " ${=FZF}))
  if [ -n "$selected" ]; then
    local num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle reset-prompt
}
zle -N fzf-history


fzf-git-checkout() {
  [[ $(git status 2> /dev/null) ]] || return 0
  local branches=$(git branch -a --color=always | grep -v HEAD)
  local res=$(echo $branches \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
      --bind=\"tab:execute@
        echo {} | sed -e 's/.* //' -e 's!remotes/[^/]*/!!'@+abort\"
      --bind=\"enter:execute@
        echo git checkout \$(echo {} | sed -e 's/.* //' -e 's!remotes/[^/]*/!!')@+abort\"
      --query=${(qqq)LBUFFER}
      " ${=FZF})
  if [[ -n "$res" ]]; then
    if [[ "$res" =~ '^git checkout (.+)$' ]]
    then
      ${=res}
      zle reset-prompt
    else
      LBUFFER=$LBUFFER$res
      zle redisplay
    fi
  fi
}
zle -N fzf-git-checkout


fzf-git-log() {
  [[ $(git status 2> /dev/null) ]] || return 0
  local res=$(git log --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" \
  | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
    --no-sort
    --reverse
    --tiebreak=index
    --bind=\"tab:execute@
      echo {} | grep -o '[a-f0-9]\\\{7\\\}' | head -1@+abort\"
    --bind=\"enter:execute@
      git show --color=always \$(echo {} | grep -o '[a-f0-9]\\\{7\\\}' | head -1) \
      | less -R > /dev/tty@\"
    " ${=FZF})
  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER$res
    zle redisplay
  fi
}
zle -N fzf-git-log


fzf-git-status() {
  [[ $(git status 2> /dev/null) ]] || return 0
  local res=$(git -c color.status=always status -s \
  | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
    --no-sort
    --reverse
    --bind=\"tab:execute@echo {} | sed -e 's/^...//'@+abort\"
    --bind=\"enter:execute@
      f=\$(echo {} | sed -e 's/^...//')
      mark=\$(echo {} | grep -oP '^..')
      case \$mark in
        RM) echo \$f && echo && git diff --color=always \$(echo \$f | sed -e 's/^.* -> //') ;;
        R?) echo \$f ;;
        M?) git diff --color=always --cached \$f ;;
        ?M) git diff --color=always \$f ;;
        A? | ?D) git diff HEAD --color=always -- \$f ;;
        \\?\\?) cat \$f ;;
      esac | less -R > /dev/tty@\"
    " ${=FZF})
  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER$res
    zle redisplay
  fi
}
zle -N fzf-git-status


fzf-kill-proc-by-list() {
  local cmd=$([ "$UID" != '0' ] && echo "ps -f -u $UID" || echo 'ps -ef')
  local res=$(${=cmd} \
  | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
    --no-sort
    --reverse
    --bind=\"tab:execute@echo {} | awk '{print \$2}'@+abort\"
    --bind=\"enter:execute@kill -9 \$(echo {} | awk '{print \$2}')@+abort\"
  " ${=FZF})
  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER$res
    zle redisplay
  fi
}
zle -N fzf-kill-proc-by-list


fzf-kill-proc-by-port() {
  local res=$(sudo ss -natup \
  | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
    --query=\'
    --no-sort
    --reverse
    --bind=\"tab:execute@echo {} | grep -oP '(?<=pid=)\\\d+(?=,)'@+abort\"
    --bind=\"enter:execute@sudo kill -9 \$(echo {} | grep -oP '(?<=pid=)\\\d+(?=,)')@+abort\"
  " ${=FZF})
  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER$res
    zle redisplay
  fi
}
zle -N fzf-kill-proc-by-port

