smartty_get_suggestion() {
    local input="$1"
    local -a candidates
    local candidate
    local base_cmd
    local freq
    local best_cmd=""
    local best_score=0

    for candidate in "${SMARTTY_COMMANDS[@]}"; do
        [[ "$candidate" == "$input"* ]] && candidates+=("$candidate")
    done

    (( ${#candidates[@]} )) || return 1

    for candidate in "${candidates[@]}"; do
        base_cmd=${candidate%% *}
        base_cmd=$(smartty_sanitize_base_command "$base_cmd")
        freq=${SMARTTY_COMMAND_FREQ[$base_cmd]:-0}

        if (( freq > best_score )); then
            best_score=$freq
            best_cmd=$candidate
        fi
    done

    [[ -n "$best_cmd" ]] || best_cmd=${candidates[1]}
    print -r -- "$best_cmd"
}
