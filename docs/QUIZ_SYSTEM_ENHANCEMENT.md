# Quiz & Learning Games System

## Overview

Added a comprehensive quiz and learning games system to all learning areas in the GTD wizard. This includes pop quizzes, practice quizzes, timed quizzes, and progress tracking.

## What Was Added

### 1. Generic Quiz System (`gtd-quiz`)

A flexible quiz framework that supports:
- **Multiple quiz modes**: Practice, Timed, Pop Quiz
- **Question types**: Multiple choice, True/False, Fill-in-the-blank
- **Progress tracking**: Scores, achievements, streaks
- **Topic support**: Organization System, Second Brain, CKA/Kubernetes, Greek

### 2. Python Quiz Helper (`gtd_quiz_helper.py`)

A Python module that handles:
- Loading and managing question banks (JSON format)
- Scoring and answer checking
- Progress tracking and achievements
- Random question selection

### 3. Question Banks

Initial question banks created for:
- **Organization System**: GTD, PARA, CODE, Zettelkasten, MOCs (8 questions)
- **Second Brain**: Progressive Summarization, PARA, Evergreen Notes, Express Phase, MOCs (5 questions)

Question banks are stored in JSON format and can be easily expanded.

### 4. Integration into Wizard

Quiz options added to:
- **Second Brain Learning** (option 10)
- **Kubernetes/CKA Learning** (option 8)
- **Greek Language Learning** (option 6)

## How to Use

### Initialize Question Banks

```bash
gtd-quiz-init
```

This copies question banks from `zsh/quizzes/` to your GTD quiz data directory.

### Take a Quiz

**From Wizard:**
1. Go to any learning section (Second Brain, CKA, Greek)
2. Choose "Take a Quiz" option
3. Select quiz mode (Practice, Timed, Pop Quiz)

**Direct Command:**
```bash
gtd-quiz                    # Topic selection menu
gtd-quiz organization-system # Direct topic
gtd-quiz second-brain
gtd-quiz cka-kubernetes
gtd-quiz greek
```

### Quiz Modes

1. **Practice Quiz** (5 questions, untimed)
   - Learn at your own pace
   - See explanations after each answer
   - Good for studying

2. **Timed Quiz** (10 questions, 2 min per question)
   - Test your knowledge under pressure
   - Simulates exam conditions
   - Good for CKA exam prep

3. **Pop Quiz** (Random 3 questions)
   - Quick knowledge check
   - Random selection
   - Good for daily practice

## Question Bank Format

Questions are stored in JSON format:

```json
{
  "topic": "organization-system",
  "questions": [
    {
      "id": "gtd-001",
      "type": "multiple_choice",
      "question": "What does GTD stand for?",
      "options": [
        "Getting Things Done",
        "Great Task Directory",
        "Goal Tracking Dashboard"
      ],
      "correct_answer": "Getting Things Done",
      "explanation": "GTD stands for Getting Things Done..."
    }
  ]
}
```

## Progress Tracking

The system tracks:
- Total quizzes taken
- Correct/incorrect answers
- Best score
- Last quiz date
- Achievements unlocked

Progress is stored in `~/Documents/gtd/quizzes/progress/`

## Achievements

Achievements unlock based on:
- **Perfect Score** (100%): Get a perfect score
- **Excellent Score** (90%+): Score 90% or higher
- **Good Score** (80%+): Score 80% or higher
- **Quiz Master 10**: Complete 10 quizzes
- **Quiz Master 50**: Complete 50 quizzes
- **Quiz Master 100**: Complete 100 quizzes

## Adding More Questions

### For Organization System

Edit: `zsh/quizzes/organization-system-questions.json`

Add questions covering:
- GTD methodology
- PARA organization
- Second Brain CODE method
- Zettelkasten concepts
- MOCs and knowledge organization

### For Second Brain

Edit: `zsh/quizzes/second-brain-questions.json`

Add questions covering:
- Progressive Summarization
- PARA method
- Evergreen Notes
- Express Phase
- MOCs
- Templates

### For CKA/Kubernetes

Create: `zsh/quizzes/cka-kubernetes-questions.json`

Add questions covering:
- Kubernetes basics
- Pods, Deployments, Services
- ConfigMaps & Secrets
- Storage (PVs, PVCs)
- Networking
- Troubleshooting
- CKA exam topics

### For Greek

Create: `zsh/quizzes/greek-questions.json`

Add questions covering:
- Alphabet
- Vocabulary
- Grammar
- Verbs
- Nouns
- Reading comprehension

## Future Enhancements

Potential additions:
1. **Flashcard Mode**: Study mode with spaced repetition
2. **Challenge Mode**: Compete against previous scores
3. **Daily Quiz**: Random question each day
4. **Study Streaks**: Track consecutive quiz days
5. **Leaderboards**: Compare with yourself over time
6. **Adaptive Difficulty**: Questions get harder as you improve
7. **Question Explanations**: Detailed explanations for wrong answers
8. **Topic-Specific Quizzes**: Focus on specific areas

## Integration Points

### Wizard Integration

Quizzes are accessible from:
- **Second Brain Learning** → Option 10
- **Kubernetes/CKA Learning** → Option 8
- **Greek Language Learning** → Option 6

### Direct Access

```bash
gtd-quiz                    # Interactive menu
gtd-quiz <topic>           # Direct topic
```

### Question Bank Management

```bash
gtd-quiz-init              # Initialize/copy question banks
```

## Technical Details

### Files Created

- `bin/gtd-quiz`: Main quiz script
- `bin/gtd-quiz-init`: Initialize question banks
- `zsh/functions/gtd_quiz_helper.py`: Python helper module
- `zsh/quizzes/organization-system-questions.json`: Organization questions
- `zsh/quizzes/second-brain-questions.json`: Second Brain questions

### Directory Structure

```
~/Documents/gtd/quizzes/
├── data/                  # Question banks (JSON)
│   ├── organization-system.json
│   ├── second-brain.json
│   ├── cka-kubernetes.json
│   └── greek.json
└── progress/              # User progress (JSON)
    ├── organization-system.json
    ├── second-brain.json
    ├── cka-kubernetes.json
    └── greek.json
```

## Tips

1. **Start with Practice Mode**: Get familiar with questions
2. **Use Pop Quizzes Daily**: Quick 3-question checks
3. **Review Explanations**: Learn from wrong answers
4. **Track Progress**: See improvement over time
5. **Add More Questions**: Expand question banks as you learn

## Example Usage

```bash
# Initialize question banks
gtd-quiz-init

# Take a practice quiz on Second Brain
gtd-quiz second-brain

# From wizard: Second Brain Learning → Take a Quiz

# Check your progress
# (Progress shown in quiz menu)
```

## Next Steps

1. **Add More Questions**: Expand question banks for each topic
2. **Create CKA Questions**: Add Kubernetes/CKA exam questions
3. **Create Greek Questions**: Add Greek language questions
4. **Enhance Quiz Script**: Add full interactive quiz functionality
5. **Add Achievements**: More achievement types
6. **Study Mode**: Flashcard/spaced repetition mode

