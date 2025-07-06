#!/bin/zsh

# Generic Inline Autocompletion System
# Uses actual zsh history file for suggestions

typeset -A COMPLETION_DB
typeset -A COMMAND_FREQ

# Load colors
autoload -U colors && colors

# Load zsh history file
load_history() {
    # Try common history file locations
    local histfile="$HOME/.config/zsh/histfile"
    [[ ! -f "$histfile" ]] && histfile="$HOME/.zsh_history"
    [[ ! -f "$histfile" ]] && histfile="$HOME/.zhistory"
    [[ ! -f "$histfile" ]] && echo "History file not found" && return 1

    echo "Loading history from: $histfile"

    while IFS= read -r line; do
        # Handle extended history format (:timestamp:duration;command)
        if [[ $line == ": "* ]]; then
            local cmd=${line#*;}
        else
            local cmd=$line
        fi

        [[ -z "$cmd" ]] && continue

        # Extract first word as base command
        local base_cmd=${cmd%% *}
        [[ -z "$base_cmd" ]] && continue

        # Sanitize base command to avoid array subscript issues
        base_cmd=${base_cmd//[^a-zA-Z0-9_-]/}
        [[ -z "$base_cmd" ]] && continue

        # Count frequency
        ((COMMAND_FREQ[$base_cmd]++))

        # Build prefix completions for the full command
        local prefix=""
        for ((i=1; i<=${#cmd}; i++)); do
            prefix+="${cmd:$((i-1)):1}"
            if [[ -z ${COMPLETION_DB[$prefix]} ]]; then
                COMPLETION_DB[$prefix]="$cmd"
            else
                # Avoid duplicates
                if [[ ${COMPLETION_DB[$prefix]} != *"$cmd"* ]]; then
                    COMPLETION_DB[$prefix]+=$'\n'"$cmd"
                fi
            fi
        done
    done < "$histfile"

    echo "Loaded ${#COMMAND_FREQ[@]} unique commands"
}

# Get best suggestion based on actual usage frequency
get_suggestion() {
    local input="$1"
    local -a candidates=(${(f)COMPLETION_DB[$input]})
    candidates=(${(u)candidates})  # Remove duplicates

    if [[ ${#candidates[@]} -eq 0 ]]; then
        return 1
    fi

    # Find most frequently used command that starts with input
    local best_cmd=""
    local best_score=0

    for candidate in $candidates; do
        local base_cmd=${candidate%% *}
        base_cmd=${base_cmd//[^a-zA-Z0-9_-]/}
        local freq=${COMMAND_FREQ[$base_cmd]:-0}
        
        if [[ $freq -gt $best_score ]]; then
            best_score=$freq
            best_cmd=$candidate
        fi
    done

    # If no frequency data, just return first candidate
    [[ -z "$best_cmd" ]] && best_cmd=${candidates[1]}
    
    echo "$best_cmd"
}

# Inline mode with dimmed suggestions
inline_mode() {
    echo "${fg[green]}=== Inline Autocompletion ===${reset_color}"
    echo "Tab to accept • Enter to execute • Ctrl+C to exit"
    echo

    stty -echo -icanon
    local input=""
    local char

    while true; do
        # Clear line and show input
        printf "\r\033[K${fg[cyan]}❯ %s${reset_color}" "$input"

        # Show dimmed suggestion
        local suggestion=$(get_suggestion "$input")
        if [[ -n $suggestion && $suggestion != $input ]]; then
            local completion=${suggestion:${#input}}
            printf "\033[2m%s\033[0m" "$completion"
        fi

        read -k 1 char

        case $char in
            $'\x03')  # Ctrl+C
                echo -e "\n${fg[red]}Exiting...${reset_color}"
                break
                ;;
            $'\x09')  # Tab
                suggestion=$(get_suggestion "$input")
                if [[ -n $suggestion ]]; then
                    input="$suggestion"
                    printf "\r\033[K${fg[green]}✓ Accepted: %s${reset_color}" "$input"
                    sleep 0.2
                fi
                ;;
            $'\x0a'|$'\x0d')  # Enter
                if [[ -n $input ]]; then
                    printf "\n${fg[yellow]}Executing: %s${reset_color}\n" "$input"
                    stty echo icanon
                    eval "$input"
                    local exit_code=$?
                    stty -echo -icanon
                    
                    if [[ $exit_code -eq 0 ]]; then
                        printf "${fg[green]}✅ Success${reset_color}\n"
                    else
                        printf "${fg[red]}❌ Failed (exit code: %d)${reset_color}\n" $exit_code
                    fi
                    
                    input=""
                    echo
                fi
                ;;
            $'\x7f'|$'\x08')  # Backspace
                if [[ ${#input} -gt 0 ]]; then
                    input=${input:0:-1}
                fi
                ;;
            *)
                if [[ -n $char && $char != $'\x00' ]]; then
                    input+=$char
                fi
                ;;
        esac
    done

    stty echo icanon
}

# Show statistics from actual usage
show_stats() {
    echo "${fg[green]}Command Usage Statistics${reset_color}"
    echo "Most used commands from your history:"
    echo

    for cmd freq in ${(kv)COMMAND_FREQ}; do
        echo "$freq:$cmd"
    done | sort -nr | head -15 | while IFS=: read freq cmd; do
        printf "  ${fg[cyan]}%s${reset_color} ${fg[yellow]}(%d times)${reset_color}\n" "$cmd" "$freq"
    done
}

# Main function
main() {
    load_history
    echo

    case "$1" in
        "-i"|"--inline")
            inline_mode
            ;;
        "-s"|"--stats")
            show_stats
            ;;
        "-h"|"--help")
            echo "Generic Autocompletion System"
            echo
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  -i, --inline     Inline suggestion mode"
            echo "  -s, --stats      Show usage statistics"
            echo "  -h, --help       Show this help"
            echo
            echo "Features:"
            echo "  • Learns from your actual command history"
            echo "  • Suggests full commands as you type"
            echo "  • Executes commands when you press Enter"
            echo "  • Dimmed suggestions with Tab to accept"
            ;;
        "")
            echo "Usage: $0 [options]"
            echo "Try: $0 -i (for inline autocompletion)"
            ;;
        *)
            local suggestion=$(get_suggestion "$1")
            echo "Input: $1"
            [[ -n $suggestion ]] && echo "Suggestion: $suggestion" || echo "No suggestions"
            ;;
    esac
}

main "$@"


