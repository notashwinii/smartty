typeset -g SMARTTY_STTY_SAVED=""
typeset -gi SMARTTY_INTERRUPTED=0
typeset -g SMARTTY_KEY=""
typeset -g SMARTTY_KEY_TYPE=""

smartty_raw_on() {
    stty -echo -icanon min 1 time 0 2>/dev/null
}

smartty_restore_terminal() {
    if [[ -n "$SMARTTY_STTY_SAVED" ]]; then
        stty "$SMARTTY_STTY_SAVED" 2>/dev/null
    else
        stty echo icanon 2>/dev/null
    fi
}

smartty_execute_input() {
    local input="$1"
    local exit_code

    smartty_init_colors

    printf '\n'
    smartty_restore_terminal
    eval "$input"
    exit_code=$?
    smartty_raw_on

    smartty_index_command "$input"
    SMARTTY_SESSION_HISTORY+=("$input")

    if (( exit_code == 0 )); then
        printf '%s\n' "${fg[green]}(exit 0)${reset_color}"
    else
        printf '%s\n' "${fg[red]}(exit $exit_code)${reset_color}"
    fi
    return $exit_code
}

# Read one keypress, decoding escape sequences.
# Sets SMARTTY_KEY_TYPE to a key name (up, down, left, right, home, end,
# delete, ctrl-right, esc, char) and SMARTTY_KEY to the literal character.
smartty__read_key() {
    local char c2 c seq
    SMARTTY_KEY="" SMARTTY_KEY_TYPE=""

    read -k 1 char 2>/dev/null || return 1

    if [[ $char != $'\x1b' ]]; then
        SMARTTY_KEY_TYPE=char
        SMARTTY_KEY=$char
        return 0
    fi

    read -k 1 -t 0.05 c2 2>/dev/null || { SMARTTY_KEY_TYPE=esc; return 0 }
    if [[ $c2 != '[' && $c2 != O ]]; then
        SMARTTY_KEY_TYPE=esc
        return 0
    fi

    seq=$c2
    while read -k 1 -t 0.05 c 2>/dev/null; do
        seq+=$c
        [[ $c == [A-Za-z~] ]] && break
    done

    case $seq in
        '[A'|OA)        SMARTTY_KEY_TYPE=up ;;
        '[B'|OB)        SMARTTY_KEY_TYPE=down ;;
        '[C'|OC)        SMARTTY_KEY_TYPE=right ;;
        '[D'|OD)        SMARTTY_KEY_TYPE=left ;;
        '[H'|OH|'[1~')  SMARTTY_KEY_TYPE=home ;;
        '[F'|OF|'[4~')  SMARTTY_KEY_TYPE=end ;;
        '[3~')          SMARTTY_KEY_TYPE=delete ;;
        '[1;5C')        SMARTTY_KEY_TYPE=ctrl-right ;;
        *)              SMARTTY_KEY_TYPE=unknown ;;
    esac
    return 0
}

smartty__redraw() {
    local input="$1" ghost="$3"
    local -i cursor=$2
    local -i back=$(( ${#input} - cursor + ${#ghost} ))

    printf '\r\033[K%s' "${fg[cyan]}> ${reset_color}"
    printf '%s' "$input"
    [[ -n "$ghost" ]] && printf '\033[2m%s\033[0m' "$ghost"
    (( back > 0 )) && printf '\033[%dD' $back
}

smartty_inline_mode() {
    setopt localoptions extendedglob
    local input="" ghost="" draft="" add="" head="" tail="" best=""
    local -a matches
    local -i cursor=0 match_idx=1 hist_idx=0

    smartty_init_colors

    print -r -- "${fg[green]}smartty — inline autocompletion${reset_color}"
    print -r -- "Tab/→/End accept · Ctrl+→ accept word · Ctrl+N/P cycle · ↑/↓ session history"
    print -r -- "Enter run · Ctrl+C clear line · Ctrl+D exit"
    print

    SMARTTY_STTY_SAVED=$(stty -g 2>/dev/null)
    SMARTTY_INTERRUPTED=0
    trap 'SMARTTY_INTERRUPTED=1' INT
    trap 'smartty_restore_terminal' TERM EXIT

    smartty_raw_on

    while true; do
        matches=()
        ghost=""
        if [[ -n "$input" ]] && (( cursor == ${#input} )); then
            if smartty_compute_matches "$input" 8; then
                matches=("${(@)SMARTTY_MATCHES:#${(b)input}}")
            fi
            (( match_idx > ${#matches} )) && match_idx=1
            if (( ${#matches} )); then
                best=${matches[match_idx]}
                ghost=${best:${#input}}
            fi
        fi

        smartty__redraw "$input" $cursor "$ghost"

        if ! smartty__read_key; then
            if (( SMARTTY_INTERRUPTED )); then
                SMARTTY_INTERRUPTED=0
                printf '^C\n'
                input="" cursor=0 match_idx=1 hist_idx=0
                continue
            fi
            printf '\n'
            break
        fi

        case $SMARTTY_KEY_TYPE in
            char)
                case $SMARTTY_KEY in
                    $'\x04')                              # Ctrl+D
                        if [[ -z "$input" ]]; then
                            printf '\n'
                            break
                        fi
                        ;;
                    $'\x09')                              # Tab
                        if [[ -n "$ghost" ]]; then
                            input+=$ghost
                            cursor=${#input}
                            match_idx=1
                        fi
                        ;;
                    $'\x0a'|$'\x0d')                      # Enter
                        if [[ -n "$input" ]]; then
                            smartty_execute_input "$input"
                            input="" cursor=0 match_idx=1 hist_idx=0
                            print
                        fi
                        ;;
                    $'\x7f'|$'\x08')                      # Backspace
                        if (( cursor > 0 )); then
                            input=${input[1,cursor-1]}${input[cursor+1,-1]}
                            (( cursor-- ))
                            match_idx=1
                        fi
                        ;;
                    $'\x01') cursor=0 ;;                  # Ctrl+A
                    $'\x05')                              # Ctrl+E
                        if [[ -n "$ghost" ]]; then
                            input+=$ghost
                            match_idx=1
                        fi
                        cursor=${#input}
                        ;;
                    $'\x0b') input=${input[1,cursor]} ;;   # Ctrl+K
                    $'\x15')                              # Ctrl+U
                        input=${input[cursor+1,-1]}
                        cursor=0
                        match_idx=1
                        ;;
                    $'\x17')                              # Ctrl+W
                        if (( cursor > 0 )); then
                            head=${input[1,cursor]}
                            tail=${input[cursor+1,-1]}
                            head=${head%%[^[:space:]]#[[:space:]]#}
                            input=$head$tail
                            cursor=${#head}
                            match_idx=1
                        fi
                        ;;
                    $'\x0e')                              # Ctrl+N
                        (( ${#matches} )) && (( match_idx = match_idx % ${#matches} + 1 ))
                        ;;
                    $'\x10')                              # Ctrl+P
                        (( ${#matches} )) && (( match_idx = (match_idx + ${#matches} - 2) % ${#matches} + 1 ))
                        ;;
                    $'\x0c') printf '\033[2J\033[H' ;;    # Ctrl+L
                    *)
                        if [[ $SMARTTY_KEY == [[:print:]] ]]; then
                            input=${input[1,cursor]}$SMARTTY_KEY${input[cursor+1,-1]}
                            (( cursor++ ))
                            match_idx=1
                        fi
                        ;;
                esac
                ;;
            up)
                if (( ${#SMARTTY_SESSION_HISTORY} )) && (( hist_idx < ${#SMARTTY_SESSION_HISTORY} )); then
                    (( hist_idx == 0 )) && draft=$input
                    (( hist_idx++ ))
                    input=${SMARTTY_SESSION_HISTORY[-hist_idx]}
                    cursor=${#input}
                    match_idx=1
                fi
                ;;
            down)
                if (( hist_idx > 0 )); then
                    (( hist_idx-- ))
                    if (( hist_idx == 0 )); then
                        input=$draft
                    else
                        input=${SMARTTY_SESSION_HISTORY[-hist_idx]}
                    fi
                    cursor=${#input}
                    match_idx=1
                fi
                ;;
            left)  (( cursor > 0 )) && (( cursor-- )) ;;
            right)
                if (( cursor < ${#input} )); then
                    (( cursor++ ))
                elif [[ -n "$ghost" ]]; then
                    input+=$ghost
                    cursor=${#input}
                    match_idx=1
                fi
                ;;
            home) cursor=0 ;;
            end)
                if [[ -n "$ghost" ]]; then
                    input+=$ghost
                    match_idx=1
                fi
                cursor=${#input}
                ;;
            delete)
                (( cursor < ${#input} )) && input=${input[1,cursor]}${input[cursor+2,-1]}
                ;;
            ctrl-right)
                if [[ -n "$ghost" ]]; then
                    add=${(M)ghost##[[:space:]]#[^[:space:]]##}
                    [[ -z "$add" ]] && add=$ghost
                    input+=$add
                    cursor=${#input}
                    match_idx=1
                elif (( cursor < ${#input} )); then
                    cursor=${#input}
                fi
                ;;
        esac
    done

    smartty_restore_terminal
    trap - INT TERM EXIT
}
