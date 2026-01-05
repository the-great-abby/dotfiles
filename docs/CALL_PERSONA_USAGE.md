# `call_persona()` Usage Locations

This document lists all places in the codebase that use `call_persona()` (via `gtd_persona_helper.py`).

## Summary

- **Total locations:** ~20+ files
- **Model used:** `gemma3:1b` (chat model) - unless using `gtd_persona_helper_deep.py`
- **Tool support:** ✅ Yes (when using Ollama Controller and `enable_gtd_tools=True`)

## Shell Scripts (Direct Calls)

These scripts call `gtd_persona_helper.py` directly:

1. **`bin/gtd-advise`** - Main interactive advice command
   - Uses: Interactive persona advice with optional web search
   - Context: User-initiated advice requests

2. **`bin/gtd-checkin`** - Check-in reminders with persona advice
   - Uses: Persona advice for check-in prompts
   - Context: Scheduled check-ins

3. **`bin/gtd-review`** - Review workflows
   - Uses: Persona advice during reviews
   - Context: Task/project reviews

4. **`bin/gtd-kingmaker-advise`** - Pathfinder Kingmaker character advice
   - Uses: Special persona for game character advice
   - Context: Game-specific advice

5. **`bin/gtd-learn`** - Learning assistant
   - Uses: Persona advice for learning questions
   - Context: Learning workflows

6. **`bin/gtd-learn-kubernetes`** - Kubernetes learning assistant
   - Uses: Technical persona for K8s questions
   - Context: Kubernetes learning

7. **`bin/gtd-learn-greek`** - Greek language learning
   - Uses: Language learning persona
   - Context: Greek language learning

8. **`bin/gtd-generate-checkin-suggestions`** - Generate check-in suggestions
   - Uses: Persona for generating suggestions
   - Context: Scheduled check-ins

9. **`bin/gtd-advice-worker`** - Advice worker wrapper
   - Uses: Helper script (may use persona helper)
   - Context: Background worker

10. **`bin/gtd-suggest-badges`** - Badge suggestion generator
    - Uses: Persona for badge suggestions
    - Context: Gamification system

11. **`bin/gtd-milestone-celebration`** - Milestone celebrations
    - Uses: Celebratory persona messages
    - Context: Achievement milestones

12. **`bin/gtd-weekly-progress`** - Weekly progress reports
    - Uses: Persona for progress summaries
    - Context: Weekly reviews

13. **`bin/gtd-weekly-reminder`** - Weekly reminders
    - Uses: Persona for reminder messages
    - Context: Scheduled weekly reminders
    - **Note:** Still uses regular `gtd_persona_helper.py` (not deep version)

14. **`bin/gtd-scan-insights`** - Scan insights generator
    - Uses: Persona for insights
    - Context: Data analysis

15. **`bin/gtd-diagram`** - Diagram generation
    - Uses: Persona for diagram descriptions
    - Context: Visualizations

16. **`bin/gtd-brain-suggest-connections`** - Brain connection suggestions
    - Uses: Persona for connection suggestions
    - Context: Knowledge graph

## Zsh Functions

17. **`zsh/zshrc_mac_mise`** - `addInfoToDailyLog()` function
    - **Status:** ✅ **CHANGED** - Now uses `gtd_persona_helper_deep.py`
    - Uses: Persona advice when adding log entries
    - Context: Daily log entries
    - **Also contains:** Kettlebell coach, Maxfit coach (still use regular version)

## Python Code (Function Imports)

18. **`mcp/gtd_mcp_server.py`** - MCP server
    - Function: `call_persona()` import
    - Uses: Extract suggestions from analysis
    - Context: MCP server tool calls
    - Line: ~520

19. **`mcp/gtd_smart_suggestions.py`** - Smart suggestions
    - Function: `call_persona()` import  
    - Uses: Suggest projects for tasks
    - Context: Task processing
    - Line: ~362

## Which Should Use Deep Model?

Based on usage patterns, these might benefit from using `gtd_persona_helper_deep.py`:

### High Priority (Tool Support Needed)
- ✅ **`zsh/zshrc_mac_mise`** (`addInfoToDailyLog`) - **DONE**
- ⚠️ **`bin/gtd-advise`** - Interactive advice (could benefit from tools)
- ⚠️ **`bin/gtd-review`** - Reviews might need task/project access
- ⚠️ **`bin/gtd-checkin`** - Check-ins might need task access
- ⚠️ **`mcp/gtd_mcp_server.py`** - MCP server (might need tools)
- ⚠️ **`mcp/gtd_smart_suggestions.py`** - Project suggestions (might need tools)

### Medium Priority (Might Benefit)
- ⚠️ **`bin/gtd-weekly-progress`** - Progress reports might need data access
- ⚠️ **`bin/gtd-suggest-badges`** - Badge suggestions might need data
- ⚠️ **`bin/gtd-brain-suggest-connections`** - Connections might need data

### Low Priority (Probably Fine as Is)
- ✅ Scheduled reminders - **ALREADY CHANGED** to use deep model
- Learning assistants (`gtd-learn*`) - Simple Q&A, tools probably not needed
- Celebration scripts (`gtd-milestone-celebration`) - Simple messages
- Special coaches (kettlebell, maxfit) - Simple workout generation

## Notes

- Most scripts use the **chat model** (`gemma3:1b`) by default
- Only `gtd_persona_helper_deep.py` uses the **deep model** (`qwen3:4b`)
- Tool support requires Ollama Controller and `enable_gtd_tools=True` (or automatic detection)
- Deep model is better for:
  - Complex reasoning
  - Tool usage
  - Long-form responses
  - Data analysis
  
- Chat model is fine for:
  - Quick responses
  - Simple Q&A
  - Short messages
  - Celebratory content
