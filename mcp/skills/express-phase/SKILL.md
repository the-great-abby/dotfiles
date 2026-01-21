---
name: Express Phase - Content Creation
description: Guide through creating content from Second Brain notes. Transform knowledge into articles, blog posts, presentations, and other shareable content. Manages content pipeline from ideas to published content.
version: 1.0.0
tags:
  - second-brain
  - content
  - creation
  - express
  - writing
  - productivity
author: GTD System
---

# Express Phase - Content Creation Workflow

A comprehensive skill for creating content from your Second Brain notes. Transform your knowledge into articles, blog posts, presentations, reports, and other shareable content. Manages the content pipeline from ideas to published pieces.

## When to Use

Use this skill when you want to:
- **Create content from notes**: Transform knowledge into shareable content
- **Build content pipeline**: Manage ideas, drafts, and published content
- **Share knowledge**: Turn Second Brain into articles, posts, presentations
- **Express insights**: Communicate what you've learned
- **Create from multiple notes**: Combine notes into cohesive content
- **Track content ideas**: Capture and develop content ideas

## How It Works

The Express Phase uses your Second Brain notes as source material to create drafts, which can then be refined and published. It extracts summaries and insights from notes and combines them into new content.

## Step-by-Step Workflow

### Step 1: Identify Content Idea

**Purpose:** Determine what content you want to create.

**Actions:**
1. **Option A: Start with an idea**
   - Capture content idea: `gtd-brain-express idea "Description"`
   - Develop idea into content plan
   - Identify source notes

2. **Option B: Start with notes**
   - Identify notes that would make good content
   - Determine what content type fits
   - Plan how to combine notes

**Questions to ask:**
- What do I want to write/create?
- What notes contain relevant information?
- What type of content is this? (article, blog, presentation, report)
- Who is the audience?

**Commands:**
- `gtd-brain-express idea "Description"` - Capture content idea
- `gtd-brain list` - Browse notes for source material
- `gtd_search_second_brain(query="...")` - Find relevant notes

---

### Step 2: Identify Source Notes

**Purpose:** Find notes that will be source material for the content.

**Actions:**
1. Search for relevant notes:
   - Use `gtd_search_second_brain(query="topic")` to find notes
   - Review MOCs for topic-related notes
   - Browse notes by category
2. Review notes to determine relevance:
   - Do they contain information for the content?
   - Are they well-distilled (have summaries/insights)?
   - Do they fit the content theme?
3. Select 2-5 notes as source material (more can be overwhelming)

**MCP Tools:**
- `gtd_search_second_brain(query="...")` - Search for notes
- `gtd-brain-moc view "Topic"` - Review MOC for notes
- `gtd-brain list [category]` - Browse notes

**What to look for:**
- Notes with summaries (Level 2 distill)
- Notes with core insights (Level 3 distill)
- Evergreen notes (well-developed)
- Notes that complement each other

**Best practices:**
- Start with 2-3 notes, add more if needed
- Prefer distilled notes (have summaries/insights)
- Choose notes that complement each other
- Consider notes from different angles on the topic

---

### Step 3: Create Draft from Notes

**Purpose:** Generate initial draft from source notes.

**Actions:**
1. Create draft from selected notes:
   ```bash
   gtd-brain-express create "Title" "note1.md,note2.md,note3.md" <type>
   ```
2. Provide:
   - **Title**: What the content will be called
   - **Notes**: Comma-separated list of note paths
   - **Type**: article, blog, presentation, report (default: article)
3. Review the generated draft

**Commands:**
- `gtd-brain-express create "Title" "notes" <type>` - Create draft

**Content types:**
- **article**: Long-form article (default)
- **blog**: Blog post
- **presentation**: Presentation/slides
- **report**: Report or document

**What the tool does:**
- Extracts summaries from notes (if available)
- Extracts core insights (if available)
- Combines content from multiple notes
- Creates draft with sources listed
- Saves to `Express/drafts/` directory

**Example:**
```bash
gtd-brain-express create "GTD and Second Brain Integration Guide" \
  "gtd-notes.md,second-brain-notes.md,productivity-principles.md" article
```

---

### Step 4: Review and Refine Draft

**Purpose:** Improve the draft into publishable content.

**Actions:**
1. Read through the generated draft
2. Review extracted content:
   - Is it accurate?
   - Does it flow well?
   - Are key points included?
3. Add your own thoughts and insights:
   - Add connections between ideas
   - Add personal experiences
   - Add examples or case studies
   - Add conclusions or recommendations
4. Refine structure:
   - Organize sections logically
   - Add transitions
   - Improve flow
   - Add introduction and conclusion

**Draft structure:**
- Title
- Sources (links to original notes)
- Content (extracted from notes)
- Notes section (for your additions)
- Next Steps section

**What to add:**
- Your own insights and connections
- Examples and case studies
- Personal experiences
- Conclusions and recommendations
- Transitions between sections
- Introduction and conclusion

---

### Step 5: Develop Content Further (Optional)

**Purpose:** Enhance content with additional research or insights.

**Actions:**
1. **Add more source notes** if needed:
   - Search for additional relevant notes
   - Add content from new notes
   - Integrate into existing draft

2. **Research additional information**:
   - Use web search if needed
   - Add external references
   - Verify facts

3. **Enhance with diagrams**:
   - Use `diagram-generation` skill to create visuals
   - Add diagrams to illustrate concepts
   - Link diagrams in content

**Integration:**
- `gtd_search_second_brain(query="...")` - Find more notes
- `diagram-generation` skill - Create visuals
- Web search tools - Research additional info

---

### Step 6: Finalize Draft

**Purpose:** Prepare draft for publishing.

**Actions:**
1. Review complete draft:
   - Check for completeness
   - Verify accuracy
   - Ensure good flow
   - Check grammar and style
2. Add final touches:
   - Add metadata (tags, categories)
   - Add links to related content
   - Add call-to-action if appropriate
   - Format for target platform
3. Save final draft

**Final review checklist:**
- [ ] Content is complete
- [ ] Information is accurate
- [ ] Flow is logical
- [ ] Sources are credited
- [ ] Grammar and style are good
- [ ] Formatting is correct

---

### Step 7: Publish Content

**Purpose:** Move draft to published content.

**Actions:**
1. When draft is ready, publish it:
   ```bash
   gtd-brain-express publish <draft-path>
   ```
2. Review published content
3. Optionally:
   - Share the content
   - Link back to source notes
   - Update source notes with link to published content

**Commands:**
- `gtd-brain-express publish <draft-path>` - Publish draft

**What publishing does:**
- Moves draft from `Express/drafts/` to `Express/published/`
- Updates status to "published"
- Adds publication date
- Keeps source links

---

### Step 8: Manage Content Pipeline

**Purpose:** Track ideas, drafts, and published content.

**Actions:**
1. **List drafts:**
   ```bash
   gtd-brain-express drafts
   ```
2. **List published content:**
   ```bash
   gtd-brain-express published
   ```
3. **Review content pipeline:**
   - What ideas are waiting?
   - What drafts are in progress?
   - What content is published?
4. **Plan next content:**
   - Develop ideas into drafts
   - Work on in-progress drafts
   - Publish completed drafts

**Commands:**
- `gtd-brain-express drafts` - List all drafts
- `gtd-brain-express published` - List published content
- `gtd-brain-express idea "..."` - Capture new ideas

---

## Detailed Workflow Examples

### Example 1: Create Article from Multiple Notes

**Scenario:** You want to write an article combining insights from several productivity notes.

**Steps:**
1. **Identify idea:**
   ```bash
   gtd-brain-express idea "Write article about GTD and Second Brain integration"
   ```

2. **Find source notes:**
   ```bash
   gtd_search_second_brain(query="GTD")
   gtd_search_second_brain(query="Second Brain")
   ```
   - Found: `gtd-principles.md`, `second-brain-methodology.md`, `productivity-systems.md`

3. **Create draft:**
   ```bash
   gtd-brain-express create "GTD and Second Brain: A Complete Integration Guide" \
     "gtd-principles.md,second-brain-methodology.md,productivity-systems.md" article
   ```

4. **Review and refine:**
   - Read generated draft
   - Add personal insights
   - Add examples
   - Improve flow

5. **Add diagram:**
   - Use `diagram-generation` skill to create workflow diagram
   - Add diagram to article

6. **Publish:**
   ```bash
   gtd-brain-express publish drafts/gtd-and-second-brain-integration-guide.md
   ```

### Example 2: Create Blog Post from Single Note

**Scenario:** You have a well-distilled note that would make a good blog post.

**Steps:**
1. **Identify note:** `kubernetes-pods-explained.md` (has summary and core insights)

2. **Create draft:**
   ```bash
   gtd-brain-express create "Understanding Kubernetes Pods" \
     "kubernetes-pods-explained.md" blog
   ```

3. **Enhance draft:**
   - Add introduction
   - Add practical examples
   - Add conclusion
   - Add call-to-action

4. **Publish:**
   ```bash
   gtd-brain-express publish drafts/understanding-kubernetes-pods.md
   ```

### Example 3: Create Presentation from MOC

**Scenario:** You want to create a presentation from all notes in a MOC.

**Steps:**
1. **View MOC:**
   ```bash
   gtd-brain-moc view "Kubernetes Learning"
   ```

2. **Select key notes from MOC:**
   - `kubernetes-basics.md`
   - `pods-and-containers.md`
   - `deployments-and-services.md`
   - `networking.md`

3. **Create presentation draft:**
   ```bash
   gtd-brain-express create "Kubernetes Fundamentals" \
     "kubernetes-basics.md,pods-and-containers.md,deployments-and-services.md,networking.md" \
     presentation
   ```

4. **Organize as slides:**
   - Each note becomes a section/slide
   - Add transitions
   - Add visuals

5. **Publish:**
   ```bash
   gtd-brain-express publish drafts/kubernetes-fundamentals.md
   ```

---

## Best Practices

### Source Note Selection

**Choose notes that:**
- ✅ Are well-distilled (have summaries/insights)
- ✅ Complement each other
- ✅ Cover the topic comprehensively
- ✅ Are evergreen (timeless insights)

**Avoid:**
- ❌ Too many notes (overwhelming)
- ❌ Undistilled notes (too raw)
- ❌ Duplicate information
- ❌ Outdated notes

### Content Development

**When refining drafts:**
- Add your voice and perspective
- Connect ideas from different notes
- Add examples and case studies
- Add personal experiences
- Create logical flow

**Structure:**
- Introduction: Hook and overview
- Body: Main content from notes + your insights
- Conclusion: Summary and next steps
- Sources: Credit original notes

### Content Pipeline Management

**Maintain pipeline:**
- **Ideas**: Capture when they come to you
- **Drafts**: Work on 1-2 at a time
- **Published**: Track what you've shared
- **Review**: Regularly review pipeline

**Workflow:**
- Idea → Draft → Refine → Publish
- Don't let drafts sit too long
- Finish one before starting many
- Celebrate published content

### Content Types

**Article:**
- Long-form, comprehensive
- 1000+ words typically
- Deep dive into topic
- Multiple sources

**Blog:**
- Shorter, more casual
- 500-1000 words typically
- Single topic focus
- Quick to read

**Presentation:**
- Slide-based format
- Key points only
- Visual-friendly
- Audience-focused

**Report:**
- Structured document
- Data and analysis
- Formal tone
- Comprehensive

---

## Integration with Other Skills

This skill works well with:
- **`progressive-summarization`**: Use distilled notes as source material
- **`moc-creation`**: Use MOC notes for content
- **`diagram-generation`**: Add visuals to content
- **`evergreen-note-development`**: Use evergreen notes as sources
- **`knowledge-discovery`**: Find related notes for content

---

## Troubleshooting

### "Draft doesn't have enough content"

**Solutions:**
- Add more source notes
- Enhance with your own insights
- Research additional information
- Add examples and case studies

### "Content from notes doesn't flow well"

**Solutions:**
- Add transitions between sections
- Reorganize content logically
- Add your own connecting thoughts
- Create introduction and conclusion

### "I don't know what to write about"

**Solutions:**
- Review your MOCs for topics
- Look at your evergreen notes
- Review your learning notes
- Check your daily logs for ideas
- Use `gtd-brain-express idea` to capture ideas

### "I have too many drafts"

**Solutions:**
- Focus on finishing 1-2 drafts
- Archive or delete old drafts
- Prioritize drafts by importance
- Set deadline for each draft

---

## Success Criteria

Successful content creation:
- ✓ Draft created from source notes
- ✓ Content is well-structured and flows
- ✓ Your insights and voice are added
- ✓ Sources are credited
- ✓ Content is ready to publish
- ✓ Published content is tracked

---

## Commands Reference

### Content Creation
```bash
# Create draft from notes
gtd-brain-express create "Title" "note1.md,note2.md" [type]

# Create content idea
gtd-brain-express idea "Description"
```

### Content Management
```bash
# List drafts
gtd-brain-express drafts

# List published
gtd-brain-express published

# Publish draft
gtd-brain-express publish <draft-path>
```

### Finding Source Notes
```bash
# Search Second Brain
gtd_search_second_brain(query="topic")

# View MOC
gtd-brain-moc view "Topic"

# List notes
gtd-brain list [category]
```

---

## Workflow Summary

```
Express Phase - Content Creation Workflow
│
├─ 1. Identify Content Idea
│   ├─ gtd-brain-express idea "Description"
│   └─ Or start with notes
│
├─ 2. Identify Source Notes
│   ├─ gtd_search_second_brain(query="...")
│   ├─ gtd-brain-moc view "Topic"
│   └─ Select 2-5 relevant notes
│
├─ 3. Create Draft from Notes
│   └─ gtd-brain-express create "Title" "notes" <type>
│
├─ 4. Review and Refine Draft
│   ├─ Review extracted content
│   ├─ Add your insights
│   └─ Improve structure and flow
│
├─ 5. Develop Content Further (Optional)
│   ├─ Add more notes
│   ├─ Research additional info
│   └─ Add diagrams
│
├─ 6. Finalize Draft
│   ├─ Review completeness
│   ├─ Check accuracy
│   └─ Add final touches
│
├─ 7. Publish Content
│   └─ gtd-brain-express publish <draft-path>
│
└─ 8. Manage Content Pipeline
    ├─ gtd-brain-express drafts
    ├─ gtd-brain-express published
    └─ Plan next content
```

---

## Content Pipeline Stages

### 1. Ideas
- Capture with `gtd-brain-express idea`
- Develop into content plans
- Prioritize ideas

### 2. Drafts
- Create from notes
- Refine and develop
- Work toward completion

### 3. Published
- Finalized content
- Ready to share
- Tracked for reference

---

Remember: The Express Phase is about sharing your knowledge. Start with well-distilled notes, add your voice and insights, and create content that helps others. Don't aim for perfection - aim for sharing valuable knowledge.
