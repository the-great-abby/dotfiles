# System Decision Tree: What Goes Where?

## 🎯 Quick Decision Guide

### When You Have Something to Capture

```
┌─────────────────────────────────────┐
│  Something comes to mind...         │
└──────────────┬──────────────────────┘
               │
               ▼
    ┌──────────────────────┐
    │ Is it actionable?   │
    └──┬───────────────┬──┘
       │               │
      YES              NO
       │               │
       ▼               ▼
┌─────────────┐  ┌──────────────────┐
│ Single task?│  │ Atomic idea/      │
└──┬──────┬──┘  │ concept?          │
   │      │     └──┬─────────────┬──┘
  YES     NO       │             │
   │      │        YES            NO
   │      │         │             │
   │      │         ▼             ▼
   │      │    ┌─────────┐  ┌──────────┐
   │      │    │ Zettel-  │  │ Reference│
   │      │    │ kasten   │  │ material │
   │      │    │ (zet)    │  │          │
   │      │    └─────────┘  └─────┬────┘
   │      │                        │
   │      │                        ▼
   │      │                   ┌──────────┐
   │      │                   │ GTD      │
   │      │                   │ Capture  │
   │      │                   │ → Second │
   │      │                   │   Brain  │
   │      │                   └──────────┘
   │      │
   │      ▼
   │ ┌──────────┐
   │ │ GTD      │
   │ │ Project  │
   │ └──────────┘
   │
   ▼
┌──────────┐
│ GTD      │
│ Capture  │
│ (task)   │
└──────────┘
```

## 📝 Practical Examples

### Example 1: Learning Something New

**Scenario**: Learning about Kubernetes

```
1. Capture atomic concepts as you learn:
   zet -z "Kubernetes Pods"
   zet -z "Kubernetes Services"
   
2. Link them together (edit notes):
   In "Pods" note: [[Kubernetes Services]]
   
3. Create Second Brain resource:
   gtd-brain create "Kubernetes Learning" Resources
   
4. Link atomic notes to resource:
   zet-link link <pods-note> Resources/kubernetes-learning.md
   
5. Create GTD project if actionable:
   gtd-project create "Learn Kubernetes"
   
6. Create tasks from learning:
   gtd-task add "Practice kubectl commands"
```

### Example 2: Project Work

**Scenario**: Building a new feature

```
1. Capture ideas:
   zet "Feature idea A"
   zet "Technical approach"
   
2. Create GTD project:
   gtd-project create "New Feature"
   
3. Sync to Second Brain:
   gtd-brain-sync projects
   
4. Link ideas to project:
   zet-link link <idea-a> Projects/new-feature.md
   
5. Create tasks:
   gtd-task add "Design API" --project="New Feature"
```

### Example 3: Quick Thought

**Scenario**: Random idea pops up

```
Just capture it quickly:
zet "Random idea"

Process later during review time.
Don't overthink it!
```

## 🔄 The Flow

### Capture → Process → Organize → Act

```
CAPTURE (All Systems)
    │
    ├─→ GTD Inbox (tasks, projects)
    ├─→ Zettelkasten Inbox (ideas)
    └─→ Second Brain (references)
    
PROCESS (Daily/Weekly)
    │
    ├─→ GTD: Create tasks/projects
    ├─→ Zettelkasten: Organize notes
    └─→ Second Brain: Link and organize
    
ORGANIZE (Second Brain)
    │
    ├─→ PARA method
    ├─→ MOCs
    └─→ Progressive summarization
    
ACT (GTD)
    │
    └─→ Complete tasks
        └─→ Update projects
            └─→ Archive when done
```

## 🎯 When to Use What

### Use Zettelkasten When:
- ✅ You have an atomic idea (one concept)
- ✅ You want to build knowledge connections
- ✅ You're learning something new
- ✅ You're brainstorming
- ✅ You want to capture a fleeting thought

### Use GTD When:
- ✅ You have something actionable
- ✅ You need to track tasks
- ✅ You're managing projects
- ✅ You need to get things done
- ✅ You want to organize by context/energy

### Use Second Brain When:
- ✅ You have reference material
- ✅ You want to organize by PARA
- ✅ You're building knowledge over time
- ✅ You want to create content
- ✅ You need progressive summarization

## 💡 The Golden Rules

1. **Capture First, Organize Later**
   - Don't think about where it goes
   - Just get it into an inbox
   - Process during review time

2. **One System, Multiple Layers**
   - They're not separate systems
   - They're different views of the same information
   - Use the right tool for the job

3. **Link Everything**
   - Connect atomic notes to larger concepts
   - Link ideas to projects
   - Build your knowledge graph

4. **Process Regularly**
   - Daily: Quick inbox processing
   - Weekly: Full review and organization
   - Monthly: Archive and cleanup

5. **Trust the System**
   - If it's not captured, it doesn't exist
   - The system remembers, you don't have to
   - Review regularly to stay on top

## 🚀 Quick Start Decision

**New to the system? Start here:**

```
1. Capture everything to inboxes
   - Ideas → zet
   - Tasks → gtd-capture
   - References → gtd-capture

2. Process once a day
   - Use the wizard: make gtd-wizard
   - Process inboxes
   - Don't overthink organization

3. Review weekly
   - Full weekly review
   - Link notes together
   - Organize properly

4. Build complexity gradually
   - Add features as you need them
   - Don't try to use everything at once
```

## 🎨 The Art of the System

**Remember**: The system should feel natural, not burdensome.

- If you're not using it, simplify
- If it's too complex, remove features
- If it's working, keep doing what you're doing
- The best system is the one you actually use



