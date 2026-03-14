typeset -g SMARTTY_COLORS_READY=0

smartty_init_colors() {
    (( SMARTTY_COLORS_READY )) && return 0

    autoload -U colors && colors
    SMARTTY_COLORS_READY=1
}
