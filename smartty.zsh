#!/bin/zsh

SMARTTY_ROOT=${0:A:h}

for smartty_file in \
    "$SMARTTY_ROOT/lib/smartty/state.zsh" \
    "$SMARTTY_ROOT/lib/smartty/display.zsh" \
    "$SMARTTY_ROOT/lib/smartty/history.zsh" \
    "$SMARTTY_ROOT/lib/smartty/suggestions.zsh" \
    "$SMARTTY_ROOT/lib/smartty/ui.zsh" \
    "$SMARTTY_ROOT/lib/smartty/cli.zsh"; do
    source "$smartty_file" || exit 1
done

smartty_main "$@"
