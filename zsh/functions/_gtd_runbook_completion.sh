#!/bin/zsh
# GTD Runbook tab completion for zsh

_gtd_runbook() {
    local state context line
    typeset -A opt_args

    # Define the completion context
    _arguments -C \
        '1:command:->commands' \
        '*:runbook:->runbooks' \
        && return 0

    case $state in
        commands)
            local commands=(
                'list:List all runbooks with descriptions'
                'search:Search runbooks by keyword' 
                'info:Show detailed runbook information'
                'completion:Show tab completion setup'
                'help:Show help information'
            )
            
            # Also add all runbook names as possible commands
            local runbook_names
            if [[ -x "$HOME/code/dotfiles/bin/gtd-runbook" ]]; then
                runbook_names=(${(f)"$($HOME/code/dotfiles/bin/gtd-runbook list-names 2>/dev/null)"})
            fi
            
            # Combine commands and runbook names
            local all_options=($commands $runbook_names)
            _describe 'gtd-runbook commands and runbooks' all_options
            ;;
        runbooks)
            # For second argument (e.g., after 'search' or 'info'), complete with runbook names
            if [[ -x "$HOME/code/dotfiles/bin/gtd-runbook" ]]; then
                local runbook_names=(${(f)"$($HOME/code/dotfiles/bin/gtd-runbook list-names 2>/dev/null)"})
                _describe 'runbooks' runbook_names
            fi
            ;;
    esac
    
    return 0
}

# Set up completion for gtd-runbook command
compdef _gtd_runbook gtd-runbook