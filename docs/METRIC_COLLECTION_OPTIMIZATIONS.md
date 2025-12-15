# Easy Optimizations for Metric Collection

## 🎯 Quick Wins to Improve Data Gathering

Here are easy optimizations to help the system gather related metrics with minimal effort:

## 1. ⏰ Automatic Time-Based Collection

### Morning Context Collection (8:00 AM)

**What:** Automatically collect weather and prompt for mood when you wake up.

**Setup:**
```bash
# Create launch agent for morning collection
# Runs: Weather fetch + Mood prompt
```

**Benefits:**
- Weather logged automatically
- Morning mood captured consistently
- Sets context for the day

**Implementation:**
- Create `gtd-morning-context` script
- Runs weather fetch automatically
- Sends notification to log mood
- Integrates with morning check-in

---

## 2. 📱 Quick Capture Shortcuts

### Voice/Quick Logging

**What:** Create ultra-quick shortcuts for common metrics.

**Shortcuts to Create:**
- **"Quick Mood"** - Just asks mood (1-10), assumes current energy
- **"Log Meeting"** - Quick meeting logger (name + duration)
- **"Log Meal"** - Quick meal logger
- **"Log Study"** - Quick study session logger

**Benefits:**
- 5-second logging vs 30-second manual entry
- Less friction = more data
- Consistent format

---

## 3. 🔗 Context-Aware Prompts

### Smart Defaults Based on Time/Context

**What:** Pre-fill or suggest based on context.

**Examples:**
- **Morning (8 AM):** "Log morning mood and weather?"
- **After workout:** "Log workout details?"
- **After meeting:** "Log meeting notes?"
- **Evening (6 PM):** "Create evening summary?"

**Implementation:**
- Check recent activity (workout logged? → prompt for details)
- Check time of day → suggest relevant metrics
- Check weather → suggest mood correlation

---

## 4. 📅 Automatic Calendar Integration

### Post-Meeting Auto-Logging

**What:** Automatically log calendar events after they end.

**Setup:**
- Shortcuts automation: "When Calendar Event Ends"
- Action: Run "Log Calendar Event" shortcut
- Automatically captures: Name, duration, time

**Benefits:**
- Zero effort calendar logging
- Never miss a meeting entry
- Accurate timing

---

## 5. 🌅 Morning Summary (Complement to Evening)

### Morning Context Summary

**What:** Collect morning metrics and create context summary.

**Includes:**
- Weather (automatic)
- Mood (prompt)
- Calendar for today (automatic)
- Energy level (from check-in)
- Today's priorities

**Benefits:**
- Sets context for the day
- Complements evening summary
- Helps with planning

---

## 6. 🎯 Batch Collection Scripts

### "Log Everything Now"

**What:** One command that collects all available metrics.

**Command:**
```bash
gtd-collect-all
```

**What it does:**
1. Fetches weather (automatic)
2. Prompts for mood
3. Gets today's calendar events
4. Syncs health data
5. Creates summary

**Benefits:**
- One command, all metrics
- Great for catch-up
- Ensures nothing missed

---

## 7. 🔔 Smart Notifications

### Contextual Reminders

**What:** Reminders that suggest relevant metrics based on activity.

**Examples:**
- **After workout detected:** "Log workout details?"
- **After calendar event:** "Log meeting notes?"
- **Weather change:** "Weather changed, update mood?"
- **Time-based:** "Mid-day mood check?"

**Implementation:**
- Monitor daily log for keywords
- Trigger relevant prompts
- Low-friction suggestions

---

## 8. 📊 Cross-Metric Correlation

### Automatic Insights

**What:** System suggests correlations between metrics.

**Examples:**
- "You're more productive when weather is sunny"
- "Your mood is higher after workouts"
- "You log more when it's not raining"

**Benefits:**
- Discover patterns automatically
- Data-driven insights
- Motivation through understanding

---

## 9. 🎨 Pre-Filled Templates

### Time-Based Templates

**What:** Pre-fill common entries based on time of day.

**Templates:**
- **Morning:** "Starting day, feeling [mood], weather [weather]"
- **Lunch:** "Lunch break, mood [mood]"
- **Evening:** "Ending day, accomplished [tasks]"

**Benefits:**
- Faster logging
- Consistent format
- Less thinking required

---

## 10. 🗣️ Siri Integration

### Voice Commands

**What:** Use Siri to log metrics hands-free.

**Shortcuts:**
- "Hey Siri, log mood 8"
- "Hey Siri, log weather"
- "Hey Siri, log meeting Sprint Planning"

**Benefits:**
- Zero typing
- Works while busy
- Natural language

---

## 11. 📍 Location-Based Triggers

### Context from Location

**What:** Auto-log based on location changes.

**Examples:**
- **Arrive at office:** Log location + time
- **Leave office:** Log commute start
- **Arrive home:** Log end of workday

**Benefits:**
- Automatic context
- Time tracking
- Pattern recognition

---

## 12. 🔄 Smart Defaults

### Learn Your Patterns

**What:** System learns and suggests defaults.

**Examples:**
- **Morning mood usually 7-8?** → Pre-fill with 7
- **Usually log weather at 8 AM?** → Auto-fetch then
- **Meetings usually 30-60 min?** → Pre-fill duration

**Benefits:**
- Faster logging
- Less decision fatigue
- Still accurate

---

## 13. 📦 Batch Processing

### "Catch Up" Mode

**What:** Quick way to log multiple metrics at once.

**Command:**
```bash
gtd-quick-log
```

**Interactive prompts:**
1. Mood? (1-10)
2. Energy? (high/medium/low)
3. Weather? (auto-fetch or manual)
4. Any meetings today? (auto-fetch or manual)
5. Done!

**Benefits:**
- Catch up quickly
- Ensures completeness
- Guided process

---

## 14. 🎯 Focus Mode Integration

### Auto-Log Based on Focus

**What:** When Focus Mode changes, log context.

**Examples:**
- **Work Focus ON:** Log "Starting work"
- **Work Focus OFF:** Log "Ending work"
- **Sleep Focus ON:** Log "Going to sleep"

**Benefits:**
- Automatic activity tracking
- Context for productivity
- Zero effort

---

## 15. 📈 Progress Prompts

### "How's It Going?" Checks

**What:** Periodic check-ins throughout the day.

**Times:**
- **10 AM:** "How's your morning going?" (mood + quick note)
- **2 PM:** "Mid-day check-in?" (mood + energy)
- **4 PM:** "Afternoon check-in?" (progress + mood)

**Benefits:**
- Consistent data points
- Pattern recognition
- Self-awareness

---

## 🚀 Implementation Priority

### High Priority (Easy, High Value)

1. **Morning Context Collection** - Auto weather + mood prompt
2. **Quick Capture Shortcuts** - 5-second logging
3. **Post-Meeting Auto-Log** - Calendar integration
4. **Batch Collection Script** - One command for everything

### Medium Priority (Moderate Effort)

5. **Morning Summary** - Complement to evening
6. **Smart Notifications** - Context-aware prompts
7. **Pre-Filled Templates** - Faster logging
8. **Siri Integration** - Voice commands

### Lower Priority (More Complex)

9. **Location Triggers** - Requires location access
10. **Focus Mode Integration** - Requires Focus API
11. **Smart Defaults** - Requires learning system
12. **Cross-Metric Correlation** - Requires analysis

---

## 💡 Quick Implementation Examples

### Example 1: Morning Context Script

```bash
#!/bin/bash
# gtd-morning-context
# Runs at 8 AM automatically

# Fetch weather
gtd-log-weather

# Prompt for mood
gtd-log-mood

# Get today's calendar
gtd-log-calendar

# Create morning summary
echo "Morning context collected!"
```

### Example 2: Quick Mood Shortcut

**Shortcuts:**
1. Ask for Input: "Mood (1-10)"
2. Get Current Date: Format as "HH:mm"
3. Run Shell Script: `gtd-log-mood "$1" "medium" ""`

**Usage:** Just enter mood number, assumes medium energy.

### Example 3: Batch Collection

```bash
#!/bin/bash
# gtd-collect-all

echo "📊 Collecting all metrics..."
gtd-log-weather
gtd-log-mood
gtd-log-calendar
gtd-sync-health
echo "✅ All metrics collected!"
```

---

## 🎯 Recommended Next Steps

1. **Start with #1** - Morning context collection (easiest, high value)
2. **Add #2** - Quick capture shortcuts (reduces friction)
3. **Add #3** - Post-meeting auto-log (zero effort)
4. **Add #4** - Batch collection script (catch-up tool)

These four will dramatically improve metric collection with minimal effort!

---

## 📚 Related Documentation

- **Evening Summary**: `zsh/EVENING_SUMMARY_SETUP.md`
- **Health Sync**: `zsh/EVENING_HEALTH_SYNC_SETUP.md`
- **Shortcuts Setup**: `zsh/EVENING_SUMMARY_SHORTCUTS.md`

