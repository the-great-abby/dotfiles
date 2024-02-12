function help_helpers_todo {
  echo "0: $0"
  echo "hello $1"
}
function kill_port_proc {
    lsof -i tcp:"$1" | grep LISTEN | awk '{print $2}'
}
if [ -f ~/.zsh/zshalias ]; then
    source ~/.zsh/zshalias
else
    print "404: ~/.zsh/zshalias not found."
fi
