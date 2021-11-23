Set-ExecutionPolicy RemoteSigned -scope CurrentUser
iwr -useb [get.scoop.sh](http://get.scoop.sh/) | iex
scoop install git
scoop bucket add extras
scoop install notepadplusplus
scoop search googlechrome
scoop install googlechrome
# "Cat with Wings" ...
scoop install bat
# Other items needed
#scoop search firefox
#scoop search opera
#scoop search aws
#scoop search starship
#scoop search zlocation
