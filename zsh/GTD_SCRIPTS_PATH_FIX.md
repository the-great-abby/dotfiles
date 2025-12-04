# GTD Scripts PATH Fix

## Problem

When running gtd commands (like `gtd-task`, `gtd-process`, etc.), the scripts were running in a bash shell that didn't have access to the PATH variables configured in your `zshrc` file. This caused the scripts to "forget" the various paths that were set up when you source zshrc.

## Root Cause

The gtd commands are bash scripts (`#!/bin/bash`), and when they execute, they run in a fresh bash environment that doesn't automatically source your zshrc file. Bash scripts only inherit environment variables that are:
1. Exported in the parent shell
2. Set in files that bash sources (like `~/.bashrc` or `~/.bash_profile`)
3. Explicitly sourced within the script itself

## Solution

Created a common environment file (`zsh/common_env.sh`) that contains all the PATH configuration in a format compatible with both bash and zsh. This file is now sourced at the beginning of all gtd bash scripts, ensuring they have access to the same PATH setup as your interactive zsh shell.

### Files Created/Modified

1. **`zsh/common_env.sh`** - New file containing PATH setup that works for both bash and zsh
   - Sets up system paths (`/usr/bin`, `/bin`, etc.)
   - Adds Homebrew paths (both Apple Silicon and Intel)
   - Adds user bin directories
   - Adds dotfiles bin directory
   - Adds other tool-specific paths (LM Studio, Rancher Desktop, Ruby gems, etc.)

2. **Updated gtd scripts** to source `common_env.sh`:
   - `bin/gtd-task`
   - `bin/gtd-process`
   - `bin/gtd-project`
   - `bin/gtd-capture`
   - `bin/gtd-review`
   - `bin/gtd-area`
   - `bin/gtd-wizard`
   - `bin/gtd-now`
   - `bin/gtd-morning`
   - `bin/gtd-daily-log`

## How It Works

Each updated script now includes this snippet at the beginning (after the shebang):

```bash
# Source common environment (PATH setup)
COMMON_ENV="$HOME/code/dotfiles/zsh/common_env.sh"
if [[ ! -f "$COMMON_ENV" && -f "$HOME/code/personal/dotfiles/zsh/common_env.sh" ]]; then
  COMMON_ENV="$HOME/code/personal/dotfiles/zsh/common_env.sh"
fi
if [[ -f "$COMMON_ENV" ]]; then
  source "$COMMON_ENV"
fi
```

This ensures:
- The script looks for `common_env.sh` in the standard location
- Falls back to personal dotfiles location if needed
- Only sources if the file exists (graceful degradation)

## Updating Remaining Scripts

If you have other gtd-* bash scripts that need the same fix, you can:

1. **Manual update**: Add the same snippet (shown above) to any gtd-* script right after the `#!/bin/bash` line and before any other configuration loading.

2. **Automated update**: A helper script `bin/update-gtd-scripts-env.sh` was created (though it may need adjustment based on script formats).

## Testing

To verify the fix works:

```bash
# In your zsh shell, check your PATH
echo $PATH

# Run a gtd command and check if it can find tools
gtd-task list

# If you have tools that should be in PATH (like from Homebrew), they should now work
# inside the gtd scripts
```

## Notes

- The `common_env.sh` file uses bash-compatible syntax that also works in zsh
- Paths are added conditionally (only if directories exist)
- System paths are always ensured to be present for basic commands
- The solution is backward compatible - if `common_env.sh` doesn't exist, scripts will still work (just without the extra paths)

