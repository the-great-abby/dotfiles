GLIBC_VER=2.31-r0

install:
	./bootstrap.sh
	echo "run 'source ~/.bashrc' to update console"

install_zshrc:
	ln -s ${PWD}/zsh/zshrc ~/.zshrc
	# New-Item -Path ~/.zshrc -ItemType SymbolicLink -Target ${PWD}/zsh/zshrc
#install:
#	yarn
#
#start:
#	yarn start
#
install_aws_amplify_cli:
	yarn global add @aws-amplify/cli
	#npm -g i @aws-amplify/cli
	echo "Run 'amplify configure' from the command line"

install_aws_amplify_cli_gitlab:
	#yarn global add @aws-amplify/cli
	npm -g i @aws-amplify/cli
	echo "Run 'amplify configure' from the command line"

test:
	echo "Hi There!"

# Use asdf to install and manage JDK
install_jdk_via_asdf:
	# asdf current java
	asdf install java openjdk-16
	asdf global java openjdk-16
	# asdf shell java openjdk-16
	asdf local java openjdk-16

#check_jdk_in_path:
	# echo "PATH: ${`PATH | grep asdf`}"

update_plugin_asdf:
	asdf plugin update java

add_plugin_jdk:
	asdf plugin add java

list_all_available_jdk:
	asdf list all java
	asdf latest java openjdk


show_gitlab_ci_pipeline:
	glab pipeline ci view

install_glab:
	brew install glab

update_glab:
	brew update glab

install_oh_my_zsh:
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh")
install_zshrc_mac:
	ln -s ${PWD}/zsh/zshrc_mac ~/.zshrc
	brew install zsh-syntax-highlighting
	brew install zsh-autosuggestions
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

github_ssh_keygen:
	ssh-keygen -t ed25519 -C "github@augustmalson.com"

github_ssh_keygen_step2:
	eval "$(ssh-agent -s)"
	cat ~/.ssh/id_ed25519.pub

install_rectangle:
	brew install --cask rectangle

install_tmux:
	brew install tmux

setup_tmux:
	ln -s ~/code/dotfiles/unix_shell/tmux.conf ~/.tmux.conf

setup_vim:
	echo "setup_vim"	
	ln -s ~/code/dotfiles/vim ~/.vim
	ln -s ~/code/dotfiles/vimrc ~/.vimrc
	
install_homebrew:
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	
upgrade_homebrew:
	brew doctor
	brew update

install_awscli:
	brew install awscli awslogs aws-mon

install_rosetta:
	softwareupdate --install-rosetta --agree-to-license

install_xcode:
	xcode-select --install

install_anaconda:
	brew install anaconda

install_starship:
	brew install starship

install_asdf:
	brew install asdf

install_vagrant_virtualbox:
	brew install --cask virtualbox
	brew install --cask vagrant

install_vscode:
	brew install --cask visual-studio-code

install_terraform:
	brew install terraform

install_kube_tools:
	# brew install --cask docker
	brew install kubernetes-cli
	brew install minikube
	#brew install hyperkit
	brew install kubernetes-helm
	brew install skaffold
	asdf plugin-add minikube https://github.com/alvarobp/asdf-minikube.git

list_asdf_plugins:
	asdf plugin list all

install_asdf_plugin_node:
	brew install gpg gawk
	asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
	asdf install nodejs latest
	asdf global nodejs latest
	# asdf local nodejs latest
	# https://github.com/asdf-vm/asdf-plugins

install_asdf_terraform:
	asdf plugin-add boundary https://github.com/asdf-community/asdf-hashicorp.git
	asdf plugin-add consul https://github.com/asdf-community/asdf-hashicorp.git
	asdf plugin-add nomad https://github.com/asdf-community/asdf-hashicorp.git
	asdf plugin-add packer https://github.com/asdf-community/asdf-hashicorp.git
	asdf plugin-add sentinel https://github.com/asdf-community/asdf-hashicorp.git
	asdf plugin-add serf https://github.com/asdf-community/asdf-hashicorp.git
	asdf plugin-add terraform https://github.com/asdf-community/asdf-hashicorp.git
	asdf plugin-add vault https://github.com/asdf-community/asdf-hashicorp.git
	asdf plugin-add waypoint https://github.com/asdf-community/asdf-hashicorp.git

