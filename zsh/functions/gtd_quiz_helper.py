#!/usr/bin/env python3
"""
GTD Quiz Helper
Manages quiz questions, scoring, and progress tracking
"""

import json
import os
import random
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple

class QuizHelper:
    def __init__(self, gtd_base_dir: str = None):
        if gtd_base_dir is None:
            gtd_base_dir = os.path.expanduser("~/Documents/gtd")
        
        self.gtd_base_dir = gtd_base_dir
        self.quiz_dir = os.path.join(gtd_base_dir, "quizzes")
        self.data_dir = os.path.join(self.quiz_dir, "data")
        self.progress_dir = os.path.join(self.quiz_dir, "progress")
        
        # Create directories
        Path(self.data_dir).mkdir(parents=True, exist_ok=True)
        Path(self.progress_dir).mkdir(parents=True, exist_ok=True)
    
    def get_question_file(self, topic: str) -> str:
        """Get path to question file for a topic"""
        return os.path.join(self.data_dir, f"{topic}.json")
    
    def get_progress_file(self, topic: str) -> str:
        """Get path to progress file for a topic"""
        return os.path.join(self.progress_dir, f"{topic}.json")
    
    def load_questions(self, topic: str) -> List[Dict]:
        """Load questions for a topic"""
        question_file = self.get_question_file(topic)
        
        if not os.path.exists(question_file):
            return []
        
        try:
            with open(question_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                return data.get('questions', [])
        except (json.JSONDecodeError, IOError):
            return []
    
    def save_questions(self, topic: str, questions: List[Dict]):
        """Save questions for a topic"""
        question_file = self.get_question_file(topic)
        
        data = {
            'topic': topic,
            'updated': datetime.now().isoformat(),
            'questions': questions
        }
        
        with open(question_file, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    
    def get_progress(self, topic: str) -> Dict:
        """Get quiz progress for a topic"""
        progress_file = self.get_progress_file(topic)
        
        if not os.path.exists(progress_file):
            return {
                'total_quizzes': 0,
                'correct': 0,
                'incorrect': 0,
                'best_score': 0,
                'last_quiz_date': None,
                'achievements': []
            }
        
        try:
            with open(progress_file, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return {
                'total_quizzes': 0,
                'correct': 0,
                'incorrect': 0,
                'best_score': 0,
                'last_quiz_date': None,
                'achievements': []
            }
    
    def save_progress(self, topic: str, progress: Dict):
        """Save quiz progress for a topic"""
        progress_file = self.get_progress_file(topic)
        
        with open(progress_file, 'w', encoding='utf-8') as f:
            json.dump(progress, f, indent=2, ensure_ascii=False)
    
    def get_random_questions(self, topic: str, count: int) -> List[Dict]:
        """Get random questions for a topic"""
        questions = self.load_questions(topic)
        
        if len(questions) < count:
            return questions
        
        return random.sample(questions, count)
    
    def check_answer(self, question: Dict, answer: str) -> bool:
        """Check if answer is correct"""
        correct_answer = question.get('correct_answer', '').strip().lower()
        user_answer = answer.strip().lower()
        
        # Handle multiple choice (by index or letter)
        if 'options' in question:
            # If answer is a number, check by index
            try:
                idx = int(user_answer) - 1
                if 0 <= idx < len(question['options']):
                    return question['options'][idx].strip().lower() == correct_answer
            except ValueError:
                pass
            
            # If answer is a letter (a, b, c, d), convert to index
            if len(user_answer) == 1 and user_answer.isalpha():
                idx = ord(user_answer.lower()) - ord('a')
                if 0 <= idx < len(question['options']):
                    return question['options'][idx].strip().lower() == correct_answer
        
        # Direct answer comparison
        return user_answer == correct_answer
    
    def update_progress(self, topic: str, correct: int, total: int):
        """Update progress after a quiz"""
        progress = self.get_progress(topic)
        
        score = int((correct / total) * 100) if total > 0 else 0
        
        progress['total_quizzes'] = progress.get('total_quizzes', 0) + 1
        progress['correct'] = progress.get('correct', 0) + correct
        progress['incorrect'] = progress.get('incorrect', 0) + (total - correct)
        progress['last_quiz_date'] = datetime.now().isoformat()
        
        if score > progress.get('best_score', 0):
            progress['best_score'] = score
        
        # Check for achievements
        achievements = self.check_achievements(topic, progress, score)
        if achievements:
            progress['achievements'] = list(set(progress.get('achievements', []) + achievements))
        
        self.save_progress(topic, progress)
        return progress
    
    def check_achievements(self, topic: str, progress: Dict, score: int) -> List[str]:
        """Check for new achievements"""
        achievements = []
        existing = set(progress.get('achievements', []))
        
        # Score-based achievements
        if score == 100 and 'perfect_score' not in existing:
            achievements.append('perfect_score')
        if score >= 90 and 'excellent_score' not in existing:
            achievements.append('excellent_score')
        if score >= 80 and 'good_score' not in existing:
            achievements.append('good_score')
        
        # Quiz count achievements
        total_quizzes = progress.get('total_quizzes', 0)
        if total_quizzes >= 10 and 'quiz_master_10' not in existing:
            achievements.append('quiz_master_10')
        if total_quizzes >= 50 and 'quiz_master_50' not in existing:
            achievements.append('quiz_master_50')
        if total_quizzes >= 100 and 'quiz_master_100' not in existing:
            achievements.append('quiz_master_100')
        
        # Streak achievements
        # (Would need to track consecutive perfect scores)
        
        return achievements

if __name__ == '__main__':
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: gtd_quiz_helper.py <command> [args...]")
        sys.exit(1)
    
    helper = QuizHelper()
    command = sys.argv[1]
    
    if command == 'load':
        topic = sys.argv[2] if len(sys.argv) > 2 else 'organization-system'
        questions = helper.load_questions(topic)
        print(json.dumps(questions, indent=2))
    
    elif command == 'progress':
        topic = sys.argv[2] if len(sys.argv) > 2 else 'organization-system'
        progress = helper.get_progress(topic)
        print(json.dumps(progress, indent=2))
    
    elif command == 'random':
        topic = sys.argv[2] if len(sys.argv) > 2 else 'organization-system'
        count = int(sys.argv[3]) if len(sys.argv) > 3 else 5
        questions = helper.get_random_questions(topic, count)
        print(json.dumps(questions, indent=2))

