# Unified System Workflow: Zettelkasten + GTD + Second Brain

## 🎯 The Big Picture

You have three powerful systems that work together:

1. **Zettelkasten** = Atomic ideas (one concept per note, linked together)
2. **GTD** = Action workflow (tasks, projects, getting things done)
3. **Second Brain** = Knowledge organization (PARA, progressive summarization, content creation)

**The key insight**: They're not separate systems—they're different layers of the same knowledge and productivity system.

## 🧠 The Mental Model

Think of your system as a pyramid:

```
        EXPRESS (Second Brain)
       Create content, publish
    ────────────────────────────
         ORGANIZE (Second Brain)
    PARA, MOCs, Evergreen Notes
    ────────────────────────────
         BUILD (Zettelkasten)
    Atomic notes, connections
    ────────────────────────────
         ACT (GTD)
    Tasks, projects, actions
    ────────────────────────────
         CAPTURE (All Systems)
    Quick capture to inbox
```

## 📋 Decision Tree: What Goes Where?

### When You Have Something to Capture

```
Is it actionable?
├─ YES → Is it a single task?
│   ├─ YES → GTD Capture (task)
│   └─ NO → GTD Capture (project)
│
└─ NO → Is it an atomic idea/concept?
    ├─ YES → Zettelkasten (zet)
    └─ NO → Is it reference material?
        ├─ YES → GTD Capture (reference) → Second Brain (Resources)
        └─ NO → GTD Capture (note) → Process later
```

### When Processing Your Inboxes

```
GTD Inbox Item:
├─ Actionable? → GTD Process (create task/project)
└─ Reference? → Second Brain (Resources)

Zettelkasten Inbox:
├─ Atomic idea? → Keep as Zettelkasten note
├─ Part of larger concept? → Link to Second Brain note
└─ Actionable insight? → Create GTD task/project
```

## 🔄 Daily Workflow

### Morning Routine (5 minutes)

```bash
# 1. Check GTD status
make gtd-wizard
# Choose: 17 (System status)
# Review: Tasks, projects, inbox count

# 2. Quick capture any morning thoughts
make gtd-wizard
# Choose: 1 (Capture) → 8 (Zettelkasten) for ideas
# Or: 1 (Capture) → 1 (Task) for actions

# 3. Process GTD inbox (if items exist)
make gtd-wizard
# Choose: 2 (Process inbox)
```

### During the Day

**When you have an idea:**
```bash
# Quick capture - don't think about where it goes
zet "My idea"
# Process later during review time
```

**When you have a task:**
```bash
# Quick capture
gtd-capture "Task description"
# Or use wizard: make gtd-wizard → 1 → 1
```

**When learning something:**
```bash
# 1. Create atomic notes as you learn
zet -z "Concept A"
zet -z "Concept B"

# 2. Link them together (edit notes to add [[links]])

# 3. Create Second Brain resource for the topic
gtd-brain create "Topic Name" Resources

# 4. Link atomic notes to resource
zet-link link <note-a> Resources/topic-name.md
```

### Evening Routine (10-15 minutes)

```bash
# 1. Process Zettelkasten inbox
make gtd-wizard
# Choose: 22 (Zettelkasten) → 11 (Process inbox)
# Move notes to organized locations

# 2. Process GTD inbox
make gtd-wizard
# Choose: 2 (Process inbox)

# 3. Daily log
make gtd-wizard
# Choose: 15 (Log to daily log)

# 4. Quick review
make gtd-wizard
# Choose: 6 (Review) → 1 (Daily review)
```

### Weekly Routine (30 minutes)

```bash
# 1. Weekly review
make gtd-wizard
# Choose: 6 (Review) → 2 (Weekly review)

# 2. Process all inboxes
# - GTD inbox
# - Zettelkasten inbox
# - Second Brain (if needed)

# 3. Link and connect notes
make gtd-wizard
# Choose: 22 (Zettelkasten) → 6 (Link notes)
# Discover connections: gtd-brain-discover connections

# 4. Progressive summarization
# Review important notes and distill them
gtd-brain-distill <important-note>
```

## 🎓 Learning Workflow (Complete Example)

**Scenario**: Learning Kubernetes for CKA exam

### Phase 1: Setup (One-time)

```bash
# 1. Create GTD project
make gtd-wizard
# Choose: 4 (Projects) → 1 (Create)
# Enter: "CKA Exam Preparation"

# 2. Sync to Second Brain
make gtd-wizard
# Choose: 7 (Sync) → 2 (Projects only)

# 3. Create study plan
gtd-study-plan cka
```

### Phase 2: Learning (Ongoing)

**As you learn each concept:**

```bash
# 1. Create atomic note for the concept
zet -z "Kubernetes Pods"
# Opens in editor - write your understanding

# 2. Create another related concept
zet -z "Kubernetes Containers"
# Link to pods note: [[Kubernetes Pods]]

# 3. Link to project
zet-link link ~/Documents/Second\ Brain/Zettelkasten/20250101-kubernetes-pods.md \
  Projects/cka-exam-preparation.md

# 4. Create GTD tasks for practice
make gtd-wizard
# Choose: 3 (Tasks) → 1 (Add task)
# Enter: "Practice kubectl pod commands"
```

### Phase 3: Building Knowledge

```bash
# 1. Create MOC (Map of Content) for all K8s notes
gtd-brain-moc create "Kubernetes Learning"

# 2. Add all your atomic notes to the MOC
# Edit the MOC file and add links to all notes

# 3. Progressive summarization
# After learning several concepts, distill them
gtd-brain-distill Resources/kubernetes-learning.md
```

### Phase 4: Application

```bash
# 1. Create practice exercises as GTD tasks
# 2. Link atomic notes to practice tasks
# 3. Use notes to create study guides (Express phase)
gtd-brain-express draft "K8s Study Guide"
```

## 💼 Project Workflow (Complete Example)

**Scenario**: Building a new feature

### Phase 1: Ideation

```bash
# 1. Capture ideas as atomic notes
zet "Feature idea A"
zet "Feature idea B"
zet "Technical approach"

# 2. Link related ideas
# Edit notes to add [[links]] between related concepts
```

### Phase 2: Planning

```bash
# 1. Create GTD project
make gtd-wizard
# Choose: 4 (Projects) → 1 (Create)
# Enter: "New Feature Development"

# 2. Create Second Brain project note
gtd-brain-sync projects

# 3. Link atomic notes to project
zet-link link <idea-a> Projects/new-feature-development.md
zet-link link <idea-b> Projects/new-feature-development.md

# 4. Create GTD tasks from ideas
make gtd-wizard
# Choose: 3 (Tasks) → 1 (Add task)
# Create tasks for each actionable step
```

### Phase 3: Execution

```bash
# 1. Work from GTD tasks
make gtd-wizard
# Choose: 3 (Tasks) → 2 (List tasks)
# Complete tasks as you work

# 2. Capture insights as atomic notes
zet "Technical insight discovered"
zet-link link <insight> Projects/new-feature-development.md

# 3. Update project notes in Second Brain
# Edit: Projects/new-feature-development.md
```

### Phase 4: Documentation

```bash
# 1. Use atomic notes to build documentation
gtd-brain-express draft "Feature Documentation"

# 2. Link to all relevant atomic notes
# 3. Create final documentation
```

## 🔗 Linking Strategy

### The Linking Hierarchy

```
GTD Project
    ↓
Second Brain Project Note
    ↓
MOC (Map of Content)
    ↓
Zettelkasten Notes (Atomic Ideas)
    ↓
GTD Tasks (Actions)
```

### Practical Linking Rules

1. **Zettelkasten → Zettelkasten**: Link related atomic concepts
2. **Zettelkasten → Second Brain**: Link atomic notes to larger resources/projects
3. **Second Brain → GTD**: Link resources to actionable projects
4. **GTD → Second Brain**: Auto-sync projects/areas to Second Brain
5. **All → All**: Use bidirectional linking when it makes sense

## 📊 System Maintenance

### Daily (2-5 minutes)
- Process inboxes (GTD and Zettelkasten)
- Quick capture new items
- Daily log entry

### Weekly (30 minutes)
- Weekly review
- Process all inboxes completely
- Link and connect notes
- Review and organize

### Monthly (1 hour)
- Archive completed projects
- Review evergreen notes
- Update MOCs
- Clean up orphaned notes

## 🎯 The Unified Workflow

### The Complete Cycle

```
1. CAPTURE (All Systems)
   ├─ Quick thoughts → zet (Zettelkasten inbox)
   ├─ Tasks → gtd-capture (GTD inbox)
   └─ References → gtd-capture → Second Brain

2. PROCESS (Daily/Weekly)
   ├─ GTD inbox → Tasks/Projects/Areas
   ├─ Zettelkasten inbox → Organized notes
   └─ Link everything together

3. ORGANIZE (Second Brain)
   ├─ PARA method (Projects, Areas, Resources, Archives)
   ├─ MOCs (Maps of Content)
   └─ Progressive summarization

4. ACT (GTD)
   ├─ Work from tasks
   ├─ Complete projects
   └─ Review regularly

5. BUILD (Zettelkasten)
   ├─ Create atomic notes
   ├─ Link concepts together
   └─ Build knowledge graph

6. EXPRESS (Second Brain)
   ├─ Create content from notes
   ├─ Share insights
   └─ Publish work
```

## 💡 Practical Tips

### 1. Start Simple
- Don't try to use everything at once
- Start with capture and basic organization
- Add complexity as you get comfortable

### 2. Use the Right Tool for the Job
- **Quick idea?** → Zettelkasten
- **Actionable?** → GTD
- **Reference material?** → Second Brain Resources
- **Project?** → GTD + Second Brain

### 3. Don't Overthink Organization
- Capture first, organize later
- Use inboxes liberally
- Process during dedicated review time

### 4. Link Liberally
- Connect related concepts
- Build your knowledge graph
- Use bidirectional links

### 5. Regular Reviews
- Daily: Process inboxes
- Weekly: Full review and organization
- Monthly: Archive and cleanup

## 🚀 Getting Started (First Week)

### Day 1-2: Setup
```bash
# 1. Familiarize yourself with the wizard
make gtd-wizard
# Explore all options

# 2. Create your first atomic note
zet "My first atomic idea"

# 3. Create your first GTD project
make gtd-wizard
# Choose: 4 (Projects) → 1 (Create)
```

### Day 3-4: Practice Capture
```bash
# Capture everything that comes to mind
# Don't worry about organization yet
# Just get things into the system
```

### Day 5-7: Process and Organize
```bash
# 1. Process your inboxes
# 2. Link notes together
# 3. Create your first MOC
# 4. Do a weekly review
```

## 📚 Example: Complete Day

### Morning (8:00 AM)
```bash
# Check status
make gtd-wizard → 17 (Status)

# Capture morning thought
zet "Interesting idea about productivity"
```

### During Work (10:00 AM)
```bash
# Task comes up
make gtd-wizard → 1 (Capture) → 1 (Task)
# Enter: "Review quarterly report"
```

### Learning Break (2:00 PM)
```bash
# Learning something new
zet -z "New concept learned"
zet -z "Related concept"
# Link them in editor
```

### End of Day (5:00 PM)
```bash
# Process inboxes
make gtd-wizard → 22 (Zettelkasten) → 11 (Process inbox)
make gtd-wizard → 2 (Process GTD inbox)

# Daily log
make gtd-wizard → 15 (Log to daily log)
```

## 🎨 The Art of the System

Remember: **The system serves you, not the other way around.**

- **Capture liberally** - Get everything out of your head
- **Process regularly** - Don't let inboxes pile up
- **Organize thoughtfully** - But don't overthink it
- **Link meaningfully** - Build connections that matter
- **Review consistently** - Keep the system fresh

The magic happens when these systems work together:
- **Zettelkasten** captures and connects ideas
- **GTD** turns ideas into action
- **Second Brain** organizes and expresses knowledge

Together, they create a complete system for thinking, doing, and creating.

## 🔍 Troubleshooting

### "I have too many notes in my inbox"
→ Process more regularly. Set a daily reminder.

### "I don't know where to put something"
→ Put it in an inbox. Process it later. Don't overthink capture.

### "My notes aren't connected"
→ Use the discovery tools: `gtd-brain-discover connections`
→ Link notes during weekly review

### "I'm not using the system"
→ Start with just capture. Build the habit first.
→ Use the wizard - it guides you through everything.

## 🎉 Success Metrics

You'll know the system is working when:

1. ✅ Your inboxes are regularly processed
2. ✅ You can find information quickly
3. ✅ Ideas flow from capture to action
4. ✅ You're creating content from your notes
5. ✅ The system feels natural, not burdensome

Remember: **A good system is one you actually use.** Start simple, build complexity gradually, and let the system evolve with your needs.




