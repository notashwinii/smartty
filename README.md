# smartty

Lightweight inline autocompletion for Zsh, powered by your command history.

## Usage
```bash
chmod +x smartty.zsh
./smartty.zsh         # inline mode
./smartty.zsh -i      # inline mode
./smartty.zsh -s      # stats
./smartty.zsh -h      # help
./smartty.zsh "git st"

Options:
  -i, --inline    Interactive completion mode (default)
  -s, --stats     Show command frequency statistics
  -h, --help      Show help

Inline mode controls:
  Tab        Accept suggestion
  Enter      Execute command
  Backspace  Delete character
  Ctrl+C     Exit

## Structure
```text
smartty.zsh              # thin entrypoint
lib/smartty/state.zsh    # shared associative arrays
lib/smartty/display.zsh  # color setup
lib/smartty/history.zsh  # history loading and indexing
lib/smartty/suggestions.zsh
lib/smartty/ui.zsh       # interactive terminal mode
lib/smartty/cli.zsh      # help, stats, and argument handling
```
