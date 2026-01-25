#compdef gtd-cli

# GTD CLI Tab Completion for Zsh
# Source this file or add to your .zshrc:
#   source ~/code/dotfiles/zsh/functions/_gtd_cli_complete.zsh

_gtd_cli() {
    local context state line
    typeset -A opt_args

    # Get the GTD CLI path
    local gtd_cli_path="${HOME}/code/dotfiles/bin/gtd-cli"
    
    # Check if gtd-cli exists
    if [[ ! -x "$gtd_cli_path" ]]; then
        return 1
    fi

    # Get current word being completed
    local curcontext="$curcontext" ret=1
    local -a commands
    
    # If we're completing the first argument (command)
    if (( CURRENT == 2 )); then
        # Get completions from gtd-cli
        local partial="${words[2]:-}"
        commands=(${(f)"$($gtd_cli_path --complete "$partial" 2>/dev/null)"})
        
        if (( ${#commands[@]} > 0 )); then
            _describe 'GTD Commands' commands && ret=0
        fi
        
        return ret
    fi
    
    # If we're completing arguments to a command
    if (( CURRENT > 2 )); then
        local cmd="${words[2]}"
        
        # For tool commands, we could potentially parse help and provide argument completion
        # For now, just provide basic file completion
        case "$cmd" in
            read-daily-log|add-daily-log-entry)
                _alternative \
                    'dates:dates:(today yesterday)' \
                    'files:files:_files' && ret=0
                ;;
            list-tasks|create-task)
                _alternative \
                    'projects:projects:(work personal)' \
                    'priorities:priorities:(high medium low)' && ret=0
                ;;
            *)
                # Default to file completion
                _files && ret=0
                ;;
        esac
    fi
    
    return ret
}

# Register the completion function
compdef _gtd_cli gtd-cli

# Also provide short alias completion
alias gtd='gtd-cli'
compdef _gtd_cli gtd