# Dean Karnazes Keyword Fix

## Problem

Dean Karnazes was being selected too frequently for non-fitness log entries. This was happening because his keyword pattern included very common words that match in non-fitness contexts:

- "run" - matches "run a script", "run a meeting", "run the system"
- "pace" - matches "pace of work", "keep pace"
- "distance" - matches "distance learning", "social distance"
- "training" - matches "training session" (work-related)

## Solution

Updated Dean's keywords to be much more specific to actual running/fitness contexts. The new keywords require more context-specific phrases:

**Old keywords:**
```
run|running|jog|jogging|marathon|ultra|endurance|distance|race|pace|mile|km|cardio|aerobic|long run|training run
```

**New keywords:**
```
marathon|ultra|ultramarathon|endurance|race|running race|jog|jogging|running workout|training run|long run|running pace|running form|running distance|ultra distance|endurance running|running miles|running km|ultra running|endurance race|50k|50 mile|100k|100 mile|trail running|road race
```

## Result

Dean will now only be selected when the log entry contains:
- Specific running terms (marathon, ultramarathon, 50k, etc.)
- Running-specific phrases (running workout, running pace, running form)
- Actual fitness/running activities

He will NOT match on:
- Generic uses of "run" (run a script, run a command)
- Generic uses of "pace" (pace of work)
- Generic uses of "distance" (distance learning)
- Generic uses of "training" (training session for work)

## Testing

To verify the fix is working:
1. Log a non-fitness entry with words like "run a script" or "training session"
2. Dean should NOT be selected
3. Log a fitness entry with terms like "running workout" or "marathon training"
4. Dean should be selected appropriately

## Location

The fix was made in:
- `zsh/zshrc_mac_mise` (line 955)

The persona selection logic prioritizes fitness coaches for fitness content, but now Dean's keywords are specific enough to only match actual fitness/running contexts.

