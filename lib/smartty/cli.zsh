smartty_print_help() {
    cat <<'EOF'
smartty

Lightweight inline autocompletion for Zsh, powered by your command history.

Usage:
  ./smartty.zsh              Start inline mode
  ./smartty.zsh -i           Start inline mode
  ./smartty.zsh -s           Show command frequency statistics
  ./smartty.zsh -h           Show help
  ./smartty.zsh "git st"     Show the best matching suggestion

Options:
  -i, --inline    Interactive completion mode
  -s, --stats     Show command frequency statistics
  -h, --help      Show help

Inline mode controls:
  Tab        Accept suggestion
  Enter      Execute command
  Backspace  Delete character
  Ctrl+C     Exit
EOF
}

smartty_show_stats() {
    local cmd freq

    smartty_init_colors

    echo "${fg[green]}Command Usage Statistics${reset_color}"
    echo "Most used commands from your history:"
    echo

    for cmd freq in ${(kv)SMARTTY_COMMAND_FREQ}; do
        echo "$freq:$cmd"
    done | sort -nr | head -15 | while IFS=: read -r freq cmd; do
        printf "  ${fg[cyan]}%s${reset_color} ${fg[yellow]}(%d times)${reset_color}\n" "$cmd" "$freq"
    done
}

smartty_main() {
    case "$1" in
        "-h"|"--help")
            smartty_print_help
            return 0
            ;;
    esac

    smartty_load_history || return 1
    echo

    case "${1:--inline}" in
        "-i"|"--inline")
            smartty_inline_mode
            ;;
        "-s"|"--stats")
            smartty_show_stats
            ;;
        *)
            local suggestion
            suggestion=$(smartty_get_suggestion "$1")
            echo "Input: $1"
            [[ -n "$suggestion" ]] && echo "Suggestion: $suggestion" || echo "No suggestions"
            ;;
    esac
}
