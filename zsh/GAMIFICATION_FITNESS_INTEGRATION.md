# 💪 Gamification & Fitness/Workout Integration

## 🎮 How Fitness Activities Award XP

The gamification system now tracks and rewards your fitness and workout activities! Every time you log a workout or exercise, you earn XP and maintain your exercise streak.

## 🎯 XP Awards for Fitness Activities

### 1. Creating Workout Notes
**Commands:** `workout` or `workout_run`

**XP Award:** 
- Normal workout: 20 XP (exercise activity type)
- Running workout: 40 XP (exercise_intense activity type)

**When:** Every time you create a new workout note

**Example:**
```bash
workout
# File does not exist, creating new workout.
# +20 XP (Created workout log)
# 🔥 Exercise streak: 3 days
```

### 2. Logging Exercise to Daily Log
**Commands:** `gtd-daily-log`, `gtd-healthkit-log`, or `addInfoToDailyLog`

**XP Award:**
- Normal exercise: 20 XP (exercise activity type)
- Intense exercise: 40 XP (exercise_intense activity type)

**Detection:** Automatically detects workout keywords in your log entry

**Keywords Detected:**
- workout, exercise, kettlebell, walk, run, weight, lifting, gym, fitness, training
- cardio, strength, squat, deadlift, press, swing, snatch, clean, row
- bike, cycling, yoga, stretch, active, movement

**Intense Exercise Keywords:**
- run, running, sprint, intense, hard, heavy, cardio

**Example:**
```bash
gtd-daily-log "Kettlebell workout: 100 swings, 50 snatches"
# ✓ Added: 14:30 - Kettlebell workout: 100 swings, 50 snatches
# +20 XP (Logged exercise: Kettlebell workout...)
# 🔥 Exercise streak: 5 days

gtd-daily-log "Ran 5 miles this morning"
# ✓ Added: 08:00 - Ran 5 miles this morning
# +40 XP (Logged exercise: Ran 5 miles...) [intense exercise]
# 🔥 Exercise streak: 6 days
```

### 3. Syncing Health Data
**Command:** `gtd-sync-health`

**XP Award:** 5 XP (health_log activity type)

**When:** Every time you sync Apple Health data to your daily log

**Example:**
```bash
gtd-sync-health
# ✓ Health data sync triggered via Shortcuts
# +5 XP (Synced health data)
```

## 🔥 Exercise Streak Tracking

### Automatic Streak Updates
- **Exercise logged**: Streak automatically updated
- **Daily tracking**: Maintains consecutive days with exercise
- **Longest streak**: Tracks your best exercise streak ever

### Streak Milestones
- **3 days**: Building habit
- **7 days**: Fitness Week achievement (75 XP)
- **30 days**: Fitness Month achievement (300 XP)

## 🏆 Fitness Achievements

Unlock achievements as you exercise:

| Achievement | Requirement | XP Reward |
|-------------|-------------|-----------|
| **Getting Active** | Logged 1 exercise | 15 XP |
| **Fitness Enthusiast** | Logged 10 exercises | 50 XP |
| **Fitness Champion** | Logged 50 exercises | 200 XP |
| **Fitness Week** | 7-day exercise streak | 75 XP |
| **Fitness Month** | 30-day exercise streak | 300 XP |

## 📊 Integration Points

### Automatic Detection
The system automatically detects exercise in:
- **`gtd-daily-log`**: Detects workout keywords in log entries
- **`gtd-healthkit-log`**: Detects workout keywords in health logs
- **`workout`**: Awards XP when creating workout notes
- **`workout_run`**: Awards XP when creating running workout notes
- **`gtd-sync-health`**: Awards XP for syncing health data

### Smart Detection
- **Normal Exercise**: 20 XP (kettlebell, weights, yoga, etc.)
- **Intense Exercise**: 40 XP (running, sprinting, intense cardio, etc.)
- **Health Logging**: 5 XP (non-exercise health data)

## 💡 Tips for Maximum XP

1. **Log Your Workouts**: Use `workout` or log to daily log
2. **Be Specific**: Include exercise type for better tracking
3. **Maintain Streaks**: Exercise daily to build streaks
4. **Sync Health Data**: Use `gtd-sync-health` for bonus XP
5. **Track Everything**: Log all exercise activities

## 🎯 Example Workflows

### Morning Workout
```bash
# Create workout note
workout
# +20 XP (Created workout log)
# 🔥 Exercise streak: 1 days

# Log to daily log
gtd-daily-log "Kettlebell EMOM: 10 rounds"
# +20 XP (Logged exercise)
# 🔥 Exercise streak: 2 days
```

### Running Workout
```bash
# Create running workout
workout_run
# +40 XP (Created running workout log) [intense]
# 🔥 Exercise streak: 3 days

# Log run details
gtd-daily-log "Ran 5K in 25 minutes"
# +40 XP (Logged exercise) [intense]
# 🔥 Exercise streak: 4 days
```

### Health Data Sync
```bash
# Sync Apple Health data
gtd-sync-health
# +5 XP (Synced health data)
# (Exercise XP awarded separately when health data is logged)
```

## 📈 View Your Fitness Stats

```bash
gtd-gamify dashboard
```

Shows:
- **Exercise Sessions**: Total workouts logged
- **Exercise Streak**: Current and longest streaks
- **Fitness Achievements**: Unlocked fitness achievements

## 🔄 Integration with Existing System

### Works With
- **Daily Logging**: Exercise entries in daily logs are detected
- **Health Sync**: Apple Health sync triggers gamification
- **Workout Notes**: Creating workout notes awards XP
- **Streak Tracking**: Exercise streaks maintained automatically

### Silent Operation
- Gamification hooks fail silently if gamification isn't set up
- Fitness logging works normally even without gamification
- No performance impact

## 🎮 Exercise Keywords

The system detects these keywords (case-insensitive):
- **General**: workout, exercise, fitness, training, active, movement
- **Equipment**: kettlebell, weights, weight, lifting, gym
- **Activities**: walk, run, bike, cycling, yoga, stretch
- **Exercises**: squat, deadlift, press, swing, snatch, clean, row
- **Intensity**: cardio, strength, sprint, intense, hard, heavy

## 💪 Motivation Features

- **Immediate Feedback**: XP awarded instantly when you log exercise
- **Streak Tracking**: Visual progress on exercise streaks
- **Achievement Unlocks**: Celebrate fitness milestones
- **Progress Tracking**: See total exercise sessions over time

---

**Stay active and earn XP!** 💪🎮

