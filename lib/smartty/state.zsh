# Frequency of each base command (first word), used for stats.
typeset -gA SMARTTY_COMMAND_FREQ
# Frequency and most recent history position of each full command line.
typeset -gA SMARTTY_CMD_COUNT
typeset -gA SMARTTY_CMD_LAST
# Dedup set and insertion-ordered list of suggestible commands.
typeset -gA SMARTTY_SEEN_COMMANDS
typeset -ga SMARTTY_COMMANDS
# Monotonic position counter used for recency ranking.
typeset -gi SMARTTY_HISTORY_CLOCK=0
typeset -gi SMARTTY_LOADED=0
# Output of the last smartty_compute_matches call.
typeset -g SMARTTY_SUGGESTION=""
typeset -ga SMARTTY_MATCHES
# Commands executed in the current inline session.
typeset -ga SMARTTY_SESSION_HISTORY
# Maximum number of history entries to index.
typeset -gi SMARTTY_HISTORY_MAX=${SMARTTY_HISTORY_MAX:-10000}
