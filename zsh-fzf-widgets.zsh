#!/usr/bin/env zsh

: ${FZF_CMD="fzf --ansi"}
: ${ZSH_FZF_PASTE_KEY=tab}
: ${ZSH_FZF_EXEC_KEY=enter}


fzf-cd() {
  local dir=$(find -L . -mindepth 1 \
    \( -path '*/\.*' \
      -o -fstype 'sysfs' \
      -o -fstype 'devfs' \
      -o -fstype 'devtmpfs' \
      -o -fstype 'proc' \) -prune -o -type d -print 2> /dev/null | cut -b3- \
      | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
        --bind=\"${ZSH_FZF_PASTE_KEY}:execute@echo {}@+abort\"
        --bind=\"${ZSH_FZF_EXEC_KEY}:execute@echo 'cd {}'@+abort\"
        " ${=FZF_CMD})
  if [[ -n "$dir" ]]; then
    if [[ "$dir" =~ '^cd (.+)$' ]]
    then
      ${=dir}
      zle reset-prompt
    else
      LBUFFER="${LBUFFER}${dir}"
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
      --bind=\"${ZSH_FZF_PASTE_KEY}:execute@echo {}@+abort\"
      --bind=\"${ZSH_FZF_EXEC_KEY}:execute@echo 'cd {}'@+abort\"
      " ${=FZF_CMD})
  if [[ -n "$dir" ]]; then
    if [[ "$dir" =~ '^cd (.+)$' ]]
    then
      ${=dir}
      zle reset-prompt
    else
      LBUFFER="${LBUFFER}${dir}"
      zle redisplay
    fi
  fi
}
zle -N fzf-cdr


fzf-history() {
  local res=($(fc -rl 1 \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
      --query=${(qqq)LBUFFER}
      -n2..,..
      --tiebreak=index
      --bind=${ZSH_FZF_PASTE_KEY}:accept
      --bind=\"${ZSH_FZF_EXEC_KEY}:execute@echo -\$(echo {} | sed -e 's/^ //')@+abort\"
      " ${=FZF_CMD}))
  if [ -n "$res" ]; then
    local num=$res[1]
    if [ -n "$num" ]; then
      if [ $num -ge 1 ]; then
        zle vi-fetch-history -n $num
        zle reset-prompt
      else
        zle vi-fetch-history -n ${num#-}
        zle accept-line
      fi
    fi
  fi
}
zle -N fzf-history


fzf-git-checkout() {
  [[ $(git status 2> /dev/null) ]] || return 0
  local branches=$(git branch -a --color=always | grep -v HEAD)
  local res=$(echo $branches \
    | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
      --bind=\"${ZSH_FZF_PASTE_KEY}:execute@
        echo {} | sed -e 's/.* //' -e 's!remotes/[^/]*/!!'@+abort\"
      --bind=\"${ZSH_FZF_EXEC_KEY}:execute@
        echo git checkout \$(echo {} | sed -e 's/.* //' -e 's!remotes/[^/]*/!!')@+abort\"
      --query=${(qqq)LBUFFER}
      " ${=FZF_CMD})
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
    --bind=\"${ZSH_FZF_PASTE_KEY}:execute@
      echo {} | grep -o '[a-f0-9]\\\{7\\\}' | head -1@+abort\"
    --bind=\"${ZSH_FZF_EXEC_KEY}:execute@
      git show --color=always \$(echo {} | grep -o '[a-f0-9]\\\{7\\\}' | head -1) \
      | less -R > /dev/tty@\"
    " ${=FZF_CMD})
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
    --bind=\"${ZSH_FZF_PASTE_KEY}:execute@echo {} | sed -e 's/^...//'@+abort\"
    --bind=\"${ZSH_FZF_EXEC_KEY}:execute@
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
    " ${=FZF_CMD})
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
    --bind=\"${ZSH_FZF_PASTE_KEY}:execute@echo {} | awk '{print \$2}'@+abort\"
    --bind=\"${ZSH_FZF_EXEC_KEY}:execute@kill -9 \$(echo {} | awk '{print \$2}')@+abort\"
  " ${=FZF_CMD})
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
    --bind=\"${ZSH_FZF_PASTE_KEY}:execute@echo {} | grep -oP '(?<=pid=)\\\d+(?=,)'@+abort\"
    --bind=\"${ZSH_FZF_EXEC_KEY}:execute@sudo kill -9 \$(echo {} | grep -oP '(?<=pid=)\\\d+(?=,)')@+abort\"
  " ${=FZF_CMD})
  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER$res
    zle redisplay
  fi
}
zle -N fzf-kill-proc-by-port


fzf-gitmoji() {
  local res=$(gitmoji -l \
  | FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS}
    --bind=${ZSH_FZF_PASTE_KEY}:accept
  " ${=FZF_CMD} \
  | grep -oP ':.+:')
  if [[ -n "$res" ]]; then
    LBUFFER=$LBUFFER$res
    zle redisplay
  fi
}
zle -N fzf-gitmoji

