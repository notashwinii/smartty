smartty_resolve_history_file() {
    local histfile

    for histfile in \
        "$HOME/.config/zsh/histfile" \
        "$HOME/.zsh_history" \
        "$HOME/.zhistory"; do
        [[ -f "$histfile" ]] && print -r -- "$histfile" && return 0
    done

    return 1
}

smartty_extract_history_command() {
    local line="$1"

    if [[ $line == ": "* ]]; then
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

smartty_remember_command() {
    local cmd="$1"

    [[ -n ${SMARTTY_SEEN_COMMANDS[$cmd]} ]] && return 0

    SMARTTY_SEEN_COMMANDS[$cmd]=1
    SMARTTY_COMMANDS+=("$cmd")
}

smartty_load_history() {
    local histfile
    histfile=$(smartty_resolve_history_file) || {
        print -r -- "History file not found"
        return 1
    }

    print -r -- "Loading history from: $histfile"

    local line cmd base_cmd
    SMARTTY_COMMAND_FREQ=()
    SMARTTY_SEEN_COMMANDS=()
    SMARTTY_COMMANDS=()

    while IFS= read -r line; do
        if [[ $line == ": "* ]]; then
            cmd=${line#*;}
        else
            cmd=$line
        fi
        [[ -z "$cmd" ]] && continue

        base_cmd=${cmd%% *}
        base_cmd=${base_cmd//[^a-zA-Z0-9_-]/}
        [[ -z "$base_cmd" ]] && continue

        (( SMARTTY_COMMAND_FREQ[$base_cmd]++ ))
        smartty_remember_command "$cmd"
    done < "$histfile"

    print -r -- "Loaded ${#SMARTTY_COMMAND_FREQ[@]} unique commands and ${#SMARTTY_COMMANDS[@]} suggestions"
}
