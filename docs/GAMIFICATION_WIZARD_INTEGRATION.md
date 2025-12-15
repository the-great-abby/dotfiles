# 🧙 Gamification & Wizard Integration

## 🎮 How Wizard Usage Awards XP

The gamification system now tracks your GTD system usage through the wizard! Every time you use the wizard, you earn XP and track your engagement with the system.

## 🎯 XP Awards for Wizard Usage

### 1. Opening the Wizard
**Action:** Starting `gtd-wizard`

**XP Award:** 1 XP (wizard_use activity type)

**When:** Every time you open the wizard

**Example:**
```bash
gtd-wizard
# +1 XP (Opened GTD wizard)
```

### 2. Using Wizard Actions
**Actions:** Viewing status, searching, learning, configuring

**XP Award:** 2 XP (wizard_action activity type)

**Wizard Options:**
- Manage areas (5)
- Sync with Second Brain (7)
- Manage MOCs (8)
- Templates (10)
- Get advice (11)
- Learn GTD/Second Brain (12, 13)
- Life vision (14)
- Search (16)
- System status (17)
- Learn Kubernetes/Greek (20, 21)
- Diagrams (22)
- AI suggestions (24)
- Goal tracking (25)
- Energy audit (26)
- Configuration (27)
- Gamification (28)

### 3. Productive Wizard Actions
**Actions:** Capture, process, tasks, projects, reviews, logs, habits, check-ins, zettelkasten

**XP Award:** 5 XP (wizard_productive activity type)

**Wizard Options:**
- Capture to inbox (1)
- Process inbox (2)
- Manage tasks (3)
- Manage projects (4)
- Review (6)
- Express phase (9)
- Daily log (15)
- Habits (18)
- Check-in (19)
- Zettelkasten (23)

## 📊 Tracking System Usage

### Wizard Usage Statistics
The gamification system tracks:
- **Total wizard uses**: How many times you've used the wizard
- **Wizard actions**: Different types of wizard activities
- **System engagement**: Overall GTD system usage

### View Your Stats
```bash
gtd-gamify dashboard
```

Shows:
- Wizard Uses: Total number of wizard sessions
- All other GTD statistics

## 🏆 Wizard Achievements

Unlock achievements as you use the wizard:

| Achievement | Requirement | XP Reward |
|-------------|-------------|-----------|
| **Wizard Starter** | Used wizard 1 time | 5 XP |
| **Wizard Apprentice** | Used wizard 10 times | 25 XP |
| **Wizard Regular** | Used wizard 50 times | 75 XP |
| **Wizard Master** | Used wizard 100 times | 150 XP |
| **Wizard Legend** | Used wizard 500 times | 500 XP |

## 💡 Why This Matters

### Track System Engagement
- See how often you use the GTD system
- Identify which wizard features you use most
- Understand your productivity patterns

### Motivation
- Small XP rewards for using the system
- Higher rewards for productive actions
- Achievements celebrate consistent usage

### Insights
- Wizard usage stats show system engagement
- Can identify if you're using the system regularly
- Helps track overall GTD adoption

## 🎯 XP Values Summary

| Activity | XP Amount | Type |
|----------|-----------|------|
| Open wizard | 1 XP | wizard_use |
| View/learn/search | 2 XP | wizard_action |
| Capture/process/tasks | 5 XP | wizard_productive |

## 🔄 Example Session

```bash
$ gtd-wizard
# +1 XP (Opened GTD wizard)

# Choose option 1: Capture
# +5 XP (Used wizard: Capture)

# Choose option 3: Manage tasks
# +5 XP (Used wizard: Manage tasks)

# Choose option 17: System status
# +2 XP (Used wizard: System status)
```

## 📈 Integration Points

### Automatic Tracking
- **Wizard opens**: 1 XP automatically awarded
- **Each option selected**: XP awarded based on action type
- **Stats updated**: Wizard usage tracked in gamification stats

### Silent Operation
- Gamification hooks fail silently if gamification isn't set up
- Wizard works normally even without gamification
- No performance impact

## 🎮 Tips for Maximum Engagement

1. **Use the Wizard Regularly**: Even just opening it earns XP
2. **Productive Actions**: Focus on capture, tasks, projects for higher XP
3. **Track Your Usage**: Check dashboard to see your wizard usage stats
4. **Unlock Achievements**: Work toward wizard usage milestones

## 📚 Related Commands

- **`gtd-wizard`**: Main wizard entry point (+1 XP on open, +2-5 XP per action)
- **`gtd-gamify dashboard`**: View wizard usage statistics
- **`gtd-gamify achievements`**: Check wizard usage achievements

---

**The wizard now tracks your GTD system engagement!** 🧙🎮

