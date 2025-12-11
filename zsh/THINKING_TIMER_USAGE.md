# Thinking Timer Usage Guide

## Overview

The thinking timer automatically appears when any operation takes longer than 2 seconds, providing visual feedback with a count-up timer.

## Quick Start

### Method 1: Automatic Wrapper (Easiest)

```bash
# Source the common functions
source "$HOME/code/dotfiles/bin/gtd-common.sh"

# Run any command with automatic timer
run_with_thinking_timer "Processing" your_long_command arg1 arg2
```

### Method 2: Manual Control (More Flexible)

```bash
# Source the common functions
source "$HOME/code/dotfiles/bin/gtd-common.sh"

# Start timer in background
show_thinking_timer "Thinking" &
timer_pid=$!

# Your long-running command
your_long_command

# Stop timer when done
stop_thinking_timer $timer_pid
```

## Examples

### AI/LLM API Calls

```bash
source "$HOME/code/dotfiles/bin/gtd-common.sh"

show_thinking_timer "Calling AI" &
timer_pid=$!

python3 "$PERSONA_HELPER" "$persona" "$prompt" > "$output_file"
exit_code=$?

stop_thinking_timer $timer_pid
```

### File Operations

```bash
source "$HOME/code/dotfiles/bin/gtd-common.sh"

run_with_thinking_timer "Processing files" process_large_file "$file_path"
```

### Network Requests

```bash
source "$HOME/code/dotfiles/bin/gtd-common.sh"

show_thinking_timer "Searching web" &
timer_pid=$!

search_results=$(curl -s "https://api.example.com/search?q=$query")

stop_thinking_timer $timer_pid
```

## Function Reference

### `show_thinking_timer [label] [delay]`

Starts a thinking timer in the background.

- **label**: Text to display (default: "Thinking")
- **delay**: Seconds to wait before showing timer (default: 2)
- **Returns**: Process ID (store in variable for cleanup)

**Note**: Timer only appears if the operation takes longer than the delay time.

### `stop_thinking_timer [pid]`

Stops the thinking timer and clears the display line.

- **pid**: Process ID from `show_thinking_timer`

### `run_with_thinking_timer [label] [command] [args...]`

Wrapper that automatically handles timer for a command.

- **label**: Text to display
- **command**: Command to run
- **args**: Arguments to pass to command
- **Returns**: Exit code from the command

## Timer Display

The timer shows:
- Animated spinner: `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏`
- Elapsed time: `T+MM:SS` or `T+HH:MM:SS`
- Format: `🤔 [label] [spinner] T+[time]`

Example output:
```
🤔 Thinking ⠋ T+00:05
🤔 Processing ⠹ T+01:23
🤔 Calling AI ⠸ T+02:45:12
```

## Best Practices

1. **Always use for operations > 2 seconds**:
   - AI/LLM API calls
   - File operations on large files
   - Network requests
   - Database queries
   - Complex data processing

2. **Use descriptive labels**:
   ```bash
   show_thinking_timer "Calling LM Studio" &
   show_thinking_timer "Processing daily logs" &
   show_thinking_timer "Generating suggestions" &
   ```

3. **Handle errors properly**:
   ```bash
   show_thinking_timer "Processing" &
   timer_pid=$!
   
   if ! your_command; then
     stop_thinking_timer $timer_pid
     echo "Error occurred"
     exit 1
   fi
   
   stop_thinking_timer $timer_pid
   ```

4. **Clean up in all cases**:
   ```bash
   show_thinking_timer "Processing" &
   timer_pid=$!
   
   trap "stop_thinking_timer $timer_pid" EXIT
   
   your_command
   ```

## Integration with Existing Code

The timer functions are available in `gtd-common.sh`, which is already sourced by most GTD scripts. You can use them directly:

```bash
# In any script that sources gtd-common.sh
show_thinking_timer "My operation" &
timer_pid=$!
# ... your code ...
stop_thinking_timer $timer_pid
```

## Cursor Rule

The `.cursorrules` file contains a rule that instructs AI to automatically add thinking timers when generating code for operations that might take > 2 seconds. This ensures consistent user experience across all scripts.

