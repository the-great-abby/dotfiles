# Alias Conflict Analysis

## 🔍 Found Conflicts

### Current Status (After Loading GTD Aliases)

From your current shell, these aliases are active:

| Alias | Current Value | Source | Conflict? |
|-------|--------------|--------|-----------|
| `l` | `ls -lah` | Oh My Zsh (likely) | ⚠️ **YES** - We want `l` for logging |
| `p` | `gtd-process` | GTD aliases | ✅ OK |
| `t` | `gtd-task list` | GTD aliases | ✅ OK |
| `w` | `make gtd-wizard` | GTD aliases | ✅ OK |
| `c` | `gtd-c` | GTD aliases | ✅ OK (protected) |

### Potential Conflicts from Oh My Zsh Plugins

Oh My Zsh plugins may define:
- `alias c='cat'` or `alias c='composer'`
- `alias l='ls -lFh'` (common in Oh My Zsh)
- `alias p='"$PAGER"'` or `alias p='ps -f'`
- `alias t='tail -f'` or `alias t=task`
- `alias w='echo >'`

## ✅ Current Protection

Our `gtd-aliases.zsh` file already protects:
- `c` - Only sets if not already defined
- `i` - Only sets if not already defined  
- `l` - Only sets if not already defined

**But we're NOT protecting:**
- `p` - Could conflict with `p='ps -f'` or `p='"$PAGER"'`
- `t` - Could conflict with `t='tail -f'` or `t=task`
- `w` - Could conflict with `w='echo >'`

## 🔧 Recommended Fix

Update `gtd-aliases.zsh` to protect all single-letter aliases:

```bash
# Short aliases (only if not already defined)
if ! alias p &>/dev/null; then
  alias p="gtd-process"
fi
if ! alias t &>/dev/null; then
  alias t="gtd-task list"
fi
if ! alias w &>/dev/null; then
  alias w="make gtd-wizard"
fi
if ! alias c &>/dev/null; then
  alias c="gtd-c"
fi
if ! alias i &>/dev/null; then
  alias i="gtd-i"
fi
if ! alias l &>/dev/null; then
  alias l="gtd-l"
fi
```

## 🎯 The `l` Conflict

**Current situation:**
- Oh My Zsh likely sets `l='ls -lah'` (or similar)
- We want `l` for quick logging: `l "my log entry"`

**Options:**
1. **Keep Oh My Zsh's `l`** - Use `log` instead for logging
2. **Override with GTD `l`** - Use `ll` or `ls -lah` for listing
3. **Use different alias** - Use `lg` for logging instead

**Recommendation:** Keep `l` for listing (common convention), use `log` for logging (more explicit).

## 📋 Action Items

1. ✅ `c`, `i`, `l` are already protected
2. ⚠️ Add protection for `p`, `t`, `w`
3. ⚠️ Decide on `l` conflict (listing vs logging)





