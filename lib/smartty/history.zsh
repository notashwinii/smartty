smartty_resolve_history_file() {
    local histfile

    for histfile in \
        "$HISTFILE" \
        "$HOME/.config/zsh/histfile" \
        "$HOME/.zsh_history" \
        "$HOME/.zhistory"; do
        [[ -n "$histfile" && -f "$histfile" ]] && print -r -- "$histfile" && return 0
    done

    return 1
}

smartty_extract_history_command() {
    local line="$1"

    if [[ $line == ": "<->":"<->";"* ]]; then
        print -r -- "${line#*;}"
    else
        print -r -- "$line"
    fi
}

smartty_sanitize_base_command() {
    local base_cmd="$1"

    base_cmd=${base_cmd//[^a-zA-Z0-9_-]/}
    print -r -- "$base_cmd"
}

smartty_index_command() {
    setopt localoptions extendedglob
    local cmd="$1"

    cmd=${cmd##[[:space:]]#}
    cmd=${cmd%%[[:space:]]#}
    [[ -z "$cmd" ]] && return 1

    local base_cmd=${cmd%% *}
    base_cmd=${base_cmd//[^a-zA-Z0-9_-]/}

    (( SMARTTY_HISTORY_CLOCK++ ))

    if [[ -n "$base_cmd" ]]; then
        SMARTTY_COMMAND_FREQ[$base_cmd]=$(( ${SMARTTY_COMMAND_FREQ[$base_cmd]:-0} + 1 ))
    fi

    # Multiline commands can't render as inline ghost text; count them but don't suggest.
    [[ $cmd == *$'\n'* ]] && return 0

    SMARTTY_CMD_COUNT[$cmd]=$(( ${SMARTTY_CMD_COUNT[$cmd]:-0} + 1 ))
    SMARTTY_CMD_LAST[$cmd]=$SMARTTY_HISTORY_CLOCK

    if [[ -z ${SMARTTY_SEEN_COMMANDS[$cmd]} ]]; then
        SMARTTY_SEEN_COMMANDS[$cmd]=1
        SMARTTY_COMMANDS+=("$cmd")
    fi
    return 0
}

smartty_load_history() {
    local quiet=0
    [[ "$1" == "-q" ]] && quiet=1

    local histfile
    histfile=$(smartty_resolve_history_file) || {
        (( quiet )) || print -r -- "History file not found"
        return 1
    }

    (( quiet )) || print -r -- "Loading history from: $histfile"

    SMARTTY_COMMAND_FREQ=()
    SMARTTY_CMD_COUNT=()
    SMARTTY_CMD_LAST=()
    SMARTTY_SEEN_COMMANDS=()
    SMARTTY_COMMANDS=()
    SMARTTY_HISTORY_CLOCK=0

    local -a lines
    lines=("${(@f)$(<"$histfile")}") 2>/dev/null
    (( ${#lines} > SMARTTY_HISTORY_MAX )) && lines=("${(@)lines[-SMARTTY_HISTORY_MAX,-1]}")

    local entry
    local metachar=$'\x83'
    local -i i=1 total=${#lines}

    while (( i <= total )); do
        entry=${lines[i]}
        (( i++ ))

        # Continuation lines: zsh writes embedded newlines as backslash-newline.
        while [[ $entry == *\\ ]] && (( i <= total )); do
            entry=${entry%\\}$'\n'${lines[i]}
            (( i++ ))
        done

        [[ $entry == ": "<->":"<->";"* ]] && entry=${entry#*;}
        # Skip entries with metafied (non-ASCII) bytes we can't decode.
        [[ $entry == *$metachar* ]] && continue

        smartty_index_command "$entry"
    done

    SMARTTY_LOADED=1
    (( quiet )) || print -r -- "Loaded ${#SMARTTY_COMMANDS[@]} unique commands (${#SMARTTY_COMMAND_FREQ[@]} distinct programs)"
    return 0
}
