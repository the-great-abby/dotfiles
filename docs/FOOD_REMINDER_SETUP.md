# Food Reminder Setup Guide

Mistress Louiza will now remind you about healthy eating and hold you accountable for food choices.

## 🍎 Overview

The food reminder system:
- Monitors your daily log for food entries
- Detects junk food/trash mentions
- Sends reminders from Mistress Louiza
- Encourages healthy choices
- Scolds when you eat junk food
- Sends to Discord with full messages

## 🚀 Quick Setup

### 1. Install the Launch Agent

```bash
gtd-setup-food-reminder
```

This will:
- Create the launch agent configuration
- Set it to check every 4 hours (configurable)
- Load it into macOS's scheduler

### 2. Configure Reminder Interval

Edit your `.gtd_config` file:

```bash
# Enable food reminders
GTD_FOOD_REMINDER_ENABLED="true"

# Food reminder interval in hours
GTD_FOOD_REMINDER_INTERVAL="4"  # Check every 4 hours
```

## 📊 How It Works

### Food Detection

The system checks your daily log for:

**Junk Food Keywords:**
- fast food, junk food, trash
- mcdonald, burger king, taco bell
- pizza, chips, candy, soda
- donut, ice cream, cake, cookie
- processed, frozen meal, takeout, delivery

**Healthy Keywords:**
- salad, vegetable, fruit
- healthy, home cooked, meal prep
- nutritious, protein, whole food

### Reminder Logic

- **Junk Food Detected**: Severe scolding with consequences
- **No Food Logged**: Firm reminder to log meals and make healthy choices
- **Healthy Choices**: Praise and encouragement
- **Neutral**: General reminder about healthy eating

## 💬 What You'll Receive

### Discord Message

**Title:** "Mistress Louiza - Food Reminder"

**Content:**
- Personalized message from Mistress Louiza
- Scolding level based on food choices
- Reminders about logging meals
- Full message (no truncation)

### macOS Notification

Short version for quick alert (full message in Discord)

### Terminal Output

Full message printed to terminal

## 🎯 Reminder Examples

### Severe Scolding (Junk Food Detected)

**Mistress Louiza:**
> "Abby has been eating junk food/trash. This is completely unacceptable. Scold her severely but constructively. Tell her that eating trash is not acceptable - her body deserves better. Be very strict - use phrases like 'this is completely unacceptable' or 'we need to have a serious talk'. Tell her that I'm watching and I'm NOT pleased. Remind her that she needs to make better choices. Suggest consequences: she needs to meal prep, she needs to plan healthy meals, she needs to stop ordering takeout."

### Firm Reminder (No Food Logged)

**Mistress Louiza:**
> "Abby hasn't logged any food choices today. Remind her firmly that I'm watching what she eats. Tell her to log her meals and make healthy choices. Remind her that eating trash is not acceptable. Be encouraging but firm - use phrases like 'good girl' when she makes good choices, but be strict about logging and making healthy decisions."

### Praise (Healthy Choices)

**Mistress Louiza:**
> "Abby has been making healthy food choices today. Acknowledge this and praise her - use phrases like 'good girl' or 'baby girl, I'm proud of you'. Encourage her to keep it up. Remind her that I'm watching and I'm pleased when she takes care of herself."

## ⚙️ Configuration

### In `.gtd_config`:

```bash
# Enable food reminders
GTD_FOOD_REMINDER_ENABLED="true"

# Food reminder interval in hours
GTD_FOOD_REMINDER_INTERVAL="4"  # Check every 4 hours

# Discord settings
GTD_DISCORD_DAILY_REMINDERS="true"
GTD_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/..."

# Enable notifications
GTD_NOTIFICATIONS="true"
```

### Recommended Intervals

- **Frequent (2-3 hours)**: For intensive accountability
- **Regular (4 hours)**: Default, good balance
- **Moderate (6 hours)**: For lighter reminders
- **Daily (12-24 hours)**: Minimum reminder frequency

## 🧪 Testing

### Test the Reminder

```bash
# Force send a reminder
gtd-food-reminder --force
```

This will:
- Check your daily log for food entries
- Get message from Mistress Louiza
- Send to Discord
- Show in terminal

## 📝 Food Logging

### How to Log Meals

The system detects food when you log:

```bash
# Log healthy meals
addInfoToDailyLog "Ate: Salad with grilled chicken for lunch"
addInfoToDailyLog "Ate: Home cooked meal prep - vegetables and protein"
addInfoToDailyLog "Ate: Healthy breakfast - eggs and fruit"

# Log junk food (will trigger scolding)
addInfoToDailyLog "Ate: Fast food for lunch"
addInfoToDailyLog "Ate: Junk food - pizza and soda"
addInfoToDailyLog "Ate: Trash - chips and candy"
```

### Food Keywords

The system looks for these keywords:
- **Junk**: fast food, junk food, trash, mcdonald, burger king, pizza, chips, candy, soda, donut, ice cream, cake, cookie, processed, frozen meal, takeout, delivery
- **Healthy**: salad, vegetable, fruit, healthy, home cooked, meal prep, nutritious, protein, whole food

## 🔔 Managing the Launch Agent

### Check Status

```bash
launchctl list | grep gtd.food
```

### Unload (Disable)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.food.plist
```

### Reload (After Changes)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.food.plist
launchctl load ~/Library/LaunchAgents/com.abby.gtd.food.plist

# Or
gtd-setup-food-reminder
```

### Remove (Uninstall)

```bash
launchctl unload ~/Library/LaunchAgents/com.abby.gtd.food.plist
rm ~/Library/LaunchAgents/com.abby.gtd.food.plist
```

## 💡 Tips

1. **Log your meals** - Use `addInfoToDailyLog` after every meal
2. **Be honest** - The system detects junk food mentions
3. **Plan ahead** - Meal prep helps avoid junk food
4. **Check Discord** - Full messages are there
5. **Adjust interval** - Set based on your needs

## 🎓 Remember

Mistress Louiza will:
- **Monitor your food choices** - Checks your daily log
- **Scold you** - If you eat junk food/trash
- **Encourage you** - When you make healthy choices
- **Hold you accountable** - For taking care of your body
- **Remind you** - To log meals and make good decisions

**She's watching what you eat, baby girl. No trash!**

