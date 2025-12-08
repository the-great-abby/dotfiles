#!/usr/bin/env python3
"""
Extract daily log content from Obsidian Daily Note.
Called by gtd-brain-bidirectional-sync.
"""
import re
import sys
from pathlib import Path

def extract_log_from_daily_note(note_file_path, log_file_path, date):
    """Extract log content from Daily Note file."""
    note_file = Path(note_file_path)
    log_file = Path(log_file_path)
    
    if not note_file.exists():
        print("ERROR: Note file not found", file=sys.stderr)
        return 1
    
    content = note_file.read_text()
    log_content = None
    
    # Method 1: Look for "### Full Log" section with code block
    full_log_pattern = r'### Full Log\s*\n```[a-z]*\s*\n(.*?)\n```'
    full_log_match = re.search(full_log_pattern, content, re.DOTALL)
    if full_log_match:
        log_content = full_log_match.group(1)
        if not log_content.startswith(date):
            log_content = f"{date}\n\n{log_content}"
    
    # Method 2: Look for any code block (might contain log)
    if not log_content:
        code_block_pattern = r'```[a-z]*\s*\n(.*?)\n```'
        code_block_match = re.search(code_block_pattern, content, re.DOTALL)
        if code_block_match:
            potential_log = code_block_match.group(1)
            if re.search(r'^\d{2}:\d{2}\s+-', potential_log, re.MULTILINE):
                log_content = potential_log
                if not log_content.startswith(date):
                    log_content = f"{date}\n\n{log_content}"
    
    # Method 3: Extract time-stamped entries from anywhere in the note
    if not log_content:
        entries = re.findall(r'^\d{2}:\d{2}\s+-.*$', content, re.MULTILINE)
        if entries:
            log_content = f"{date}\n\n" + "\n".join(entries)
    
    # Method 4: Extract from Highlights sections
    if not log_content:
        highlight_pattern = r'#### (Goals|Workouts|Medication|Projects)\s*\n((?:\s+- .*\n?)+)'
        highlight_sections = re.findall(highlight_pattern, content, re.MULTILINE)
        if highlight_sections:
            all_entries = []
            for section_type, section_content in highlight_sections:
                entries = re.findall(r'\d{2}:\d{2}\s+-.*', section_content)
                all_entries.extend(entries)
            if all_entries:
                log_content = f"{date}\n\n" + "\n".join(all_entries)
    
    # Method 5: Extract from "Notes" section
    if not log_content:
        notes_pattern = r'## Notes\s*\n(.*?)(?=\n## |\Z)'
        notes_match = re.search(notes_pattern, content, re.DOTALL)
        if notes_match:
            notes_content = notes_match.group(1)
            entries = re.findall(r'^\d{2}:\d{2}\s+-.*$', notes_content, re.MULTILINE)
            if entries:
                log_content = f"{date}\n\n" + "\n".join(entries)
    
    if log_content and len(log_content.strip()) > len(date):
        log_file.parent.mkdir(parents=True, exist_ok=True)
        log_file.write_text(log_content)
        print(f"SUCCESS: {log_file}")
        return 0
    else:
        log_file.parent.mkdir(parents=True, exist_ok=True)
        empty_content = f"{date}\n\n<!-- Log extracted from Obsidian Daily Note: {date} -->\n<!-- Note: This log was created from Obsidian. Add entries below. -->\n"
        log_file.write_text(empty_content)
        print(f"EMPTY: {log_file}")
        return 0

if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: gtd-extract-log-from-note.py <note-file> <log-file> <date>", file=sys.stderr)
        sys.exit(1)
    
    exit_code = extract_log_from_daily_note(sys.argv[1], sys.argv[2], sys.argv[3])
    sys.exit(exit_code)
