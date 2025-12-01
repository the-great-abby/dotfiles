# Wedding & Marriage Planning & Tracking Guide

## 🎯 Overview

Getting married is a major life event that requires planning, organization, and ongoing attention. This guide helps you track everything you need for your wedding and build the foundation for a successful marriage.

---

## 📋 Essential Areas of Focus for Getting Married

### 1. **Wedding Planning** (Project)
**Why:** This is a time-bound project with a clear outcome.

**What to track:**
- Budget and expenses
- Venue selection and booking
- Vendor selection (caterer, photographer, florist, etc.)
- Guest list and invitations
- Timeline and deadlines
- Dress/attire
- Ceremony details
- Reception planning
- Honeymoon planning

**Create it:**
```bash
gtd-project create "Plan Our Wedding" --area="Relationships"
```

### 2. **Relationships** (Area - Enhanced)
**Why:** Marriage requires ongoing relationship maintenance.

**What to track:**
- Date nights
- Communication
- Quality time together
- Relationship goals
- Conflict resolution
- Shared activities
- Intimacy and connection

**Enhance existing:**
```bash
gtd-area view "Relationships"
# Add marriage-specific standards
```

### 3. **Finances** (Area - Enhanced)
**Why:** Marriage changes your financial situation significantly.

**What to track:**
- Combined budget
- Joint accounts
- Individual accounts
- Debt management
- Savings goals (wedding, house, etc.)
- Financial goals as a couple
- Tax implications
- Insurance updates
- Estate planning

**Enhance existing:**
```bash
gtd-area view "Finances"
# Add marriage-specific financial goals
```

### 4. **Legal & Administrative** (Area - New or Enhanced)
**Why:** Marriage requires legal and administrative updates.

**What to track:**
- Marriage license
- Name change (if applicable)
- Will and estate planning
- Power of attorney
- Beneficiary updates
- Insurance updates (health, life, auto)
- Tax filing status
- Social Security updates
- Driver's license/ID updates
- Bank account updates
- Credit card updates
- Employer benefits updates

**Create it:**
```bash
gtd-area create "Legal & Administrative"
```

### 5. **Home & Living Space** (Area - Enhanced)
**Why:** You may be combining households or moving.

**What to track:**
- Moving/relocation (if applicable)
- Combining households
- Home organization
- Shared responsibilities
- Home improvements
- Decorating together
- Creating shared spaces

**Enhance existing:**
```bash
gtd-area view "Home & Living Space"
# Add marriage-specific home goals
```

### 6. **Family & Extended Family** (Area - New or Enhanced)
**Why:** Marriage connects two families.

**What to track:**
- In-law relationships
- Family traditions
- Family events
- Holiday planning
- Family communication
- Blending families
- Family boundaries

**Create or enhance:**
```bash
gtd-area create "Family & Extended Family"
# Or enhance existing Relationships area
```

### 7. **Health & Wellness** (Area - Enhanced)
**Why:** You may be combining health insurance and care.

**What to track:**
- Health insurance updates
- Combined health goals
- Exercise together
- Meal planning together
- Health check-ups
- Mental health support

**Enhance existing:**
```bash
gtd-area view "Health & Wellness"
# Add couple health goals
```

---

## 💒 Wedding Planning: What to Track

### Phase 1: Initial Planning (6-12 months before)

#### Budget & Finances
- Total wedding budget
- Who's contributing (you, partner, family)
- Payment schedule
- Expense tracking
- Contingency fund

**Track in GTD:**
```bash
# Create budget project
gtd-project create "Wedding Budget Planning" --area="Finances"

# Track expenses
addInfoToDailyLog "Wedding: Booked venue, $5000 deposit (Finances)"
```

#### Venue & Date
- Venue options
- Availability
- Date selection
- Backup dates
- Contract details

**Track in GTD:**
```bash
gtd-task add "Research wedding venues" --area="Relationships"
gtd-task add "Tour top 3 venues" --area="Relationships"
gtd-task add "Book venue and date" --area="Relationships"
```

#### Guest List
- Initial guest list
- Family requirements
- Friend list
- Plus-ones policy
- Final count

**Track in Second Brain:**
```bash
gtd-brain create "Wedding Guest List" Resources
```

### Phase 2: Vendor Selection (4-8 months before)

#### Key Vendors
- Photographer
- Videographer
- Caterer
- Florist
- DJ/Band
- Officiant
- Baker (cake)
- Transportation
- Hair & Makeup
- Coordinator/Planner

**Track in GTD:**
```bash
# Create vendor project
gtd-project create "Select Wedding Vendors" --area="Relationships"

# Track each vendor
gtd-task add "Research photographers" --area="Relationships"
gtd-task add "Interview top 3 photographers" --area="Relationships"
gtd-task add "Book photographer" --area="Relationships"
```

**Track in Second Brain:**
```bash
# Create vendor comparison note
gtd-brain create "Vendor Comparison - Photographers" Resources
```

### Phase 3: Details & Logistics (2-6 months before)

#### Attire
- Wedding dress/suit
- Alterations
- Accessories
- Shoes
- Undergarments
- Hair & makeup trial

**Track in GTD:**
```bash
gtd-task add "Shop for wedding dress" --area="Relationships"
gtd-task add "Schedule dress alterations" --area="Relationships"
```

#### Invitations
- Design selection
- Ordering
- Addressing
- Mailing
- RSVP tracking

**Track in GTD:**
```bash
gtd-task add "Order invitations" --area="Relationships"
gtd-task add "Address invitations" --area="Relationships"
gtd-task add "Mail invitations" --area="Relationships"
gtd-task add "Track RSVPs" --area="Relationships"
```

#### Ceremony Details
- Vows
- Readings
- Music
- Processional order
- Recessional
- Unity ceremony (if any)

**Track in Second Brain:**
```bash
gtd-brain create "Wedding Ceremony Details" Resources
```

#### Reception Details
- Seating chart
- Menu selection
- Bar options
- Music playlist
- Toasts
- First dance
- Cake cutting

**Track in Second Brain:**
```bash
gtd-brain create "Wedding Reception Details" Resources
```

### Phase 4: Final Preparations (1-2 months before)

#### Final Details
- Final guest count
- Final vendor confirmations
- Timeline creation
- Day-of schedule
- Emergency contacts
- Backup plans

**Track in GTD:**
```bash
gtd-task add "Confirm final guest count" --area="Relationships"
gtd-task add "Create day-of timeline" --area="Relationships"
gtd-task add "Confirm all vendors" --area="Relationships"
```

#### Legal Requirements
- Marriage license application
- Required documents
- License pickup
- Officiant confirmation

**Track in GTD:**
```bash
gtd-task add "Apply for marriage license" --area="Legal & Administrative"
gtd-task add "Pick up marriage license" --area="Legal & Administrative"
```

### Phase 5: Honeymoon Planning

#### Honeymoon Details
- Destination selection
- Booking (flights, hotel, activities)
- Budget
- Packing list
- Travel documents
- Travel insurance

**Track in GTD:**
```bash
gtd-project create "Plan Honeymoon" --area="Relationships"
gtd-task add "Research honeymoon destinations" --area="Relationships"
gtd-task add "Book flights and hotel" --area="Relationships"
```

---

## 💑 Post-Wedding: What to Track

### Immediate (First Month)

#### Legal & Administrative Updates
- Update Social Security (if name change)
- Update driver's license/ID
- Update bank accounts
- Update credit cards
- Update insurance (health, auto, life)
- Update employer benefits
- Update tax filing status
- Update will/estate planning

**Track in GTD:**
```bash
# Create post-wedding admin project
gtd-project create "Post-Wedding Administrative Updates" --area="Legal & Administrative"

# Add tasks
gtd-task add "Update Social Security card" --area="Legal & Administrative"
gtd-task add "Update driver's license" --area="Legal & Administrative"
gtd-task add "Update bank accounts" --area="Legal & Administrative"
gtd-task add "Update health insurance" --area="Legal & Administrative"
gtd-task add "Update life insurance beneficiaries" --area="Legal & Administrative"
gtd-task add "Update will/estate planning" --area="Legal & Administrative"
```

#### Financial Integration
- Combine or coordinate finances
- Set up joint accounts (if desired)
- Update budget
- Set financial goals together
- Review debt together
- Plan savings together

**Track in GTD:**
```bash
# Create financial integration project
gtd-project create "Combine Finances" --area="Finances"

# Add tasks
gtd-task add "Discuss financial goals" --area="Finances"
gtd-task add "Set up joint accounts" --area="Finances"
gtd-task add "Create combined budget" --area="Finances"
```

### Ongoing (First Year & Beyond)

#### Relationship Maintenance
- Regular date nights
- Communication check-ins
- Shared goals
- Conflict resolution
- Quality time
- Intimacy and connection

**Track in GTD:**
```bash
# Create relationship habits
gtd-habit create "Weekly date night" --frequency="weekly" --area="Relationships"
gtd-habit create "Monthly relationship check-in" --frequency="monthly" --area="Relationships"

# Track in daily logs
addInfoToDailyLog "Date night: Dinner and movie with Louiza (Relationships)"
```

#### Home & Living Together
- Shared responsibilities
- Home organization
- Decorating together
- Creating routines
- Managing household tasks

**Track in GTD:**
```bash
# Create shared home habits
gtd-habit create "Weekly home organization" --frequency="weekly" --area="Home & Living Space"
gtd-habit create "Monthly home improvement discussion" --frequency="monthly" --area="Home & Living Space"
```

#### Family Integration
- In-law relationships
- Family traditions
- Holiday planning
- Family boundaries
- Blending families

**Track in GTD:**
```bash
# Track family activities
addInfoToDailyLog "Dinner with Louiza's family (Family & Extended Family)"
```

---

## 📝 Wedding Planning Template

### Wedding Planning Note Template

```markdown
# Wedding Planning - [Date]

---
tags:
  - wedding
  - planning
  - marriage
date: [YYYY-MM-DD]
status: [planning/in-progress/completed]
---

## Budget
- **Total Budget**: $[amount]
- **Spent So Far**: $[amount]
- **Remaining**: $[amount]
- **Contingency**: $[amount]

## Key Details
- **Date**: [YYYY-MM-DD]
- **Venue**: [Name]
- **Guest Count**: [number]
- **Theme/Style**: [description]

## Vendors
- **Photographer**: [Name/Status]
- **Caterer**: [Name/Status]
- **Florist**: [Name/Status]
- **DJ/Band**: [Name/Status]
- **Officiant**: [Name/Status]

## Timeline
- [ ] 6-12 months: Initial planning
- [ ] 4-8 months: Vendor selection
- [ ] 2-6 months: Details & logistics
- [ ] 1-2 months: Final preparations
- [ ] Day of: Wedding day

## Notes
[Additional planning notes]

## Links
- [[Wedding Guest List]]
- [[Wedding Budget]]
- [[Vendor Comparison]]
```

---

## 🗺️ Organizing Wedding Information

### MOC Structure

Create a MOC for wedding planning:

```bash
gtd-brain-moc create "Wedding Planning"
```

**MOC Sections:**
- Budget & Finances
- Venue & Date
- Vendors
- Guest List
- Ceremony Details
- Reception Details
- Attire
- Honeymoon
- Legal & Administrative
- Timeline

### PARA Method Organization

**Projects:**
- Plan Our Wedding
- Post-Wedding Administrative Updates
- Combine Finances
- Plan Honeymoon

**Areas:**
- Relationships (enhanced)
- Finances (enhanced)
- Legal & Administrative (new or enhanced)
- Home & Living Space (enhanced)
- Family & Extended Family (new or enhanced)

**Resources:**
- Wedding planning notes
- Vendor comparisons
- Guest list
- Budget tracking
- Timeline
- Legal documents

**Archives:**
- Completed wedding planning
- Old vendor quotes
- Historical budget versions

---

## 🎯 Key Areas to Focus On

### 1. **Communication**
- Regular check-ins about planning
- Discuss expectations
- Share concerns
- Make decisions together

**Track:**
```bash
addInfoToDailyLog "Wedding planning discussion: Venue selection (Relationships)"
```

### 2. **Budget Management**
- Track all expenses
- Stay within budget
- Plan for unexpected costs
- Discuss financial priorities

**Track:**
```bash
# Create budget tracking project
gtd-project create "Wedding Budget Tracking" --area="Finances"

# Track expenses
addInfoToDailyLog "Wedding expense: Photographer deposit $1000 (Finances)"
```

### 3. **Timeline Management**
- Create master timeline
- Set deadlines
- Track progress
- Adjust as needed

**Track:**
```bash
# Create timeline project
gtd-project create "Wedding Timeline" --area="Relationships"

# Add deadline tasks
gtd-task add "Book photographer by [date]" --area="Relationships" --deadline="[date]"
```

### 4. **Vendor Management**
- Research thoroughly
- Compare options
- Read contracts carefully
- Maintain relationships

**Track in Second Brain:**
```bash
gtd-brain create "Vendor - Photographer" Resources
gtd-brain create "Vendor Comparison - Photographers" Resources
```

### 5. **Guest Management**
- Maintain guest list
- Track RSVPs
- Plan seating
- Accommodations

**Track in Second Brain:**
```bash
gtd-brain create "Wedding Guest List" Resources
gtd-brain create "RSVP Tracking" Resources
```

---

## 💡 Pro Tips

### 1. **Start Early**
- Begin planning 6-12 months before
- Book vendors early
- Give yourself buffer time

### 2. **Stay Organized**
- Use your GTD system
- Create projects for major phases
- Track everything in one place

### 3. **Communicate Regularly**
- Weekly planning meetings
- Discuss decisions together
- Share concerns openly

### 4. **Budget Realistically**
- Plan for unexpected costs
- Track all expenses
- Have a contingency fund

### 5. **Delegate When Possible**
- Ask for help
- Use wedding planner if needed
- Don't do everything yourself

### 6. **Take Breaks**
- Don't let planning consume you
- Maintain other areas of life
- Enjoy the process

### 7. **Document Everything**
- Keep contracts
- Save receipts
- Track decisions
- Note what worked/didn't

---

## 🚀 Quick Start Setup

### 1. Create Wedding Planning Structure

```bash
# Create main wedding project
gtd-project create "Plan Our Wedding" --area="Relationships"

# Create sub-projects
gtd-project create "Wedding Budget Planning" --area="Finances"
gtd-project create "Select Wedding Vendors" --area="Relationships"
gtd-project create "Post-Wedding Administrative Updates" --area="Legal & Administrative"
```

### 2. Create MOC

```bash
gtd-brain-moc create "Wedding Planning"
```

### 3. Create Key Notes

```bash
# Budget tracking
gtd-brain create "Wedding Budget" Resources

# Guest list
gtd-brain create "Wedding Guest List" Resources

# Vendor tracking
gtd-brain create "Vendor Comparison" Resources

# Timeline
gtd-brain create "Wedding Timeline" Resources
```

### 4. Set Up Areas

```bash
# Enhance existing areas
gtd-area view "Relationships"
gtd-area view "Finances"

# Create new areas if needed
gtd-area create "Legal & Administrative"
gtd-area create "Family & Extended Family"
```

### 5. Create Review Habits

```bash
# Weekly wedding planning check-in
gtd-habit create "Weekly wedding planning meeting" --frequency="weekly" --area="Relationships"

# Monthly budget review
gtd-habit create "Monthly wedding budget review" --frequency="monthly" --area="Finances"
```

---

## 📊 Integration with Reviews

### Weekly Review
- Review wedding planning progress
- Check budget status
- Update timeline
- Discuss with partner

### Monthly Review
- Review overall progress
- Assess budget
- Adjust timeline if needed
- Celebrate milestones

### Quarterly Review
- Review relationship goals
- Assess financial goals
- Review family integration
- Plan ahead

---

## 🎯 Post-Wedding Focus Areas

### First 3 Months
- Complete administrative updates
- Combine finances
- Establish routines
- Adjust to married life

### First Year
- Build relationship habits
- Set shared goals
- Create traditions
- Establish boundaries

### Ongoing
- Maintain relationship
- Review goals together
- Grow together
- Support each other

---

## 📚 Additional Resources

### Your GTD System
- `gtd-project create "Plan Our Wedding"` - Main wedding project
- `gtd-area create "Legal & Administrative"` - Legal updates
- `gtd-brain-moc create "Wedding Planning"` - Organize planning
- `gtd-review weekly` - Weekly planning check-ins

### Guides
- `zsh/FINANCIAL_REVIEW_GUIDE.md` - Financial planning
- `zsh/AREA_REVIEW_GUIDE.md` - Area maintenance
- `zsh/RELATIONSHIPS_GUIDE.md` - Relationship maintenance (if exists)

---

## 🎉 Your Wedding Planning System is Ready!

You now have a complete system for:
- ✅ Wedding planning (project-based)
- ✅ Post-wedding administrative tasks
- ✅ Financial integration
- ✅ Relationship maintenance
- ✅ Family integration
- ✅ Legal and administrative updates

Start planning your wedding today! 💒✨


