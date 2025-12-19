# GTD System - Complete Schedule

**Optimized for minimal disruption - intensive jobs run at 3 AM while you sleep!** 🌙

## 📅 Daily Schedule

### **3:00 AM** 🌙 (Every Night - Middle of the Night)

**Two Jobs Run in Sequence:**

#### 1. Knowledge Organization Scan - Time-Consuming
- **What:** Deep scan for organizational opportunities
- **Duration:** 2-5 minutes
- **Launchd:** `com.gtd.knowledge-scan`
- **Runs:** Every night at 3 AM
- **Actions:**
  - Scan all projects for area assignment opportunities
  - Analyze notes for MoC (Map of Content) suggestions
  - Mine 30 days of daily logs for life themes
  - Suggest new areas based on patterns
  - Generate confidence scores using learning system
- **Output:** `~/Documents/gtd/knowledge_organization_results/`
- **Priority:** Nice value 10 (lower priority, won't impact system)

#### 2. Auto-Suggest Run - Fast
- **What:** Scans and implements AI suggestions
- **Duration:** < 10 seconds
- **Launchd:** `com.gtd.auto-suggest`
- **Runs:** Every night at 3 AM (after knowledge scan completes)
- **Actions:**
  - Scan all suggestion sources (including fresh knowledge org results!)
  - Implement high-confidence suggestions (max 5 per run)
  - Log all actions
  - Send Discord daily summary
  - Record in learning system
- **Output:** Discord notification + `~/Documents/gtd/auto_suggest_actions.jsonl`

**Why 3 AM Every Night?**
- Computer is idle
- Fresh suggestions every morning
- Knowledge org scan generates suggestions → Auto-suggest implements them
- Results ready when you wake up
- Won't slow down your morning
- More responsive than weekly scans

---

### **8:00 AM** ☕ (Morning)

**Morning Reminder** - Lightweight
- **What:** Notification to start your day
- **Duration:** Instant
- **Launchd:** `com.abby.gtd.morning`
- **Purpose:** Gentle reminder to check GTD system

---

### **6:00 PM** 🌆 (Evening)

**Daily Reminder** - Lightweight
- **What:** End-of-day reminder
- **Duration:** Instant
- **Launchd:** `com.abby.gtd.daily`
- **Purpose:** Reminder to review day and capture items

---

## 📅 Weekly Schedule

### **Every 7 Days at 3:00 AM** (Part of Nightly Run)

**Smart Threshold Adjustment** - Fast
- **What:** Tunes confidence thresholds based on your patterns
- **Duration:** < 5 seconds
- **Runs:** Every 7 days at 3 AM (tracked via `.last_threshold_adjustment`)
- **Actions:**
  - Analyze acceptance rates per suggestion type
  - Adjust thresholds if needed (±5%)
  - Respect safety bounds (70%-98%)
  - Send Discord notification of changes
- **Output:** Updated `~/.auto_suggest_config.json`

**Note:** This runs as part of the nightly auto-suggest job, so it happens seamlessly every 7 days.

---

### **Sunday 9:00 AM** 📅 (Morning)

**Weekly Reminder** - Lightweight
- **What:** Notification for weekly review
- **Duration:** Instant
- **Launchd:** `com.abby.gtd.weekly`
- **Purpose:** Reminder to do weekly review

---

## 📅 On-Demand Jobs (User-Triggered)

These run when you explicitly request them via the wizard:

### **Deep Analysis Worker**
- **Weekly Review Analysis** → 3-10 minutes
- **Energy Pattern Analysis** → 2-5 minutes
- **Connection Finding** → 5-15 minutes
- **Insight Generation** → 3-8 minutes

**Triggered by:**
- GTD Wizard → AI Suggestions & MCP Tools
- Background queue from other tools

**Model:** GPT-OSS 20b (thinking model)

**Runs in:** Background (non-blocking)

---

## 📊 Visual Schedule

```
┌─────────────────────────────────────────────────────────────┐
│                 EVERY NIGHT AT 3:00 AM 🌙                   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Knowledge Organization Scan (2-5 min)                   │
│     • Scan projects for area opportunities                   │
│     • Analyze notes for MoC suggestions                      │
│     • Mine daily logs for themes                             │
│     • Generate fresh suggestions                             │
│                                                              │
│  2. Auto-Suggest Run (<10s)                                 │
│     • Scan all suggestions (including fresh ones!)           │
│     • Implement high-confidence items                        │
│     • Send Discord summary                                   │
│                                                              │
│  3. Threshold Adjustment (every 7 days, <5s)                │
│     • Analyze acceptance patterns                            │
│     • Tune confidence thresholds                             │
│                                                              │
│  Total: ~2-5 minutes every night while you sleep            │
│  Fresh suggestions ready every morning! ☕                   │
│                                                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                      DAYTIME SCHEDULE                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ☕ 08:00 AM  →  Morning Reminder (instant)                 │
│                  Start your day with fresh suggestions!      │
│                                                              │
│  🌆 06:00 PM  →  Daily Reminder (instant)                   │
│                  End of day review                           │
│                                                              │
│  📅 09:00 AM  →  Weekly Reminder (Sunday, instant)          │
│  (Sunday)        Time for weekly review                      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 Key Optimizations

### All Intensive Jobs at 3 AM
- **Knowledge scan:** 2-5 minutes (every night)
- **Auto-suggest:** < 10 seconds (every night)
- **Threshold adjustment:** < 5 seconds (every 7 nights)

**Total time at 3 AM:**
- Every night: ~2-5 minutes
- Plus threshold adjustment every 7 days: +5 seconds

**Impact on you:** ZERO - you're asleep! 😴

**Benefit:** Fresh suggestions every single morning!

### Lightweight Jobs During Day
- **Morning reminder:** Instant notification
- **Evening reminder:** Instant notification
- **Weekly reminder:** Instant notification

**Total disruption:** None

---

## 🔧 Configuration

### Change Auto-Suggest Time

```bash
# Move to different time (e.g., 7 AM)
gtd-auto-suggest-schedule install --hour 7 --minute 0

# Run every 6 hours
gtd-auto-suggest-schedule install --hourly  # Then modify interval in plist

# Keep default (3 AM)
gtd-auto-suggest-schedule install
```

### Change Knowledge Scan Time

```bash
# Edit directly
vim ~/Library/LaunchAgents/com.gtd.knowledge-scan.plist
# Change Hour to desired time

# Reload
launchctl unload ~/Library/LaunchAgents/com.gtd.knowledge-scan.plist
launchctl load ~/Library/LaunchAgents/com.gtd.knowledge-scan.plist
```

### Change Reminder Times

```bash
# Morning reminder (default 8 AM)
vim ~/Library/LaunchAgents/com.abby.gtd.morning.plist

# Evening reminder (default 6 PM)
vim ~/Library/LaunchAgents/com.abby.gtd.daily.plist

# Weekly reminder (default Sunday 9 AM)
vim ~/Library/LaunchAgents/com.abby.gtd.weekly.plist

# Reload after changes
launchctl unload <plist>
launchctl load <plist>
```

---

## 📍 Check Schedule Status

```bash
# List all GTD jobs
launchctl list | grep gtd

# Check specific job
launchctl list com.gtd.auto-suggest
launchctl list com.gtd.knowledge-scan

# View next run time
launchctl print gui/$(id -u)/com.gtd.auto-suggest

# View logs
tail -f ~/Documents/gtd/auto_suggest_scheduled.log
tail -f ~/Documents/gtd/logs/knowledge-scan-stdout.log
```

---

## 🌙 Sleep Schedule Considerations

**Does your Mac sleep at night?**

### If your Mac sleeps:
- Jobs will run when Mac wakes up
- macOS is smart about catching up missed schedules
- Consider using `pmset` to wake for network access:
  ```bash
  sudo pmset repeat wake MTWRFSU 02:55:00
  ```

### If your Mac stays awake:
- Perfect! Jobs run exactly at 3 AM
- Consider Energy Saver settings to allow this

### Check current power settings:
```bash
pmset -g
```

---

## 💡 Why This Schedule is Optimal

### 3 AM for Intensive Jobs
- ✅ Computer is idle
- ✅ No interruption to your work
- ✅ Results ready in the morning
- ✅ Lower CPU contention
- ✅ Can run longer if needed
- ✅ Network is available (if needed)

### Daytime for Reminders
- ✅ Timely notifications
- ✅ Instant (no waiting)
- ✅ Context-appropriate times:
  - Morning: Start of day
  - Evening: End of day wrap-up
  - Sunday AM: Weekly planning

### On-Demand for Deep Analysis
- ✅ You control when it runs
- ✅ Can run while you work on other things
- ✅ Results saved for later review
- ✅ No forced interruptions

---

## 📊 Expected CPU Usage

```
03:00 AM - 03:05 AM (Every Night)
├─ Knowledge Scan: ~10-30% CPU for 2-5 minutes
├─ Auto-suggest: ~5-10% CPU for <10 seconds
└─ Threshold Adjustment (every 7 days): ~5% CPU for <5 seconds

All other times: <1% (notification only)
```

**Impact on battery:** Minimal if plugged in at night  
**Impact on system:** Lower priority (Nice: 10) won't slow other processes

**Benefits of Nightly Scans:**
- ✅ Fresher suggestions (daily vs weekly)
- ✅ Catch new patterns faster
- ✅ More responsive system
- ✅ Knowledge org scan generates suggestions → Auto-suggest implements them same night
- ✅ Zero user impact (you're asleep)

---

## 🎯 Recommendation

**Current Schedule:** ✅ OPTIMAL

- Intensive jobs at 3 AM **every night** (zero user impact)
- Lightweight reminders during the day
- On-demand for optional deep analysis
- Knowledge scan runs nightly → Fresh suggestions every morning

**Benefits of Nightly Knowledge Scan:**
- More responsive to changes in your GTD system
- Catches new organizational opportunities daily
- Auto-suggest has fresh data every morning
- Still zero impact on you (happens while sleeping)
- Only takes 2-5 minutes per night

**No changes needed** unless you have specific preferences!

---

## 📚 Related Documentation

- [Auto-Suggest Complete Guide](AUTO_SUGGEST_COMPLETE.md)
- [Auto-Suggest Phase 3](AUTO_SUGGEST_PHASE3.md)
- [Knowledge Organization System](KNOWLEDGE_ORGANIZATION_SYSTEM.md)

---

**Last Updated:** December 17, 2025  
**Schedule Version:** 2.0 (Night-Optimized)

