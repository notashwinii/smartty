# Fill SMARTTY_MATCHES with up to $2 (default 5) history commands starting with
# $1, ranked by frequency then recency. SMARTTY_SUGGESTION gets the best match.
smartty_compute_matches() {
    setopt localoptions extendedglob
    local input="$1"
    local -i max=${2:-5}

    SMARTTY_MATCHES=()
    SMARTTY_SUGGESTION=""

    [[ -z "$input" ]] && return 1

    local -a candidates
    candidates=("${(@M)SMARTTY_COMMANDS:#${(b)input}*}")
    (( ${#candidates} )) || return 1

    # Sort key: zero-padded frequency + recency, so lexicographic order is numeric.
    local candidate key
    local -a scored
    for candidate in "${candidates[@]}"; do
        printf -v key '%010d %010d' \
            "${SMARTTY_CMD_COUNT[$candidate]:-0}" \
            "${SMARTTY_CMD_LAST[$candidate]:-0}"
        scored+=("$key $candidate")
    done

    scored=("${(@O)scored}")
    (( ${#scored} > max )) && scored=("${(@)scored[1,max]}")

    local entry
    for entry in "${scored[@]}"; do
        SMARTTY_MATCHES+=("${entry:22}")
    done

    SMARTTY_SUGGESTION=${SMARTTY_MATCHES[1]}
    return 0
}

smartty_get_suggestion() {
    smartty_compute_matches "$1" 1 || return 1
    print -r -- "$SMARTTY_SUGGESTION"
}
