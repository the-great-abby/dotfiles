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

2. **Updated all 88 gtd scripts** to source `common_env.sh`:
   
   **Core GTD Commands:**
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
   - `bin/gtd-afternoon`
   - `bin/gtd-evening`
   - `bin/gtd-find`
   - `bin/gtd-log`
   - `bin/gtd-search`
   - `bin/gtd-help`
   - `bin/gtd-brain`
   - `bin/gtd-calendar`
   - `bin/gtd-notify`
   - `bin/gtd-weekly-reminder`
   - `bin/gtd-welcome`
   - `bin/gtd-aliases`
   - `bin/gtd-select-item`
   - `bin/gtd-select-helper.sh`
   - `bin/gtd-setup-weekly-reminder`
   
   **Additional GTD Commands (all 88 total):**
   - All remaining `gtd-*` scripts in `bin/` directory, including:
     - Brain commands (`gtd-brain-*`)
     - Reminder scripts (`gtd-*-reminder`, `gtd-setup-*-reminder`)
     - Logging commands (`gtd-log-*`, `gtd-daily-log-*`)
     - Learning commands (`gtd-learn-*`)
     - Health tracking (`gtd-health-*`, `gtd-healthkit-*`)
     - Habit tracking (`gtd-habit`, `gtd-cka-*`, `gtd-greek-*`)
     - And all other GTD-related scripts

3. **Updated zshrc files** to source `common_env.sh`:
   - `zsh/zshrc`
   - `zsh/zshrc_mac_mise`

4. **Helper script created**:
   - `bin/update-gtd-scripts-env.sh` - Automated script to update gtd scripts (used during initial rollout)

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

## Status

✅ **All 88 gtd-* scripts have been updated** to source `common_env.sh`. The fix is comprehensive and complete.

**Verification:** 
- ✅ Confirmed 88/88 scripts updated (100% coverage)
- ✅ All `gtd-*` scripts in `bin/` directory now source `common_env.sh`
- ✅ Both `zshrc` files (`zshrc` and `zshrc_mac_mise`) have been updated
- ✅ `common_env.sh` file exists and is properly configured

**Complete List of Updated Scripts (88 total):**

**Core GTD Commands (24):**
`gtd-task`, `gtd-process`, `gtd-project`, `gtd-capture`, `gtd-review`, `gtd-area`, `gtd-wizard`, `gtd-now`, `gtd-morning`, `gtd-afternoon`, `gtd-evening`, `gtd-daily-log`, `gtd-find`, `gtd-log`, `gtd-search`, `gtd-help`, `gtd-brain`, `gtd-calendar`, `gtd-notify`, `gtd-weekly-reminder`, `gtd-welcome`, `gtd-aliases`, `gtd-select-item`, `gtd-select-helper.sh`

**Brain Commands (14):**
`gtd-brain-connect`, `gtd-brain-converge`, `gtd-brain-discover`, `gtd-brain-distill`, `gtd-brain-diverge`, `gtd-brain-evergreen`, `gtd-brain-express`, `gtd-brain-metrics`, `gtd-brain-moc`, `gtd-brain-moc-starter`, `gtd-brain-packet`, `gtd-brain-sync`, `gtd-brain-sync-daily-logs`, `gtd-brain-template`

**Reminder Scripts (15):**
`gtd-daily-reminder`, `gtd-food-reminder`, `gtd-health-reminder`, `gtd-lunch-reminder`, `gtd-morning-reminder`, `gtd-study-reminder`, `gtd-setup-all-reminders`, `gtd-setup-daily-reminder`, `gtd-setup-food-reminder`, `gtd-setup-health-reminder`, `gtd-setup-health-sync`, `gtd-setup-morning-context`, `gtd-setup-study-reminder`, `gtd-setup-weekly-reminder`, `gtd-setup-evening-summary`

**Logging Commands (7):**
`gtd-daily-log-sync`, `gtd-log-calendar`, `gtd-log-mood`, `gtd-log-stats`, `gtd-log-weather`, `gtd-healthkit-log`, `gtd-sync-health`

**Learning Commands (3):**
`gtd-learn`, `gtd-learn-greek`, `gtd-learn-kubernetes`

**Habit Tracking (6):**
`gtd-habit`, `gtd-cka-gamification`, `gtd-cka-quick`, `gtd-cka-setup-habit`, `gtd-cka-typing`, `gtd-greek-setup-habit`

**Other GTD Commands (19):**
`gtd-advise`, `gtd-area-starter`, `gtd-checkin`, `gtd-collect-all`, `gtd-context`, `gtd-diagram`, `gtd-energy-audit`, `gtd-energy-schedule`, `gtd-evening-summary`, `gtd-goal`, `gtd-metric-correlations`, `gtd-milestone-celebration`, `gtd-morning-context`, `gtd-pattern-recognition`, `gtd-predictive-reminders`, `gtd-study-plan`, `gtd-test-discord`, `gtd-tips`, `gtd-weekly-progress`

If you add new gtd-* bash scripts in the future, you should include the same `common_env.sh` sourcing snippet (shown above) right after the `#!/bin/bash` line and before any other configuration loading.

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

**Verification Commands:**

You can verify the fix is complete by running:

```bash
cd ~/code/dotfiles

# Count total gtd-* scripts
find bin -name 'gtd-*' -type f | wc -l

# Count scripts that source common_env.sh
grep -l 'common_env.sh' bin/gtd-* 2>/dev/null | wc -l

# Verify zshrc files are updated
grep -l 'common_env.sh' zsh/zshrc* 2>/dev/null | wc -l

# Check if common_env.sh exists
[ -f zsh/common_env.sh ] && echo "✓ common_env.sh exists" || echo "✗ common_env.sh missing"
```

All counts should match: 88 scripts total, 88 scripts with `common_env.sh`, 2 zshrc files updated.

## Notes

- The `common_env.sh` file uses bash-compatible syntax that also works in zsh
- Paths are added conditionally (only if directories exist)
- System paths are always ensured to be present for basic commands
- The solution is backward compatible - if `common_env.sh` doesn't exist, scripts will still work (just without the extra paths)

