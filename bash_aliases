# Custom aliases.
# alias ultragrep='fgrep -R --color=always --exclude='\''*.svn*'\'' --exclude='\''*CVS*'\'' --exclude='\''*.rej'\'' --exclude='\''*.#*'\'' --exclude='\''*.diff'\'' --exclude='\''*.*~'\'' --exclude='\''*.tmp*'\'' -n -i'
alias bd='cd $OLDPWD'
alias behatc='behat --colors'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias todo='todo -tn'
alias pomo='pomojs -t -l ~/.pomo.log'
alias less='less -FXR'
#alias ls='ls --color'
#alias la='ls -A'
alias ll='ls -Al'
alias tmux='tmux -2'
alias vi='vim -p'
alias ultragrep='grep -rnHi --color=always --exclude="*.swp" --exclude="*.orig" --exclude="*.svn*" --exclude="*.diff"'
alias quickFileGrep='g'


# vim: ft=sh
