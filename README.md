# smartty

Lightweight inline autocompletion for Zsh, powered by your command history.
Suggestions are ranked by how often you run a command, with recency as the
tiebreaker, and rendered as gray ghost text after your cursor.

## Plugin mode (recommended)

Source smartty from your `.zshrc` to get suggestions in your real shell:

```zsh
source /path/to/smartty/smartty.zsh
```

As you type, the best history match appears as ghost text. Commands you run
are learned live, so new commands become suggestible immediately.

| Key | Action |
| --- | --- |
| `→` / `End` / `Ctrl+E` | Accept the whole suggestion |
| `Ctrl+→` | Accept the next word of the suggestion |


## Standalone mode

```bash
chmod +x smartty.zsh
./smartty.zsh           # interactive inline mode
./smartty.zsh -s        # command frequency statistics
./smartty.zsh -h        # help
./smartty.zsh "git st"  # print the top suggestions for a prefix
```

Inline mode controls:

| Key | Action |
| --- | --- |
| `Tab` / `→` / `End` | Accept suggestion |
| `Ctrl+→` | Accept next word of suggestion |
| `Ctrl+N` / `Ctrl+P` | Cycle through suggestions |
| `↑` / `↓` | Navigate session history |
| `←` / `→`, `Home`/`End` | Move cursor |
| `Ctrl+A` / `Ctrl+E` | Start / end of line |
| `Ctrl+U` / `Ctrl+K` / `Ctrl+W` | Kill to start / to end / previous word |
| `Ctrl+L` | Clear screen |
| `Enter` | Execute command |
| `Ctrl+C` | Clear line |
| `Ctrl+D` | Exit |

Commands run in the current shell, so `cd` and variable assignments persist
within the session.

## How it works

- History is read from `$HISTFILE` (falling back to common locations),
  handling zsh extended-history timestamps and multiline entries.
- Every full command line is counted; suggestions are ranked by frequency,
  then by how recently the command was last used.
- Matching is a literal prefix match (glob characters in your input are not
  interpreted).

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `SMARTTY_HISTORY_MAX` | `10000` | Maximum history entries to index |
