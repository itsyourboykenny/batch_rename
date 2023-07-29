#!/bin/zsh
setopt BASH_REMATCH # For compatibility with zsh
METHOD=""
FORMAT=""
STARTINDEX=1
PATTERN=""
DIGITS=0
DRYRUN=0
EXTIGNORE=0

function print_help() {
    echo \
    "brename: Batch RENAME utility\n\
    Requires at least 1 method to be specified: Sequence or regex (--seq or --regex)\n\
    \n\
    usage: batchRename.sh [options] [file1 file2 file3 ...]\n\n\
    Example: batchRename.sh --seq 1 --dry-run file1.txt file2.txt file3.txt\n\
        file1 -> file11.txt\n\
        file2 -> file22.txt\n\
        file3 -> file33.txt\n\
    \n\
    Example: batchRename.sh --regex '([a-z]+)([0-9]+)' --format 'Renamed_%1_%2.png' --dry-run file1.txt file2.txt file3.txt\n\
        file1.txt -> Renamed_file_1.png\n\
        file2.txt -> Renamed_file_2.png\n\
        file3.txt -> Renamed_file_3.png\n\
    \n\
    Options:\n\
        (-s | --seq) number\n\
            Rename using numerical sequence. By default it will be appended\n\
        (-r | --regex) pattern\n\
            Captures values from the files and uses its values to rename\n\
            Must use capture groups with (). Each corresponding groups are assigned to tags\n\
              chronologically. ie: (group1)(group2)(group3) -> %1 %2 %3 respectively\n\
        (-f | --format) format\n\
            Format of each files will use for renaming.\n\
            Requires at least 1 tag. ie: %1\n\
            Example: renamed_file_%1.txt\n\
        (-a | --append)\n\
            Appends the sequence or values to the end of the file name\n\
        (-p | --prepend)\n\
            Prepends the sequence or values to the beginning of the file\n\
        (--dry-run)\n\
            Preview your changes. Nothing will be modified\n\
        (-d | --padding) number\n\
            How may zeros to be pad the sequence with. If omittited it will be generated\n\
        (-i | --ignore-extension)\n\
            Extensions will be ignored"
}

# FUNCTIONS USED FOR THIS SCRIPT
function regex_rename() {
    # Takes a regex pattern as 1st parameter, output format as 2nd and the filename as the 3rd
    # Prints the final filename and returns with exit code 0 if successful
    # Prints the error message if exit with code 1
    # Usage: regex_rename regex format filename
    if ! [[ $3 =~ $1 ]]; then
        echo "Pattern not found"
        return 1
    fi

    tagcount=$((${#BASH_REMATCH[@]} - 1))
    for ((x=1; x<=$tagcount; x++)); do
        count=$(grep -c "%$x" <<< $2)
        if ! [ $count -ge 1 ]; then
            echo "Format has too few tags"
            return 1
        fi
    done

    formatted="$2"
    for ((x=1; x<=$tagcount; x++)); do
        formatted=$(echo "$formatted" | sed "s/%$x/${BASH_REMATCH[$((x + 1))]}/")
    done

    echo $formatted
    return 0
}

function sub_rename() {
    # $1: Value to replace with
    # $2: Format to be placed. Will replace %1 tag
    # sub_rename val format
    tagcount=$(grep -o '%1' <<< $2 | wc -l)
    if [ $tagcount -lt 1 ]; then
        echo 'Format is missing tags'
        return 1
    fi

    result=$(echo $2 | sed "s/%1/$1/")
    echo $result
    return 0
}


function remove_extension() {
    echo $1 | sed "s/\.[^.]*$//"
    return 1
}

function get_extension() {
    echo $(egrep -o '[^.]*$' <<< $1)
}

# CHECKS FOR OPTIONS
# * You can only specify a sequence or regex, but not both. Exits otherwise
while [ $# -gt 0 ]; do
    case "$1" in
        -s | --seq) # Sequence method
            # Make sure starting index is good
            if ! [ -z $METHOD ]; then
                echo "You cannot use modes Sequence and Regex together"
                exit 1
            fi
            if ! [[ $2 =~ '^[0-9]+$' ]]; then
                echo 'Starting index must be a number'
                exit 1
            fi
            METHOD='s'
            STARTINDEX=$(($2))
            shift 2
            echo "Sequence starting at $STARTINDEX"
            ;;
        -r | --regex) # Regex Method
            if ! [ -z $METHOD ]; then
                    echo "You cannot use modes Sequence and Regex together"
                    exit 1
            fi
            METHOD='r'
            PATTERN="$2"

            # Make sure regex is good
            opencap=$(grep -o '(' <<< $PATTERN | wc -l)
            if ! [ $opencap -ge 1 ]; then
                echo "You must use regex capture groups"
                exit 1
            fi
            closecap=$(grep -o ')' <<< $PATTERN | wc -l)
            if [ $opencap -ne $closecap ]; then
                echo "Unterminated capture group"
                exit 1
            fi

            shift 2
            echo "Regex matching using pattern $PATTERN"
            ;;
        -a | --append)
            if [[ $METHOD = 'p' ]]; then
                echo "Cannot set append and prepend together"
                exit 1
            fi
            METHOD='a'
            shift
            ;;
        -p | --prepend)
            if [[ $METHOD = 'a' ]]; then
                    echo "Cannot set append and prepend together"
                    exit 1
            fi
            METHOD='p'
            shift
            ;;
        --dry-run)
            DRYRUN=1
            shift
            echo "Dry run enabled"
            ;;
        -f | --format)
            FORMAT="$2"
            shift 2
            echo "Using format $FORMAT"
            ;;
        -d | --padding)
            if ! [[ $2 =~ '^[0-9]+$' ]]; then
                echo 'Padding must be a number'
                exit 1
            fi
            DIGITS=$2
            shift 2
            echo "Padding with $DIGITS numbers"
            ;;
        -i | --ignore-extension)
            EXTIGNORE=1
            shift
            echo 'Extensions are ignored'
            ;;
        -h | --help)
            print_help
            exit 0
            ;;
        *)
            break
            ;;
    esac
done

# IF A NAMING METHOD IS NOT SPECIFIED, EXIT
if [ -z $METHOD ]; then
    echo "You must specity a method using -s or -r"
    exit 1
fi

# IF NUMBER OF PADDING IS NOT SPECIFIED, GENERATE ONE
if [ "$DIGITS" -eq 0 ]; then
    DIGITS="$(($STARTINDEX + $# - 1))"
    DIGITS=${#DIGITS}
fi

# LOOP WHERE ALL THE MAGIC HAPPENS. RUNS THE SPECIFIED METHOD FOR EACH FILES PASSED AS PARAMETER
for item in "$@"; do
    if ! [ -f "$item" ]; then
        echo "$item does not exist: Skipping"
        continue
    fi

    if [ $EXTIGNORE -eq 1 ]; then
        ext=$(get_extension "$item")
        item=$(remove_extension "$item")
    fi

    case "$METHOD" in
        s | a | p)
            if [[ $METHOD = 's' ]] && [ -z $FORMAT ]; then
                echo "Format not specified. Defaulting to append"
                METHOD='a'
            fi

            if [[ $METHOD = 'a' ]]; then
                if [ $EXTIGNORE -eq 0 ]; then
                    ext=$(get_extension "$item")
                    item=$(remove_extension "$item")
                    FORMAT="$item"'%1'".$ext"
                else
                    FORMAT="$item"'%1'
                fi
            fi

            if [[ $METHOD = 'p' ]]; then
                FORMAT='%1'"$item"
            fi

            newname=$(sub_rename $(printf '%0'"$DIGITS"'d' $STARTINDEX) $FORMAT)
            if [ $? -eq 0 ]; then
                if [ $EXTIGNORE -eq 1 ]; then
                    newname="$newname.$ext"
                    item="$item"".$ext"
                fi

                if [ $DRYRUN -eq 0 ]; then
                    mv "$item" "$newname"
                else
                    echo "$item -> $newname"
                fi
            else
                echo $newname
                exit 1
            fi
            STARTINDEX=$(($STARTINDEX + 1))
            ;;
        r)
            if [ -z $FORMAT ]; then
                echo "Regex matching requires a format"
                exit 1
            fi

            newname=$(regex_rename $PATTERN $FORMAT $item)
            if [ $? -eq 0 ]; then
                if [ $EXTIGNORE -eq 1 ]; then
                        newname="$newname.$ext"
                        item="$item"".$ext"
                fi

                if [ $DRYRUN -eq 0 ]; then
                    mv "$item" "$newname"
                else
                    echo "$item -> $newname"
                fi
            else
                echo $newname
                exit 1
            fi
            ;;
    esac
done