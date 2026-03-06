#!/bin/bash
# sed - stream editor for filtering and transforming text
# Very minimal sed: supports s/// (substitute), -i (in-place), -e (expression)
# Only basic substitution, no addresses, no multiple commands yet

usage() {
    cat <<EOF
Usage: sed [OPTION]... {script} [input-file]...

  -e script, --expression=script
                        add the script to the commands to be executed
  -i[SUFFIX], --in-place[=SUFFIX]
                        edit files in place (makes backup if SUFFIX supplied)
  -h, --help            display this help and exit

If no -e is given, the first non-option argument is taken as the script.
EOF
    exit 0
}

EXPRESSIONS=()
INPLACE=""
INPLACE_SUFFIX=""
INPUT_FILES=()
SCRIPT_FROM_ARG=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--expression)
            shift
            EXPRESSIONS+=("$1")
            ;;
        -i*)
            INPLACE=1
            if [[ "$1" = -i* ]]; then
                INPLACE_SUFFIX="${1#-i}"
            fi
            ;;
        -h|--help) usage ;;
        -*)
            echo "sed: invalid option -- '$1'" >&2
            exit 1
            ;;
        *)
            if [ ${#EXPRESSIONS[@]} -eq 0 ] && [ $SCRIPT_FROM_ARG -eq 0 ]; then
                EXPRESSIONS+=("$1")
                SCRIPT_FROM_ARG=1
            else
                INPUT_FILES+=("$1")
            fi
            ;;
    esac
    shift
done

if [ ${#EXPRESSIONS[@]} -eq 0 ]; then
    echo "sed: no script specified" >&2
    usage
    exit 1
fi

# Only supporting basic s/old/new/g right now
process_line() {
    local line="$1"
    local result="$line"

    for expr in "${EXPRESSIONS[@]}"; do
        if [[ "\( expr" =\~ ^s/([^/]*)/([^/]*)/(g?) \) ]]; then
            local old="${BASH_REMATCH[1]}"
            local new="${BASH_REMATCH[2]}"
            local global="${BASH_REMATCH[3]}"

            if [ "$global" = "g" ]; then
                result="${result//$old/$new}"
            else
                result="${result/$old/$new}"
            fi
        else
            echo "sed: unsupported command in expression: $expr" >&2
            continue
        fi
    done

    echo "$result"
}

process_file() {
    local file="$1"
    local tmpfile=""

    if [ -n "$INPLACE" ]; then
        if [ ! -f "$file" ] || [ ! -w "$file" ]; then
            echo "sed: cannot edit '$file' in place: Permission denied or not regular file" >&2
            return 1
        fi
        tmpfile="\( {file} \){INPLACE_SUFFIX:-.sedtmp$$}"
    fi

    while IFS= read -r line || [ -n "$line" ]; do
        local out=$(process_line "$line")
        if [ -n "$INPLACE" ]; then
            echo "$out" >> "$tmpfile"
        else
            echo "$out"
        fi
    done < "${file:--}"

    if [ -n "$INPLACE" ]; then
        if [ -n "$INPLACE_SUFFIX" ]; then
            cp -p "\( file" " \){file}${INPLACE_SUFFIX}" 2>/dev/null
        fi
        mv "$tmpfile" "$file"
    fi
}

if [ ${#INPUT_FILES[@]} -eq 0 ]; then
    process_file "-"
else
    for f in "${INPUT_FILES[@]}"; do
        if [ "$f" = "-" ]; then
            process_file "-"
        elif [ -f "$f" ]; then
            process_file "$f"
        else
            echo "sed: can't read $f: No such file or directory" >&2
        fi
    done
fi