# How to Use Your GTD System Effectively

This guide shows you how to actually use your GTD system day-to-day to stay organized and productive.

## 🎯 Core Principles

1. **Capture Everything** - Get it out of your head
2. **Process Regularly** - Don't let inbox pile up
3. **Review Weekly** - Stay on top of everything
4. **Trust the System** - If it's not in the system, it doesn't exist

## 📅 Daily Workflow

### Morning Routine (5-10 minutes)

```bash
# 1. Check your daily log
gtd-log

# 2. Process any new inbox items
gtd-process

# 3. Review today's priorities
gtd-review daily

# 4. See what tasks you can do
gtd-task list --context=computer --energy=high
```

**What this does:**
- Gets you oriented for the day
- Clears your inbox
- Sets priorities
- Shows you what to work on

### Throughout the Day

**When something comes to mind:**
```bash
# Quick capture - don't think, just capture
gtd-capture "Call John about project"
gtd-capture "Research new tool for X"
gtd-capture "Remember to update docs"
```

**When you complete something:**
```bash
# Log it in your daily log
addInfoToDailyLog "Completed project proposal"

# Get advice from a persona
gtd-advise david "Just finished a big project, what should I focus on next?"
```

**When you need to work on something:**
```bash
# Find tasks by context
gtd-task list --context=home
gtd-task list --energy=low

# Or by project
gtd-task list --project=myproject
```

### Evening Routine (2-5 minutes)

```bash
# 1. Log your day
addInfoToDailyLog "Wrapped up work on X, feeling good about progress"

# 2. Quick inbox check
gtd-process  # Process 1-2 items if any

# 3. Review tomorrow
gtd-task list --priority=urgent_important
```

## 📆 Weekly Workflow

### Sunday Morning (30-60 minutes)

**You'll get a notification automatically**, or run:
```bash
gtd-review weekly
```

**This covers:**
1. Process all inbox items
2. Review all active projects
3. Check waiting-for items
4. Review areas of responsibility
5. Check someday/maybe list
6. Update next actions

**After the review:**
```bash
# Get advice on your week
gtd-advise --all "Review my weekly review and give me strategic advice"

# Sync with Second Brain
gtd-brain-sync
```

## 🔄 The Complete Capture → Process → Organize → Review Cycle

### 1. CAPTURE (Get it out of your head)

**Use `gtd-capture` for everything:**
- Ideas
- Tasks
- Reminders
- Links
- Meeting notes
- Email actions

**Don't judge, just capture:**
```bash
gtd-capture "Maybe learn Python"
gtd-capture "Fix bug in login"
gtd-capture "https://interesting-article.com"
gtd-capture "Talk to Sarah about project"
```

**Pro tip:** Set up quick aliases:
```bash
# Add to your .zshrc
alias c="gtd-capture"
alias cap="gtd-capture"
```

### 2. PROCESS (Decide what it is)

**Process your inbox regularly:**
```bash
# Process one item
gtd-process

# Or process all at once
gtd-process --all
```

**For each item, ask:**
- What is it?
- Is it actionable?
  - **No** → Delete, Reference, or Someday/Maybe
  - **Yes** → Continue
- Will it take < 2 minutes?
  - **Yes** → Do it now
  - **No** → Continue
- Does it need multiple steps?
  - **Yes** → Create project
  - **No** → Create task

**Pro tip:** Process inbox at least once daily, ideally twice (morning + evening).

### 3. ORGANIZE (Put it in the right place)

**The system organizes automatically, but you decide:**
- **Tasks** → Go to tasks directory
- **Projects** → Go to projects directory
- **Areas** → Go to areas directory
- **Reference** → Go to reference directory
- **Someday/Maybe** → For later
- **Waiting For** → Things you're waiting on

**Link to Second Brain:**
```bash
# When processing, create Second Brain note if needed
gtd-brain create "Project Notes" Projects
gtd-brain link ~/Documents/gtd/1-projects/myproject.md ~/Documents/Second\ Brain/Projects/myproject.md
```

### 4. REVIEW (Stay on top of everything)

**Daily Review (5 minutes):**
```bash
gtd-review daily
```

**Weekly Review (30-60 minutes):**
```bash
gtd-review weekly
```

**Monthly Review (optional):**
- Review all areas
- Archive old projects
- Update Second Brain notes

## 🎨 Effective Patterns

### Pattern 1: The Morning Startup

```bash
# Create an alias for this
alias gtd-morning="gtd-log && gtd-process && gtd-review daily && gtd-task list --priority=urgent_important"
```

### Pattern 2: The Evening Wind-Down

```bash
# Create an alias for this
alias gtd-evening="addInfoToDailyLog 'End of day' && gtd-process && gtd-task list --status=active"
```

### Pattern 3: Context Switching

**When you change locations or energy levels:**
```bash
# At home
gtd-task list --context=home --energy=low

# At computer
gtd-task list --context=computer --energy=high

# On phone
gtd-task list --context=phone
```

### Pattern 4: Project Deep Work

```bash
# 1. Review project
gtd-project view myproject

# 2. See project tasks
gtd-task list --project=myproject

# 3. Create Second Brain note for project
gtd-brain create "My Project Notes" Projects
gtd-brain link ~/Documents/gtd/1-projects/myproject.md ~/Documents/Second\ Brain/Projects/myproject.md

# 4. Work on tasks
gtd-task complete <task-id>
```

### Pattern 5: Weekly Planning

```bash
# 1. Do weekly review
gtd-review weekly

# 2. Get strategic advice
gtd-advise warren "Review my projects and priorities, give me strategic advice"

# 3. Sync systems
gtd-brain-sync

# 4. Plan week ahead
gtd-task list --priority=not_urgent_important  # Important but not urgent
```

## 🧠 Using Second Brain Effectively

### Capture Knowledge

```bash
# When you learn something
gtd-brain create "What I Learned About X" Resources

# When researching
gtd-brain create "Research: Topic Name" Resources
```

### Progressive Summarization

```bash
# Level 1: Highlight key points (manual)
gtd-brain summarize ~/Documents/Second\ Brain/Resources/note.md 1

# Level 2: Create summary
gtd-brain summarize ~/Documents/Second\ Brain/Resources/note.md 2

# Level 3: Distill insights
gtd-brain summarize ~/Documents/Second\ Brain/Resources/note.md 3
```

### Discover Connections

```bash
# Find related notes
gtd-brain-discover connections ~/Documents/Second\ Brain/Resources/note.md

# Find by tag
gtd-brain-discover tag productivity

# Find similar notes
gtd-brain-discover similar ~/Documents/Second\ Brain/Resources/note.md
```

## 💡 Best Practices

### 1. Trust the System

**If it's not captured, it doesn't exist.**
- Capture immediately when something comes to mind
- Don't try to remember things
- Let the system remember for you

### 2. Process Regularly

**Don't let inbox pile up:**
- Process at least once daily
- Better: Morning + Evening
- Best: Process immediately after capture (if time allows)

### 3. Review Weekly

**The weekly review is critical:**
- Set aside 30-60 minutes
- Do it at the same time each week
- Use the reminder system
- Be thorough

### 4. Use Contexts

**Match tasks to your situation:**
- `@home` - Things you can do at home
- `@computer` - Things requiring a computer
- `@phone` - Phone calls
- `@errands` - When you're out
- `@low_energy` - When you're tired
- `@high_energy` - When you're focused

### 5. Use Energy Levels

**Match tasks to your energy:**
- Morning (high energy) → Important, creative work
- Afternoon (medium) → Meetings, communication
- Evening (low) → Administrative, routine tasks

### 6. Link Everything

**Connect GTD and Second Brain:**
- Link projects to Second Brain notes
- Link tasks to relevant resources
- Build a knowledge network

### 7. Get Advice Regularly

**Use personas for different situations:**
```bash
# Strategic planning
gtd-advise warren "Help me prioritize my projects"

# When stuck
gtd-advise cal "I'm having trouble focusing, what should I do?"

# When overwhelmed
gtd-advise fred "I'm feeling overwhelmed with everything"

# When procrastinating
gtd-advise louiza "I've been procrastinating on this project"

# For habits
gtd-advise james "Help me build a habit of daily review"
```

### 8. Log Daily

**Use daily logs for:**
- Tracking what you did
- Capturing thoughts
- Getting advice
- Building a record

```bash
# Quick entries throughout the day
addInfoToDailyLog "Had great meeting with team"
addInfoToDailyLog "Feeling stuck on X, need to think about it"
addInfoToDailyLog "Completed Y, feeling accomplished"
```

## 🚀 Quick Start Checklist

**Week 1: Set Up**
- [ ] Run `gtd-setup-weekly-reminder` to enable weekly reminders
- [ ] Create your first project: `gtd-project create "My First Project"`
- [ ] Capture 5 things: `gtd-capture "..."` (repeat 5 times)
- [ ] Process your inbox: `gtd-process --all`
- [ ] Do your first daily review: `gtd-review daily`

**Week 2: Build Habits**
- [ ] Set up morning routine alias
- [ ] Set up evening routine alias
- [ ] Process inbox daily
- [ ] Log daily with `addInfoToDailyLog`
- [ ] Do weekly review on Sunday

**Week 3: Go Deeper**
- [ ] Create Second Brain notes for projects
- [ ] Link GTD items to Second Brain
- [ ] Use contexts and energy levels
- [ ] Get advice from personas
- [ ] Discover connections in Second Brain

**Week 4: Optimize**
- [ ] Review what's working
- [ ] Adjust your workflow
- [ ] Customize notifications
- [ ] Set up more aliases
- [ ] Share your system (optional)

## 📊 Measuring Effectiveness

**Track these metrics:**
- Inbox count (should stay low)
- Tasks completed per week
- Projects moving forward
- Weekly reviews completed
- Daily logs maintained

**Check your stats:**
```bash
# See inbox count
gtd-process  # Shows count

# See task stats
gtd-task list --status=active  # Active tasks
gtd-task list --status=done    # Completed tasks

# See project stats
gtd-project list

# See Second Brain stats
gtd-brain-discover stats
```

## 🎯 Common Scenarios

### Scenario 1: Starting a New Project

```bash
# 1. Capture the idea
gtd-capture "New project: Build X"

# 2. Process it
gtd-process  # Choose "project"

# 3. Create project
gtd-project create "Build X"

# 4. Create Second Brain note
gtd-brain create "Build X" Projects
gtd-brain link ~/Documents/gtd/1-projects/build-x.md ~/Documents/Second\ Brain/Projects/build-x.md

# 5. Break down into tasks
gtd-task add "Research X" --project=build-x
gtd-task add "Design X" --project=build-x
gtd-task add "Build X" --project=build-x
```

### Scenario 2: Feeling Overwhelmed

```bash
# 1. Get emotional support
gtd-advise fred "I'm feeling overwhelmed"

# 2. Get practical advice
gtd-advise david "Help me organize my tasks"

# 3. Review what you have
gtd-review daily

# 4. Focus on one thing
gtd-task list --priority=urgent_important | head -1
```

### Scenario 3: Procrastinating

```bash
# 1. Get accountability
gtd-advise louiza "I've been procrastinating on X"

# 2. Break it down
gtd-task list --project=X  # See what needs to be done

# 3. Start with smallest task
gtd-task list --project=X --energy=low | head -1

# 4. Just do one thing
gtd-task complete <smallest-task-id>
```

### Scenario 4: Weekly Planning

```bash
# 1. Do weekly review (you'll get reminder)
gtd-review weekly

# 2. Get strategic advice
gtd-advise warren "Review my priorities for this week"

# 3. Plan your week
gtd-task list --priority=not_urgent_important

# 4. Set up for success
gtd-brain-sync
```

## 🔧 Customization Tips

### Create Useful Aliases

Add to your `.zshrc`:
```bash
# Quick capture
alias c="gtd-capture"
alias cap="gtd-capture"

# Quick reviews
alias gtd-daily="gtd-review daily"
alias gtd-weekly="gtd-review weekly"

# Quick lists
alias tasks="gtd-task list"
alias projects="gtd-project list"

# Morning routine
alias gtd-morning="gtd-log && gtd-process && gtd-review daily"

# Evening routine
alias gtd-evening="addInfoToDailyLog 'End of day' && gtd-process"
```

### Set Up Keyboard Shortcuts

Use tools like:
- **Alfred** (macOS) - Create workflows for GTD commands
- **Raycast** (macOS) - Create custom commands
- **Keyboard Maestro** - Automate workflows

### Integrate with Calendar

Link tasks to calendar events:
```bash
# When you have a meeting
gtd-capture "Meeting with John at 2pm"
# Then process and link to calendar
```

## 🎓 Learning Path

**Beginner (Week 1-2):**
- Focus on capture and process
- Get comfortable with basic commands
- Do daily reviews

**Intermediate (Week 3-4):**
- Use contexts and energy levels
- Link to Second Brain
- Get advice from personas
- Do weekly reviews

**Advanced (Month 2+):**
- Build knowledge network
- Use progressive summarization
- Discover connections
- Optimize your workflow

## 💬 Remember

1. **The system works if you use it** - Consistency is key
2. **Start simple** - Don't try to do everything at once
3. **Trust the process** - Capture, process, organize, review
4. **Review regularly** - Weekly review is non-negotiable
5. **Get help** - Use personas when stuck
6. **Build knowledge** - Connect everything in Second Brain

## 🆘 When Things Go Wrong

**Inbox piling up?**
```bash
gtd-process --all  # Process everything
# Then commit to processing daily
```

**Forgot to review?**
```bash
gtd-review weekly  # Do it now
# Set up the reminder system
```

**Feeling lost?**
```bash
gtd-advise david "Help me get my GTD system back on track"
gtd-review weekly  # Start fresh
```

**System not working?**
- Review this guide
- Check your workflow
- Simplify if needed
- Get advice: `gtd-advise david "Help me fix my GTD system"`

---

**The goal:** Get everything out of your head, into the system, and trust the system to remind you when you need to do something. Then you can focus on doing, not remembering.

