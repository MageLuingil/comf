#!/bin/bash
set -e

declare -r COMF_BASE_URL="https://raw.githubusercontent.com/MageLuingil/comf/main"
declare -r COMF_PROMPT="https://gist.githubusercontent.com/MageLuingil/7efc661bf1dc0f13119ad79ccfe7aadf/raw"

download_file() {
	local srcfile="$1"
	local destfile="${2-$HOME/$(basename $1)}"
	local destdir="$(dirname "$destfile")"
	
	# Create missing directories
	if [[ ! -d "$destdir" ]]; then
		$verbose && echo "Creating $destdir/"
		mkdir -p "$destdir"
	fi
	
	if [[ $verbose && "$destfile" != - ]]; then
		echo "Fetching ${destfile#$HOME/}"
	fi
	
	# Download using available tools
	if hash curl 2>/dev/null; then
		curl -LSso "$destfile" "$1"
	elif hash wget 2>/dev/null; then
		wget --no-hsts -qO "$destfile" "$1"
	else
		echo >&2 "Unable to download file"
		return 1
	fi
}

setup_profile() {
	$verbose && echo "Adding env vars to .profile"
	
	cp ~/.profile ~/.profile-dist
	
	cat >>~/.profile <<-'EOF'
	
	###################################
	# Set session environment variables
	
	# export DICEWARE_WORDLIST=
	# export HOSTCOLOR="\[\e[1;38;5;249m\]"
	export VISUAL=vim
	export EDITOR="$VISUAL"
	EOF
}

setup_bashrc() {
	$verbose && echo "Merging .bashrc configs"
	
	cp ~/.bashrc ~/.bashrc-dist
	
	# Prepend custom settings to .bashrc
	download_file "$COMF_BASE_URL/.bashrc" - > ~/.bashrc
	
	# Append original .bashrc, removing duplicate lines, and lines modifying PS1
	(awk '/^[^#]/' .bashrc && echo "PS1=") | \
		grep -Fnf- ~/.bashrc-dist | \
		awk -F: '($2 !~ /^#/) { print $1 " s/^([[:space:]]*)(.*)/\\1# Removed by comf\\n\\1; # \\2/;" }' | \
		sed -rnf- -e'p' ~/.bashrc-dist >> ~/.bashrc
	
	# Source additional files
	cat - >>~/.bashrc <<-'EOF'
	
	#######################################
	### User specific aliases and functions
	
	for script in ~/.bashrc.d/*; do
	    [[ -x "$script" ]] && . $script
	done
	EOF
}

setup_bash_profile() {
	$verbose && echo "Fixing bash profile config load order"
	
	# Don't source .bashrc from .profile
	sed -ri 's/^([[:space:]]*).*?((\.|sh|bash|source) .*?.bashrc.*)/\1# Source .bashrc from .bash_profile instead\n\1# \2\n\1;/g' ~/.profile
	
	# Source .profile and .bashrc for interactive login shells
	download_file "$COMF_BASE_URL/.bash_profile"
}

setup_prompt() {
	download_file "$COMF_PROMPT" ~/.bashrc.d/prompt
	chmod +x ~/.bashrc.d/prompt
}

download_confs() {
	local -a conf_files=( .bashrc.d/aliases .gitconfig .inputrc .vimrc )
	local filename
	for filename in "${conf_files[@]}"; do
		download_file "$COMF_BASE_URL/$filename" ~/"$filename"
	done
}

setup_environment() {
	local OPTION OPTARG OPTIND
	local HOME="$HOME"
	local verbose=true
	while getopts "d:qv" OPTION
	do
		case "$OPTION" in
			d) HOME="$OPTARG" ;;
			q) verbose=false ;;
			v) verbose=true ;;
			*) return 1 ;;
		esac
	done
	
	$verbose && echo "Making a comfy home in $HOME"
	
	hash vim 2>/dev/null || sudo apt install -y vim
	
	[[ -f ~/.profile-dist ]] 	|| setup_profile
	[[ -f ~/.bashrc-dist ]] 	|| setup_bashrc
	[[ -f ~/.bash_profile ]] 	|| setup_bash_profile
	[[ -x ~/.bashrc.d/prompt ]] || setup_prompt
	
	download_confs
	
	[[ $- == *i* ]] && . ~/.bash_profile
}

setup_environment "$@"
