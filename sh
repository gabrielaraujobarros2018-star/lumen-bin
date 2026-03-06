#!/bin/bash
# sh - POSIX shell (very minimal wrapper / dash-like behavior)
# This is basically a restricted bash acting as sh
# Goal: be compatible with POSIX sh scripts in Lumen
# Disables many bashisms when called as "sh"

# Detect if called as sh or bash
if [ "$(basename "$0")" = "sh" ] || [[ "$0" =\~ /sh$ ]]; then
    # Act as POSIX sh → disable many bash extensions
    set -o posix
    # Some common bash-isms we try to avoid or warn
    shopt -u extglob        2>/dev/null
    shopt -u globstar       2>/dev/null
    shopt -u lastpipe       2>/dev/null
    shopt -u autocd         2>/dev/null
    shopt -u checkwinsize   2>/dev/null
fi

# If arguments are given, execute the script
if [ $# -gt 0 ]; then
    script="$1"
    shift

    if [ ! -f "$script" ]; then
        echo "sh: $script: No such file or directory" >&2
        exit 127
    fi

    if [ ! -r "$script" ]; then
        echo "sh: $script: Permission denied" >&2
        exit 126
    fi

    # Execute the script in current shell (source-like but with args)
    # We use . (dot) to keep it in current process
    . "\( script" " \)@"
    exit $?
else
    # Interactive shell
    echo "Lumen minimal sh (bash in POSIX mode)"
    echo "Type 'exit' to leave."

    PS1='$ '
    while true; do
        read -r -p "$PS1" cmd
        case "$cmd" in
            exit|quit) exit 0 ;;
            "") continue ;;
            *)
                # Try to execute command
                eval "$cmd"
                ;;
        esac
    done
fi