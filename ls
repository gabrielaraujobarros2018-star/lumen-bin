#!/bin/bash
# ls - list directory contents
# Very simplified ls for Lumen - basic long listing and color support

usage() {
    cat <<EOF
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).

Common options:
  -l  use a long listing format
  -a  do not ignore entries starting with .
  -A  do not list implied . and ..
  -h  human readable sizes
  -1  list one file per line
  --color=always   force color output
  -h, --help       display this help
EOF
    exit 0
}

LONG=0
ALL=0
ALMOST_ALL=0
HUMAN=0
ONE_PER_LINE=0
COLOR=0
[ -t 1 ] && COLOR=1   # auto color to terminal

TARGETS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -l) LONG=1 ;;
        -a) ALL=1 ;;
        -A) ALMOST_ALL=1 ;;
        -h|--human-readable) HUMAN=1 ;;
        -1) ONE_PER_LINE=1 ;;
        --color=always) COLOR=1 ;;
        --color=never)  COLOR=0 ;;
        -h|--help) usage ;;
        -*)
            echo "ls: invalid option -- '$1'" >&2
            exit 1
            ;;
        *) TARGETS+=("$1") ;;
    esac
    shift
done

[ ${#TARGETS[@]} -eq 0 ] && TARGETS=(".")

color() {
    local code="$1"
    local text="$2"
    if [ $COLOR -eq 1 ]; then
        echo -e "\033[\( {code}m \){text}\033[0m"
    else
        echo "$text"
    fi
}

format_size() {
    local bytes="$1"
    if [ $HUMAN -eq 0 ]; then
        printf "%8s" "$bytes"
        return
    fi
    if [ $bytes -ge 1073741824 ]; then
        printf "%6.1fG" "$(bc <<< "scale=1; $bytes/1073741824")"
    elif [ $bytes -ge 1048576 ]; then
        printf "%6.1fM" "$(bc <<< "scale=1; $bytes/1048576")"
    elif [ $bytes -ge 1024 ]; then
        printf "%6.1fK" "$(bc <<< "scale=1; $bytes/1024")"
    else
        printf "%7d" "$bytes"
    fi
}

list_entry() {
    local path="$1"
    local name=$(basename "$path")

    if [ ! -e "$path" ]; then
        echo "ls: cannot access '$path': No such file or directory" >&2
        return
    fi

    if [ $LONG -eq 1 ]; then
        local perms=$(stat -c "%A" "$path" 2>/dev/null)
        local links=$(stat -c "%h" "$path")
        local owner=$(stat -c "%U" "$path")
        local group=$(stat -c "%G" "$path")
        local size=$(stat -c "%s" "$path")
        local time=$(stat -c "%Y" "$path")
        local timestr=$(date -d "@$time" +"%b %d %H:%M" 2>/dev/null || echo "????")

        local sizestr=$(format_size "$size")

        local indicator=""
        [ -d "$path" ] && indicator="/"
        [ -L "$path" ] && indicator="@"
        [ -x "$path" ] && [ ! -d "$path" ] && indicator="*"

        local colored_name="$name$indicator"
        if [ -d "$path" ]; then
            colored_name=$(color "1;34" "$colored_name")
        elif [ -L "$path" ]; then
            colored_name=$(color "1;36" "$colored_name")
        elif [ -x "$path" ]; then
            colored_name=$(color "1;32" "$colored_name")
        fi

        printf "%-10s %3d %-8s %-8s %8s %s %s\n" \
            "$perms" "$links" "$owner" "$group" "$sizestr" "$timestr" "$colored_name"
    else
        local indicator=""
        [ -d "$path" ] && indicator="/"
        [ -L "$path" ] && indicator="@"
        [ -x "$path" ] && [ ! -d "$path" ] && indicator="*"

        local colored_name="$name$indicator"
        if [ -d "$path" ]; then
            colored_name=$(color "1;34" "$colored_name")
        elif [ -L "$path" ]; then
            colored_name=$(color "1;36" "$colored_name")
        elif [ -x "$path" ]; then
            colored_name=$(color "1;32" "$colored_name")
        fi

        if [ $ONE_PER_LINE -eq 1 ]; then
            echo "$colored_name"
        else
            echo -n "$colored_name  "
        fi
    fi
}

for tgt in "${TARGETS[@]}"; do
    if [ ${#TARGETS[@]} -gt 1 ] || [ -d "$tgt" ]; then
        echo "$tgt:"
    fi

    if [ -d "$tgt" ]; then
        shopt -s dotglob nullglob
        entries=("$tgt"/* "$tgt"/.[!.]* "$tgt"/..?*)
        shopt -u dotglob

        if [ $ALL -eq 0 ] && [ $ALMOST_ALL -eq 0 ]; then
            entries=("$tgt"/*)
        elif [ $ALMOST_ALL -eq 1 ]; then
            entries=("$tgt"/*)
        fi

        # sort alphabetically (very basic)
        IFS=\( '\n' sorted=( \)(printf '%s\n' "${entries[@]##*/}" | sort))
        unset IFS

        for base in "${sorted[@]}"; do
            [ -z "$base" ] && continue
            entry="$tgt/$base"
            [ "$base" = "." ] || [ "$base" = ".." ] && continue
            list_entry "$entry"
        done

        [ $ONE_PER_LINE -eq 0 ] && [ $LONG -eq 0 ] && echo ""
    else
        list_entry "$tgt"
        [ $ONE_PER_LINE -eq 0 ] && [ $LONG -eq 0 ] && echo ""
    fi
done