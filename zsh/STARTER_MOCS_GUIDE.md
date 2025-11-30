# Important Maps of Content (MOCs) to Get Started

## 🗺️ What Are MOCs?

Maps of Content (MOCs) are index notes that organize related notes by topic. Think of them as a table of contents for your knowledge base.

## 🎯 Top 10 Starter MOCs

### 1. **Areas of Responsibility MOC**
**Why:** Organize notes by your life areas (Health, Finance, Relationships, etc.)

**What to include:**
- Health & Wellness notes
- Financial planning notes
- Relationship notes
- Home management notes
- Personal development notes

**Create it:**
```bash
gtd-brain-moc create "Areas of Responsibility"
```

### 2. **Active Projects MOC**
**Why:** Track all your current projects in one place

**What to include:**
- Project notes
- Project planning documents
- Related resources
- Project checklists

**Create it:**
```bash
gtd-brain-moc create "Active Projects"
```

### 3. **Learning & Study MOC**
**Why:** Organize all your learning materials (especially for Kubernetes/CKA!)

**What to include:**
- Course notes
- Book notes
- Article notes
- Study plans
- Practice exercises

**Create it:**
```bash
gtd-brain-moc create "Learning & Study"
```

### 4. **Health & Wellness MOC**
**Why:** Track workouts, nutrition, medication, and health goals

**What to include:**
- Workout logs
- Nutrition notes
- Medication tracking
- Health goals
- Wellness resources

**Create it:**
```bash
gtd-brain-moc create "Health & Wellness"
```

### 5. **Kubernetes/CKA Learning MOC**
**Why:** Centralize all your Kubernetes learning (you're studying for CKA!)

**What to include:**
- Kubernetes concepts
- CKA exam prep
- Practice labs
- Study notes
- Reference materials

**Create it:**
```bash
gtd-brain-moc create "Kubernetes Learning"
```

### 6. **GTD System MOC**
**Why:** Document your GTD workflows and best practices

**What to include:**
- GTD workflows
- Processing notes
- Review templates
- System improvements
- Productivity insights

**Create it:**
```bash
gtd-brain-moc create "GTD System"
```

### 7. **Work/Career MOC**
**Why:** Organize professional development and work-related notes

**What to include:**
- Career goals
- Skill development
- Work projects
- Professional resources
- Networking notes

**Create it:**
```bash
gtd-brain-moc create "Work & Career"
```

### 8. **Daily Reflections MOC**
**Why:** Connect daily notes and extract insights over time

**What to include:**
- Daily notes (from daily logs)
- Weekly reflections
- Monthly reviews
- Patterns and insights

**Create it:**
```bash
gtd-brain-moc create "Daily Reflections"
```

### 9. **Resources & References MOC**
**Why:** Organize useful resources you want to reference later

**What to include:**
- Articles
- Videos
- Tools
- Templates
- Cheat sheets

**Create it:**
```bash
gtd-brain-moc create "Resources & References"
```

### 10. **Ideas & Someday/Maybe MOC**
**Why:** Capture ideas and future possibilities

**What to include:**
- Future project ideas
- Someday/maybe items
- Inspiration
- Brainstorming notes

**Create it:**
```bash
gtd-brain-moc create "Ideas & Someday/Maybe"
```

## 🚀 Quick Start: Create Your First 5 MOCs

Run these commands to create the most essential MOCs:

```bash
# Core MOCs
gtd-brain-moc create "Areas of Responsibility"
gtd-brain-moc create "Active Projects"
gtd-brain-moc create "Learning & Study"

# Personal MOCs
gtd-brain-moc create "Health & Wellness"
gtd-brain-moc create "Daily Reflections"
```

## 📋 MOC Organization Strategies

### By Life Area (PARA Method)
- **Projects MOC** - All active projects
- **Areas MOC** - Ongoing responsibilities
- **Resources MOC** - Reference materials
- **Archives MOC** - Completed items

### By Topic
- **Kubernetes Learning MOC**
- **Health & Wellness MOC**
- **Work & Career MOC**
- **Personal Development MOC**

### By Time
- **Daily Reflections MOC**
- **Weekly Review MOC**
- **Monthly Goals MOC**

### By Purpose
- **GTD System MOC** - How you use GTD
- **Resources & References MOC** - Useful stuff
- **Ideas & Someday/Maybe MOC** - Future possibilities

## 💡 How to Use MOCs

### 1. Create the MOC
```bash
gtd-brain-moc create "Topic Name"
```

### 2. Add Notes Manually
```bash
gtd-brain-moc add "Topic Name" ~/Documents/obsidian/Second\ Brain/Resources/note.md
```

### 3. Auto-Populate from Tags
```bash
gtd-brain-moc auto "Topic Name" #health
```

### 4. View the MOC
```bash
gtd-brain-moc view "Topic Name"
```

### 5. Update Regularly
- Add new notes as you create them
- Remove notes that are no longer relevant
- Review during weekly review

## 🎯 Recommended MOC Structure

### For Each MOC, Include:

1. **Overview** - What this MOC is about
2. **Main Sections** - Organized by subtopic
3. **Links** - Links to related notes
4. **Tags** - Relevant tags
5. **Last Updated** - When you last reviewed it

### Example MOC Structure:

```markdown
# Health & Wellness MOC

## Overview
This MOC organizes all notes related to health, fitness, nutrition, and wellness.

## Workouts
- [[Kettlebell Workout Routine]]
- [[Morning Run Schedule]]
- [[Weight Lifting Program]]

## Nutrition
- [[Meal Planning]]
- [[Healthy Recipes]]
- [[Nutrition Guidelines]]

## Medication
- [[Medication Schedule]]
- [[Pill Tracking]]

## Goals
- [[Health Goals 2025]]
- [[Fitness Progress]]

## Related MOCs
- [[Daily Reflections]] - Daily health tracking
- [[Areas of Responsibility]] - Health area

Last Updated: 2025-11-30
```

## 🔄 MOC Maintenance

### Weekly Review
- Add new notes to relevant MOCs
- Remove notes that are no longer relevant
- Update MOC structure if needed

### Monthly Review
- Review all MOCs
- Consolidate similar MOCs
- Archive old MOCs if needed

## 🎓 Learning Path: Building Your MOC System

### Week 1: Core MOCs
1. Create "Areas of Responsibility" MOC
2. Create "Active Projects" MOC
3. Add 3-5 notes to each

### Week 2: Personal MOCs
1. Create "Health & Wellness" MOC
2. Create "Daily Reflections" MOC
3. Link daily notes to MOCs

### Week 3: Learning MOCs
1. Create "Learning & Study" MOC
2. Create "Kubernetes Learning" MOC
3. Add study notes

### Week 4: System MOCs
1. Create "GTD System" MOC
2. Create "Resources & References" MOC
3. Document your workflows

## 💡 Pro Tips

1. **Start Small** - Create 3-5 MOCs first, then expand
2. **Be Specific** - Better to have many focused MOCs than few broad ones
3. **Link Liberally** - Connect notes across MOCs
4. **Review Regularly** - Update MOCs during weekly review
5. **Use Tags** - Auto-populate MOCs from tags
6. **Keep It Simple** - Don't over-organize

## 🚀 Quick Commands Reference

```bash
# Create MOC
gtd-brain-moc create "Topic"

# Add note to MOC
gtd-brain-moc add "Topic" <note-path>

# Auto-populate from tags
gtd-brain-moc auto "Topic" <tag>

# View MOC
gtd-brain-moc view "Topic"

# List all MOCs
gtd-brain-moc list

# Remove note from MOC
gtd-brain-moc remove "Topic" <note-path>

# Delete MOC
gtd-brain-moc delete "Topic"
```

## 📊 Your Current Setup

Based on your GTD system, here are MOCs that would be most valuable:

1. **Areas of Responsibility** - You have areas defined
2. **Active Projects** - You have projects tracked
3. **Kubernetes Learning** - You're studying for CKA
4. **Health & Wellness** - You track workouts, pills, nutrition
5. **Daily Reflections** - You have daily logs that sync to Second Brain
6. **GTD System** - Document your workflows

## 🎯 Next Steps

1. **Create your first MOC:**
   ```bash
   gtd-brain-moc create "Areas of Responsibility"
   ```

2. **Add notes to it:**
   ```bash
   gtd-brain-moc add "Areas of Responsibility" <note-path>
   ```

3. **View it:**
   ```bash
   gtd-brain-moc view "Areas of Responsibility"
   ```

4. **Create more MOCs as needed!**

Happy MOC building! 🗺️✨

