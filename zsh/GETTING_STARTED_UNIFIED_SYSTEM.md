# Getting Started: Your Unified System

## 🎯 The Simple Truth

You have three systems that work together:
- **Zettelkasten** = Ideas and concepts
- **GTD** = Actions and tasks  
- **Second Brain** = Knowledge and organization

**They're not separate—they're one unified system.**

## 🚀 Week 1: Just Capture

### Goal: Build the capture habit

**Don't worry about organization yet. Just capture everything.**

```bash
# Morning: Start the wizard
make gtd-wizard

# Throughout the day:
# - Idea? → zet "my idea"
# - Task? → make gtd-wizard → 1 → 1
# - Reference? → make gtd-wizard → 1 → 3

# Evening: Quick process
make gtd-wizard → 2 (Process inbox)
```

**What to capture:**
- ✅ Any thought or idea
- ✅ Any task or action
- ✅ Any reference or link
- ✅ Anything that comes to mind

**Don't:**
- ❌ Worry about where it goes
- ❌ Try to organize immediately
- ❌ Overthink the system
- ❌ Try to use everything at once

## 📅 Week 2: Add Processing

### Goal: Process inboxes regularly

**Now that you're capturing, start processing:**

```bash
# Daily (5 minutes):
make gtd-wizard → 2 (Process GTD inbox)
make gtd-wizard → 22 → 11 (Process Zettelkasten inbox)

# Weekly (30 minutes):
make gtd-wizard → 6 → 2 (Weekly review)
```

**Processing means:**
- Decide what each item is
- Move it to the right place
- Create tasks/projects if needed
- Link related items

## 🔗 Week 3: Start Linking

### Goal: Connect your notes

**Now that you have notes, start connecting them:**

```bash
# Link atomic notes together
# Edit notes and add [[links]]

# Link notes to projects
make gtd-wizard → 22 → 6 (Link to Second Brain/PARA)

# Discover connections
gtd-brain-discover connections <note>
```

**Linking helps:**
- Build your knowledge graph
- Find related information
- See connections between ideas
- Create a web of knowledge

## 📊 Week 4: Add Organization

### Goal: Use PARA and MOCs

**Now that you have notes and links, organize:**

```bash
# Create MOCs for topics
gtd-brain-moc create "My Topic"

# Use progressive summarization
gtd-brain-distill <important-note>

# Sync GTD with Second Brain
make gtd-wizard → 7 (Sync with Second Brain)
```

**Organization helps:**
- Find information quickly
- See the big picture
- Build knowledge over time
- Create content from notes

## 🎯 The Complete Workflow (After Week 4)

### Morning (5 minutes)
```bash
make gtd-wizard → 17 (System status)
make gtd-wizard → 1 → 8 (Quick Zettelkasten capture if needed)
```

### During Day
```bash
# Capture as things come up
zet "idea"
gtd-capture "task"
```

### Evening (10 minutes)
```bash
make gtd-wizard → 22 → 11 (Process Zettelkasten inbox)
make gtd-wizard → 2 (Process GTD inbox)
make gtd-wizard → 15 (Daily log)
```

### Weekly (30 minutes)
```bash
make gtd-wizard → 6 → 2 (Weekly review)
make gtd-wizard → 7 (Sync with Second Brain)
# Link notes, discover connections
```

## 💡 Key Principles

### 1. Start Simple
- Week 1: Just capture
- Week 2: Add processing
- Week 3: Start linking
- Week 4: Add organization

### 2. Build Gradually
- Don't try to use everything at once
- Add features as you need them
- Remove what doesn't work

### 3. Trust the System
- Capture everything
- Process regularly
- Review weekly
- The system remembers, you don't have to

### 4. Use the Wizard
- It guides you through everything
- No need to remember commands
- Interactive and helpful

## 🎨 The System in Action

### Scenario: Learning Kubernetes

**Day 1-2: Capture**
```bash
zet -z "Kubernetes Pods"
zet -z "Kubernetes Services"
```

**Day 3-4: Process**
```bash
# Link notes together
# Create Second Brain resource
gtd-brain create "Kubernetes Learning" Resources
```

**Day 5-7: Organize**
```bash
# Link to resource
zet-link link <pods-note> Resources/kubernetes-learning.md

# Create GTD project
gtd-project create "Learn Kubernetes"

# Create tasks
gtd-task add "Practice kubectl" --project="Learn Kubernetes"
```

**Week 2+: Build Knowledge**
```bash
# Create MOC
gtd-brain-moc create "Kubernetes"

# Progressive summarization
gtd-brain-distill Resources/kubernetes-learning.md

# Discover connections
gtd-brain-discover connections Resources/kubernetes-learning.md
```

## 🚨 Common Mistakes (Avoid These)

### 1. Trying to Use Everything at Once
**Solution**: Start with capture, add features gradually

### 2. Overthinking Organization
**Solution**: Capture first, organize later during review

### 3. Not Processing Regularly
**Solution**: Set a daily reminder, make it a habit

### 4. Not Linking Notes
**Solution**: Link during weekly review, discover connections

### 5. Abandoning the System
**Solution**: Start simple, build gradually, trust the process

## ✅ Success Checklist

After 4 weeks, you should have:

- [ ] Daily capture habit
- [ ] Regular processing routine
- [ ] Notes linked together
- [ ] Projects organized in GTD
- [ ] Resources in Second Brain
- [ ] Weekly review habit
- [ ] System feels natural

## 🎉 You're Ready!

Start with Week 1: Just capture everything.

The system will grow with you. Don't overthink it—just start!

```bash
# Your first command:
make gtd-wizard

# Choose: 1 (Capture) → 8 (Zettelkasten)
# Enter: "My first atomic idea"

# That's it! You're using the system! 🎉
```





