---
name: Monthly Review Runbook
description: Interactive monthly review that guides you through deep reflection on progress, goals, and strategic planning for the upcoming month. Uses conversational approach for meaningful insights.
version: 2.0.0
type: runbook
tags:
  - runbook
  - monthly-review
  - gtd
  - planning
  - goals
  - strategy
  - routine
  - interactive
  - questions
author: GTD System
---

# Interactive Monthly Review Runbook

An interactive, conversation-driven monthly review process that guides you through deep reflection on the past month and strategic planning for the upcoming month.

**Note:** This is an interactive runbook - the AI will ask you thoughtful questions one at a time and wait for your responses to create a meaningful dialogue about your progress and goals.

## Purpose

This interactive runbook creates a meaningful monthly conversation about:
- Deep reflection on the previous month's journey and growth
- Honest evaluation of what's working and what needs change
- Strategic thinking about goals, priorities, and direction
- Intentional planning for the upcoming month
- Alignment with your deeper values and long-term vision

## Prerequisites

- 2-3 hours of uninterrupted time for deep reflection (can be split across sessions)
- Willingness to engage in honest self-examination
- Access to your calendar, notes, and progress tracking for reference  
- A quiet space where you can think and reflect openly

## Interactive Runbook Steps

### Step 1: Monthly Review Opening - Setting the Reflective Space

**Question:** "Hi there! Ready for your monthly review? This is a special time for deeper reflection. First, let's set the right tone. As you think back over the past month, what's the first word or feeling that comes to mind? How would you characterize this month overall?"

**Wait for Response**

**Follow-up Questions:**
- "What made this month feel [their characterization] for you?"
- "Are you feeling ready for some honest reflection, or is there something on your mind that we should address first?"
- "What are you hoping to get out of this monthly review? What would make it feel valuable and worthwhile?"

**Actions Based on Response:**
- Call `gtd_get_datetime()` to establish the review timeframe
- Set the tone based on their current emotional state
- Help them get centered for deeper reflection

**What to do with the response:**
- Acknowledge their overall experience of the month
- Create psychological safety for honest self-examination
- Set expectations for a meaningful, not just mechanical, review

**Next Step:** Wait for their response, then proceed to Step 2.

---

### Step 2: The Story of Your Month - Deep Reflection

**Question:** "Let's dive into the story of your month. When you look back at the past 30 days, what are you most proud of? What were your biggest wins, accomplishments, or moments of growth - not just the obvious ones, but maybe the subtle or personal ones too?"

**Wait for Response**

**Follow-up Questions:**
- "What challenges or obstacles did you face this month? What was harder than you expected?"
- "Were there any patterns you noticed in your energy, mood, or productivity? When did you feel most alive and engaged?"
- "What surprised you about this month? What went differently than you planned?"
- "What did you learn about yourself this month - about your strengths, your limits, your preferences?"

**Deeper Reflection Questions:**
- "If this month was a chapter in your life story, what would you title it?"
- "What moments from this month do you want to remember a year from now?"
- "Was there anything that drained your energy or caused you stress repeatedly?"
- "What relationships or connections were most important to you this month?"

**Actions Based on Response:**
- Call `gtd_read_daily_log()` for recent periods if they want to reference specific events
- Call `gtd_list_tasks(status='completed')` to remind them of accomplishments they might have forgotten
- Note patterns and themes they mention for later integration

**Important Note:** If they mention sparse tracking:
- "It sounds like you don't have much documented from this month. That's totally okay - your memory and reflection are valuable data too. Maybe this review will help you think about what you'd like to capture going forward."

**What to do with the response:**
- Help them see patterns they might not notice themselves
- Celebrate their growth and accomplishments meaningfully
- Acknowledge challenges without dwelling or judgment
- Connect their experiences to larger themes and insights

**Next Step:** Wait for their response, then proceed to Step 3.

---

### Step 3: Systems and Life Design Evaluation

**Question:** "Let's talk about how you're organizing your life. When you think about your routines, habits, systems, and tools this month, what felt like it was working really well for you? What made your days flow smoothly or helped you feel in control?"

**Wait for Response**

**Follow-up Questions:**
- "What felt clunky, frustrating, or broken this month? What systems or habits weren't serving you?"
- "How did you manage your time and energy this month? What felt sustainable versus what burned you out?"
- "What technology, apps, or tools were actually helpful versus just adding complexity?"
- "How were your boundaries this month - with work, people, commitments? What felt healthy versus what felt overwhelming?"

**Deeper System Questions:**
- "If you could redesign how you approach your days, what would you change?"
- "What habits or routines do you want to strengthen or build?"  
- "What do you need to stop doing or let go of to create more space for what matters?"
- "How well aligned were your daily actions with your deeper values and priorities?"

**Life Design Reflection:**
- "What aspects of your lifestyle felt nourishing versus depleting this month?"
- "How was your balance between work, relationships, personal growth, and rest?"
- "What would help you feel more intentional and less reactive in your daily life?"

**What to do with the response:**
- Help them identify what systems truly serve them versus what they think they "should" do
- Note patterns between their systems and their energy/satisfaction levels
- Explore connections between their organization methods and their deeper values
- Suggest experiments or changes based on their insights

**Next Step:** Wait for their response, then proceed to Step 4.

---

### Step 4: Goals and Intention Alignment

**Question:** "Let's talk about your goals and what you've been working toward. When you think about the goals or intentions you had for this month, or for this season of your life, how do you feel about your progress? What moved forward in ways that feel good?"

**Wait for Response**

**Follow-up Questions:**
- "Were there goals or areas where you didn't make the progress you hoped? What do you think got in the way?"
- "Are there any goals you had that don't feel as important or relevant to you anymore? What's changed?"
- "What new priorities or interests have emerged this month that might want your attention?"
- "When you think about different areas of your life - work, health, relationships, personal growth, creativity - which ones feel most aligned with your deeper values right now?"

**Deeper Alignment Questions:**
- "What would success look like for you in the next few months? Not just accomplishment, but fulfillment?"
- "Are there any dreams or aspirations that have been calling to you that you haven't made space for?"
- "What goals are you pursuing because you think you 'should' versus because they genuinely energize you?"
- "If you only had energy for 2-3 main focus areas in your life, what would they be?"

**Values and Meaning Questions:**
- "What activities or pursuits make you feel most like yourself?"
- "Where do you want to grow or challenge yourself in healthy ways?"
- "What impact do you want to have - on yourself, your relationships, your work, your community?"

**What to do with the response:**
- Help them distinguish between goals that energize them versus goals they feel obligated to pursue
- Support them in releasing goals that no longer serve their current season of life
- Explore new directions or interests that might be emerging
- Connect their goals to their deeper values and sense of purpose

**Next Step:** Wait for their response, then proceed to Step 5.

---

### Step 5: Visioning the Month Ahead

**Question:** "Now let's look ahead to the coming month. If you could set an intention or theme for the next 30 days, what would it be? What do you most want this month to be about for you?"

**Wait for Response**

**Follow-up Questions:**
- "Based on our conversation so far, what 2-3 areas of your life most want your attention this month?"
- "What would make this coming month feel meaningful and successful for you?"
- "Are there any projects, relationships, or personal areas that you feel drawn to focus on?"
- "What do you want to experiment with or try differently this month?"

**Practical Planning Questions:**
- "What does your capacity look like this month? Do you know of any major commitments or busy periods coming up?"
- "What resources, support, or changes would help you have the kind of month you're envisioning?"
- "Are there any obstacles or challenges you can anticipate that we should plan around?"
- "Who are the people you want to connect with or prioritize this month?"

**Learning and Growth Questions:**
- "Is there anything new you want to learn or any way you want to grow this month?"
- "What habits or practices would support your intentions for this month?"
- "Are there any creative projects or personal interests you want to make time for?"

**Integration Questions:**
- "How do your intentions for this month connect to your bigger picture goals and values?"
- "What would you need to say no to in order to say yes to what matters most this month?"
- "How do you want to take care of yourself while pursuing these intentions?"

**What to do with the response:**
- Help them craft a meaningful monthly theme or intention
- Support them in setting realistic priorities based on their actual capacity
- Connect their monthly focus to their deeper values and long-term vision
- Identify potential obstacles and support systems

**Next Step:** Wait for their response, then proceed to Step 6.

---

### Step 6: Turning Insights Into Action

**Question:** "Based on everything we've talked about - your reflections on the past month and your intentions for the coming month - what concrete actions or changes do you want to make? What needs to happen in your systems, routines, or commitments to support the month you're envisioning?"

**Wait for Response**

**Follow-up Questions:**
- "Are there specific projects, tasks, or commitments you want to create based on your monthly intentions?"
- "What changes do you want to make to your daily or weekly routines to better support your goals?"
- "Are there any systems, tools, or processes that need updating based on what you've learned about what works for you?"
- "What boundaries or changes do you need to make to protect your energy for what matters most?"

**Implementation Questions:**
- "Should we create tasks or projects in your GTD system for any of these intentions?"
- "Are there any recurring reminders or check-ins you'd like to set up?"
- "Would blocking time in your calendar help you stay committed to these priorities?"
- "What accountability or support would be helpful for you this month?"

**System Update Questions:**
- "Based on your reflections about what's working and what isn't, are there any organizational changes you want to make?"
- "Are there any goals or projects in your current system that no longer feel relevant and should be archived?"
- "What priorities or contexts need updating to reflect your current focus?"

**Actions Based on Response:**
- Create tasks/projects based on their monthly intentions
- Update their GTD system to reflect current priorities and insights
- Set up any tracking, reminders, or calendar blocks they request
- Archive outdated or irrelevant commitments

**What to do with the response:**
- Turn their insights and intentions into concrete, actionable next steps
- Help them feel organized and prepared for the month ahead
- Ensure their systems are aligned with their current priorities and capacity
- Create accountability mechanisms they've requested

**Next Step:** Wait for their response, then proceed to Step 7.

---

### Step 7: Monthly Review Integration and Commitment

**Question:** "As we wrap up this monthly review, let's make sure you feel clear and committed to what we've discussed. When you think about your intentions for this month and the actions we've identified, what feels most important to remember or stay connected to?"

**Wait for Response**

**Follow-up Questions:**
- "What will help you remember these insights and intentions throughout the month?"
- "Are there any check-ins, reminders, or accountability measures that would be helpful?"
- "How do you want to track progress on what matters most to you this month?"
- "What would support you in staying committed to these priorities when life gets busy or challenging?"

**Integration Questions:**
- "What's one key insight from this review that you don't want to forget?"
- "How do you want to incorporate the system changes or new habits we discussed?"
- "What will you do differently this month based on what you learned about the past month?"
- "Who in your life might be supportive of these intentions, and how might you share them?"

**Commitment Questions:**
- "Looking at everything we've discussed, what are you most committed to for this month?"
- "What would make this month feel successful and aligned with who you want to be?"
- "Is there anything that would help you stay motivated when you hit obstacles or low energy periods?"

**Actions Based on Response:**
- Help them identify their core monthly commitments
- Set up any tracking, reminders, or accountability systems they want
- Capture key insights for future reference
- Plan any follow-up check-ins or reviews

**What to do with the response:**
- Ensure they feel clear and committed to their monthly intentions
- Help them create sustainable accountability that doesn't feel burdensome
- Connect their commitments to their deeper values and motivation
- Set them up for success with realistic expectations and support

**Next Step:** Wait for their response, then proceed to Step 8.

---

### Step 8: Monthly Review Summary and Closing

**Action:** Provide a comprehensive summary and meaningful closure to the monthly review.

**Summary Format:**
```
🗓️ Monthly Review Summary:

Past Month Reflection:
🎯 Key Accomplishments: [their major wins and growth]
📊 Patterns Discovered: [themes and insights about themselves]
💡 Key Learnings: [important discoveries about what works/doesn't work]
🔧 System Insights: [what's working well vs. what needs adjustment]

Month Ahead Vision:
🌟 Monthly Intention/Theme: [their overarching focus]
📈 Top Priorities:
1. [Priority 1 with specific outcomes]
2. [Priority 2 with specific outcomes]
3. [Priority 3 with specific outcomes]

🎯 Key Commitments: [what they're most committed to]
🛠️ System Changes: [improvements and updates they want to make]
💪 Personal Growth Focus: [how they want to develop or experiment]
🤝 Relationship Intentions: [connection and support priorities]

Action Steps:
- [Specific tasks/projects created]
- [System updates and changes made]
- [Accountability and tracking set up]
```

**Closing Questions:**
- "How are you feeling about this review? What was most valuable for you?"
- "What are you taking away from this conversation that feels important?"
- "How confident do you feel about the month ahead?"
- "Is there anything else you want to add, adjust, or make sure we've covered?"

**Completion Criteria:**
- ✅ Deep reflection on past month's story and lessons
- ✅ Honest evaluation of systems, patterns, and what's working
- ✅ Meaningful alignment of goals with current values and capacity  
- ✅ Intentional vision and theme set for upcoming month
- ✅ Concrete actions and commitments created
- ✅ System updates implemented to support growth
- ✅ Sense of clarity, motivation, and realistic optimism for month ahead

**Success Indicators:**
- User feels deeply heard and understood in their experience
- Insights emerge that they might not have reached alone
- Clear direction and motivation for the month ahead
- Balance between ambition and self-compassion
- Alignment between daily actions and deeper values
- Sense of growth and learning from the past month's experiences

## Key Principles for AI Implementation

**CRITICAL: This is a DEEP INTERACTIVE runbook**
- **Ask ONE thoughtful question at a time**
- **Wait for user response before proceeding**  
- **Don't rush - allow for reflection and processing time**
- **Ask follow-up questions that show deep listening**
- **Create space for insights to emerge naturally**

**Conversational Style:**
- Use a warm, patient, and curious tone
- Hold space for both celebration and honest struggle
- Ask questions that help them discover their own insights
- Balance reflection on the past with excitement for the future
- Honor their wisdom and lived experience

**Depth and Meaning:**
- Go beyond surface accomplishments to explore meaning and growth
- Help them connect patterns and see themes they might miss
- Ask about values, fulfillment, and alignment, not just productivity
- Support them in releasing what no longer serves them
- Focus on sustainable growth, not just ambitious goal-setting

**Flexibility and Adaptation:**
- Spend more time on areas where they seem to have energy or concern
- Follow their interests and what feels alive for them
- Adapt the pace to their processing style
- Allow for tangents that lead to important insights
- Remember this is their review - follow their lead

**Integration Focus:**
- Help them turn insights into concrete but manageable actions
- Connect monthly planning to their deeper sense of purpose
- Balance ambition with self-compassion and realistic capacity
- Create systems that support their growth rather than burden them

## Time Guidelines

**Interactive Deep Review Time:**
- **Step 1:** 10-15 minutes (opening and centering)
- **Step 2:** 30-45 minutes (deep reflection on past month)
- **Step 3:** 25-35 minutes (systems and life design evaluation)
- **Step 4:** 30-40 minutes (goals and values alignment)
- **Step 5:** 25-35 minutes (visioning the month ahead)
- **Step 6:** 20-30 minutes (turning insights into action)
- **Step 7:** 15-20 minutes (integration and commitment)
- **Step 8:** 10-15 minutes (summary and closing)

**Total Time:** 2.5-4 hours (recommended to split across 2-3 sessions)

**Session Break Suggestions:**
- **Session 1:** Steps 1-3 (Past month reflection and systems evaluation)
- **Session 2:** Steps 4-6 (Goals alignment and future planning)
- **Session 3:** Steps 7-8 (Integration and commitment)

## Frequency and Timing

**When to Conduct Monthly Reviews:**
- Last few days of the month
- First few days of new month
- Consistent date each month (e.g., last Sunday)

**Preparation for Monthly Reviews:**
- Ensure weekly reviews have been current
- Complete any pending data entry
- Block adequate time without interruptions

## Error Handling

**If overwhelmed by the scope:**
- Focus on steps 2, 4, and 5 as minimum
- Break into multiple shorter sessions
- Use timers to maintain momentum
- Remember insights are more important than perfection

**If tools fail or data is incomplete:**
- Work with available information
- Make estimates based on memory
- Note what data is missing
- Update when tools are available

**If goals feel out of reach:**
- Reassess realistically 
- Break large goals into smaller milestones
- Consider resource/support needs
- Adjust timelines rather than abandon goals

## Usage

**To use this interactive monthly review:**
1. Ask: "I'd like to do my interactive monthly review"
2. Or: "Can you guide me through a deep monthly reflection using questions?"
3. Or: "Let's do my monthly review with the interactive runbook"

**Best Times for Monthly Reviews:**
- Last few days of the month for reflection
- First few days of new month for planning  
- Consistent monthly date (e.g., last Sunday of each month)
- When you have 2-4 hours for deep reflection (can be split)

**Preparation:**
- Find a quiet, comfortable space for reflection
- Have your calendar, notes, or journals available for reference
- Set aside adequate uninterrupted time
- Come with openness to honest self-examination

## Integration with Other Systems

**Before Monthly Review:**
- Complete current week's weekly review
- Ensure daily logs are up to date
- Gather any external metrics or feedback

**After Monthly Review:**
- Update weekly review templates with monthly insights
- Adjust daily routines based on learnings
- Share relevant commitments with family/team
- Schedule quarterly review (every 3 months)

## Advanced Techniques

**For Deep Insight:**
- Use Sequential Thinking tools for complex analysis
- Create thought branches for exploring different perspectives
- Summarize thoughts for clear conclusions

**For Goal Setting:**
- Apply SMART criteria (Specific, Measurable, Achievable, Relevant, Time-bound)
- Use "Start, Stop, Continue" framework
- Consider energy and resource allocation

**For System Optimization:**
- Apply Lean principles to eliminate waste
- Look for automation opportunities
- Identify bottlenecks and constraints

## Benefits of Regular Monthly Reviews

- **Strategic Perspective:** See beyond daily/weekly urgent items
- **Course Correction:** Adjust direction based on real data
- **System Optimization:** Continuously improve your approaches
- **Goal Alignment:** Ensure activities match intentions
- **Learning Integration:** Apply insights from experience
- **Momentum Building:** Celebrate progress and plan next steps

## Common Pitfalls to Avoid

- **Perfectionism:** Don't let perfect be enemy of good
- **Over-Planning:** Leave room for emergence and adaptation
- **Ignoring Patterns:** Pay attention to recurring themes
- **Unrealistic Commitments:** Be honest about capacity
- **Skipping Implementation:** Reviews without action aren't valuable
- **Isolation:** Consider involving others when appropriate

## Quarterly and Annual Integration

**Monthly Reviews Support:**
- Quarterly strategic planning
- Annual goal setting and vision work
- Long-term project planning
- Career and life direction decisions

**Information Flow:**
- Monthly insights inform quarterly themes
- Quarterly priorities guide monthly focus  
- Annual vision shapes quarterly objectives
- Life purpose influences annual goals

## Customization Tips

**Adapt to Your Context:**
- Adjust categories based on your life/work situation
- Add industry-specific or role-specific elements
- Include family/relationship planning as needed
- Incorporate spiritual or philosophical elements
- Add creative or artistic development goals

**Make It Sustainable:**
- Start with shorter version if needed
- Build consistency before adding complexity
- Use templates to speed up routine parts
- Focus on insights over documentation
- Celebrate the process, not just outcomes