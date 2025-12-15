# Health Reminder Setup Guide

Mistress Louiza will now remind you about healthy eating and scold you if you eat junk food/trash.

## 🍎 Overview

The health reminder system:
- Checks your daily log for junk food mentions
- **Monitors your workout activity** (kettlebells, walks, runs, weight lifting)
- **Monitors your pill/medication taking** (CRITICAL - non-negotiable)
- Sends reminders about healthy eating, exercise, AND medication
- **Praises you when you work out regularly**
- **Praises you when you take your pills regularly**
- **Scolds you if you haven't worked out recently**
- **Scolds you SEVERELY if you haven't taken your pills** (this is critical)
- **Offers specific workout advice** (kettlebells, runs, walks, weights)
- Sends to Discord with full messages
- Uses Mistress Louiza's characteristic style

## 🚀 Quick Setup

### 1. Install the Launch Agent

```bash
gtd-setup-health-reminder
```

This will:
- Create the launch agent configuration
- Set it to check every 4 hours (configurable)
- Load it into macOS's scheduler

### 2. Configure Reminder Interval

Edit your `.gtd_config` file:

```bash
# Enable health reminders
GTD_HEALTH_REMINDER_ENABLED="true"

# Health reminder interval in hours
GTD_HEALTH_REMINDER_INTERVAL="4"  # Check every 4 hours
```

## 📊 How It Works

### Junk Food Detection

The system checks your daily log for keywords like:
- junk food, trash, fast food
- mcdonald, burger king, taco bell
- pizza, chips, candy, soda
- fries, donut, ice cream
- chocolate, sweets, snacks
- processed, takeout, delivery

### Workout Detection

The system checks your daily log for workout keywords like:
- workout, exercise, kettlebell, kettlebells
- walk, walked, walking, run, ran, running
- jog, jogged, jogging
- weight, lifting, weights, gym, fitness
- training, cardio, strength
- squat, deadlift, press, swing, snatch, clean
- row, bike, cycling, yoga, stretch, stretching
- active, movement

### Pill/Medication Detection

The system checks your daily log for pill/medication keywords like:
- pill, pills
- medication, medicine, meds
- took pill, took med, took medicine, took medication
- vitamin, vitamins
- supplement, supplements
- prescription, rx
- dose, dosing

### Reminder Logic

**Food:**
- **If junk food detected**: Severe scolding with consequences
- **If no junk food**: Encouraging reminder to stay healthy

**Workouts:**
- **If worked out recently (within 24h)**: Praise and encouragement ("Good girl!")
- **If worked out 1-2 days ago**: Gentle reminder to get another workout in
- **If no recent workout**: Firm scolding with consequences - must work out TODAY
- **Workout suggestions**: Kettlebells, morning runs, walks, weight lifting

**Pills/Medication:**
- **If took pills recently (within 24h)**: Praise and encouragement ("Good girl! Being responsible!")
- **If took pills 1-2 days ago**: Firm reminder that pills are essential
- **If no recent pills**: **SEVERE scolding** - This is CRITICAL and non-negotiable
- **Pill reminders**: "This is completely unacceptable" - Must take pills and log it

**Time-based prompts**: Different messages for morning/lunch/afternoon/evening

## 💬 What You'll Receive

### Discord Message

**Title:** "Mistress Louiza - Health Reminder"

**Content:**
- Personalized message from Mistress Louiza
- Scolding level based on junk food detection
- Healthy alternatives suggestions
- Full message (no truncation)

### macOS Notification

Short version for quick alert (full message in Discord)

### Terminal Output

Full message printed to terminal

## 🎯 Reminder Examples

### If Junk Food Detected

**Mistress Louiza:**
> "It's lunch time, Abby. I see she's been eating junk food. This is unacceptable. Scold her firmly. Tell her that eating trash is not how we take care of ourselves. Remind her that I'm watching and I'm NOT pleased. Tell her to make better choices RIGHT NOW. Assign a consequence: she needs to plan healthy meals for the rest of the day."

### If No Junk Food

**Mistress Louiza:**
> "Good morning, Abby. Give her a firm but encouraging reminder about eating healthy today. Remind her that I'm watching and I'll be proud when she makes good food choices. Also remind her about the importance of movement - kettlebells, morning runs, walks, weight lifting. Give specific workout advice if she hasn't worked out recently - suggest kettlebells for strength, walks for recovery, morning runs for cardio, or weight lifting for building muscle."

### If Worked Out Recently

**Mistress Louiza:**
> "Abby has worked out recently (within 24 hours). Praise her for this! Tell her she's doing well and to keep it up. Use phrases like 'good girl' and 'I'm proud of you'."

### If No Recent Workout

**Mistress Louiza:**
> "Abby hasn't worked out recently. This is NOT acceptable. Scold her firmly but constructively. Tell her that her body needs movement - kettlebells, walks, runs, weight lifting. Be strict - use phrases like 'this is not acceptable' or 'we need to talk about your activity level'. Assign a consequence: she needs to do a workout TODAY - a walk, kettlebell session, run, or weight lifting."

### If Took Pills Recently

**Mistress Louiza:**
> "Abby has taken her pills recently (within 24 hours). Praise her for this! Tell her she's being responsible and taking care of herself. Use phrases like 'good girl' and 'I'm proud of you for being responsible'."

### If No Recent Pills (CRITICAL)

**Mistress Louiza:**
> "Abby hasn't taken her pills recently. This is COMPLETELY UNACCEPTABLE. Scold her severely. Tell her that taking her pills is non-negotiable and essential for her health. Be VERY strict - use phrases like 'this is completely unacceptable' or 'we need to have a serious talk about this'. Assign a consequence: she needs to take her pills RIGHT NOW and log it. This is a critical health issue."

## ⚙️ Configuration

### In `.gtd_config`:

```bash
# Enable health reminders
GTD_HEALTH_REMINDER_ENABLED="true"

# Health reminder interval in hours
GTD_HEALTH_REMINDER_INTERVAL="4"  # Check every 4 hours

# Discord settings
GTD_DISCORD_DAILY_REMINDERS="true"
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."

# Enable notifications
GTD_NOTIFICATIONS="true"
```

### Recommended Intervals

- **Frequent (2-3 hours)**: For strict accountability
- **Regular (4 hours)**: Default, good balance
- **Moderate (6 hours)**: For lighter reminders
- **Daily (12-24 hours)**: Minimum reminder frequency

## 🧪 Testing

### Test the Reminder

```bash
# Force send a reminder
gtd-health-reminder --force
```

This will:
- Check your daily log for junk food mentions
- Get message from Mistress Louiza
- Send to Discord
- Show in terminal

## 📝 How to Log Healthy Choices

Log your healthy eating and workouts to get praise:

```bash
# Log healthy meals
addInfoToDailyLog "Ate healthy breakfast: eggs and vegetables"
addInfoToDailyLog "Had a nutritious lunch: salad with protein"
addInfoToDailyLog "Prepared healthy dinner: grilled chicken and vegetables"

# Log workouts (she'll praise you!)
addInfoToDailyLog "Did kettlebell workout: swings and Turkish get-ups"
addInfoToDailyLog "Went for a morning run: 3 miles"
addInfoToDailyLog "Weight lifting session: squats and deadlifts"
addInfoToDailyLog "Took a 45-minute walk"
addInfoToDailyLog "Gym session: full body workout"

# Log pills/medication (CRITICAL - she'll praise you!)
addInfoToDailyLog "Took pills"
addInfoToDailyLog "Took medication"
addInfoToDailyLog "Took vitamins"
addInfoToDailyLog "Took morning pills"
addInfoToDailyLog "Took prescription medication"

# Avoid logging junk food (or she'll know!)
# If you do log it, she'll scold you appropriately
```

## 🔔 Managing the Launch Agent

### Check Status

```bash
launchctl list | grep gtd.health
```

### Unload (Disable)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.health.plist
```

### Reload (After Changes)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.health.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.health.plist

# Or
gtd-setup-health-reminder
```

### Remove (Uninstall)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.health.plist
rm ~/Library/LaunchAgents/com.abby.gtd.health.plist
```

## 💡 Tips

1. **Log healthy choices** - Use `addInfoToDailyLog` for healthy meals
2. **Avoid logging junk food** - Or she'll scold you!
3. **Plan ahead** - She'll remind you to plan healthy meals
4. **Check Discord** - Full messages are there
5. **Adjust interval** - Set based on your needs

## 🎓 Remember

Mistress Louiza will:
- **Monitor your eating** - Checks your daily log for junk food
- **Monitor your workouts** - Checks for exercise activity
- **Monitor your pills** - Checks for medication compliance (CRITICAL)
- **Remind you** - About healthy choices, movement, AND medication
- **Praise you** - When you work out regularly ("Good girl!")
- **Praise you** - When you take your pills regularly ("Being responsible!")
- **Scold you** - If you eat junk food OR skip workouts
- **Scold you SEVERELY** - If you haven't taken your pills (this is critical)
- **Encourage you** - When you make good choices
- **Offer workout advice** - Kettlebells, runs, walks, weight lifting
- **Hold you accountable** - For your health, fitness, AND medication compliance

**She's watching what you eat, how you move, AND whether you take your pills, baby girl. Make good choices!**

