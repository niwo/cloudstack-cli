#!/bin/bash

# cloudstack-cli
# https://github.com/niwo/cloudstack-cli
#
# Copyright (c) 2014 Nik Wolfgramm
# Licensed under the MIT license.
# https://raw.github.com/niwo/cloudstack-cli/master/LICENSE.txt

# Usage:
#
# To enable bash <tab> completion for cloudstack-cli, add the following line (minus the
# leading #, which is the bash comment character) to your ~/.bashrc file:
#
# eval "$(cs completion --shell=bash)"

_cs() {
  COMPREPLY=()
  local word="${COMP_WORDS[COMP_CWORD]}"
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(cs help | grep cs | cut -d ' ' -f4)" -- "$word") )
  else
    local words=("${COMP_WORDS[@]}")
    if [ $(echo ${words[@]} | wc -w) -eq 2 ]; then
      COMPREPLY=( $(compgen -W "$(${words[@]} help | grep cs | cut -d ' ' -f5)" -- "$word") )
    fi
    if [ $(echo ${words[@]} | wc -w) -ge 3 ]; then
      local cp1=$(echo ${words[@]} | cut -d ' ' -f1-2)
      local cp2=$(echo ${words[@]} | cut -d ' ' -f3)
      if [ "$cp2" != "help" ]; then
        local cp3=$($cp1 help $cp2)
        COMPREPLY=( $(compgen -W "$(echo $cp3 | awk 'NR>1{print $1}' RS=[ FS='\=')" -- "$word") )
      fi
    fi
  fi
}

complete -F _cs cs