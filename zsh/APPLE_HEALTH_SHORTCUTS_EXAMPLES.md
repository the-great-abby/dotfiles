# Apple Health Shortcuts - Ready-to-Use Examples

## ⚠️ CRITICAL: Health Actions Don't Show Up in Search!

**The Reality:** Health actions are **NOT searchable** in the Shortcuts gallery. If you search for "Health" or "Get Health Samples", you'll likely find nothing.

### ✅ Recommended: Skip Automated Health Actions

Since Health actions are unreliable and hard to find, we **strongly recommend** using **Manual Logging** instead:

1. **Scroll down to "Alternative: Manual Logging Shortcut"** section below
2. Use the simple manual logging shortcut - it works everywhere
3. Just type your health data when prompted
4. Much simpler and more reliable!

**The automated Health actions below are only useful if you happen to find them** (they're often hidden in categories, not searchable). Most people should use manual logging.

---

## ⚠️ If You Still Want to Try: Health Actions May Not Be Searchable

**The Reality:** Health actions may NOT appear when searching in the Shortcuts gallery. This is a known limitation.

### Why Health Actions Are Hard to Find:

- Health actions are often **not indexed in the search**
- They may only appear when adding actions manually
- Some versions of iOS/macOS don't include Health actions at all
- Health permissions must be granted first

### How to Actually Find Health Actions (If Available):

1. **Method 1: Browse Actions Manually**
   - Open Shortcuts app → Tap **+** to create new shortcut
   - Scroll through action categories
   - Look for a **"Health"** category in the action library
   - Health actions are usually grouped together

2. **Method 2: Type Action Name Directly**
   - When adding an action, start typing the exact name:
   - Try: **"Find Health Samples"** (type it exactly)
   - Try: **"Get Health Sample"**
   - Try: **"Log Health Sample"**

3. **Method 3: Enable Health Permissions First**
   - Open **Health** app → Profile (top right) → **Apps** → **Shortcuts**
   - Enable ALL permissions for health data types
   - Sometimes actions only appear after permissions are granted
   - Restart Shortcuts app after granting permissions

4. **Check Your Device:**
   - Health actions require iOS 13+ or macOS 10.15+
   - Better support in iOS 15+ or macOS 12+
   - Some features only work on iPhone/iPad (not Mac)

### If Health Actions Still Don't Appear:

**✅ Recommended Solution: Use Manual Logging**

Since Health actions are unreliable, we recommend using **manual logging shortcuts** instead. They're:
- ✅ **More reliable** - Work on all devices
- ✅ **Easier to set up** - No complex Health permissions
- ✅ **Faster** - Quick manual entry
- ✅ **More flexible** - Enter any health data format

**Skip to "Alternative: Manual Logging Shortcut" section below** - it's the recommended approach!

---

## 📋 Quick Reference: Shortcuts Actions

Here are the exact actions you need for each type of health logging:

> **Note:** If you can't find "Get Health Samples", try searching for "Find Health Samples" or "Health Samples" in the Shortcuts action library.

## 🏃 Workout Logger

### Step-by-Step Actions:

1. **Get Health Samples**
   - Health Type: **Workouts**
   - Date: **Today**
   - Sort Order: **Newest First**
   - Limit: **1** (or more for multiple workouts)

2. **Get Details of Health Samples**
   - Get: **Workout Type**
   - From: **Health Samples** (from step 1)

3. **Get Details of Health Samples**
   - Get: **Duration**
   - From: **Health Samples** (from step 1)

4. **Get Details of Health Samples**
   - Get: **Total Energy Burned**
   - From: **Health Samples** (from step 1)

5. **Get Details of Health Samples**
   - Get: **Total Distance**
   - From: **Health Samples** (from step 1)

6. **Text**
   ```
   Apple Watch Workout: [Workout Type] - [Duration] minutes, [Total Energy Burned] calories
   ```
   (Replace [Workout Type], [Duration], [Total Energy Burned] with the variables from steps 2-4)

7. **Get Current Date**
   - Format: **Custom**
   - Format String: **HH:mm**

8. **Run Shell Script**
   - Shell: **/bin/zsh**
   - Input: **as arguments**
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
     ```
   - Pass inputs:
     - **$1**: Text (from step 6)
     - **$2**: Formatted Date (from step 7)

## 👣 Daily Steps Logger

1. **Get Health Samples**
   - Health Type: **Step Count**
   - Date: **Today**
   - Aggregation: **Sum**

2. **Text**
   ```
   Apple Watch: [Health Samples] steps today
   ```
   (Replace [Health Samples] with variable from step 1)

3. **Get Current Date**
   - Format: **Custom**
   - Format String: **HH:mm**

4. **Run Shell Script**
   - Shell: **/bin/zsh**
   - Input: **as arguments**
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
     ```
   - Pass inputs:
     - **$1**: Text (from step 2)
     - **$2**: Formatted Date (from step 3)

## ❤️ Heart Rate Logger

1. **Get Health Samples**
   - Health Type: **Heart Rate**
   - Date: **Today**
   - Sort Order: **Newest First**
   - Limit: **1**

2. **Text**
   ```
   Apple Watch Heart Rate: [Health Samples] bpm
   ```
   (Replace [Health Samples] with variable from step 1)

3. **Get Current Date**
   - Format: **Custom**
   - Format String: **HH:mm**

4. **Run Shell Script**
   - Shell: **/bin/zsh**
   - Input: **as arguments**
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
     ```
   - Pass inputs:
     - **$1**: Text (from step 2)
     - **$2**: Formatted Date (from step 3)

## 📊 Daily Health Summary

1. **Get Health Samples** (Steps)
   - Health Type: **Step Count**
   - Date: **Today**
   - Aggregation: **Sum**
   - Save to variable: **Steps**

2. **Get Health Samples** (Active Energy)
   - Health Type: **Active Energy Burned**
   - Date: **Today**
   - Aggregation: **Sum**
   - Save to variable: **Active Energy**

3. **Get Health Samples** (Exercise)
   - Health Type: **Apple Exercise Time**
   - Date: **Today**
   - Aggregation: **Sum**
   - Save to variable: **Exercise**

4. **Get Health Samples** (Stand Hours)
   - Health Type: **Apple Stand Time**
   - Date: **Today**
   - Aggregation: **Sum**
   - Save to variable: **Stand**

5. **Text**
   ```
   Apple Watch Daily Summary: [Steps] steps, [Active Energy] cal burned, [Exercise] min exercise, [Stand] stand hours
   ```
   (Replace variables with actual variable names from steps 1-4)

6. **Get Current Date**
   - Format: **Custom**
   - Format String: **HH:mm**

7. **Run Shell Script**
   - Shell: **/bin/zsh**
   - Input: **as arguments**
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
     ```
   - Pass inputs:
     - **$1**: Text (from step 5)
     - **$2**: Formatted Date (from step 6)

## 🛌 Sleep Logger

1. **Get Health Samples**
   - Health Type: **Sleep Analysis**
   - Date: **Today**
   - Sort Order: **Newest First**
   - Limit: **1**

2. **Get Details of Health Samples**
   - Get: **Sleep Value**
   - From: **Health Samples** (from step 1)

3. **Get Details of Health Samples**
   - Get: **Start Date**
   - From: **Health Samples** (from step 1)

4. **Get Details of Health Samples**
   - Get: **End Date**
   - From: **Health Samples** (from step 1)

5. **Calculate** (Duration)
   - Operation: **Subtract**
   - First Number: **End Date** (from step 4)
   - Second Number: **Start Date** (from step 3)
   - Result Format: **Hours**

6. **Text**
   ```
   Apple Watch Sleep: [Sleep Value] - [Calculate Result] hours
   ```
   (Replace with variables from steps 2 and 5)

7. **Get Current Date**
   - Format: **Custom**
   - Format String: **HH:mm**

8. **Run Shell Script**
   - Shell: **/bin/zsh**
   - Input: **as arguments**
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
     ```
   - Pass inputs:
     - **$1**: Text (from step 6)
     - **$2**: Formatted Date (from step 7)

## 🔄 Automation Triggers

### End of Day Summary (9 PM Daily)

1. **Create Personal Automation**
2. **Trigger**: **Time of Day**
   - Time: **9:00 PM**
   - Repeat: **Every Day**
3. **Action**: **Run Shortcut**
   - Shortcut: **Daily Health Summary**
4. **Options**: Turn off "Ask Before Running" for automatic logging

### After Workout Ends

1. **Create Personal Automation**
2. **Trigger**: **When Workout Ends**
3. **Action**: **Run Shortcut**
   - Shortcut: **Workout Logger**
4. **Options**: Turn off "Ask Before Running"

### Morning Steps Check (8 AM Daily)

1. **Create Personal Automation**
2. **Trigger**: **Time of Day**
   - Time: **8:00 AM**
   - Repeat: **Every Day**
3. **Action**: **Run Shortcut**
   - Shortcut: **Daily Steps Logger**

## 💡 Pro Tips

1. **Use Variables**: Name your variables clearly (e.g., "Steps", "Workout Type") to make the shortcut easier to read

2. **Format Numbers**: For calories, steps, etc., you might want to format them:
   - Use "Format Number" action
   - Set format to remove decimals if needed

3. **Handle Missing Data**: Add "If" actions to check if health samples exist before logging

4. **Combine Multiple Workouts**: Use "Repeat with Each" to log all workouts from today

5. **Add Emojis**: Make entries more readable:
   ```
   🏃 Apple Watch Workout: [Workout Type] - [Duration] minutes
   👣 Apple Watch: [Steps] steps today
   ❤️ Apple Watch Heart Rate: [Heart Rate] bpm
   ```

## 🧪 Testing Your Shortcut

Before automating, always test manually:

1. Run the shortcut from Shortcuts app
2. Check for any errors
3. Verify the entry in your daily log:
   ```bash
   cat ~/Documents/daily_logs/$(date +%Y-%m-%d).md | tail -5
   ```
4. Make sure the format looks correct

## 📱 Sharing Shortcuts

Once you've created a working shortcut:
1. Tap the "..." menu on your shortcut
2. Tap "Share"
3. Export as a file or share with others
4. Others can import it and adjust the script path if needed

---

## 🔧 Alternative: Manual Logging Shortcut

**If you can't find Health actions, use this simple manual logging shortcut:**

### Simple Manual Health Logger

1. **Ask for Input**
   - Type: **Text**
   - Prompt: **"Enter health data (e.g., '12,345 steps' or '30 min workout'):"**
   - Allow Multiple Lines: **No**

2. **Get Current Date**
   - Format: **Custom**
   - Format String: **HH:mm**

3. **Run Shell Script**
   - Shell: **/bin/zsh**
   - Input: **as arguments**
   - Script:
     ```bash
     "$HOME/code/dotfiles/bin/gtd-healthkit-log" "$1" "$2"
     ```
   - Pass inputs:
     - **$1**: Ask for Input (from step 1)
     - **$2**: Formatted Date (from step 2)

**Usage:**
- Run the shortcut manually
- Enter your health data when prompted
- Example inputs:
  - "12,345 steps"
  - "30 min kettlebell workout, 300 calories"
  - "Heart rate: 72 bpm"
  - "8 hours sleep"

### Quick Entry Shortcuts

Create multiple shortcuts for common entries:

**Quick Steps:**
1. **Text**: `"Apple Watch: [Your step count] steps today"`
2. **Get Current Date** (HH:mm format)
3. **Run Shell Script** (same as above)

**Quick Workout:**
1. **Text**: `"Apple Watch Workout: [Type] - [Duration] minutes, [Calories] calories"`
2. **Get Current Date** (HH:mm format)
3. **Run Shell Script** (same as above)

---

## 🐛 Troubleshooting

### "Get Health Samples" Not Found

**Try these solutions:**

1. **Search for alternative names:**
   - "Find Health Samples"
   - "Health Samples"
   - "Get Health Sample"
   - "Read Health Data"

2. **Check Health permissions:**
   ```
   Health App → Profile → Apps → Shortcuts
   Enable: Steps, Workouts, Heart Rate, etc.
   ```

3. **Update your device:**
   - iOS 13+ required for Health actions
   - iOS 15+ recommended for full features

4. **Restart Shortcuts app:**
   - Force quit and reopen Shortcuts
   - Sometimes actions appear after restart

5. **Use manual logging:**
   - See "Alternative: Manual Logging Shortcut" above
   - Works on all iOS/macOS versions

### Shortcut Runs But No Data

**Check:**
- Health app has data for that day
- Health permissions are enabled
- Date range is set correctly (usually "Today")
- Health data type matches (e.g., "Step Count" not "Steps")

### Script Path Error

**Fix:**
- Update script path to match your dotfiles location:
  ```bash
  "$HOME/code/dotfiles/bin/gtd-healthkit-log"
  # or
  "$HOME/code/personal/dotfiles/bin/gtd-healthkit-log"
  ```
- Make sure the script is executable:
  ```bash
  chmod +x ~/code/dotfiles/bin/gtd-healthkit-log
  ```

---

## 📚 Additional Resources

- **Apple Shortcuts Documentation**: [support.apple.com/shortcuts](https://support.apple.com/shortcuts)
- **Health App Guide**: Check Health app → Browse tab for available data types
- **Shortcuts Gallery**: Browse example shortcuts in Shortcuts app

