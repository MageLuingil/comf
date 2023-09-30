# Check for interactive mode to avoid breaking things like sftp
[[ $- == *i* ]] || return 0

# Source global definitions (for non-Debian systems)
# if [ -f /etc/bashrc ]; then
#     . /etc/bashrc
# fi

#####################
### Set shell options

shopt -s autocd
shopt -s globstar

####################
### History Settings

shopt -s histappend
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

############################
### Original Distro Settings

