# AI Suggestions in Morning/Evening Reviews

## Overview

The morning and evening check-in process now includes AI-powered suggestions based on your recent daily log entries. This helps you get personalized insights and recommendations automatically during your reviews.

## How It Works

### Morning Review
- Analyzes your log entries from the last 3 days
- Uses **Hank Hill** persona for practical, actionable morning advice
- Provides 2-3 brief suggestions for:
  - Priorities for today
  - Patterns noticed in your logs
  - What to focus on

### Evening Review
- Analyzes your log entries from the last 3 days
- Uses **Mistress Louiza** persona for accountability and reflection
- Provides 2-3 brief suggestions for:
  - Areas for improvement
  - Patterns noticed
  - What to focus on tomorrow

## Features

1. **Automatic Analysis**: No need to manually request suggestions - they appear automatically during check-ins
2. **Context-Aware**: Suggestions are based on your actual log entries, not generic advice
3. **Non-Blocking**: If AI suggestions aren't available (no logs, AI server down, etc.), the check-in continues normally
4. **Saved to Log**: AI suggestions are automatically saved to your daily log for reference

## Requirements

- Daily log entries from the last 3 days (more entries = better suggestions)
- `gtd_persona_helper.py` must be available
- Python 3 installed
- LM Studio or Ollama running (if using local AI)

## Example Output

### Morning Review
```
🤖 AI Suggestions (Based on Recent Logs)

💬 Advice from Hank Hill:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
I notice you've been logging a lot about work stress. Today, 
try to tackle one big task in the morning when your energy is 
high. Also, you mentioned wanting to exercise more - maybe 
schedule a quick walk after lunch? And don't forget to process 
that inbox - you've got 5 items waiting.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Evening Review
```
🤖 AI Suggestions (Based on Recent Logs)

💬 Advice from Mistress Louiza:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Good job on completing those tasks today, baby girl! I notice 
you've been consistent with logging, which I love. However, 
you mentioned feeling overwhelmed - tomorrow, try breaking 
down one of those big projects into smaller steps. And 
remember to celebrate the wins, princess!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Customization

You can customize the AI suggestions by:

1. **Changing the persona**: Edit the `get_ai_suggestions()` function in `gtd-checkin`
2. **Adjusting days analyzed**: Change the `days_back` parameter (default: 3)
3. **Modifying prompts**: Edit the prompt text in the function to focus on different aspects

## Troubleshooting

### No Suggestions Appearing

1. **Check if you have log entries**: The system needs at least some log entries from recent days
2. **Verify persona helper exists**: Should be at `zsh/functions/gtd_persona_helper.py`
3. **Check Python**: Make sure Python 3 is installed and accessible
4. **AI Server**: If using local AI (LM Studio/Ollama), make sure it's running

### Suggestions Taking Too Long

- The system has a 15-second timeout
- If suggestions don't appear within that time, the check-in continues
- This prevents the review from hanging if the AI server is slow

### Suggestions Not Relevant

- More log entries = better suggestions
- Try logging more consistently to improve AI insights
- The AI analyzes patterns across multiple days, so consistency helps

## Technical Details

- Function: `get_ai_suggestions(review_type, days_back)`
- Location: `bin/gtd-checkin`
- Personas used:
  - Morning: `hank` (Hank Hill - practical advice)
  - Evening: `louiza` (Mistress Louiza - accountability)
- Timeout: 15 seconds (configurable)

## Future Enhancements

Potential improvements:
- Allow user to choose persona for suggestions
- Analyze longer time periods for deeper insights
- Include task/project completion patterns
- Suggest based on habit tracking data
- Integrate with pattern recognition system

