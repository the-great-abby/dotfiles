# If not running interactively, don't do anything.
[ -z "$PS1" ] && return

# Update window size.
shopt -s checkwinsize
shopt -s histappend

# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps
# History Sizes
HISTSIZE=5000
HISTFILESIZE=10000

# Bash specific functions 
export DOTFILES_PATH="${HOME}/code/dotfiles/"
# Bash specific functions
[ -f "$HOME/.bash_functions_colors" ] && . "$HOME/.bash_functions_colors"
[ -f "$HOME/.bash_functions_git" ] && . "$HOME/.bash_functions_git"
[ -f "$HOME/.bash_functions_calendar" ] && . "$HOME/.bash_functions_calendar"
[ -f "$HOME/.bash_functions_weedmaps" ] && . "$HOME/.bash_functions_weedmaps"
[ -f "$HOME/.bash_functions_docker" ] && . "$HOME/.bash_functions_docker"
[ -f "$HOME/.bash_functions_tail" ] && . "$HOME/.bash_functions_tail"
[ -f "$HOME/.bash_functions" ] && . "$HOME/.bash_functions"

export BUILD_RELEASE_LOCAL_DIR='code/weedmaps/build-release/'
export BUILD_RELEASE_LOCAL_HELP_DIR="${HOME}/${BUILD_RELEASE_LOCAL_DIR}/command-line-help"
[ -f "${BUILD_RELEASE_LOCAL_HELP_DIR}/bash_functions_weedmaps" ] && . "${BUILD_RELEASE_LOCAL_HELP_DIR}/bash_functions_weedmaps"
export CLAPTT_GENERALTEMPLATE='code/wm/claptt_general_template/' # change this to point to your local claptt_general_template repo
export CLAPTT_GENERALTEMPLATE_HELP_DIR="${HOME}/${CLAPTT_GENERALTEMPLATE}/" # You should not have to modify this
# Uncomment the below line in .bashrc to include this file
[ -f "${CLAPTT_GENERALTEMPLATE_HELP_DIR}/bash_functions_help" ] && . "${CLAPTT_GENERALTEMPLATE_HELP_DIR}/bash_functions_help"
# Let's add in the additional files/structures (Copy this into your ~/.bashrc file)
export CLAPTT_ABBY='code/personal_kb/' # change this to point to your local claptt_abby repo
export CLAPTT_ABBY_HELP_DIR="${HOME}/${CLAPTT_ABBY}/" # You should not have to modify this
# Uncomment the below line in .bashrc to include this file
[ -f "${CLAPTT_ABBY_HELP_DIR}/bash_functions_help" ] && . "${CLAPTT_ABBY_HELP_DIR}/bash_functions_help"
# Let's add in the additional files/structures (Copy this into your ~/.bashrc file)
export CLAPTT_BNR='code/wm/claptt_build_and_release/' # change this to point to your local claptt_build_and_release repo
export CLAPTT_BNR_HELP_DIR="${HOME}/${CLAPTT_BNR}/" # You should not have to modify this
# Uncomment the below line in .bashrc to include this file
[ -f "${CLAPTT_BNR_HELP_DIR}/bash_functions_help" ] && . "${CLAPTT_BNR_HELP_DIR}/bash_functions_help"

export BUILD_RELEASE_LOCAL_DIR='code/weedmaps_code/build-release/' # change this to point to your local build-release repo
export BUILD_RELEASE_LOCAL_HELP_DIR="${HOME}/${BUILD_RELEASE_LOCAL_DIR}/command-line-help" # You should not have to modify this
[ -f "${BUILD_RELEASE_LOCAL_HELP_DIR}/bash_functions_weedmaps" ] && . "${BUILD_RELEASE_LOCAL_HELP_DIR}/bash_functions_weedmaps"
export CLAPTT_BNR='code/weedmaps_code/claptt_build_and_release/' # change this to point to your local claptt_build_and_release repo
export CLAPTT_BNR_HELP_DIR="${HOME}/${CLAPTT_BNR}/" # You should not have to modify this
# Uncomment the below line in .bashrc to include this file
[ -f "${CLAPTT_BNR_HELP_DIR}/bash_functions_help" ] && . "${CLAPTT_BNR_HELP_DIR}/bash_functions_help"
# Let's add in the additional files/structures (Copy this into your ~/.bashrc file)
export CLAPTT_ABBY='code/claptt_abby/' # change this to point to your local claptt_abby repo
export CLAPTT_ABBY_HELP_DIR="${HOME}/${CLAPTT_ABBY}/" # You should not have to modify this
# Uncomment the below line in .bashrc to include this file
[ -f "${CLAPTT_ABBY_HELP_DIR}/bash_functions_help" ] && . "${CLAPTT_ABBY_HELP_DIR}/bash_functions_help"

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

# https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps

# Adding shared history support -- multiple terminals (useful for tmux/screen)
export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

#
# ALIASES
#

#PS1=""

# Linux specific setup.
#if [ $(uname) == 'Linux' && 'custom']; then
#  [ -f "$HOME/.bash_aliases_linux_custom" ] && . "$HOME/.bash_aliases_linux_custom"
#fi
if [ $(uname) == 'Linux' ]; then
  [ -f "$HOME/.bash_aliases_linux" ] && . "$HOME/.bash_aliases_linux"
fi
if [ $(uname) == 'CYGWIN_NT-10.0' ]; then
  [ -f "$HOME/.bash_aliases_cygwin" ] && . "$HOME/.bash_aliases_cygwin"
fi

# Mac OS X specific setup.
if [ $(uname) == 'Darwin' ]; then
  [ -f "$HOME/.bash_aliases_darwin" ] && . "$HOME/.bash_aliases_darwin"
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

export PATH="~/code/weedmaps_code/weedmaps-tools/git:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:~/go/bin:~/code/dotfiles/bin:$PATH"
# export GIT_EXEC_PATH="/usr/libexec/git-core/"
# Add user binary path.
[ -d "$HOME/bin" ] && export PATH="$PATH:$HOME/bin"
# Add RVM to path.
# [ -f "$HOME/.rvm/scripts/rvm" ] && . "$HOME/.rvm/scripts/rvm"

#
# OTHER
#

# Allow server-specific scripting.
[ -f "$HOME/.bash_custom" ] && . "$HOME/.bash_custom"
[ -f "$HOME/.bash_alias" ] && . "$HOME/.bash_alias"

# Bash specific aliases
[ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"

# vim:: set ft=sh
