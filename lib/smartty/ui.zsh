smartty_restore_terminal() {
    stty echo icanon 2>/dev/null
}

smartty_execute_input() {
    local input="$1"
    local exit_code

    smartty_init_colors

    printf "\n${fg[yellow]}Executing: %s${reset_color}\n" "$input"
    smartty_restore_terminal
    eval "$input"
    exit_code=$?
    stty -echo -icanon

    if (( exit_code == 0 )); then
        printf "${fg[green]}Success${reset_color}\n"
    else
        printf "${fg[red]}Failed (exit code: %d)${reset_color}\n" "$exit_code"
    fi
}

smartty_inline_mode() {
    local input=""
    local char
    local suggestion
    local completion

    smartty_init_colors

    echo "${fg[green]}=== Inline Autocompletion ===${reset_color}"
    echo "Tab to accept | Enter to execute | Ctrl+C to exit"
    echo

    trap 'smartty_restore_terminal; exit 130' INT TERM
    trap 'smartty_restore_terminal' EXIT

    stty -echo -icanon

    while true; do
        printf "\r\033[K${fg[cyan]}> %s${reset_color}" "$input"

        suggestion=$(smartty_get_suggestion "$input")
        if [[ -n "$suggestion" && "$suggestion" != "$input" ]]; then
            completion=${suggestion:${#input}}
            printf "\033[2m%s\033[0m" "$completion"
        fi

        read -k 1 char

        case $char in
            $'\x03')
                printf "\n${fg[red]}Exiting...${reset_color}\n"
                break
                ;;
            $'\x09')
                suggestion=$(smartty_get_suggestion "$input")
                if [[ -n "$suggestion" ]]; then
                    input="$suggestion"
                    printf "\r\033[K${fg[green]}Accepted: %s${reset_color}" "$input"
                    sleep 0.2
                fi
                ;;
            $'\x0a'|$'\x0d')
                if [[ -n "$input" ]]; then
                    smartty_execute_input "$input"
                    input=""
                    echo
                fi
                ;;
            $'\x7f'|$'\x08')
                [[ ${#input} -gt 0 ]] && input=${input:0:-1}
                ;;
            *)
                [[ -n "$char" && "$char" != $'\x00' ]] && input+=$char
                ;;
        esac
    done

    smartty_restore_terminal
    trap - INT TERM EXIT
}
