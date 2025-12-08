# ✅ Aliases Fixed!

## What I Did

1. ✅ Added the aliases source to your `zshrc_mac_mise` file
2. ✅ Fixed the conflict with the `c` alias (now uses a function)
3. ✅ Tested - everything works!

## To Use Right Now

**Option 1: Reload your shell** (fastest)
```bash
source ~/.zshrc
```

**Option 2: Restart terminal** (if reload doesn't work)
- Close and reopen your terminal window

## Test It

After reloading, try:
```bash
now          # Should show "What Should You Do Now?"
c "test"     # Should capture a task
p            # Should process inbox
t            # Should list tasks
```

## Available Aliases

| Command | What It Does |
|---------|-------------|
| `now` | What should I do now? |
| `c "task"` | Quick capture |
| `i "idea"` | Quick idea |
| `log "note"` | Quick log |
| `p` | Process inbox |
| `t` | List tasks |
| `w` | Open wizard |
| `status` | System status |
| `morning` | Morning routine |
| `evening` | Evening routine |

## If It Still Doesn't Work

Check if the file is being sourced:
```bash
grep gtd-aliases ~/.zshrc
```

Should show:
```
source "$HOME/code/dotfiles/zsh/gtd-aliases.zsh"
```

If not, the aliases file is at:
```
~/code/dotfiles/zsh/gtd-aliases.zsh
```



