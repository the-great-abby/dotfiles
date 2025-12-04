# Evening Summary Shortcuts Setup

## 📋 Required Shortcuts

Create these Shortcuts shortcuts to enable automatic data collection:

### 1. "Log Mood" Shortcut

**Actions:**
1. **Ask for Input**
   - Prompt: "Mood (1-10)"
   - Input Type: Number
   - Save to variable: `Mood`

2. **Ask for Input**
   - Prompt: "Energy (high/medium/low)"
   - Input Type: Text
   - Save to variable: `Energy`

3. **Ask for Input** (Optional)
   - Prompt: "Note (optional)"
   - Input Type: Text
   - Save to variable: `Note`

4. **Run Shell Script**
   - Shell: `/bin/zsh`
   - Input: `as arguments`
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-log-mood" "$1" "$2" "$3"
     ```
   - Pass inputs:
     - `$1`: Mood
     - `$2`: Energy
     - `$3`: Note (or empty)

---

### 2. "Get Weather" Shortcut

**Actions:**
1. **Get Current Weather**
   - Location: Current Location
   - Get: Condition, Temperature

2. **Text**
   ```
   [Condition], [Temperature]°F
   ```
   (Replace with variables from step 1)

3. **Run Shell Script**
   - Shell: `/bin/zsh`
   - Input: `as arguments`
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-log-weather" "$1"
     ```
   - Pass input: Text from step 2

**Alternative (Manual):**
If automatic weather fetch doesn't work, create a simpler version that prompts for input.

---

### 3. "Get Today's Calendar" Shortcut

**Actions:**
1. **Get Calendar Events**
   - Date: Today
   - Limit: 20

2. **Repeat with Each** (for each event)
   - Get event title
   - Get event start time
   - Get event duration
   - Format: `[Title] ([Duration])`

3. **Combine Text**
   - Combine all events with newlines
   - Save to variable: `CalendarSummary`

4. **Run Shell Script**
   - Shell: `/bin/zsh`
   - Input: `as arguments`
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-log-calendar" "$1"
     ```
   - Pass input: CalendarSummary

**Alternative (Single Event):**
If you want to log events individually as they happen, create a simpler version that logs one event at a time.

---

### 4. "Log Daily Health Summary" Shortcut

**Already created** (from health sync setup):
- Gets health data
- Logs to daily log
- See `APPLE_HEALTH_SHORTCUTS_EXAMPLES.md` for details

---

## 🚀 Evening Summary Automation

### Option 1: Automatic via Launch Agent (Recommended)

The evening summary script will automatically:
1. Check for logged health data
2. Check for logged weather
3. Check for logged calendar events
4. Check for logged mood
5. Compile summary
6. Log to daily log
7. Send to Discord

Just run `gtd-setup-evening-summary` to set up automation.

### Option 2: Shortcuts Automation

Create a Shortcuts automation:
1. **Trigger**: Time of Day (5:50 PM daily)
2. **Actions**:
   - Run Shortcut: "Get Weather"
   - Run Shortcut: "Get Today's Calendar"
   - Run Shortcut: "Log Daily Health Summary"
   - Run Shell Script: `gtd-evening-summary`

---

## 📱 Quick Manual Shortcuts

### "Quick Mood Check"

Simple version for quick mood logging:
1. **Ask for Input**: Mood (1-10)
2. **Ask for Input**: Energy (high/medium/low)
3. **Run Shell Script**: `gtd-log-mood "$1" "$2"`

### "Quick Weather"

Simple version:
1. **Get Current Weather**
2. **Run Shell Script**: `gtd-log-weather "$1" "$2"` (condition, temp)

### "Log Meeting"

After a meeting:
1. **Ask for Input**: Meeting name
2. **Ask for Input**: Duration (minutes)
3. **Run Shell Script**: `gtd-log-calendar "Meeting: $1 ($2 minutes)"`

---

## 🧪 Testing

Test each shortcut manually:
1. Run shortcut in Shortcuts app
2. Check daily log: `cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md | tail -5`
3. Verify entry was added correctly

Test evening summary:
```bash
gtd-evening-summary --no-discord  # Test without Discord
gtd-evening-summary  # Test with Discord
```

---

## 💡 Tips

1. **Start Simple**: Create basic shortcuts first, test them, then add complexity
2. **Use Variables**: Name your variables clearly in Shortcuts
3. **Error Handling**: Add "If" actions to check if data exists before logging
4. **Combine Metrics**: The evening summary script will find all logged data automatically
5. **Manual Override**: You can always log manually if shortcuts fail

---

## 🔗 Integration

All shortcuts integrate with:
- ✅ Daily log system
- ✅ Evening summary
- ✅ Discord notifications
- ✅ AI suggestions
- ✅ Second Brain sync

Just like health data! 🎉

