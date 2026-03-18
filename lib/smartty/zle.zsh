# Plugin mode: ghost-text suggestions in the user's real interactive shell,
# rendered via POSTDISPLAY from a zle-line-pre-redraw hook.

typeset -g SMARTTY_LAST_HIGHLIGHT=""

smartty__zle_update() {
    emulate -L zsh

    if [[ -n $SMARTTY_LAST_HIGHLIGHT ]]; then
        region_highlight=("${(@)region_highlight:#$SMARTTY_LAST_HIGHLIGHT}")
        SMARTTY_LAST_HIGHLIGHT=""
    fi
    POSTDISPLAY=""

    [[ -n $BUFFER && $BUFFER != *$'\n'* ]] || return 0
    (( CURSOR == ${#BUFFER} )) || return 0

    smartty_compute_matches "$BUFFER" 1 || return 0
    [[ $SMARTTY_SUGGESTION == "$BUFFER" ]] && return 0

    POSTDISPLAY=${SMARTTY_SUGGESTION:${#BUFFER}}
    SMARTTY_LAST_HIGHLIGHT="${#BUFFER} $(( ${#BUFFER} + ${#POSTDISPLAY} )) fg=8"
    region_highlight+=("$SMARTTY_LAST_HIGHLIGHT")
    return 0
}

smartty__zle_finish() {
    if [[ -n $SMARTTY_LAST_HIGHLIGHT ]]; then
        region_highlight=("${(@)region_highlight:#$SMARTTY_LAST_HIGHLIGHT}")
        SMARTTY_LAST_HIGHLIGHT=""
    fi
    POSTDISPLAY=""
    return 0
}

smartty__zle_accept() {
    if [[ -n $POSTDISPLAY ]]; then
        BUFFER+=$POSTDISPLAY
        POSTDISPLAY=""
        CURSOR=${#BUFFER}
    fi
}

smartty__zle_accept_word() {
    emulate -L zsh
    setopt extendedglob
    [[ -n $POSTDISPLAY ]] || return 0

    local add=${(M)POSTDISPLAY##[[:space:]]#[^[:space:]]##}
    [[ -z $add ]] && add=$POSTDISPLAY
    BUFFER+=$add
    CURSOR=${#BUFFER}
    POSTDISPLAY=${POSTDISPLAY:${#add}}
}

smartty__zle_forward_char() {
    if (( CURSOR == ${#BUFFER} )) && [[ -n $POSTDISPLAY ]]; then
        smartty__zle_accept
    else
        zle .forward-char
    fi
}

smartty__zle_end_of_line() {
    if (( CURSOR == ${#BUFFER} )) && [[ -n $POSTDISPLAY ]]; then
        smartty__zle_accept
    else
        zle .end-of-line
    fi
}

# Learn commands as they are executed in this shell.
smartty__zle_record() {
    local cmd=${1%$'\n'}
    [[ -n ${cmd//[[:space:]]/} ]] && smartty_index_command "$cmd"
    return 0
}

smartty_zle_init() {
    [[ -o interactive ]] || return 0
    autoload -Uz add-zle-hook-widget add-zsh-hook || return 1

    (( SMARTTY_LOADED )) || smartty_load_history -q

    zle -N smartty-accept smartty__zle_accept
    zle -N smartty-accept-word smartty__zle_accept_word
    zle -N smartty-forward-char smartty__zle_forward_char
    zle -N smartty-end-of-line smartty__zle_end_of_line

    add-zle-hook-widget zle-line-pre-redraw smartty__zle_update
    add-zle-hook-widget zle-line-finish smartty__zle_finish
    add-zsh-hook zshaddhistory smartty__zle_record

    bindkey '^[[C' smartty-forward-char
    bindkey '^[OC' smartty-forward-char
    bindkey '^[[F' smartty-end-of-line
    bindkey '^[OF' smartty-end-of-line
    bindkey '^E' smartty-end-of-line
    bindkey '^[[1;5C' smartty-accept-word
}
