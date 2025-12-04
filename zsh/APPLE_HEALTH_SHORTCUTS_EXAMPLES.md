# Apple Health Shortcuts - Ready-to-Use Examples

## 📋 Quick Reference: Shortcuts Actions

Here are the exact actions you need for each type of health logging:

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

