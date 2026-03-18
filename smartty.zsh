#!/bin/zsh
# smartty — history-powered inline autocompletion for zsh.
#
# Run it:     ./smartty.zsh            (standalone interactive mode)
# Source it:  source smartty.zsh       (plugin mode in your own shell)

SMARTTY_ROOT=${${(%):-%N}:A:h}

for smartty_file in \
    "$SMARTTY_ROOT/lib/smartty/state.zsh" \
    "$SMARTTY_ROOT/lib/smartty/display.zsh" \
    "$SMARTTY_ROOT/lib/smartty/history.zsh" \
    "$SMARTTY_ROOT/lib/smartty/suggestions.zsh" \
    "$SMARTTY_ROOT/lib/smartty/ui.zsh" \
    "$SMARTTY_ROOT/lib/smartty/zle.zsh" \
    "$SMARTTY_ROOT/lib/smartty/cli.zsh"; do
    if ! source "$smartty_file"; then
        print -ru2 -- "smartty: failed to load $smartty_file"
        return 1 2>/dev/null || exit 1
    fi
done
unset smartty_file

if [[ $ZSH_EVAL_CONTEXT == *file* ]]; then
    # Sourced: act as a plugin when the shell is interactive.
    [[ -o interactive ]] && smartty_zle_init
else
    smartty_main "$@"
fi
