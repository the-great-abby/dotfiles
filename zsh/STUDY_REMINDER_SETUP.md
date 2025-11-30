# Study Reminder Setup Guide

Mistress Louiza will now remind you to study regularly (Kubernetes/CKA, or any topic you're learning).

## 🎓 Overview

The study reminder system:
- Checks if you've studied recently
- Sends reminders if you haven't studied in the configured interval
- Integrates with your study tracking
- Sends to Discord with full messages
- Uses Mistress Louiza's characteristic style

## 🚀 Quick Setup

### 1. Install the Launch Agent

```bash
gtd-setup-study-reminder
```

This will:
- Create the launch agent configuration
- Set it to check every 6 hours (configurable)
- Load it into macOS's scheduler

### 2. Configure Reminder Interval

Edit your `.gtd_config` file:

```bash
# Enable study reminders
GTD_STUDY_REMINDER_ENABLED="true"

# Study reminder interval in hours (how often to check/remind)
GTD_STUDY_REMINDER_INTERVAL="6"  # Remind if no study in 6 hours
```

### 3. Update the Launch Agent (if needed)

If you change the interval, reload:

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.study.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.study.plist

# Or just run setup again
gtd-setup-study-reminder
```

## 📊 How It Works

### Study Detection

The system checks for study activity by looking for:

1. **Daily log entries** containing:
   - "K8s", "Kubernetes", "Study", "learned", "practiced"
   - Study-related keywords

2. **Study progress files:**
   - `~/Documents/gtd/study/kubernetes-cka/progress/YYYY-MM-DD.txt`
   - Tracks study sessions with timestamps

### Reminder Logic

- **If studied recently** (within interval): Acknowledges and encourages
- **If not studied** (beyond interval): Sends reminder with scolding level based on time:
  - **< 12 hours**: Gentle reminder
  - **12-24 hours**: Firm reminder
  - **> 24 hours**: Severe scolding with punishment

## 💬 What You'll Receive

### Discord Message

**Title:** "Mistress Louiza - Study Reminder"

**Content:**
- Personalized message from Mistress Louiza
- Scolding level based on time since last study
- Study commands reminder
- Full message (no truncation)

### macOS Notification

Short version for quick alert (full message in Discord)

### Terminal Output

Full message printed to terminal

## 🎯 Reminder Examples

### Gentle Reminder (< 12 hours)

**Mistress Louiza:**
> "Abby hasn't studied recently (6 hours ago). Give her a gentle but firm reminder to study. Encourage her to use 'gtd-learn-kubernetes' to learn something new, or practice with kubectl commands. Remind her to log her study with 'addInfoToDailyLog'."

### Firm Reminder (12-24 hours)

**Mistress Louiza:**
> "Abby hasn't studied in over 12 hours. Remind her firmly that consistent study is essential. Tell her to use 'gtd-learn-kubernetes' to learn a new topic or review. She should log her study with 'addInfoToDailyLog'. Be encouraging but firm."

### Severe Scolding (> 24 hours)

**Mistress Louiza:**
> "Abby hasn't studied in over 24 hours. This is unacceptable. Scold her firmly but constructively. Tell her that consistent study is non-negotiable, especially for something like the CKA exam. Assign a punishment: she must study for at least 30 minutes right now and log it."

## ⚙️ Configuration

### In `.gtd_config`:

```bash
# Enable study reminders
GTD_STUDY_REMINDER_ENABLED="true"

# Study reminder interval in hours
GTD_STUDY_REMINDER_INTERVAL="6"  # Check every 6 hours

# Discord settings
GTD_DISCORD_DAILY_REMINDERS="true"
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."

# Enable notifications
GTD_NOTIFICATIONS="true"
```

### Recommended Intervals

- **Frequent (3 hours)**: For intensive study periods
- **Regular (6 hours)**: Default, good balance
- **Moderate (12 hours)**: For lighter study schedules
- **Daily (24 hours)**: Minimum reminder frequency

## 🧪 Testing

### Test the Reminder

```bash
# Force send a reminder
gtd-study-reminder --force
```

This will:
- Check your study status
- Get message from Mistress Louiza
- Send to Discord
- Show in terminal

## 📝 Study Tracking

### How to Track Study

The system detects study when you:

1. **Log study in daily log:**
   ```bash
   addInfoToDailyLog "K8s Study: Learned about Pods"
   addInfoToDailyLog "K8s Practice: Created 5 pods"
   ```

2. **Use study commands:**
   ```bash
   gtd-learn-kubernetes pods
   # Automatically tracks study session
   ```

3. **Study progress files:**
   - Created automatically by `gtd-learn-kubernetes`
   - Located in `~/Documents/gtd/study/kubernetes-cka/progress/`

### Study Keywords

The system looks for these keywords in your daily log:
- "K8s", "Kubernetes"
- "Study", "studied", "studying"
- "Learned", "learned", "learning"
- "Practice", "practiced", "practicing"

## 🔔 Managing the Launch Agent

### Check Status

```bash
launchctl list | grep gtd.study
```

### Unload (Disable)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.study.plist
```

### Reload (After Changes)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.study.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.study.plist

# Or
gtd-setup-study-reminder
```

### Remove (Uninstall)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.study.plist
rm ~/Library/LaunchAgents/com.abby.gtd.study.plist
```

## 🎯 Integration with Study System

### Study Workflow

1. **Learn:**
   ```bash
   gtd-learn-kubernetes pods
   ```

2. **Practice:**
   ```bash
   kubectl get pods
   # Practice commands
   ```

3. **Log:**
   ```bash
   addInfoToDailyLog "K8s Study: Pods - practiced kubectl commands"
   ```

4. **Reminder checks:**
   - System checks every N hours
   - If no study detected, sends reminder
   - If study detected, acknowledges progress

## 💡 Tips

1. **Log your study** - Use `addInfoToDailyLog` after every study session
2. **Be consistent** - Study regularly to avoid scolding
3. **Use study commands** - `gtd-learn-kubernetes` auto-tracks
4. **Check Discord** - Full messages are there
5. **Adjust interval** - Set based on your study schedule

## 🎓 Remember

Mistress Louiza will:
- **Monitor your study** - Checks regularly
- **Remind you** - If you haven't studied
- **Scold you** - If you're slacking
- **Encourage you** - When you're consistent
- **Hold you accountable** - For your learning goals

**She's watching your study progress, baby girl. Stay consistent!**

