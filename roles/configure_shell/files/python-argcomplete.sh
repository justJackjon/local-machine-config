#!/bin/bash
# PYTHON_ARGCOMPLETE_OK
_python_argcomplete()
{
    local COMPLETION_ARGS=$(echo "$COMP_LINE" | python -c 'import sys; from argcomplete.compat import os_environ_bytes; sys.stdout.write(os_environ_bytes[b"_ARGCOMPLETE_COMP_WORDBREAKS"])')
    local IFS=$'\t'
    COMPREPLY=( $(IFS="$IFS" \
                  COMP_LINE="$COMP_LINE" \
                  COMP_POINT="$COMP_POINT" \
                  COMP_WORDBREAKS="$COMPLETION_ARGS" \
                  _ARGCOMPLETE=1 \
                  "$1" 8>&1 9>/dev/null) )
    if [[ $? != 0 ]]; then
        unset COMPREPLY
    fi
}
complete -o nospace -o default -F _python_argcomplete
