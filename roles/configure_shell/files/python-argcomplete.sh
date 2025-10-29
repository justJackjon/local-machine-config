# This file is part of argcomplete.
#
# Copyright 2012-2023, Andrey Kislyuk and argcomplete contributors.
# Licensed under the Apache License. See LICENSE for details.
#
# This file is sourced by bash-completion to activate global completion.
#
# See https://github.com/kislyuk/argcomplete

_python_argcomplete() {
  local IFS=$'\013'
  local COMP_WORDBREAKS=${COMP_WORDBREAKS//:/}
  local SUPPRESS_SPACE=0
  if compopt +o nospace 2>/dev/null; then
    SUPPRESS_SPACE=1
  fi
  COMPREPLY=($(IFS="$IFS" \
    _ARGCOMPLETE_SUPER_SECRET_LEVEL=1 \
    _ARGCOMPLETE_COMP_WORDBREAKS="$COMP_WORDBREAKS" \
    _ARGCOMPLETE_COMP_CWORD=$COMP_CWORD \
    _ARGCOMPLETE_COMP_POINT=$COMP_POINT \
    _ARGCOMPLETE_SUPPRESS_SPACE=$SUPPRESS_SPACE \
    _ARGCOMPLETE=1 \
    _ARGCOMPLETE_DFS_SETUP=1 \
    "$1" 8>&1 9>&2 1>/dev/null 2>/dev/null))
  if [[ $? != 0 ]]; then
    unset COMPREPLY
  elif [[ $SUPPRESS_SPACE == 1 ]] && [[ "${COMPREPLY-}" == *"="* ]]; then
    compopt -o nospace
  fi
}
complete -o nospace -o default -o bashdefault -D -F _python_argcomplete
