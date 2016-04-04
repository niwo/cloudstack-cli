#!/bin/bash

# cloudstack-cli
# https://github.com/niwo/cloudstack-cli
#
# Copyright (c) 2015 Nik Wolfgramm
# Licensed under the MIT license.
# https://raw.github.com/niwo/cloudstack-cli/master/LICENSE.txt

# Usage:
#
# To enable bash <tab> completion for cloudstack-cli, add the following line (minus the
# leading #, which is the bash comment character) to your ~/.bash_profile file (use ~/.bashrc on Ubuntu):
#
# eval "$(cloudstack-cli completion --shell=bash)"

_cloudstack_cli() {
  COMPREPLY=()
  local word="${COMP_WORDS[COMP_CWORD]}"
  # list available base commands
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(cloudstack-cli help | grep cloudstack-cli | cut -d ' ' -f4)" -- "$word") )
  else
    local words=("${COMP_WORDS[@]}")
    # ignore commands which contain 'help'
    if [[ "${words[@]}" == *help* ]]; then
      COMPREPLY=( $(compgen -W '' -- "$word") )
    # search for subcommand
    elif [[ "$word" != -* ]] && [ "$COMP_CWORD" -eq 2 ]; then
      local cp1=$(echo ${words[@]} | cut -d ' ' -f1-2)
      COMPREPLY=( $(compgen -W "$($cp1 help | grep cloudstack-cli | cut -d ' ' -f5)" -- "$word") )
    # list options for the subcommand
    elif [[ "$word" =~ -* ]] && [ "$COMP_CWORD" -gt 2 ]; then
      local cp1=$(echo ${words[@]} | cut -d ' ' -f1-2)
      local cp2=$(echo ${words[@]} | cut -d ' ' -f3)
      local cp3=$($cp1 help $cp2 2>/dev/null)
      COMPREPLY=( $(compgen -W "$(echo $cp3 | awk 'NR>1{print $1}' RS=[ FS='\=' 2>/dev/null)" -- "$word") )
    else
      COMPREPLY=()
    fi
    return 0
  fi
}

complete -o bashdefault -o default -F _cloudstack_cli cloudstack-cli cs
