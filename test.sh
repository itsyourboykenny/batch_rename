#!/bin/zsh
setopt BASH_REMATCH

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run)
            DRYRUN=1
            shift
            ;;
        -v | --verbose)
            VERBOSE=1
            shift
            ;;
        -s | --sub)
            INDEX=$2
            shift 2
            ;;
        *)
            break
            ;;
    esac
done

if [ $DRYRUN -eq 1 ]; then
    echo "Dry Run"
fi

if [ $VERBOSE -eq 1 ]; then
    echo "Verbose mode"
fi

if [ $INDEX -ne 0 ]; then
    echo "index = $INDEX"
fi

for files in "$@"; do
    echo "$files"
done