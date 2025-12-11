# Troubleshooting: gtd-study-plan Stuck

## 🔍 The Problem

If `gtd-study-plan cka` appears stuck, it's because `gtd-task add` is waiting for interactive input. The script is prompting you to answer questions, but you might not see the prompts.

## ✅ Quick Fix

### Option 1: Kill and Retry (Easiest)

```bash
# Kill any stuck processes
pkill -f "gtd-study-plan|gtd-task"

# Or press Ctrl+C in the terminal where it's running

# Try again - it should work now
gtd-study-plan cka
```

### Option 2: The Project Might Already Be Created

Check if the project was actually created:

```bash
ls ~/Documents/gtd/1-projects/cka-exam-preparation/
cat ~/Documents/gtd/1-projects/cka-exam-preparation/README.md
```

If the project exists, you can just create the tasks manually:

```bash
gtd-task add "Study Kubernetes basics" --project=cka-exam-preparation --context=computer --energy=high
```

### Option 3: Create Tasks Non-Interactively

The `gtd-task` command now supports flags for non-interactive use:

```bash
# Create tasks with all flags (no prompts)
gtd-task add "Study Kubernetes basics" \
  --project=cka-exam-preparation \
  --context=computer \
  --energy=high \
  --priority=not_urgent_important
```

## 🛠️ What Was Fixed

I've updated `gtd-task` to:
- Accept `--project`, `--context`, `--energy`, `--priority` flags
- Run non-interactively when flags are provided
- Skip all prompts when flags are used

## 📝 Manual Workaround

If the script is still having issues, you can create everything manually:

```bash
# 1. Create the project
gtd-project create "cka-exam-preparation"

# 2. Create tasks one by one
gtd-task add "Study Kubernetes basics and architecture" \
  --project=cka-exam-preparation \
  --context=computer \
  --energy=high

gtd-task add "Practice kubectl commands daily" \
  --project=cka-exam-preparation \
  --context=computer \
  --energy=medium

gtd-task add "Set up local Kubernetes cluster" \
  --project=cka-exam-preparation \
  --context=computer \
  --energy=high
```

## 💡 Why It Got Stuck

The old version of `gtd-task add` always prompted for:
- Recurring task? (y/n)
- Context
- Energy level  
- Priority

When `gtd-study-plan` called it with flags, it ignored the flags and still prompted. The updated version now recognizes flags and skips prompts.

## 🎯 Next Steps

After fixing:

1. **Check if project was created:**
   ```bash
   ls ~/Documents/gtd/1-projects/cka-exam-preparation/
   ```

2. **If project exists, verify tasks:**
   ```bash
   gtd-task list --project=cka-exam-preparation
   ```

3. **If tasks are missing, create them:**
   ```bash
   # Use the manual commands above
   ```

4. **Start learning:**
   ```bash
   gtd-learn-kubernetes
   ```

The script should work smoothly now! 🚀





