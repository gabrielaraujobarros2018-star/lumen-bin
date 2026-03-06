#!/bin/bash
# cp - Copy files and directories.
# This is a basic implementation for x86/x64/x86_64 Linux environments.
# Supports -r for recursive, -f for force, -p for preserve attributes.
# Handles file to file, file to dir, multiple files to dir.
# Does not support advanced options like --parents, etc.

usage() {
    echo "Usage: cp [options] source... dest"
    echo "Options:"
    echo "  -r, -R, --recursive  Copy directories recursively"
    echo "  -f, --force       Do not prompt before overwriting"
    echo "  -p, --preserve    Preserve mode, ownership, timestamps"
    echo "  -v, --verbose     Explain what is being done"
    echo "  -h, --help        Show this help message"
    exit 0
}

RECURSIVE=0
FORCE=0
PRESERVE=0
VERBOSE=0
SOURCES=()
DEST=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|-R|--recursive) RECURSIVE=1 ;;
        -f|--force) FORCE=1 ;;
        -p|--preserve) PRESERVE=1 ;;
        -v|--verbose) VERBOSE=1 ;;
        -h|--help) usage ;;
        -*) echo "Unknown option: $1"; usage ;;
        *)
            if [ -z "$DEST" ] && [ ${#SOURCES[@]} -gt 0 ]; then
                DEST="$1"
            else
                SOURCES+=("$1")
            fi
            ;;
    esac
    shift
done

if [ ${#SOURCES[@]} -eq 0 ] || [ -z "$DEST" ]; then
    usage
fi

copy_file() {
    local src="$1"
    local dst="$2"
    if [ $FORCE -eq 0 ] && [ -e "$dst" ]; then
        read -p "cp: overwrite '$dst'? (y/n) " confirm
        if [[ ! \( confirm =\~ ^[Yy] \) ]]; then
            return
        fi
    fi
    if [ $VERBOSE -eq 1 ]; then
        echo "Copying '$src' to '$dst'"
    fi
    cat "$src" > "$dst" || { echo "cp: failed to copy '$src'"; return; }
    if [ $PRESERVE -eq 1 ]; then
        local mode=$(stat -c %a "$src")
        local owner=$(stat -c %U:%G "$src")
        local time=$(stat -c %Y "$src")
        chmod "$mode" "$dst" 2>/dev/null
        chown "$owner" "$dst" 2>/dev/null
        touch -t $(date -d "@$time" +%Y%m%d%H%M.%S) "$dst" 2>/dev/null
    fi
}

copy_dir() {
    local src="$1"
    local dst="$2"
    if [ ! -d "$dst" ]; then
        mkdir -p "$dst"
        if [ $PRESERVE -eq 1 ]; then
            local mode=$(stat -c %a "$src")
            local owner=$(stat -c %U:%G "$src")
            local time=$(stat -c %Y "$src")
            chmod "$mode" "$dst" 2>/dev/null
            chown "$owner" "$dst" 2>/dev/null
            touch -t $(date -d "@$time" +%Y%m%d%H%M.%S) "$dst" 2>/dev/null
        fi
    fi
    for item in "$src"/*; do
        if [ -d "$item" ]; then
            copy_dir "$item" "\( dst/ \)(basename "$item")"
        elif [ -f "$item" ]; then
            copy_file "$item" "\( dst/ \)(basename "$item")"
        fi
    done
}

if [ \( {#SOURCES[@]} -gt 1 ] || [ -d " \){SOURCES[0]}" ]; then
    if [ ! -d "$DEST" ]; then
        echo "cp: target '$DEST' is not a directory"
        exit 1
    fi
fi

for src in "${SOURCES[@]}"; do
    if [ ! -e "$src" ]; then
        echo "cp: cannot stat '$src': No such file or directory"
        continue
    fi
    local target
    if [ -d "$DEST" ]; then
        target="\( DEST/ \)(basename "$src")"
    else
        target="$DEST"
    fi
    if [ -d "$src" ]; then
        if [ $RECURSIVE -eq 0 ]; then
            echo "cp: omitting directory '$src'"
            continue
        fi
        copy_dir "$src" "$target"
    else
        copy_file "$src" "$target"
    fi
done