# David Goggins Keyword Fix

## Problem

David Goggins was being selected too frequently for non-fitness log entries. This was happening because his keyword pattern included very generic standalone words that match in non-fitness contexts:

- "run" / "running" - matches "run a script", "running a meeting"
- "training" - matches "training session" (work-related)
- "push" - matches "push code", "push changes"
- "hard" - matches "working hard", "hard problem"
- "discipline" - matches "work discipline", "self-discipline" (non-fitness)
- "tough" - matches "tough problem", "tough decision"
- "pain" - matches "pain point" (business context)
- "suffer" - can match non-fitness contexts

## Solution

Removed standalone generic words and replaced with fitness-specific terms and phrases. The keywords now focus on:

**Removed problematic standalone words:**
- "run", "running" (too generic)
- "training" (as standalone word - too generic)
- "push" (matches "push code")
- "hard" (matches "working hard")
- "discipline" (matches work contexts)
- "tough" (matches problem-solving contexts)
- "pain" (matches "pain point")
- "suffer" (can be generic)

**Kept/Added fitness-specific terms:**
- "workout", "exercise", "fitness", "gym"
- "weight", "lifting", "strength training"
- "cardio workout", "endurance workout"
- "mental toughness" (fitness context)
- "stay hard", "callous your mind" (Goggins-specific phrases)
- Fitness activities: "bench press", "squat", "deadlift"
- Fitness equipment: "barbell", "dumbbell", "kettlebell"
- Workout types: "HIIT", "crossfit", "powerlifting"
- Body parts: "leg day", "chest day", "back day"
- Fitness context phrases: "push your limits", "physical limits", "fitness goal"

**Old keywords:**
```
workout|exercise|fitness|training|cardio|strength|run|running|gym|weight|lifting|endurance|ultra|marathon|mental toughness|push|hard|stay hard|callous|suffer|pain|discipline|tough
```

**New keywords:**
```
workout|exercise|fitness|gym|weight|lifting|strength training|cardio workout|endurance workout|mental toughness|stay hard|callous your mind|who's gonna carry the boats|physical limits|body limits|ultramarathon|endurance training|leg day|chest day|back day|shoulder day|arm day|workout session|fitness training|gym session|lifting session|physical training|PT session|fitness motivation|push your limits|break through barriers|physical barriers|body building|muscle building|powerlifting|crossfit|HIIT|high intensity|fitness challenge|physical challenge|fitness goal|training goal|bench press|squat|deadlift|barbell|dumbbell|kettlebell|pull up|push up|fitness routine|exercise routine|workout routine|training program|fitness program|muscle|muscle group|reps|sets|personal trainer|fitness coach|gym workout|home workout|strength workout
```

## Key Changes

1. **Removed generic standalone words** that match non-fitness contexts
2. **Made phrases more specific** - "push your limits" instead of just "push"
3. **Added fitness-specific equipment and exercises** - "barbell", "squat", "bench press"
4. **Added workout type identifiers** - "HIIT", "crossfit", "powerlifting"
5. **Added body part workout days** - "leg day", "chest day"
6. **Added Goggins-specific phrases** - "who's gonna carry the boats", "callous your mind"

## Result

Goggins will now only be selected when the log entry contains:
- Actual fitness activities (workout, exercise, gym)
- Fitness-specific equipment (barbell, dumbbell, kettlebell)
- Fitness exercises (squat, bench press, deadlift)
- Fitness contexts (fitness goal, workout session, gym session)
- Goggins-specific motivational phrases

He will NOT match on:
- Generic uses of "run" (run a script)
- Generic uses of "training" (work training)
- Generic uses of "push" (push code)
- Generic uses of "hard" (working hard)
- Generic uses of "discipline" (work discipline)
- Generic uses of "tough" (tough problem)

## Testing

To verify the fix is working:
1. Log a non-fitness entry with words like "push code", "working hard", "training session"
2. Goggins should NOT be selected
3. Log a fitness entry with terms like "workout", "gym session", "leg day"
4. Goggins should be selected appropriately

## Location

The fix was made in:
- `zsh/zshrc_mac_mise` (line 954)

Both Dean Karnazes and David Goggins have now been fixed to only match actual fitness content.

