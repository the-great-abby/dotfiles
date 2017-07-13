if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

export NPM_TOKEN=24741636-a15e-47f1-883b-36bd8fa2de1b

export NVM_DIR="$HOME/.nvm"
source $(brew --prefix nvm)/nvm.sh
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

alias gst='git status'
alias gl='git pull'
alias gp='git push'
alias gpo='git push origin'
alias gd='git diff | mate'
alias gau='git add --update'
alias gc='git commit -v'
alias gca='git commit -v -a'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gplo='git pull origin'

alias git high='git push origin master'

function git_cleanup {
  # Prune
  git fetch -p
  git branch --merged | grep -v '\*\|master\|develop' | xargs -n 1 git branch -d
  git fetch -p
  git branch -vv|grep ': gone]'| grep -v '\*\|master\|develop' |awk '{print $1}'|xargs git branch -D
}
export -f git_cleanup
=======
# vim:: set ft=sh
#export CLICOLOR=1
#export LSCOLORS=GxFxCxDxBxegedabagaced
