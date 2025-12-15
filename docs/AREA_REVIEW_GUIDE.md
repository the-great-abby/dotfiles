# Area Review Guide - Keeping Your Areas Relevant

## 🎯 Overview

Areas of Responsibility need regular review to ensure they're still relevant to your life. This guide explains how to review areas, identify ones to archive, and add new ones as needed.

## 🔄 When to Review Areas

### Weekly Review
- Quick check: Are areas still relevant?
- What needs attention this week?
- Any new areas needed?

### Monthly Review
- Comprehensive review of all areas
- Check if areas should be archived
- Identify new areas to add
- Review standards and goals

### Quarterly Review
- Major area audit
- Archive inactive areas
- Merge overlapping areas
- Refine area definitions

## 📋 Review Questions for Each Area

### 1. Is it still relevant?
- Does this area still matter to my life?
- Is it something I need to maintain?
- Has my life changed in ways that affect this?

### 2. Does it need regular attention?
- Do I actively work on this area?
- Is it something I think about regularly?
- Does it require ongoing maintenance?

### 3. Are standards being met?
- Am I meeting my standards for this area?
- Do my standards need adjustment?
- What's working well? What's not?

### 4. Should it be archived or merged?
- Is this area no longer active?
- Does it overlap with another area?
- Should it be combined with something else?

## 🛠️ How to Review Areas

### Quick Review (Weekly)
```bash
# During weekly review
gtd-review weekly
# Answer question 6 about areas
# Optionally review areas interactively
```

### Comprehensive Review (Monthly)
```bash
# Review all areas systematically
gtd-area review-all

# Or review individual area
gtd-area review "Health & Wellness"
```

### Review from Wizard
```bash
make gtd-wizard
# Choose: 5) 🎯 Manage areas of responsibility
# Then: 6) Review areas
```

## 📊 What Gets Reviewed

### For Each Area:
1. **Relevance Check**
   - Is it still important?
   - Does it need regular attention?

2. **Status Review**
   - Current status (active/on-hold/archived)
   - Last review date
   - Related projects and tasks

3. **Performance Check**
   - Are standards being met?
   - What's working well?
   - What needs improvement?

4. **Action Items**
   - What needs attention?
   - Any new projects needed?
   - Standards to adjust?

## 🗑️ When to Archive Areas

Archive an area when:
- It's no longer relevant to your life
- You haven't worked on it in months
- It's been replaced by another area
- Your life circumstances have changed

### Archive an Area
```bash
gtd-area archive "Area Name"
```

This will:
- Change status to "archived"
- Move to archive directory (if configured)
- Preserve history and reviews

## 🔀 When to Merge Areas

Merge areas when:
- They overlap significantly
- They cover similar responsibilities
- You want to simplify your system
- One area has become part of another

### Manual Merge Process
1. Review both areas
2. Decide which area to keep
3. Move projects/tasks to the kept area
4. Archive the merged area
5. Update references

## ➕ When to Add New Areas

Add a new area when:
- A new ongoing responsibility emerges
- You realize something needs regular attention
- Life circumstances change (new job, relationship, etc.)
- You want to track something systematically

### Add New Area
```bash
# Create custom area
gtd-area create "New Area Name"

# Or use starter wizard
gtd-area-starter
```

## 🔄 Review Process

### Step 1: List All Areas
```bash
gtd-area list
```

### Step 2: Review Each Area
```bash
# Review all areas
gtd-area review-all

# Or review individually
gtd-area review "Area Name"
```

### Step 3: Take Action
- Archive irrelevant areas
- Merge overlapping areas
- Update standards
- Add new areas

### Step 4: Update Related Items
- Move projects to appropriate areas
- Update tasks with new area assignments
- Update Second Brain links

## 📝 Review Checklist

### Weekly Review
- [ ] Quick check: Are all areas still relevant?
- [ ] What areas need attention this week?
- [ ] Any new areas emerging?

### Monthly Review
- [ ] Review all areas systematically
- [ ] Check if any should be archived
- [ ] Identify areas to merge
- [ ] Review standards for each area
- [ ] Check related projects and tasks
- [ ] Consider new areas to add

### Quarterly Review
- [ ] Comprehensive area audit
- [ ] Archive inactive areas
- [ ] Merge overlapping areas
- [ ] Refine area definitions
- [ ] Update area standards
- [ ] Review area structure

## 💡 Pro Tips

### 1. **Regular Reviews Prevent Drift**
- Review areas monthly to keep them relevant
- Don't let areas become stale
- Archive what's no longer needed

### 2. **Be Honest About Relevance**
- If you haven't thought about an area in months, archive it
- Don't keep areas "just in case"
- Focus on what actually matters

### 3. **Start Small, Grow Gradually**
- Begin with 5-7 areas
- Add new areas as needed
- Archive areas that no longer fit

### 4. **Review Standards Regularly**
- Are your standards realistic?
- Do they need adjustment?
- Are they helping or hindering?

### 5. **Link Reviews to Projects**
- Areas spawn projects when needed
- Review projects during area review
- Keep areas and projects aligned

## 🎯 Example Review Session

```bash
# Start comprehensive review
$ gtd-area review-all

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Comprehensive Area Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Reviewing 6 area(s) of responsibility...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 Health & Wellness
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: active
Last reviewed: 2025-11-23

Related items:
  • Projects: 2
  • Tasks: 5

1. Is this area still relevant to your life? (y/n/archive)
   y

2. How is this area doing? (good/needs-attention/excellent)
   good

3. Any updates needed? (y/n)
   n

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📂 Old Hobby Area
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status: active
Last reviewed: Never

Related items:
  • Projects: 0
  • Tasks: 0

1. Is this area still relevant to your life? (y/n/archive)
   archive

   → Marked for archiving

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Review Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Areas to archive:
  • Old Hobby Area

Archive these areas now? (y/n) y
✓ Archived: old-hobby-area

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🆕 New Areas
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Are there new areas of responsibility you need to add?
  (y/n): y

Options:
  1) Use starter areas wizard (recommended)
  2) Create custom area

Choose (1/2): 1
[Starter wizard opens...]

✓ Area review complete!
```

## 🚀 Quick Commands

```bash
# Review all areas
gtd-area review-all

# Review specific area
gtd-area review "Health & Wellness"

# List all areas
gtd-area list

# Archive an area
gtd-area archive "Area Name"

# Create new area
gtd-area create "New Area Name"

# Use starter wizard
gtd-area-starter
```

## 📅 Review Schedule

### Recommended Schedule:
- **Weekly**: Quick check during weekly review
- **Monthly**: Comprehensive review of all areas
- **Quarterly**: Major audit and cleanup

### Integration with Weekly Review:
The weekly review now includes:
1. List of all areas with status
2. Option to review areas interactively
3. Question about new areas to add
4. Integration with area review system

## 🎯 Next Steps

1. **Set up review schedule:**
   - Add to weekly review routine
   - Schedule monthly comprehensive review
   - Plan quarterly audit

2. **Start reviewing:**
   ```bash
   gtd-area review-all
   ```

3. **Take action:**
   - Archive irrelevant areas
   - Add new areas as needed
   - Update standards

4. **Maintain regularly:**
   - Review during weekly review
   - Keep areas relevant
   - Adjust as life changes

Your areas should evolve with your life! 🎯✨

