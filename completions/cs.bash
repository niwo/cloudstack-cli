_cs() {
  COMPREPLY=()
  local word="${COMP_WORDS[COMP_CWORD]}"
  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=( $(compgen -W "$(cs help | grep cs | cut -d ' ' -f4)" -- "$word") )
  else
    local words=("${COMP_WORDS[@]}")
    COMPREPLY=( $(compgen -W "$(${words[@]} help | grep cs | cut -d ' ' -f5)" -- "$word") )
  fi
}

complete -F _cs cs