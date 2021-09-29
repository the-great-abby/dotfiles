install:
	./bootstrap.sh
	echo "run 'source ~/.bashrc' to update console"

install_zshrc:
	ln -s ${PWD}/zsh/zshrc ~/.zshrc
	# New-Item -Path ~/.zshrc -ItemType SymbolicLink -Target ${PWD}/zsh/zshrc

install_vimrc:
	#mv ~/.vimrc ~/.vimrc_old
	ln -s ~/code/dotfiles/vimrc ~/.vimrc
	#mv ~/.vim ~/.vim_old
	ln -s ~/code/dotfiles/vim ~/.vim

install_bashrc:
	#mv ~/.vimrc ~/.vimrc_old
	# mv ~/.bashrc ~/.bashrc_old
	ln -s ~/code/dotfiles/bash/bashrc                        ~/.bashrc
	ln -s ~/code/dotfiles/git/git-completion.bash            ~/.git-completion.bash
	# mv ~/.bash_aliases ~/.bash_aliases_old
	#ln -s ~/code/dotfiles/bash/bash_aliases                  ~/.bash_aliases
	#ln -s ~/code/dotfiles/bash/bash_aliases_linux            ~/.bash_aliases_linux
	#ln -s ~/code/dotfiles/bash/bash_aliases_linux_custom     ~/.bash_aliases_linux_custom
	#ln -s ~/code/dotfiles/bash/bash_functions                ~/.bash_functions
	#ln -s ~/code/dotfiles/bash/bash_functions_calendar       ~/.bash_functions_calendar
	#ln -s ~/code/dotfiles/bash/bash_functions_colors         ~/.bash_functions_colors
	#ln -s ~/code/dotfiles/bash/bash_functions_docker         ~/.bash_functions_docker
	#ln -s ~/code/dotfiles/bash/bash_functions_git            ~/.bash_functions_git
	#ln -s ~/code/dotfiles/bash/bash_functions_tail           ~/.bash_functions_tail
	#ln -s ~/code/dotfiles/bash/bash_functions_work_general   ~/.bash_functions_work_general
	#ln -s ~/code/dotfiles/bash/bash_functions_aws            ~/.bash_functions_aws
	#ln -s ~/code/dotfiles/bash/bash_functions_azure          ~/.bash_functions_azure
	#ln -s ~/code/dotfiles/bash/bash_functions_gcp            ~/.bash_functions_gcp
	#ln -s ~/code/dotfiles/bash/bash_functions_vultr          ~/.bash_functions_vultr

remove_extra_links:
	rm ~/.bash_aliases_linux
	rm ~/.bash_aliases_linux_custom
	rm ~/.bash_functions
	rm ~/.bash_functions_vultr
	rm ~/.bash_functions_aws
	rm ~/.bash_functions_azure
	rm ~/.bash_functions_gcp
	rm ~/.bash_functions_work_general
	rm ~/.bash_functions_tail
	rm ~/.bash_functions_git
	rm ~/.bash_functions_colors
	rm ~/.bash_functions_docker
	rm ~/.bash_functions_calendar

install_tmux:
	# mv ~/.tmux.conf ~/tmux.conf_old
	ln -s ~/code/dotfiles/unix_shell/tmux.conf ~/.tmux.conf

