# GTD Wizard System Guide

The GTD Wizard provides an interactive, menu-driven interface to guide you through all GTD operations.

## 🧙 Quick Start

```bash
# Start the interactive wizard
make gtd-wizard

# Or use the direct command
gtd-wizard
```

## 📋 Available Commands

### Makefile Commands

```bash
make help          # Show all available commands
make gtd-wizard    # Interactive wizard (main entry point)
make gtd-capture   # Quick capture to inbox
make gtd-process   # Process inbox items
make gtd-review    # Start daily/weekly review
make gtd-sync      # Sync with Second Brain
make gtd-advise    # Get advice from personas
make gtd-learn     # Learn GTD concepts
make gtd-status    # Show system status
```

## 🎯 Wizard Menu Options

The wizard provides 22 main options:

### 1. 📥 Capture Something to Inbox
Guides you through capturing different types of items:
- Task (actionable item)
- Idea (someday/maybe)
- Reference (information to keep)
- Link (URL to save)
- Call (phone call notes)
- Email (email action)
- General note
- Zettelkasten note (atomic idea)

### 2. 📋 Process Inbox Items
- Shows inbox count
- Guides through processing each item
- Helps decide what to do with each item

### 3. ✅ Manage Tasks
- Add new task
- List tasks
- Complete a task
- Update a task
- Link tasks to projects

### 4. 📁 Manage Projects
- Create new project
- List projects
- View project details
- Add task to project
- Update project status
- Archive project

### 5. 📊 Review (Daily/Weekly)
- Daily review
- Weekly review
- Guided review process

### 6. 🧠 Sync with Second Brain
- Full sync (projects, areas, references)
- Projects only
- Areas only
- References only

### 7. 🤖 Get Advice from Personas
- Random persona
- Specific persona
- All personas
- Review daily log

### 8. 📚 Learn GTD Concepts
- Interactive GTD learning
- Mistress Louiza as instructor
- Various topics

### 9. 📝 Log to Daily Log
- Quick daily log entry
- Automatic persona advice

### 10. 🔍 Search GTD System
- Search GTD system
- Search Second Brain
- Find items across both systems

### 11. 📊 System Status
- Inbox count
- Active projects count
- Active tasks count
- Today's log entries

### 12. ☸️ Learn Kubernetes/CKA
- Start learning (interactive menu)
- Learn specific topic
- Create study plan
- View study progress

### 22. 🔗 Zettelkasten (Atomic Notes)
- Create atomic note (inbox)
- Create atomic note (Zettelkasten directory)
- Create atomic note (Resources/Projects/Areas - PARA)
- Link note to Second Brain/PARA
- Link note to GTD item
- Move note to PARA category
- List notes in inbox
- List notes in Zettelkasten directory
- Process inbox (move to organized location)

## 💡 Example Workflows

### Quick Capture Workflow

```bash
make gtd-wizard
# Choose: 1 (Capture)
# Choose: 1 (Task)
# Enter: "Review quarterly report"
# Done! Item captured to inbox
```

### Project Creation Workflow

```bash
make gtd-wizard
# Choose: 4 (Manage projects)
# Choose: 1 (Create new project)
# Enter: "Website Redesign"
# Project created!
# Then: Choose 6 (Sync with Second Brain)
# Choose: 2 (Projects only)
# Synced to Second Brain!
```

### Daily Review Workflow

```bash
make gtd-wizard
# Choose: 5 (Review)
# Choose: 1 (Daily review)
# Follow guided review process
```

### Getting Advice Workflow

```bash
make gtd-wizard
# Choose: 7 (Get advice)
# Choose: 1 (Random persona)
# Enter: "I'm feeling overwhelmed"
# Get personalized advice!
```

## 🎨 Features

### Interactive Menus
- Clear, numbered options
- Color-coded for easy reading
- Context-aware prompts

### Guided Processes
- Step-by-step guidance
- Helpful prompts
- Error handling

### Integration
- Works with all GTD commands
- Integrates with Second Brain
- Connects to persona system

## 🔧 Makefile Shortcuts

The Makefile provides quick shortcuts for common operations:

```bash
# Quick capture (prompts for input)
make gtd-capture

# Quick status check
make gtd-status

# Quick sync
make gtd-sync
```

## 📚 Tips

1. **Use the wizard for complex operations** - It guides you through multi-step processes
2. **Use Makefile shortcuts for quick actions** - Faster for simple operations
3. **The wizard remembers context** - It shows relevant information as you work
4. **All operations are reversible** - You can always go back or cancel

## 🎯 When to Use What

### Use the Wizard When:
- You're learning GTD
- You need guidance through a process
- You want to see all options
- You're doing complex operations

### Use Direct Commands When:
- You know exactly what you want
- You're doing quick, simple operations
- You're scripting or automating
- You prefer command-line efficiency

## 🚀 Getting Started

1. **Try the wizard:**
   ```bash
   make gtd-wizard
   ```

2. **Explore the menu:**
   - Try different options
   - See what each does
   - Get familiar with the flow

3. **Use regularly:**
   - Daily: Capture, log, review
   - Weekly: Review, sync, status
   - As needed: Projects, tasks, advice

## 💬 Remember

The wizard is there to help! Use it whenever you need guidance or want to explore what's possible with your GTD system.

**Start exploring: `make gtd-wizard`**

