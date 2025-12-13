# smartty

Lightweight inline autocompletion for Zsh, powered by your command history.

## Usage
```bash
chmod +x smartty.zsh
./smartty.zsh -i      # inline mode
./smartty.zsh -s      # stats
./smartty.zsh -h      # help

Options:
  -i, --inline    Interactive completion mode (default)
  -s, --stats     Show command frequency statistics
  -h, --help      Show help

Inline mode controls:
  Tab        Accept suggestion
  Enter      Execute command
  Backspace  Delete character
  Ctrl+C     Exit
