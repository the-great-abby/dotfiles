---
name: Task Summary Generator
description: Generate a summary of tasks from daily logs or text
version: 1.0.0
tags:
  - tasks
  - summary
  - productivity
author: GTD System
---

# Task Summary Generator

A skill that helps extract and summarize tasks from text, daily logs, or other sources.

## When to Use

Use this skill when you need to:
- Extract tasks from unstructured text
- Create task summaries from daily logs
- Generate reports on pending tasks
- Organize task-related information

## How It Works

This skill integrates with the GTD system's task suggestion and management capabilities to help extract, organize, and summarize tasks from various sources.

## Usage

Execute this skill with text content to extract tasks:

```python
execute_agent_skill(
    skill_name="Task Summary Generator",
    method="instructions",
    args={}
)
```

The skill instructions provide guidance to the AI agent on how to use the underlying GTD tools to generate task summaries.
