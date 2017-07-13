# If not running interactively, don't do anything.
[ -z "$PS1" ] && return

# Update window size.
shopt -s checkwinsize

# Bash specific functions
[ -f "$HOME/.bash_functions_colors" ] && . "$HOME/.bash_functions_colors"
[ -f "$HOME/.bash_functions_git" ] && . "$HOME/.bash_functions_git"
[ -f "$HOME/.bash_functions_calendar" ] && . "$HOME/.bash_functions_calendar"
[ -f "$HOME/.bash_functions_weedmaps" ] && . "$HOME/.bash_functions_weedmaps"
[ -f "$HOME/.bash_functions_tail" ] && . "$HOME/.bash_functions_tail"
[ -f "$HOME/.bash_functions" ] && . "$HOME/.bash_functions"

#
# PROMPT
#

if [[ "$TERM" =~ .*-256color ]]; then
    icon_commit='➦'
    icon_branch='|>'
    icon_separator=''
else
    icon_commit='c:'
    icon_branch='b:'
    icon_separator=''
fi

PROMPT_COMMAND='set_prompt'

#
# ALIASES
#

PS1=""

# Linux specific setup.
if [ $(uname) == 'Linux' ]; then
    eval "$(dircolors -b)"
    alias ls='ls --color=auto'
fi

# Mac OS X specific setup.
if [ $(uname) == 'Darwin' ]; then
    alias ls='ls -G'
    #alias vim='mvim -v'
fi

#
# SSH
#

# Setup SSH agent.
if [ -n "$SSH_TTY" ]; then
    SSH_ENV=~/.ssh/environment

    function start_agent {
        echo "Initializing new SSH agent..."
        /usr/bin/ssh-agent | sed 's/^echo/#echo/' > "${SSH_ENV}"
        chmod 600 "${SSH_ENV}"
        . "${SSH_ENV}" > /dev/null
        ssh-add
    }

    # Source SSH settings, if applicable.
    if [ -f "${SSH_ENV}" ]; then
        . "${SSH_ENV}" > /dev/null
        ps -ef | grep ${SSH_AGENT_PID} | grep ssh-agent$ > /dev/null || {
            start_agent
        }
    else
        start_agent
    fi
fi

#
# GIT
#

# Git paging.
export GIT_PAGER='less -+$LESS -FXR'

# Git auto completion.
if [ -n "$BASH_VERSION" ]; then
    . ~/.git-completion.bash
fi

#
# PATHS
#

export PATH="~/code/weedmaps_code/weedmaps-tools/git:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
export GIT_EXEC_PATH="~/code/weedmaps_code/weedmaps-tools/git"
# Add user binary path.
[ -d "$HOME/bin" ] && export PATH="$PATH:$HOME/bin"
# Add RVM to path.
[ -f "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"

#
# OTHER
#

# Allow server-specific scripting.
[ -f "$HOME/.bash_custom" ] && . "$HOME/.bash_custom"
[ -f "$HOME/.bash_alias" ] && . "$HOME/.bash_alias"

# Bash specific aliases
[ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"

# Node Virtual Machine
if hash brew 2>/dev/null; then
  export NVM_DIR="$HOME/.nvm"
  source $(brew --prefix nvm)/nvm.sh
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
fi

#source ~/liquidprompt/liquidprompt
# vim:: set ft=sh

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# for NPM
export NPM_TOKEN=24741636-a15e-47f1-883b-36bd8fa2de1b
