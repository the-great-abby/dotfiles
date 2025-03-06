GLIBC_VER=2.31-r0

#install:
#	./bootstrap.sh
#	echo "run 'source ~/.bashrc' to update console"

install_zshrc:
	ln -s ${PWD}/zsh/zshrc ~/.zshrc
install_zshrc_alias:
	mkdir -p ~/.zsh
	ln -s ${PWD}/zsh/zshalias ~/.zsh/zshalias
	# New-Item -Path ~/.zshrc -ItemType SymbolicLink -Target ${PWD}/zsh/zshrc
#install:
#	yarn
#
#start:
#	yarn start
#
#install_aws_amplify_cli:
#	yarn global add @aws-amplify/cli
#	#npm -g i @aws-amplify/cli
#	echo "Run 'amplify configure' from the command line"
##
#install_aws_amplify_cli_gitlab:
#	#yarn global add @aws-amplify/cli
#	npm -g i @aws-amplify/cli
#	echo "Run 'amplify configure' from the command line"

#test:
#	echo "Hi There!"

# Use asdf to install and manage JDK
install_jdk_via_asdf:
	# asdf current java
	asdf install java openjdk-16
	asdf global java openjdk-16
	# asdf shell java openjdk-16
	asdf local java openjdk-16

check_asdf_in_path:
	echo "PATH: ${`PATH | grep asdf`}"

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
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

install_zshrc_mac:
	ln -s ${PWD}/zsh/zshrc_mac ~/.zshrc
	brew install zsh-syntax-highlighting
	brew install zsh-autosuggestions
	#git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /themes/powerlevel10k

github_ssh_keygen:
	ssh-keygen -t ed25519 -C "github@augustmalson.com"

github_ssh_keygen_step2:
	eval "$(ssh-agent -s)"
	cat ~/.ssh/id_ed25519.pub

install_rectangle:
	brew install --cask rectangle

install_tmux:
	brew install tmux

install_pomo:
	npm install -g pomojs

install_gcalcli:
	brew install gcalcli

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

software_update_list:
	softwareupdate --list


install_xcode:
	xcode-select --install

install_anaconda:
	brew install anaconda

install_starship:
	brew install starship

install_pwsh:
	brew install powershell/tap/powershell
#	brew update
#    brew upgrade powershell
#	brew install pssh

install_asdf:
	brew install asdf

install_vagrant_virtualbox:
	brew install --cask virtualbox
	brew install --cask vagrant

install_vscode:
	brew install --cask visual-studio-code

install_ohmyposh_mac:
	brew install jandedobbeleer/oh-my-posh/oh-my-posh
update_ohmyposh_mac:
	brew update && brew upgrade oh-my-posh
check_ohmyposh_themes:
	ls $(brew --prefix oh-my-posh)/themes
install_nerdfont:
	brew install --cask font-open-dyslexic-nerd-font
install_dbeaver:
	brew install --cask dbeaver-community

install_ripgrep:
	brew install ripgrep
asdf_list_plugins:
	asdf plugin list all
PYTHON_VERSION = "latest"
install_python:
	asdf plugin-add python
	asdf install python ${PYTHON_VERSION}
	asdf global python ${PYTHON_VERSION}
RUBY_VERSION = "latest"
# ASDF_RUBY_OVERWRITE_ARCH = "amd64"
install_ruby:
	asdf plugin-add ruby 
	asdf install ruby ${RUBY_VERSION}
	asdf global ruby ${RUBY_VERSION}
ollama_pull_models:
	ollama pull llama3.2-vision
	ollama pull nomic-embed-text
	ollama pull llama3.2:1b
	# ollama pull marco-o1
# Override to install amd64, install specific version (can be "latest")
TF_VERSION = "latest"
ASDF_HASHICORP_OVERWRITE_ARCH = "amd64"
install_terraform:
#	brew install terraform
	asdf plugin-add terraform https://github.com/asdf-community/asdf-hashicorp.git
	# install and set globally
	asdf install terraform ${TF_VERSION}
	asdf global terraform ${TF_VERSION}

	# show version for good measure
	terraform -v

install_kube_tools:
	# brew install --cask docker
	brew install kubernetes-cli
	brew install --cask openlens
#	brew install minikube
	#brew install hyperkit
	brew install kubernetes-helm
	brew install skaffold
#	asdf plugin-add minikube https://github.com/alvarobp/asdf-minikube.git

install_google_drive:
	brew install --cask google-drive
list_asdf_plugins:
	asdf plugin list

install_docker:
	brew install --cask docker
install_ollama:
	brew install --cask ollama
install_neovim:
	brew install neovim
install_invoke_build_pwsh:
	Install-Module InvokeBuild
install_firefox:
	brew install --cask firefox

list_asdf_plugins_all:
	asdf plugin list all
NODEJS_VERSION = "latest"
install_asdf_plugin_node:
	brew install gpg gawk
	asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
	asdf install nodejs ${NODEJS_VERSION}
	asdf global nodejs ${NODEJS_VERSION} 
	# asdf local nodejs ${NODEJS_VERSION} 
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

# Aider Setup
# This doens't actually work the way I think it does
# in order for this to work as desired
# you want to dump this file in to the PWD
# of the codebase
install_aider_model_settings_file:
	ln -s ~/code/dotfiles/aider.model.settings.yaml ~/.aider.model.settings.yaml
install_aider_model_metadata_file:
	ln -s ~/code/dotfiles/aider.model.metadata.json ~/.aider.model.metadata.json


rb_kube_dd_init:
	echo "hi"
	make -f kubernetes/Makefile check-docker-running
	make -f kubernetes/Makefile kube-version
	make -f kubernetes/Makefile.variables -f kubernetes/Makefile kube-testme
	make -f kubernetes/Makefile.notes -f kubernetes/Makefile kube-readme
	make -f kubernetes/Makefile.notes -f kubernetes/Makefile show-docker-kube
	make -f kubernetes/Makefile kube-start-2-cluster

rb_kube_dd_step1:
	make -f kubernetes/Makefile kube-sample-deployment

rb_kube_docker_status:
	make -f kubernetes/Makefile check-docker-running

rb_kube_get_deployments:
	make -f kubernetes/Makefile kube-get-deployments
	make -f kubernetes/Makefile kube-get-info
	make -f kubernetes/Makefile kube-get-rollout-status

rb_notion_init:
	# ln -s ~/code/research
	# make -f ~/code/research/notion/Makefile.dotfile init
	# https://stackoverflow.com/questions/1789594/how-do-i-write-the-cd-command-in-a-makefile
	cd ~/code/research/notion/; \
		make -f Makefile.dotfile init

rb_notion_run:
	# ln -s ~/code/research
	# Docker commands don't work in a different directory ...
	# make -f ~/code/research/notion/Makefile.dotfile init
	# https://stackoverflow.com/questions/1789594/how-do-i-write-the-cd-command-in-a-makefile
	cd ~/code/research/notion/; \
		make -f Makefile.dotfile run



ln_claude_desktop:
	#ln -s ~/code/dotfiles/desktop.claude.desktop ~/.local/share/applications/claude.desktop
	# Create directory if needed
	mkdir -p ~/Library/Application\ Support/Claude/

	# Create/edit config file
	ln -s ~/code/dotfiles/desktop.claude.desktop ~/Library/Application\ Support/Claude/claude_desktop_config.json
