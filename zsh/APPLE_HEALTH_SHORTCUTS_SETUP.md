# Apple Health Integration via Shortcuts

This guide shows you how to set up Shortcuts automation to automatically log Apple Health and Apple Watch data to your daily log.

## 🎯 What This Does

Automatically logs health data from Apple Health/Apple Watch to your daily log:
- **Workouts** (type, duration, calories, distance)
- **Steps** (daily step count)
- **Heart Rate** (resting, walking average, workout average)
- **Active Energy** (calories burned)
- **Exercise Minutes** (Apple Watch rings)
- **Stand Hours** (Apple Watch stand goal)
- **Sleep** (sleep duration and quality)

## 🚀 Quick Setup

### Step 1: Make the Helper Script Executable

The helper script should already be executable, but verify:

```bash
chmod +x ~/code/dotfiles/bin/gtd-healthkit-log
```

### Step 2: Create the Shortcuts Workflow

1. **Open Shortcuts app** on your iPhone/iPad/Mac
2. **Create a new shortcut** (tap "+" or "New Shortcut")
3. **Name it**: "Log Health Data to Daily Log"

### Step 3: Build the Workflow

Add these actions in order:

#### Action 1: Get Health Samples
- Search for "Get Health Samples"
- Choose the health data type you want (e.g., "Workouts", "Steps", "Heart Rate")
- Set date range to "Today" or "Last 1 Day"
- Set sort order to "Newest First"
- Limit to 1 result (or more if you want multiple entries)

#### Action 2: Format the Data
- Add "Text" action
- Build your log entry format, for example:
  ```
  Apple Watch Workout: [Workout Type] for [Duration] - [Total Energy Burned] calories, [Total Distance] km
  ```
  Or for steps:
  ```
  Apple Watch: [Step Count] steps today
  ```

#### Action 3: Get Current Time
- Add "Get Current Date"
- Format it as "HH:mm" (hours and minutes)

#### Action 4: Run Shell Script
- Add "Run Shell Script" action
- Set shell to "/bin/zsh" or "/bin/bash"
- Set input to "as arguments"
- Use this script:
  ```bash
  "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
  ```
- Pass inputs:
  - First input: The formatted text from Action 2
  - Second input: The time from Action 3

### Step 4: Test the Shortcut

1. Run the shortcut manually
2. Check your daily log: `cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md`
3. Verify the entry was added correctly

## 📱 Example Shortcuts Workflows

### Workout Logger

**Name**: "Log Today's Workouts"

**Actions**:
1. **Get Health Samples**
   - Type: Workouts
   - Date: Today
   - Limit: 10 (to get all workouts today)

2. **Repeat with Each** (to process each workout)
   - Get workout type
   - Get duration
   - Get total energy burned
   - Get total distance

3. **Text** (format the entry)
   ```
   Apple Watch Workout: [Workout Type] - [Duration] minutes, [Total Energy Burned] calories, [Total Distance] km
   ```

4. **Get Current Date** (format as HH:mm)

5. **Run Shell Script**
   ```bash
   "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
   ```

### Daily Steps Logger

**Name**: "Log Today's Steps"

**Actions**:
1. **Get Health Samples**
   - Type: Step Count
   - Date: Today
   - Aggregation: Sum

2. **Text**
   ```
   Apple Watch: [Step Count] steps today
   ```

3. **Get Current Date** (format as HH:mm)

4. **Run Shell Script**
   ```bash
   "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
   ```

### Heart Rate Logger

**Name**: "Log Heart Rate Stats"

**Actions**:
1. **Get Health Samples**
   - Type: Heart Rate
   - Date: Today
   - Limit: 1 (most recent)

2. **Text**
   ```
   Apple Watch Heart Rate: [Heart Rate] bpm
   ```

3. **Get Current Date** (format as HH:mm)

4. **Run Shell Script**
   ```bash
   "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
   ```

### Daily Summary Logger

**Name**: "Log Daily Health Summary"

**Actions**:
1. **Get Health Samples** (Steps)
   - Type: Step Count
   - Date: Today
   - Aggregation: Sum

2. **Get Health Samples** (Active Energy)
   - Type: Active Energy Burned
   - Date: Today
   - Aggregation: Sum

3. **Get Health Samples** (Exercise Minutes)
   - Type: Apple Exercise Time
   - Date: Today
   - Aggregation: Sum

4. **Text** (combine all)
   ```
   Apple Watch Daily Summary: [Step Count] steps, [Active Energy] calories burned, [Exercise Minutes] exercise minutes
   ```

5. **Get Current Date** (format as HH:mm)

6. **Run Shell Script**
   ```bash
   "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
   ```

## ⏰ Automation Setup

### Option 1: Manual Trigger
- Add the shortcut to your home screen
- Tap to run whenever you want

### Option 2: Time-Based Automation
1. In Shortcuts app, go to **Automation** tab
2. Tap **+** → **Create Personal Automation**
3. Choose **Time of Day**
4. Set time (e.g., 9:00 PM daily)
5. Add action: **Run Shortcut**
6. Select your health logging shortcut
7. Turn off "Ask Before Running" (optional, for automatic logging)

### Option 3: Workout End Automation
1. Create automation: **When Workout Ends**
2. Add action: **Run Shortcut**
3. Select your workout logging shortcut
4. Turn off "Ask Before Running"

### Option 4: Focus Mode Automation
1. Create automation: **When Focus Mode Turns On**
2. Choose your focus mode (e.g., "Sleep")
3. Add action: **Run Shortcut**
4. Select your health summary shortcut

## 🔧 Advanced: Multiple Health Metrics

To log multiple metrics in one entry:

1. **Get Health Samples** for each metric
2. **Combine** them using "Text" action
3. Format as a single entry:
   ```
   Apple Watch: [Steps] steps, [Active Energy] cal, [Exercise] min exercise, [Stand Hours] stand hours
   ```
4. **Run Shell Script** with the combined text

## 📊 What Gets Logged

The entries will appear in your daily log like:

```
14:30 - Apple Watch Workout: Running - 45 minutes, 450 calories, 5.2 km
18:00 - Apple Watch: 12,345 steps today
20:00 - Apple Watch Daily Summary: 12,345 steps, 650 calories burned, 60 exercise minutes
```

These entries will:
- ✅ Trigger your health reminder system
- ✅ Be included in daily log syncs
- ✅ Generate AI suggestions/banter
- ✅ Be searchable in your GTD system

## 🐛 Troubleshooting

### Shortcut Can't Find Script
- Make sure the path is correct: `$HOME/code/dotfiles/bin/gtd-healthkit-log`
- Try using full path: `/Users/abby/code/dotfiles/bin/gtd-healthkit-log`
- Verify script is executable: `chmod +x ~/code/dotfiles/bin/gtd-healthkit-log`

### Permission Issues
- Shortcuts needs permission to access Health data
- Go to Settings → Privacy & Security → Health → Shortcuts
- Enable access to the health data types you want

### Script Not Running on Mac
- Make sure you're using macOS Shortcuts (not just iOS)
- Or use SSH to run on Mac from iOS device
- Or use iCloud Drive to sync and run on Mac

### Entries Not Appearing
- Check the log file: `cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md`
- Check script output for errors
- Verify DAILY_LOG_DIR in your config

## 💡 Tips

1. **Start Simple**: Create one shortcut for workouts first, test it, then add more
2. **Use Variables**: Shortcuts variables make it easy to format entries
3. **Test Manually**: Always test shortcuts manually before automating
4. **Check Logs**: Regularly check your daily logs to ensure entries are formatted correctly
5. **Combine Metrics**: Create a "Daily Summary" shortcut that logs multiple metrics at once

## 🎉 Next Steps

Once set up, your Apple Health data will automatically flow into your daily log system, where it will:
- Be tracked by your health reminder system
- Generate AI suggestions
- Sync to your Second Brain
- Be searchable and analyzable

Enjoy your automated health logging! 🏃‍♀️💪

