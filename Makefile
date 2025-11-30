GLIBC_VER=2.31-r0

# GTD System Commands
.PHONY: gtd-wizard gtd-capture gtd-process gtd-review gtd-sync gtd-advise gtd-learn gtd-status

# GTD Interactive Wizard
gtd-wizard:
	@$(HOME)/code/dotfiles/bin/gtd-wizard

# Quick capture
gtd-capture:
	@echo "📥 Quick Capture"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@read -p "What do you want to capture? " item && \
		gtd-capture "$$item" || echo "❌ Capture failed"

# Process inbox
gtd-process:
	@gtd-process

# Review
gtd-review:
	@echo "📋 GTD Review"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "1) Daily review"
	@echo "2) Weekly review"
	@echo "3) Monthly review"
	@echo "4) Quarterly review"
	@echo "5) Yearly review"
	@echo ""
	@read -p "Choose (1-5): " choice && \
		if [ "$$choice" = "1" ]; then \
			gtd-review daily; \
		elif [ "$$choice" = "2" ]; then \
			gtd-review weekly; \
		elif [ "$$choice" = "3" ]; then \
			gtd-review monthly; \
		elif [ "$$choice" = "4" ]; then \
			gtd-review quarterly; \
		elif [ "$$choice" = "5" ]; then \
			gtd-review yearly; \
		else \
			echo "Invalid choice"; \
		fi

# Sync with Second Brain
gtd-sync:
	@gtd-brain-sync

# Get advice
gtd-advise:
	@echo "🤖 Get Advice"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@read -p "What do you need advice about? " question && \
		gtd-advise --random "$$question" || echo "❌ Advice failed"

# Learn GTD
gtd-learn:
	@gtd-learn

# System status
gtd-status:
	@echo "📊 GTD System Status"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Inbox items:"
	@ls -1 ~/Documents/gtd/0-inbox/*.md 2>/dev/null | wc -l | xargs echo "  "
	@echo ""
	@echo "Active projects:"
	@ls -1 ~/Documents/gtd/1-projects/*/README.md 2>/dev/null | wc -l | xargs echo "  "
	@echo ""
	@echo "Active tasks:"
	@find ~/Documents/gtd/tasks -name "*.md" -type f 2>/dev/null | wc -l | xargs echo "  "
	@echo ""
	@echo "Today's log entries:"
	@date +"%Y-%m-%d" | xargs -I {} cat ~/Documents/daily_logs/{}.txt 2>/dev/null | grep -c "^[0-9][0-9]:[0-9][0-9]" || echo "  0"
	@echo ""

.PHONY: setup wizard
setup wizard:
	@echo "╔════════════════════════════════════════════════════════════╗"
	@echo "║     Welcome to the Dotfiles Setup Wizard                  ║"
	@echo "╚════════════════════════════════════════════════════════════╝"
	@echo ""
	@bash -c ' \
	selected_targets=""; \
	while true; do \
		echo "┌────────────────────────────────────────────────────────────┐"; \
		echo "│  Main Menu - Select a category:                            │"; \
		echo "└────────────────────────────────────────────────────────────┘"; \
		echo ""; \
		echo "  1) Shell Configuration (zsh, bash, tmux, vim)"; \
		echo "  2) Development Tools (asdf, languages, editors)"; \
		echo "  3) Cloud & Infrastructure (AWS, Docker, Kubernetes)"; \
		echo "  4) Productivity Tools (Rectangle, Calendar, etc.)"; \
		echo "  5) System Setup (Homebrew, Xcode, Rosetta)"; \
		echo "  6) View Selected Items"; \
		echo "  7) Clear Selected Items"; \
		echo "  8) Run Selected Installations"; \
		echo "  9) Exit"; \
		echo ""; \
		read -p "Select an option [1-9]: " choice; \
		case $$choice in \
			1) \
				echo ""; \
				echo "┌─ Shell Configuration ────────────────────────────────┐"; \
				echo "│  1) Install zshrc (macOS)"; \
				echo "│  2) Install zshrc (generic)"; \
				echo "│  3) Install Oh My Zsh"; \
				echo "│  4) Setup tmux"; \
				echo "│  5) Setup vim"; \
				echo "│  6) Install Starship prompt"; \
				echo "│  7) Install Oh My Posh (macOS)"; \
				echo "│  8) Back to main menu"; \
				echo "└───────────────────────────────────────────────────────┘"; \
				read -p "Select [1-8]: " subchoice; \
				case $$subchoice in \
					1) selected_targets="$$selected_targets install_zshrc_mac "; echo "✓ Added: install_zshrc_mac"; ;; \
					2) selected_targets="$$selected_targets install_zshrc "; echo "✓ Added: install_zshrc"; ;; \
					3) selected_targets="$$selected_targets install_oh_my_zsh "; echo "✓ Added: install_oh_my_zsh"; ;; \
					4) selected_targets="$$selected_targets setup_tmux "; echo "✓ Added: setup_tmux"; ;; \
					5) selected_targets="$$selected_targets setup_vim "; echo "✓ Added: setup_vim"; ;; \
					6) selected_targets="$$selected_targets install_starship "; echo "✓ Added: install_starship"; ;; \
					7) selected_targets="$$selected_targets install_ohmyposh_mac "; echo "✓ Added: install_ohmyposh_mac"; ;; \
					8) ;; \
					*) echo "Invalid option"; ;; \
				esac; \
				;; \
			2) \
				echo ""; \
				echo "┌─ Development Tools ──────────────────────────────────┐"; \
				echo "│  Version Managers:"; \
				echo "│  1) Install asdf (version manager)"; \
				echo "│  2) Install mise (version manager, formerly rtx)"; \
				echo ""; \
				echo "│  Languages & Tools via asdf:"; \
				echo "│  3) Install Node.js via asdf"; \
				echo "│  4) Install Python via asdf"; \
				echo "│  5) Install Ruby via asdf"; \
				echo "│  6) Install Terraform via asdf"; \
				echo "│  7) Install JDK via asdf"; \
				echo ""; \
				echo "│  Languages & Tools via mise:"; \
				echo "│  8) Install Node.js via mise"; \
				echo "│  9) Install Python via mise"; \
				echo "│ 10) Install Ruby via mise"; \
				echo "│ 11) Install Terraform via mise"; \
				echo "│ 12) Install JDK via mise"; \
				echo "│ 13) Install HashiCorp tools via mise"; \
				echo ""; \
				echo "│  Editors & Tools:"; \
				echo "│ 14) Install Neovim"; \
				echo "│ 15) Install VS Code"; \
				echo "│ 16) Install DBeaver"; \
				echo "│ 17) Install Ripgrep"; \
				echo ""; \
				echo "│ 18) Back to main menu"; \
				echo "└───────────────────────────────────────────────────────┘"; \
				read -p "Select [1-18]: " subchoice; \
				case $$subchoice in \
					1) selected_targets="$$selected_targets install_asdf "; echo "✓ Added: install_asdf"; ;; \
					2) selected_targets="$$selected_targets install_mise "; echo "✓ Added: install_mise"; ;; \
					3) selected_targets="$$selected_targets install_asdf_plugin_node "; echo "✓ Added: install_asdf_plugin_node"; ;; \
					4) selected_targets="$$selected_targets install_python "; echo "✓ Added: install_python"; ;; \
					5) selected_targets="$$selected_targets install_ruby "; echo "✓ Added: install_ruby"; ;; \
					6) selected_targets="$$selected_targets install_terraform "; echo "✓ Added: install_terraform"; ;; \
					7) selected_targets="$$selected_targets install_jdk_via_asdf "; echo "✓ Added: install_jdk_via_asdf"; ;; \
					8) selected_targets="$$selected_targets install_mise_plugin_node "; echo "✓ Added: install_mise_plugin_node"; ;; \
					9) selected_targets="$$selected_targets install_mise_python "; echo "✓ Added: install_mise_python"; ;; \
					10) selected_targets="$$selected_targets install_mise_ruby "; echo "✓ Added: install_mise_ruby"; ;; \
					11) selected_targets="$$selected_targets install_mise_terraform "; echo "✓ Added: install_mise_terraform"; ;; \
					12) selected_targets="$$selected_targets install_jdk_via_mise "; echo "✓ Added: install_jdk_via_mise"; ;; \
					13) selected_targets="$$selected_targets install_mise_hashicorp_tools "; echo "✓ Added: install_mise_hashicorp_tools"; ;; \
					14) selected_targets="$$selected_targets install_neovim "; echo "✓ Added: install_neovim"; ;; \
					15) selected_targets="$$selected_targets install_vscode "; echo "✓ Added: install_vscode"; ;; \
					16) selected_targets="$$selected_targets install_dbeaver "; echo "✓ Added: install_dbeaver"; ;; \
					17) selected_targets="$$selected_targets install_ripgrep "; echo "✓ Added: install_ripgrep"; ;; \
					18) ;; \
					*) echo "Invalid option"; ;; \
				esac; \
				;; \
			3) \
				echo ""; \
				echo "┌─ Cloud & Infrastructure ─────────────────────────────┐"; \
				echo "│  1) Install AWS CLI"; \
				echo "│  2) Install Docker"; \
				echo "│  3) Install Kubernetes Tools"; \
				echo "│  4) Install Terraform (via asdf)"; \
				echo "│  5) Install Ollama"; \
				echo "│  6) Back to main menu"; \
				echo "└───────────────────────────────────────────────────────┘"; \
				read -p "Select [1-6]: " subchoice; \
				case $$subchoice in \
					1) selected_targets="$$selected_targets install_awscli "; echo "✓ Added: install_awscli"; ;; \
					2) selected_targets="$$selected_targets install_docker "; echo "✓ Added: install_docker"; ;; \
					3) selected_targets="$$selected_targets install_kube_tools "; echo "✓ Added: install_kube_tools"; ;; \
					4) selected_targets="$$selected_targets install_terraform "; echo "✓ Added: install_terraform"; ;; \
					5) selected_targets="$$selected_targets install_ollama "; echo "✓ Added: install_ollama"; ;; \
					6) ;; \
					*) echo "Invalid option"; ;; \
				esac; \
				;; \
			4) \
				echo ""; \
				echo "┌─ Productivity Tools ──────────────────────────────────┐"; \
				echo "│  1) Install Rectangle (window manager)"; \
				echo "│  2) Install Google Drive"; \
				echo "│  3) Install Firefox"; \
				echo "│  4) Install gcalcli (Google Calendar CLI)"; \
				echo "│  5) Install pomojs (Pomodoro timer)"; \
				echo "│  6) Install tmux"; \
				echo "│  7) Back to main menu"; \
				echo "└───────────────────────────────────────────────────────┘"; \
				read -p "Select [1-7]: " subchoice; \
				case $$subchoice in \
					1) selected_targets="$$selected_targets install_rectangle "; echo "✓ Added: install_rectangle"; ;; \
					2) selected_targets="$$selected_targets install_google_drive "; echo "✓ Added: install_google_drive"; ;; \
					3) selected_targets="$$selected_targets install_firefox "; echo "✓ Added: install_firefox"; ;; \
					4) selected_targets="$$selected_targets install_gcalcli "; echo "✓ Added: install_gcalcli"; ;; \
					5) selected_targets="$$selected_targets install_pomo "; echo "✓ Added: install_pomo"; ;; \
					6) selected_targets="$$selected_targets install_tmux "; echo "✓ Added: install_tmux"; ;; \
					7) ;; \
					*) echo "Invalid option"; ;; \
				esac; \
				;; \
			5) \
				echo ""; \
				echo "┌─ System Setup ────────────────────────────────────────┐"; \
				echo "│  1) Install Homebrew"; \
				echo "│  2) Upgrade Homebrew"; \
				echo "│  3) Install Xcode Command Line Tools"; \
				echo "│  4) Install Rosetta (for Apple Silicon)"; \
				echo "│  5) Install PowerShell"; \
				echo "│  6) Install Vagrant & VirtualBox"; \
				echo "│  7) Install Anaconda"; \
				echo "│  8) Back to main menu"; \
				echo "└───────────────────────────────────────────────────────┘"; \
				read -p "Select [1-8]: " subchoice; \
				case $$subchoice in \
					1) selected_targets="$$selected_targets install_homebrew "; echo "✓ Added: install_homebrew"; ;; \
					2) selected_targets="$$selected_targets upgrade_homebrew "; echo "✓ Added: upgrade_homebrew"; ;; \
					3) selected_targets="$$selected_targets install_xcode "; echo "✓ Added: install_xcode"; ;; \
					4) selected_targets="$$selected_targets install_rosetta "; echo "✓ Added: install_rosetta"; ;; \
					5) selected_targets="$$selected_targets install_pwsh "; echo "✓ Added: install_pwsh"; ;; \
					6) selected_targets="$$selected_targets install_vagrant_virtualbox "; echo "✓ Added: install_vagrant_virtualbox"; ;; \
					7) selected_targets="$$selected_targets install_anaconda "; echo "✓ Added: install_anaconda"; ;; \
					8) ;; \
					*) echo "Invalid option"; ;; \
				esac; \
				;; \
			6) \
				echo ""; \
				echo "┌─ Selected Items ─────────────────────────────────────┐"; \
				if [ -z "$$selected_targets" ]; then \
					echo "│  No items selected yet."; \
				else \
					echo "│  Selected targets:"; \
					for target in $$selected_targets; do \
						echo "│    - $$target"; \
					done; \
				fi; \
				echo "└───────────────────────────────────────────────────────┘"; \
				echo ""; \
				read -p "Press Enter to continue..."; \
				;; \
			7) \
				echo ""; \
				if [ -z "$$selected_targets" ]; then \
					echo "No items to clear."; \
				else \
					selected_targets=""; \
					echo "✓ Selected items cleared."; \
				fi; \
				echo ""; \
				read -p "Press Enter to continue..."; \
				;; \
			8) \
				if [ -z "$$selected_targets" ]; then \
					echo ""; \
					echo "⚠ No items selected. Please select items first."; \
					echo ""; \
					read -p "Press Enter to continue..."; \
				else \
					echo ""; \
					echo "┌─ Confirmation ───────────────────────────────────────┐"; \
					echo "│  The following will be installed/configured:"; \
					for target in $$selected_targets; do \
						echo "│    - $$target"; \
					done; \
					echo "└───────────────────────────────────────────────────────┘"; \
					echo ""; \
					read -p "Proceed with installation? [y/N]: " confirm; \
					if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
						echo ""; \
						echo "🚀 Starting installation..."; \
						echo ""; \
						for target in $$selected_targets; do \
							echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
							echo "Running: make $$target"; \
							echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
							make $$target || echo "⚠ Warning: $$target failed"; \
							echo ""; \
						done; \
						echo "✅ Installation complete!"; \
						echo ""; \
						read -p "Press Enter to continue..."; \
						selected_targets=""; \
					else \
						echo "Installation cancelled."; \
						read -p "Press Enter to continue..."; \
					fi; \
				fi; \
				;; \
			9) \
				echo ""; \
				if [ -n "$$selected_targets" ]; then \
					echo "⚠ You have unsaved selections. Exiting anyway."; \
				fi; \
				echo "👋 Goodbye!"; \
				exit 0; \
				;; \
			*) \
				echo "Invalid option. Please select 1-9."; \
				;; \
		esac; \
		echo ""; \
	done'

#install:
#	./bootstrap.sh
#	echo "run 'source ~/.bashrc' to update console"

install_zshrc:
	mv ~/.zshrc ~/.zshrc.old
	ln -s ${PWD}/zsh/zshrc ~/.zshrc
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

# Use mise to install and manage JDK
JDK_VERSION_MISE = "openjdk-16"
install_jdk_via_mise:
	mise plugin add java
	mise install java@${JDK_VERSION_MISE}
	mise use --global java@${JDK_VERSION_MISE}
	# mise use java@${JDK_VERSION_MISE}  # for local project

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
	mv ~/.zshrc ~/.zshrc.old
	ln -s ${PWD}/zsh/zshrc_mac ~/.zshrc
	brew install zsh-syntax-highlighting
	brew install zsh-autosuggestions
	#git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
	# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /themes/powerlevel10k

restore_zshrc_mac:
	mv ~/.zshrc.old ~/.zshrc

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

install_mise:
	brew install mise

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

PYTHON_VERSION_MISE = "latest"
install_mise_python:
	mise plugin add python
	mise install python@${PYTHON_VERSION_MISE}
	mise use --global python@${PYTHON_VERSION_MISE}
RUBY_VERSION = "latest"
# ASDF_RUBY_OVERWRITE_ARCH = "amd64"
install_ruby:
	asdf plugin-add ruby 
	asdf install ruby ${RUBY_VERSION}
	asdf global ruby ${RUBY_VERSION}

RUBY_VERSION_MISE = "latest"
install_mise_ruby:
	mise plugin add ruby
	mise install ruby@${RUBY_VERSION_MISE}
	mise use --global ruby@${RUBY_VERSION_MISE}
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

TF_VERSION_MISE = "latest"
install_mise_terraform:
	mise plugin add terraform
	mise install terraform@${TF_VERSION_MISE}
	mise use --global terraform@${TF_VERSION_MISE}
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

list_mise_plugins:
	mise plugin list

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

list_mise_plugins_all:
	mise plugin list --all
NODEJS_VERSION = "latest"
install_asdf_plugin_node:
	brew install gpg gawk
	asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
	asdf install nodejs ${NODEJS_VERSION}
	asdf global nodejs ${NODEJS_VERSION} 
	# asdf local nodejs ${NODEJS_VERSION} 
	# https://github.com/asdf-vm/asdf-plugins

NODEJS_VERSION_MISE = "latest"
install_mise_plugin_node:
	mise plugin add nodejs
	mise install nodejs@${NODEJS_VERSION_MISE}
	mise use --global nodejs@${NODEJS_VERSION_MISE}
	# mise use nodejs@${NODEJS_VERSION_MISE}  # for local project

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

install_mise_hashicorp_tools:
	mise plugin add boundary
	mise plugin add consul
	mise plugin add nomad
	mise plugin add packer
	mise plugin add sentinel
	mise plugin add serf
	mise plugin add terraform
	mise plugin add vault
	mise plugin add waypoint
	# Install latest versions globally
	mise install boundary@latest
	mise install consul@latest
	mise install nomad@latest
	mise install packer@latest
	mise install sentinel@latest
	mise install serf@latest
	mise install terraform@latest
	mise install vault@latest
	mise install waypoint@latest
	# Set global versions
	mise use --global boundary@latest
	mise use --global consul@latest
	mise use --global nomad@latest
	mise use --global packer@latest
	mise use --global sentinel@latest
	mise use --global serf@latest
	mise use --global terraform@latest
	mise use --global vault@latest
	mise use --global waypoint@latest

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


