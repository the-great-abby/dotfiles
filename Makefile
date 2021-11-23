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
