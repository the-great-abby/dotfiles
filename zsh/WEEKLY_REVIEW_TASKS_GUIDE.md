# Recommended Weekly Review Tasks

## 🎯 Overview

A weekly review is the cornerstone of GTD. It's your time to get clear, current, and creative. This guide provides a comprehensive checklist of recommended weekly review tasks.

## ⏱️ Time Commitment

**Recommended time:** 1-2 hours
**Best day:** Sunday morning or Friday afternoon
**Frequency:** Every week (non-negotiable!)

---

## 📋 Core Weekly Review Tasks

### Phase 1: Get Clear (15-20 minutes)

#### 1. **Process Your Inbox**
- **Task:** Process ALL inbox items to zero
- **Why:** Clear your mind and get everything into the system
- **How:**
  ```bash
  gtd-process --all
  ```
- **Questions to ask:**
  - What is it?
  - Is it actionable?
  - What's the next action?
  - Where does it belong?

#### 2. **Review Your Calendar**
- **Task:** Look at past week and upcoming week
- **Why:** See what happened and what's coming
- **What to check:**
  - Last week: What did I commit to? What actually happened?
  - This week: What's on my calendar? Any conflicts?
  - Next week: What's coming up? Any preparation needed?

#### 3. **Review Your Waiting For List**
- **Task:** Check all items you're waiting on from others
- **Why:** Follow up on commitments and unblock yourself
- **Actions:**
  - Check status of each waiting item
  - Send follow-up emails/calls if needed
  - Move items that are no longer waiting
  - Archive items that are resolved

#### 4. **Review Your Someday/Maybe List**
- **Task:** Review future possibilities
- **Why:** Activate items that are now relevant
- **Questions:**
  - What's ready to become a project?
  - What's no longer interesting?
  - What should be archived?

---

### Phase 2: Get Current (30-45 minutes)

#### 5. **Review All Active Projects**
- **Task:** Review every active project
- **Why:** Ensure each project has a next action
- **For each project:**
  - What's the current status?
  - What's the next action?
  - Is it still active?
  - Does it need to be on hold?
  - Should it be archived?

**How:**
```bash
gtd-project list
# Review each project
gtd-project view "project-name"
```

**Questions for each project:**
- What's the desired outcome?
- What's the next physical action?
- What's blocking progress?
- Is this still relevant?

#### 6. **Review All Active Tasks**
- **Task:** Review your task list
- **Why:** Ensure tasks are current and actionable
- **Actions:**
  - Review all active tasks
  - Update status (active/on-hold/done)
  - Add next actions for projects
  - Delete or archive completed tasks
  - Update contexts and priorities

**How:**
```bash
gtd-task list
# Review and update tasks
gtd-task update <task-id>
```

#### 7. **Review Areas of Responsibility**
- **Task:** Check each area of responsibility
- **Why:** Ensure all life areas get attention
- **For each area:**
  - Is it still relevant?
  - What needs attention?
  - Are standards being met?
  - Any new projects needed?

**How:**
```bash
gtd-area list
gtd-area review-all
```

**Questions for each area:**
- What's the current status?
- What needs attention this week?
- What's working well?
- What needs improvement?

#### 8. **Review Your Daily Logs**
- **Task:** Review the past week's daily logs
- **Why:** Capture insights and patterns
- **What to look for:**
  - Accomplishments
  - Patterns and trends
  - Insights and learnings
  - Items that need follow-up
  - Ideas for projects

**How:**
```bash
gtd-log view  # View today's log
# Review past week's logs
```

---

### Phase 3: Get Creative (15-20 minutes)

#### 9. **Review Your Second Brain**
- **Task:** Review Second Brain notes and connections
- **Why:** Discover insights and create content
- **Actions:**
  - Review notes that need refinement
  - Update MOCs (Maps of Content)
  - Look for connections between notes
  - Identify content to create (Express phase)
  - Archive old notes

**How:**
```bash
gtd-brain list
gtd-brain-moc list
gtd-brain-discover
```

#### 10. **Review Your Habits**
- **Task:** Check habit progress and streaks
- **Why:** Maintain consistency and adjust as needed
- **Actions:**
  - Review habit dashboard
  - Check streaks
  - Identify habits that need attention
  - Celebrate wins
  - Adjust habits if needed

**How:**
```bash
gtd-habit dashboard
gtd-habit list
```

#### 11. **Review Your Goals**
- **Task:** Check progress on short-term and long-term goals
- **Why:** Stay aligned with your vision
- **Questions:**
  - What progress did I make this week?
  - What goals need attention?
  - Are my goals still relevant?
  - What adjustments are needed?

#### 12. **Review Your Finances** (if applicable)
- **Task:** Quick financial check-in
- **Why:** Stay on top of financial health
- **Actions:**
  - Check account balances
  - Review recent transactions
  - Check upcoming bills
  - Review budget progress
  - Note any financial concerns

**How:**
```bash
# From wizard
make gtd-wizard → 6) Review → 3) Financial review → 1) Weekly
```

---

## 📊 Weekly Review Checklist

### Pre-Review Setup (5 minutes)
- [ ] Clear your workspace
- [ ] Gather all materials (calendar, notes, etc.)
- [ ] Set aside 1-2 hours of uninterrupted time
- [ ] Turn off distractions

### Phase 1: Get Clear (15-20 min)
- [ ] Process inbox to zero
- [ ] Review calendar (past week, this week, next week)
- [ ] Review Waiting For list
- [ ] Review Someday/Maybe list

### Phase 2: Get Current (30-45 min)
- [ ] Review all active projects
- [ ] Review all active tasks
- [ ] Review all areas of responsibility
- [ ] Review past week's daily logs
- [ ] Update next actions for all projects

### Phase 3: Get Creative (15-20 min)
- [ ] Review Second Brain notes
- [ ] Review habits and streaks
- [ ] Review goals and progress
- [ ] Review finances (if applicable)
- [ ] Brainstorm new ideas

### Post-Review (5 minutes)
- [ ] Save weekly review file
- [ ] Set priorities for next week
- [ ] Schedule important tasks
- [ ] Celebrate accomplishments

---

## 🎯 Essential Weekly Review Questions

### 1. Projects
- What projects need attention?
- What projects are stuck?
- What projects should be archived?
- What new projects should I start?

### 2. Tasks
- What tasks are overdue?
- What tasks are blocked?
- What tasks can I delete?
- What new tasks do I need?

### 3. Areas
- What areas need attention?
- Are all areas still relevant?
- What areas are doing well?
- What areas need improvement?

### 4. Calendar
- What's on my calendar for next week?
- What preparation do I need?
- Are there any conflicts?
- What commitments did I make?

### 5. Waiting For
- What am I waiting on?
- Should I follow up?
- Is anything overdue?
- Can I unblock anything?

### 6. Someday/Maybe
- What's ready to activate?
- What should be archived?
- What new ideas do I have?
- What's no longer interesting?

### 7. Second Brain
- What notes need refinement?
- What connections can I make?
- What content can I create?
- What MOCs need updating?

### 8. Habits
- How are my habits doing?
- What habits need attention?
- Are my habits still relevant?
- What new habits should I consider?

### 9. Goals
- What progress did I make?
- What goals need attention?
- Are my goals still relevant?
- What adjustments are needed?

### 10. Reflection
- What went well this week?
- What could have gone better?
- What did I learn?
- What am I grateful for?

---

## 🛠️ Tools and Commands

### GTD Commands for Weekly Review

```bash
# Process inbox
gtd-process --all

# Review projects
gtd-project list
gtd-project view "project-name"

# Review tasks
gtd-task list
gtd-task list --status=active
gtd-task list --overdue

# Review areas
gtd-area list
gtd-area review-all
gtd-area review "Area Name"

# Review daily logs
gtd-log view
gtd-log view "2025-11-30"

# Review habits
gtd-habit dashboard
gtd-habit list

# Review Second Brain
gtd-brain list
gtd-brain-moc list
gtd-brain-discover

# Financial review
make gtd-wizard → 6) Review → 3) Financial review

# Get advice
gtd-advise --all "Review my weekly review and give me strategic advice"
```

### From Wizard
```bash
make gtd-wizard
# Choose: 6) 📊 Review (daily/weekly)
# Then: 2) Weekly review
```

---

## 📝 Weekly Review Template

### Week of [Date]

#### Accomplishments This Week
- [ ] 
- [ ] 
- [ ] 

#### Projects Status
- **Active:** X projects
- **On Hold:** X projects
- **Completed:** X projects
- **New:** X projects

#### Areas Status
- [ ] Health & Wellness
- [ ] Finances
- [ ] Work & Career
- [ ] Relationships
- [ ] Personal Development
- [ ] Home & Living Space

#### Next Week Priorities
1. 
2. 
3. 

#### Blockers
- 
- 

#### Insights & Learnings
- 
- 

#### Gratitude
- 
- 

---

## 💡 Pro Tips for Weekly Review

### 1. **Make It Non-Negotiable**
- Schedule it like a meeting
- Same day, same time every week
- Protect this time
- Don't skip it!

### 2. **Start Fresh**
- Clear your workspace
- Turn off distractions
- Have all materials ready
- Set the right mindset

### 3. **Process to Zero**
- Get inbox to zero
- Review everything
- Don't skip steps
- Be thorough

### 4. **Be Honest**
- Acknowledge what's not working
- Celebrate what is working
- Be realistic about commitments
- Adjust as needed

### 5. **Use the System**
- Use GTD commands
- Save reviews to files
- Track in daily logs
- Update areas and projects

### 6. **Get Creative**
- Look for connections
- Brainstorm new ideas
- Review Second Brain
- Think strategically

### 7. **Set Next Week's Focus**
- Identify top priorities
- Schedule important tasks
- Plan your week
- Set intentions

### 8. **Celebrate Wins**
- Acknowledge accomplishments
- Review what went well
- Appreciate progress
- Stay motivated

---

## 🎯 Weekly Review Best Practices

### Timing
- **Best day:** Sunday morning (fresh start for the week)
- **Alternative:** Friday afternoon (wrap up the week)
- **Duration:** 1-2 hours
- **Frequency:** Every week, no exceptions

### Environment
- Quiet, distraction-free space
- All materials at hand
- Comfortable setting
- Good lighting

### Mindset
- Be present and focused
- Be honest with yourself
- Be kind to yourself
- Be strategic

### Process
- Follow the phases (Clear, Current, Creative)
- Don't skip steps
- Be thorough
- Take your time

### Follow-Through
- Save your review
- Set next week's priorities
- Schedule important tasks
- Follow up on commitments

---

## 📊 Weekly Review Metrics

Track these over time:

### System Health
- Inbox items processed
- Projects reviewed
- Tasks completed
- Areas maintained

### Personal Progress
- Goals progress
- Habits maintained
- Accomplishments
- Learnings

### System Usage
- Commands used
- Reviews completed
- Items processed
- Time spent

---

## 🔄 Integration with Your System

### Daily Logs
- Weekly reviews save to daily log
- Review past week's logs during review
- Capture insights in daily log

### Areas
- Review all areas during weekly review
- Update area status
- Add new areas if needed

### Projects
- Review all projects
- Update project status
- Add next actions
- Archive completed projects

### Second Brain
- Review Second Brain notes
- Update MOCs
- Create connections
- Express content

### Habits
- Review habit dashboard
- Check streaks
- Adjust habits
- Celebrate wins

---

## 🚀 Quick Start: Your First Weekly Review

### Step 1: Schedule It
- Pick a day and time
- Put it in your calendar
- Set a reminder

### Step 2: Prepare
- Clear your workspace
- Gather materials
- Set aside 1-2 hours

### Step 3: Run the Review
```bash
gtd-review weekly
```

### Step 4: Follow the Checklist
- Process inbox
- Review projects
- Review tasks
- Review areas
- Review habits
- Review goals

### Step 5: Set Next Week's Focus
- Identify priorities
- Schedule tasks
- Plan your week

---

## 📚 Additional Resources

### GTD Methodology
- "Getting Things Done" by David Allen
- GTD official website
- GTD Connect community

### Your System
- `gtd-review weekly` - Run weekly review
- `make gtd-wizard` - Interactive wizard
- `zsh/HOW_TO_USE_GTD_EFFECTIVELY.md` - Usage guide
- `zsh/AREA_REVIEW_GUIDE.md` - Area review guide
- `zsh/FINANCIAL_REVIEW_GUIDE.md` - Financial review guide

---

## 🎯 Next Steps

1. **Schedule your weekly review:**
   - Pick a day and time
   - Put it in your calendar
   - Set a reminder

2. **Run your first review:**
   ```bash
   gtd-review weekly
   ```

3. **Follow the checklist:**
   - Use this guide as reference
   - Don't skip steps
   - Be thorough

4. **Make it a habit:**
   - Same day, same time
   - Non-negotiable
   - Protect this time

Your weekly review is the foundation of GTD success! 📅✨

