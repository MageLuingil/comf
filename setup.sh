#!/bin/bash
set -eo pipefail

declare -r COMF_BASE_URL="https://raw.githubusercontent.com/MageLuingil/comf"

download_file() {
	local srcfile="$1"
	local destfile="${2-$HOME/$(basename $srcfile)}"
	local destdir="$(dirname "$destfile")"
	
	# Create missing directories
	if [[ ! -d "$destdir" ]]; then
		$verbose && echo "Creating $destdir/"
		mkdir -p "$destdir"
	fi
	
	if [[ $verbose && "$destfile" != - ]]; then
		echo "Fetching ${destfile#$HOME/}"
	fi
	
	# Determine whether we should use a temp file
	local outfile
	[[ "$destfile" == - ]] && outfile=$destfile || outfile="${destfile}.temp"
	
	# Download using available tools
	if hash curl 2>/dev/null; then
		curl -LSso "$outfile" "$srcfile"
	elif hash wget 2>/dev/null; then
		wget --no-hsts -qO "$outfile" "$srcfile"
	else
		echo >&2 "Unable to download file"
		return 1
	fi
	
	# Check for changes and backup old file
	if [[ -f "$outfile" ]]; then
		if cmp -s "$destfile" "$outfile"; then
			rm "$outfile"
		else
			mv --backup=numbered "$outfile" "$destfile"
		fi
	fi
}

setup_profile() {
	# The existence of .profile-dist indicates this has already been done
	[[ -f ~/.profile-dist ]] && return
	
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
	# The existence of .bashrc-dist indicates this has already been done
	[[ -f ~/.bashrc-dist ]] && return
	
	$verbose && echo "Merging .bashrc configs"
	
	mv ~/.bashrc ~/.bashrc-dist
	
	# Prepend custom settings to .bashrc
	download_file "$download_url/.bashrc" - > ~/.bashrc
	
	# Append original .bashrc, removing duplicate lines, and lines modifying PS1
	(awk '/^[^#]/' .bashrc && echo "PS1=") | \
		grep -Fnf- ~/.bashrc-dist | \
		awk -F: '($2 !~ /^#/) { print $1 " s/^([[:space:]]*)(.*)/\\1# Removed by comf\\n\\1: # \\2/;" }' | \
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
	# The existence of .bash_profile indicates this is already correct
	[[ -f ~/.bash_profile ]] && return
	
	$verbose && echo "Fixing bash profile config load order"
	
	# Don't source .bashrc from .profile
	sed -ri 's/^([[:space:]]*).*?((\.|sh|bash|source) .*?.bashrc.*)/\1# Source .bashrc from .bash_profile instead\n\1# \2\n\1:/g' ~/.profile
	
	# Source .profile and .bashrc for interactive login shells
	download_file "$download_url/.bash_profile"
}

download_confs() {
	local -a conf_files=( .bashrc.d/aliases .bashrc.d/prompt .gitconfig .inputrc .vimrc )
	local filename
	for filename in "${conf_files[@]}"; do
		download_file "$download_url/$filename" ~/"$filename"
		if [[ "$filename" == .bashrc.d/* ]]; then
			chmod +x ~/"$filename"
		fi
	done
}

move_xdg_user_dir() {
	local xdg_dir_name="$1" destdir="$2"
	local srcdir="$(xdg-user-dir $xdg_dir_name)"
	
	# Skip missing and already-correct directories
	[[ ! -d "$srcdir" || "$srcdir" == ~ || "$srcdir" == "$destdir" ]] && return
	
	$verbose && echo "Moving XDG_${xdg_dir_name}_DIR to $destdir"
	
	if [[ -d "$destdir" ]]; then
		# Destination directory already exists; move directory contents (if any)
		# Source directory will be deleted later (XDG doesn't like when we delete active user dirs)
		if [[ -z "$(find "$srcdir" -maxdepth 0 -empty)" ]]; then
			mv "$srcdir"/* $destdir
		fi
	else
		# Destination directory does not already exist; move entire directory
		mkdir -p "$(dirname $destdir)"
		mv "$srcdir" "$destdir"
	fi
	
	xdg-user-dirs-update --set "$xdg_dir_name" "$destdir"
	if [[ -d "$srcdir" ]]; then
		rm -r "$srcdir"
	fi
}

setup_xdg_dirs() {
	if ! hash xdg-user-dir 2>/dev/null || ! hash xdg-user-dirs-update 2>/dev/null; then
		$verbose && echo >&2 "Skipping XDG setup - xdg-user-dirs utility not found"
		return
	fi
	
	move_xdg_user_dir DESKTOP ~/System/Desktop
	move_xdg_user_dir DOWNLOAD ~/System/Downloads
	move_xdg_user_dir TEMPLATES ~/System/Templates
	move_xdg_user_dir PUBLICSHARE ~/System/Public
	move_xdg_user_dir MUSIC ~/Multimedia/Music
	move_xdg_user_dir PICTURES ~/Multimedia/Pictures
	move_xdg_user_dir VIDEOS ~/Multimedia/Videos
}

setup_environment() {
	local OPTION OPTARG OPTIND
	local HOME="$HOME"
	local download_filename
	local download_url="$COMF_BASE_URL/main"
	local verbose=true
	while getopts "b:d:f:qv" OPTION
	do
		case "$OPTION" in
			b) download_url="$COMF_BASE_URL/$OPTARG" ;;
			d) HOME="$OPTARG" ;;
			f) download_filename="$OPTARG" ;;
			q) verbose=false ;;
			v) verbose=true ;;
			*) return 1 ;;
		esac
	done
	
	$verbose && echo "Making a comfy home in $HOME"
	
	if [[ -n "$download_filename" ]]; then
		download_file "$download_url/$download_filename" ~/"$download_filename"
	else
		hash vim 2>/dev/null || sudo apt install -y vim
		
		# Update bash profile configs
		setup_profile
		setup_bashrc
		setup_bash_profile
		
		# Update all other configs
		download_confs
		
		# Clean up default XDG dirs from the root of home
		setup_xdg_dirs
	fi
	
	# Source new bash configs
	if [[ -r ~/.bash_profile ]]; then
		. ~/.bash_profile
	fi
}

setup_environment "$@"
