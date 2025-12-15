# User Name Confusion Fix

## Problem

The AI was confusing names mentioned in log entries with the user's name. For example:
- Log entry: "sent logan the presentation..."
- AI response: "Hello, Logan..." ❌ (incorrect - Logan is the recipient, not the user)

The user is **Abby**, but the AI was addressing **Logan** because "logan" appeared in the log content.

## Solution

Made multiple improvements to prevent name confusion:

### 1. Enhanced System Prompt (`gtd_persona_helper.py`)

Added explicit instructions to the system prompt:

```
CRITICAL: You are speaking to {user_name} (the person whose log/journal this is). 
ALWAYS address them as {user_name}. If the content mentions other people's names 
(like colleagues, friends, or recipients), those are OTHER PEOPLE - do NOT confuse 
them with {user_name}. {user_name} is the person writing the log, not anyone 
mentioned in it. Always use {user_name}'s name when addressing them directly.
```

### 2. Updated User Prompt (`zshrc_mac_mise`)

Modified the prompt text to explicitly state:
- "This is **Abby's** daily log. You are providing advice to **Abby**..."
- "CRITICAL: If the log mentions other people's names..., those are OTHER PEOPLE - NOT **Abby**"
- Repeatedly emphasizes that **Abby** is the user, not anyone mentioned in the log

### 3. Config Reading

- Updated persona helper to read both `GTD_USER_NAME` and `NAME` from config
- Added user name extraction in the daily log function
- Reads from `.gtd_config` file (which has `GTD_USER_NAME="Abby"`)

## Example

**Before Fix:**
- Log: "sent logan the presentation and the queries for cloudwatch"
- AI: "Hello, Logan..." ❌

**After Fix:**
- Log: "sent logan the presentation and the queries for cloudwatch"
- AI: "Hello, Abby..." ✅ (knows Abby is the user, Logan is mentioned in the log)

## Files Changed

1. `zsh/functions/gtd_persona_helper.py`:
   - Updated system prompt to be explicit about user identity
   - Added support for `GTD_USER_NAME` config variable

2. `zsh/zshrc_mac_mise`:
   - Added user name extraction from config
   - Updated prompt text to explicitly state user's name
   - Added warnings about not confusing names in content with user

## Testing

To verify the fix works:
1. Log an entry mentioning someone else: `log "sent john the report"`
2. AI should address you (Abby), not John
3. AI should understand that John is mentioned in the log but is not the user

## Configuration

The user name comes from `.gtd_config`:
```
GTD_USER_NAME="Abby"
```

Or from environment variable:
```bash
export GTD_USER_NAME="Abby"
```

The persona helper will automatically use this to ensure correct addressing.

