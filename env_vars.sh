#!/usr/bin/env bash
#  ---------------------------------------------------------------------------
#
#  Description: Core environment variables and shell settings
#
#  Sections:
#  1.  Path Configuration
#  2.  History Settings
#  3.  Display & Terminal Settings
#  4.  Shell-Specific Configuration
#  5.  Program-Specific Settings
#  6.  Local Overrides
#
#  ---------------------------------------------------------------------------

#   -----------------------------
#   1. PATH CONFIGURATION
#   -----------------------------

# Standard paths
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

# Add user's private bin if it exists
[[ -d "$HOME/bin" ]] && export PATH="$HOME/bin:$PATH"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Add other common paths if they exist
[[ -d "/usr/local/git/bin" ]] && export PATH="/usr/local/git/bin:$PATH"
[[ -d "/usr/local/mysql/bin" ]] && export PATH="/usr/local/mysql/bin:$PATH"

# Environment variables for tools
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"  # Rust
[[ -d "$HOME/.rbenv/bin" ]] && export PATH="$HOME/.rbenv/bin:$PATH"  # Ruby

#   -----------------------------
#   2. HISTORY SETTINGS
#   -----------------------------

# History file and size
export HISTFILE=~/.shell_history
export HISTFILESIZE=100000         # File size
export HISTSIZE=200000             # Command history size

# Dont' add these commands to history
export HISTIGNORE="&:ls:[bf]g:exit:pwd:clear:history:cd:cd -:cd ..:cd -:..:...:.3:.4:.5:.6:cat:ll"

# Ensure every command gets a timestamp
export HISTTIMEFORMAT="%F %T: "

#   ------------------------------
#   3. DISPLAY & TERMINAL SETTINGS
#   ------------------------------

# Block size for ls and du
export BLOCKSIZE=1024k

# Colors
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# GPG settings
# shellcheck disable=SC2155
export GPG_TTY=$(tty)

# Less improvements
export LESS='-R'                   # Raw control characters for colors
export LESS_TERMCAP_mb=$'\E[1;31m' # Start blinking
export LESS_TERMCAP_md=$'\E[1;36m' # Start bold
export LESS_TERMCAP_me=$'\E[0m'    # End mode
export LESS_TERMCAP_se=$'\E[0m'    # End standout
export LESS_TERMCAP_so=$'\E[01;44;33m' # Start standout
export LESS_TERMCAP_ue=$'\E[0m'    # End underline
export LESS_TERMCAP_us=$'\E[1;32m' # Start underline

# Default Editor
export EDITOR="vim"
export VISUAL="vim"

#   -------------------------------
#   4. SHELL-SPECIFIC CONFIGURATION
#   -------------------------------

# Detect which shell is being used and apply appropriate settings
case $(ps -o comm= -p $$) in
  *zsh)
    # ZSH History Configuration
    setopt HIST_EXPIRE_DUPS_FIRST     # Expire duplicate entries first
    setopt HIST_FIND_NO_DUPS          # Don't display duplicates during search
    setopt HIST_IGNORE_ALL_DUPS       # Remove older dups when added again
    setopt HIST_IGNORE_SPACE          # Don't record if command starts with space
    setopt HIST_REDUCE_BLANKS         # Remove superfluous blanks
    setopt INC_APPEND_HISTORY         # Add commands immediately
    export SAVEHIST=100000            # Save this many commands

    # ZSH Completion
    setopt AUTO_MENU                  # Show completion menu on tab press
    setopt COMPLETE_IN_WORD           # Complete from both ends
    setopt ALWAYS_TO_END              # Move cursor to end after completion

    # ZSH Miscellaneous
    setopt AUTO_CD                    # cd by typing directory name
    setopt AUTO_PUSHD                 # Push old dir onto stack
    setopt PUSHD_IGNORE_DUPS          # Don't store duplicates in stack
    setopt PUSHD_SILENT               # Don't print directory stack
    setopt EXTENDED_GLOB              # Extended globbing
    ;;

  *bash)
    # BASH History Configuration
    export HISTCONTROL=ignoreboth:ignoredups:erasedups  # Ignore duplicates
    shopt -s histappend               # Append to history, don't overwrite

    # Set the PROMPT_COMMAND to update history
    export PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r"

    # BASH Completion and Navigation
    shopt -s cdspell                  # Correct minor spelling errors in cd
    shopt -s dirspell                 # Correct spelling in directory completion
    shopt -s globstar                 # ** matches all files and directories/subdirectories
    shopt -s nocaseglob               # Case-insensitive globbing
    shopt -s autocd                   # cd by typing directory name

    # BASH Miscellaneous
    shopt -s checkwinsize             # Check window size after commands
    shopt -s cmdhist                  # Save multi-line commands as single line
    ;;
esac

#   -----------------------------
#   5. PROGRAM-SPECIFIC SETTINGS
#   -----------------------------

# Python settings
export PYTHONDONTWRITEBYTECODE=1     # Don't create .pyc files
export PYTHONUNBUFFERED=1            # Don't buffer Python output

# Node.js settings
export NODE_OPTIONS="--max-old-space-size=4096"  # Increase Node.js memory

# Java settings
if command -v java > /dev/null 2>&1; then
    # shellcheck disable=SC2155
    export JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || echo "/usr/lib/jvm/default-java")
fi

# Go settings
export GOPATH="$HOME/go"
[[ -d "$GOPATH/bin" ]] && export PATH="$GOPATH/bin:$PATH"

# Ruby settings
if command -v rbenv > /dev/null 2>&1; then
    eval "$(rbenv init -)"
fi

#   -----------------------------
#   6. LOCAL OVERRIDES
#   -----------------------------
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
