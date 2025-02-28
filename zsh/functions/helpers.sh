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

function htmlEscape () {
    local s
    s=${1//&/&amp;}
    s=${s//</&lt;}
    s=${s//>/&gt;}
    s=${s//'"'/&quot;}
    printf -- %s "$s"
}
function removeCurrentDayEntry {

	local today=$(date +"%Y-%m-%d")
	local file="$SECOND_BRAIN"'/daily_notes/'$(date +"%Y-%m-%d").md
	ls $file
	rm $file
}
