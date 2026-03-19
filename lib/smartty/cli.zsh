smartty_print_help() {
    cat <<'EOF'
smartty

Lightweight inline autocompletion for Zsh, powered by your command history.

Usage:
  ./smartty.zsh              Start inline mode
  ./smartty.zsh -i           Start inline mode
  ./smartty.zsh -s           Show command frequency statistics
  ./smartty.zsh -h           Show help
  ./smartty.zsh "git st"     Show the best matching suggestions

Plugin mode (suggestions in your real shell):
  Add to ~/.zshrc:  source /path/to/smartty.zsh
  Then: → / End / Ctrl+E accept, Ctrl+→ accept one word.

Options:
  -i, --inline    Interactive completion mode
  -s, --stats     Show command frequency statistics
  -h, --help      Show help

Inline mode controls:
  Tab / → / End   Accept suggestion
  Ctrl+→          Accept next word of suggestion
  Ctrl+N / Ctrl+P Cycle through suggestions
  ↑ / ↓           Session history
  ← / →           Move cursor
  Ctrl+A/E/K/U/W  Line editing
  Enter           Execute command
  Ctrl+C          Clear line
  Ctrl+D          Exit
EOF
}

smartty_show_stats() {
    local cmd freq

    smartty_init_colors

    echo "${fg[green]}Command Usage Statistics${reset_color}"
    echo

    echo "${fg[cyan]}Most used programs:${reset_color}"
    for cmd freq in "${(@kv)SMARTTY_COMMAND_FREQ}"; do
        printf '%s\t%s\n' "$freq" "$cmd"
    done | sort -nr | head -10 | while IFS=$'\t' read -r freq cmd; do
        printf "  %-40s ${fg[yellow]}%d${reset_color}\n" "$cmd" "$freq"
    done

    echo
    echo "${fg[cyan]}Most used commands:${reset_color}"
    for cmd freq in "${(@kv)SMARTTY_CMD_COUNT}"; do
        printf '%s\t%s\n' "$freq" "$cmd"
    done | sort -nr | head -10 | while IFS=$'\t' read -r freq cmd; do
        printf "  %-40s ${fg[yellow]}%d${reset_color}\n" "$cmd" "$freq"
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

    case "${1:---inline}" in
        "-i"|"--inline")
            smartty_inline_mode
            ;;
        "-s"|"--stats")
            smartty_show_stats
            ;;
        *)
            local query="$*"
            if smartty_compute_matches "$query" 5; then
                echo "Input: $query"
                local match
                local -i i=1
                for match in "${SMARTTY_MATCHES[@]}"; do
                    printf '%d. %s\n' $i "$match"
                    (( i++ ))
                done
            else
                echo "No suggestions for: $query"
            fi
            ;;
    esac
}
