#!/usr/bin/env python3
"""
Extract GTD-related Makefile targets and create a new Makefile for the exported repository.
"""

import os
import re
import sys
from pathlib import Path

# GTD-related target patterns
GTD_TARGET_PATTERNS = [
    r'^gtd-',           # All gtd-* targets
    r'^worker-',        # Worker management
    r'^filewatcher-',   # Filewatcher
    r'^scheduler-',     # Scheduler
    r'^vector-db-',     # Vector database
    r'^rabbitmq-status', # RabbitMQ
    r'^verify-nodeport', # NodePort verification
    r'^diagnose-nodeport', # NodePort diagnosis
    r'^advice-worker-', # Advice worker
    r'^claude-ask-',    # Claude ask
    r'^services-',      # External services
]

def is_gtd_target(line):
    """Check if a line starts a GTD-related target."""
    stripped = line.strip()
    if not stripped or stripped.startswith('#'):
        return False
    # Check if it's a target definition (starts with target: or target: ##)
    if ':' in stripped and not stripped.startswith('\t'):
        target_name = stripped.split(':')[0].strip()
        return any(re.match(pattern, target_name) for pattern in GTD_TARGET_PATTERNS)
    return False

def extract_makefile_targets(source_file, dest_file, export_root):
    """Extract GTD-related targets from source Makefile."""
    
    with open(source_file, 'r') as f:
        lines = f.readlines()
    
    output_lines = []
    in_target = False
    current_target = None
    target_lines = []
    
    # Add header
    output_lines.extend([
        '# GTD Organization System Makefile\n',
        '# This Makefile contains all GTD-related commands and targets\n',
        '\n',
        '# Configuration\n',
        f'GTD_BASE_DIR ?= $(HOME)/code/gtd-organization-system\n',
        'GTD_BIN_DIR = $(GTD_BASE_DIR)/bin\n',
        'GTD_MCP_DIR = $(GTD_BASE_DIR)/mcp\n',
        'GTD_ZSH_DIR = $(GTD_BASE_DIR)/zsh\n',
        '\n',
        '# Default variables\n',
        'QUESTION ?= "Help review my daily log using daily log review runbook."\n',
        'GTD_REVIEW_CMD ?= "gtd read-daily-log today"\n',
        'CMD ?=\n',
        '\n',
        '# GTD System Commands\n',
        '.PHONY: gtd-wizard gtd-wizard-2col gtd-wizard-fuzzy gtd-wizard-full gtd-capture gtd-process gtd-review gtd-sync gtd-advise gtd-learn gtd-status gtd-diagram\n',
        '.PHONY: worker-deep-start worker-deep-stop worker-vector-start worker-vector-stop worker-task-org-start worker-task-org-stop worker-brain-sync-start worker-brain-sync-stop worker-status worker-deep-status worker-vector-status worker-task-org-status rabbitmq-status filewatcher-start filewatcher-stop filewatcher-status filewatcher-scan scheduler-start scheduler-stop scheduler-status scheduler-run verify-nodeport diagnose-nodeport vector-db-init-extension vector-db-init-schema\n',
        '.PHONY: gtd-cli gtd-cli-help gtd-setup-completion gtd-test-tui-bypass gtd-check-ollama gtd-test-priority gtd-ollama-status gtd-ollama-list gtd-tui\n',
        '.PHONY: advice-worker-start advice-worker-stop advice-worker-status\n',
        '.PHONY: claude-ask-interactive claude-ask-interactive-debug claude-ask-interactive-force-ollama claude-ask-interactive-force-ollama-8b claude-ask-interactive-force-ollama-3b claude-ask-tui\n',
        '.PHONY: services-deploy-rabbitmq services-deploy-database services-deploy-all services-start-rabbitmq services-start-database services-start-all\n',
        '\n',
    ])
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # Check if this is a GTD target
        if is_gtd_target(line):
            # Save previous target if any
            if target_lines:
                output_lines.extend(target_lines)
                target_lines = []
            
            in_target = True
            current_target = stripped.split(':')[0].strip()
            target_lines.append(line)
            i += 1
            continue
        
        # If we're in a target, collect lines until next target or blank line after commands
        if in_target:
            # Check if this is the start of a new target (not GTD-related)
            if ':' in stripped and not stripped.startswith('\t') and not stripped.startswith('#'):
                target_name = stripped.split(':')[0].strip()
                if not any(re.match(pattern, target_name) for pattern in GTD_TARGET_PATTERNS):
                    # New non-GTD target, end current target
                    in_target = False
                    if target_lines:
                        output_lines.extend(target_lines)
                        target_lines = []
                    i += 1
                    continue
            
            # Continue collecting target lines
            target_lines.append(line)
            i += 1
        else:
            i += 1
    
    # Add any remaining target lines
    if target_lines:
        output_lines.extend(target_lines)
    
    # Replace paths in output
    output_text = ''.join(output_lines)
    
    # Replace old paths with new paths
    output_text = re.sub(
        r'\$\(HOME\)/code/dotfiles',
        r'$(GTD_BASE_DIR)',
        output_text
    )
    output_text = re.sub(
        r'\$\(HOME\)/code/personal/dotfiles',
        r'$(GTD_BASE_DIR)',
        output_text
    )
    output_text = re.sub(
        r'code/dotfiles',
        r'code/gtd-organization-system',
        output_text
    )
    
    # Write output
    dest_path = Path(dest_file)
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(dest_path, 'w') as f:
        f.write(output_text)
    
    return True

def main():
    script_dir = Path(__file__).parent
    dotfiles_root = script_dir.parent.parent.parent
    export_root = Path.home() / 'code' / 'gtd-organization-system'
    
    # Allow override via environment
    if 'EXPORT_ROOT' in os.environ:
        export_root = Path(os.environ['EXPORT_ROOT'])
    
    source_file = dotfiles_root / 'Makefile'
    dest_file = export_root / 'Makefile'
    
    if not source_file.exists():
        print(f"Error: Source Makefile not found: {source_file}", file=sys.stderr)
        sys.exit(1)
    
    print(f"Extracting GTD targets from: {source_file}")
    print(f"Writing to: {dest_file}")
    
    if extract_makefile_targets(source_file, dest_file, export_root):
        print(f"Success: Makefile created at {dest_file}")
    else:
        print("Error: Failed to extract Makefile targets", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    import os
    main()
