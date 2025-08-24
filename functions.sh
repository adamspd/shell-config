#!/usr/bin/env bash
#  ---------------------------------------------------------------------------
#
#  Description:  Core shell functions - making the shell do real work
#
#  Sections:
#  1.  Navigation & Display
#  2.  File & Directory Operations
#  3.  Search & Find
#  4.  Process Management
#  5.  Networking
#  6.  System Operations
#  7.  Development Tools
#  8.  Data Processing
#
#  ---------------------------------------------------------------------------

# ---------------------------------
# 1. NAVIGATION & DISPLAY
# ---------------------------------

# Enhanced cd with automatic ls
function cd {
    new_directory="$*"
    [ $# -eq 0 ] && new_directory=${HOME}

    # First cd to the directory
    builtin cd "${new_directory}" || return

    # Check if current path starts with home directory path
    current_path=$(pwd)
    if [[ "$current_path" == "$HOME"* ]]; then
        ls_sort
    else
        ls -a
    fi
}

# Go up multiple directory levels
function up {
    local levels=${1:-1}
    local result=""
    for ((i=1; i<=levels; i++)); do
        result="${result}../"
    done
    cd $result || return
}

# Sort ls output into categories and display
# shellcheck disable=SC2120
function ls_sort {
    # If directory argument provided, cd into it first
    if [ -n "$1" ]; then
        builtin cd "$1" || return 1
    fi

    entries=$(ls -A)
    printed=false

    clean_dirs() {
        while IFS= read -r line; do
            # shellcheck disable=SC2001
            echo "$line" | sed 's|\(/\)$||'
        done
    }

    print_category() {
        local title=$1
        local content=$2
        if [ -n "$content" ]; then
            $printed && echo
            echo -e "\e[1;34m=== $title ===\e[0m"
            echo "$content" | column -t
            printed=true
        fi
    }

    hidden_dirs=$(echo "$entries" | grep '^\.' | while read -r entry; do
        [ -d "$entry" ] && ls -ld --color=always "$entry"
    done | clean_dirs)
    print_category "Hidden Directories" "$hidden_dirs"

    hidden_files=$(echo "$entries" | grep '^\.' | while read -r entry; do
        [ -f "$entry" ] && ls -l --color=always "$entry"
    done)
    print_category "Hidden Files" "$hidden_files"

    dirs=$(echo "$entries" | grep -v '^\.' | while read -r entry; do
        [ -d "$entry" ] && ls -ld --color=always "$entry"
    done | clean_dirs)
    print_category "Directories" "$dirs"

    files=$(echo "$entries" | grep -v '^\.' | while read -r entry; do
        [ -f "$entry" ] && ls -l --color=always "$entry"
    done)
    print_category "Files" "$files"

    # cd back to original directory if we changed it
    if [ -n "$1" ]; then
        builtin cd - > /dev/null || return 1
    fi
}

# Show all aliases matching a pattern
function showa {
    grep --color=always -i -a1 "$@" ~/.bash/aliases.sh | grep -v '^\s*$' | less -FSRXc
}

# ---------------------------------
# 2. FILE & DIRECTORY OPERATIONS
# ---------------------------------

# Create directory and cd into it
function mcd {
    mkdir -pv "$1" && cd "$1" || return
}

# Extract most known archives with one command
function extract {
    if [ -f "$1" ] ; then
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Create a ZIP archive of a folder
function zipf {
    zip -r "$1".zip "$1"
}

# Count lines in file
function countlines {
    wc -l < "$1"
}

# Pretty print CSV
function cleancsv {
    sed -e 's/,,/, ,/g' -e 's/,,/, ,/g' "$1" | column -s, -t
}

function duf {
    fd -t f -t d . "${@:-.}" 2>/dev/null | xargs du -sk 2>/dev/null | sort -n |
    awk '{size=$1; $1=""; sub(/^ */, "");
          for(i=0; size>=1024; i++) size/=1024;
          unit=substr("KMGTP",i+1,1);
          printf("%.1f%s\t%s\n", size, unit, $0)}'
}

# ---------------------------------
# 3. SEARCH & FIND
# ---------------------------------

# Search man pages for a term
function mans {
    man "$1" | grep -iC2 --color=always "$2" | less
}

# Find files matching pattern
function ff {
    fd "$@"
}

# Find files starting with pattern
function ffs {
    fd "^$*"
}

# Find files ending with pattern
function ffe {
    fd "$*$"
}

# ---------------------------------
# 4. PROCESS MANAGEMENT
# ---------------------------------

# Find process IDs
function findPid {
    lsof -t -c "$@"
}

# List processes owned by my user
function my_ps {
    ps "$@" -u "$USER" -o pid,%cpu,%mem,start,time,bsdtime,command
}

# Kill processes matching a string
function pskill {
    pgrep -f "$1" | xargs -r kill -9
}

# List processes matching a string
function psrun {
    pgrep -af "$1"
}

# ---------------------------------
# 5. NETWORKING
# ---------------------------------

# Display useful host information
function ii {
    echo -e "\nYou are logged on ${RED:-}$HOST${RESET:-}"
    echo -e "\nAdditional information:" ; uname -a
    echo -e "\nUsers logged on:" ; w -h
    echo -e "\nCurrent date:" ; date
    echo -e "\nMachine stats:" ; uptime
    echo -e "\nPublic IP Address:" ; myip
    echo
}

# Get HTTP headers
function httpHeaders {
    curl -I -L "$@"
}

# Debug HTTP timing
function httpDebug {
    curl "$@" -o /dev/null -w "dns: %{time_namelookup} connect: %{time_connect} pretransfer: %{time_pretransfer} starttransfer: %{time_starttransfer} total: %{time_total}\n"
}

# Stop a process running on a specific port
function killport {
    local port=$1
    if [[ -z "$port" ]]; then
        echo "Usage: killport PORT_NUMBER"
        return 1
    fi

    # shellcheck disable=SC2155
    local pid=$(lsof -i :"$port" | awk 'NR>1 {print $2}' | uniq)
    if [[ -n "$pid" ]]; then
        echo "Killing process $pid running on port $port"
        kill -9 "$pid"
        echo "Process killed"
    else
        echo "No process found running on port $port"
    fi
}

# Scan the local network
function scannet {
    # shellcheck disable=SC2155
    local network=$(ip -o -f inet addr show | awk '!/127.0.0.1/ {print $4}' | head -1)
    if [[ -z "$network" ]]; then
        echo "Could not determine local network"
        return 1
    fi

    echo "Scanning network $network"
    sudo nmap -sP "$network"
}

function localip {
    hostname -I | awk '{ print $1 }';
}

# ---------------------------------
# 6. SYSTEM OPERATIONS
# ---------------------------------

# Execute command based on current shell
function execute_based_on_shell {
    local bash_command=$1
    local zsh_command=$2
    local unsupported_shell_message=${3:-'Unsupported shell. Please use bash or zsh.'}

    case $(ps -o comm= -p $$) in
        *bash)
            echo "Bash command: ${bash_command}"
            eval "${bash_command}"
            ;;
        *zsh)
            echo "ZSH command: ${zsh_command}"
            eval "${zsh_command}"
            ;;
        *)
            echo "${unsupported_shell_message}"
            ;;
    esac
}

# Show shell options
function show_option {
    execute_based_on_shell 'shopt' 'setopt'
}

# Case-insensitive completion
function cic {
    execute_based_on_shell 'set completion-ignore-case On' 'setopt no_case_glob'
}

function path {
  execute_based_on_shell "echo -e '${PATH//:/\\n}'" "echo -e '${PATH//:/\\n}'"
}

function zshaddhistory {
    case $1 in
        ls|*[bf]g|exit|pwd|clear|history|cd|'cd -'|'cd ..'|..|...|.3|.4|.5|.6|cat|ll)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

# ---------------------------------
# 7. DEVELOPMENT TOOLS
# ---------------------------------

# Protect content with hash
# usage :
# tar -c setup.* | protect (To get the hash of several files or a folder with tar)
# cat requirements.txt | protect (To get the hash of one file)
# This will create a hash that you can copy and send to someone else instead of the whole file and the person can
# use the function unprotect as described below to get the original file
# Thanks to https://github.com/romain-dartigues
function protect {
    gzip -9 | base64 -w0
    echo
}

# Unprotect hashed content
# usage :
# unprotect > filename  <<EOF
# hash_example (The base64 encoded string)
# EOF
# Thanks to https://github.com/romain-dartigues
function unprotect {
    base64 -d | gzip -d
}

# Git commit with current branch name as prefix
function gcb {
    # shellcheck disable=SC2155
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -z "$branch" ]]; then
        echo "Not in a git repository"
        return 1
    fi

    # Extract a clean branch name (remove ticket numbers, etc)
    # shellcheck disable=SC2155
    local prefix=$(echo "$branch" | sed -E 's/^([A-Za-z]+[-_][0-9]+[-_])?([A-Za-z0-9_-]+).*/\2/')

    if [[ -n "$1" ]]; then
        git commit -m "[$prefix] $1"
    else
        echo "Usage: gcb 'commit message'"
    fi
}

# ---------------------------------
# 8. DATA PROCESSING
# ---------------------------------

# JSON pretty print
function json_pretty {
    if [[ -f "$1" ]]; then
        python3 -m json.tool < "$1"
    else
        echo "$1" | python3 -m json.tool
    fi
}

# CSV to JSON conversion
function csv2json {
    if [[ -f "$1" ]]; then
        python3 -c "import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(open('$1'))], indent=4))"
    else
        echo "File not found: $1"
    fi
}

# Safely remove hidden files with protection
function rmb {
    # Check if we're in a dangerous location
    if [[ "$PWD" == "$HOME" || "$PWD" == "/" || "$PWD" =~ ^/usr ]]; then
        echo -e "\e[31mDANGER: Refusing to run in $PWD - this could damage your system!\e[0m"
        return 1
    fi

    # Show what would be deleted first
    echo -e "\e[33mFiles that would be deleted:\e[0m"
    ls -la -- .??* ?* 2>/dev/null

    # Ask for confirmation
    read -rp $'\e[31mAre you SURE you want to delete these files? This cannot be undone! (y/N): \e[0m' confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo "Removing hidden files in $PWD"
        rm -rf -- .??* ?* 2>/dev/null
        echo "Done!"
    else
        echo "Operation cancelled."
    fi
}

function resource {
    local shell_to_reload

    if [[ $# -eq 0 ]]; then
        # No argument provided, use current shell
        shell_to_reload=$(basename "$SHELL")
    else
        # Use provided argument
        shell_to_reload="$1"
    fi

    case "$shell_to_reload" in
        bash)
            echo "Resourcing bash configuration..."
            # shellcheck disable=SC1090
            source ~/.bashrc
            echo "Bash configuration reloaded!"
            ;;
        zsh)
            echo "Resourcing zsh configuration..."
            # shellcheck disable=SC1090
            source ~/.zshrc
            echo "Zsh configuration reloaded!"
            ;;
        *)
            echo "Unsupported shell: $shell_to_reload"
            echo "Usage: reload [bash|zsh]"
            echo "Without arguments, reloads current shell configuration"
            return 1
            ;;
    esac
}

# List log files in specified directory (default: /var/log)
function lslog {
    local log_dir=${1:-"/var/log"}
    fd -e log . "$log_dir" | sort
}

# Tail all log files in specified directory (default: /var/log)
function taillog {
    local log_dir=${1:-"/var/log"}
    # shellcheck disable=SC2155
    local logs=$(fd -e log . "$log_dir" | sort)
    if [[ -z "$logs" ]]; then
        echo "No log files found in $log_dir"
        return 1
    fi
    echo "Tailing logs in $log_dir (press Ctrl+C to stop)..."
    echo "$logs" | xargs sudo tail -f
}

# Show log file sizes in specified directory (default: /var/log)
function logsize {
    local log_dir=${1:-"/var/log"}
    fd -e log . "$log_dir" -x du -sh {} \; | sort -hr
}
