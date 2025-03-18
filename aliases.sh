# ---------------------------------------------------------------------------
#
# Description:  My consolidated BASH alias file - raw, transparent and goddamn useful
#
# Sections:
#  1.  Terminal Navigation & Display
#  2.  File Operations
#  3.  Searching
#  4.  Process Management
#  5.  Networking
#  6.  System Info & Monitoring
#  7.  System Operations
#  8.  Development Tools
#  9.  Editor Shortcuts
# 10.  Utility Aliases
#
# ---------------------------------------------------------------------------

# ---------------------------------
# 1. TERMINAL NAVIGATION & DISPLAY
# ---------------------------------

### Directory Navigation - get around fast ###
alias ..='cd ../'                                 # Go back 1 level
alias ...='cd ../../'                             # Go back 2 levels
alias .3='cd ../../../'                           # Go back 3 levels
alias .4='cd ../../../../'                        # Go back 4 levels
alias .5='cd ../../../../../'                     # Go back 5 levels
alias .6='cd ../../../../../../'                  # Go back 6 levels
alias cd..='cd ../'                               # Typo-friendly back nav
alias ~="cd ~"                                    # Home dir

### Terminal Display - keep it clean ###
alias c='clear'                                   # Clear screen
alias clr='clear'                                 # Alternative clear
alias h='history'                                 # Command history
alias j='jobs -l'                                 # List background jobs
alias fix_stty='stty sane'                        # Fix terminal when it breaks

### Listing - see what you've got ###
alias ls='ls -p --color=auto'                     # Basic colored list
alias la='ls -A --color=auto'                     # Show hidden files
alias l='ls -CF --color=auto'                     # Column format
alias ll='ls -alpGFh --color=auto'                # Long detail format

### Tree-like Listings - for better navigation ###
# Recursive directory listing in tree format
alias lr='ls -R | grep ":$" | sed -e "s/:$//" -e "s/[^-][^\/]*\//--/g" -e "s/^/   /" -e "s/-/|/"'
alias lr_paged='lr | less'                        # Paged tree listing
alias lx='ll -XB'                                 # Sort by extension
alias lk='ll -Sr'                                 # Sort by size
alias lt='ll -tr'                                 # Sort by time
alias lm='la | more'                              # Paged listing

# ---------------------------------
# 2. FILE OPERATIONS
# ---------------------------------

### Basic Operations - safer by default ###
alias cp='cp -iv'                                 # Interactive & verbose copy
alias mv='mv -iv'                                 # Interactive & verbose move
alias mkdir='mkdir -pv'                           # Create dirs with parents
alias md='mkdir -pv'                              # Shorthand mkdir
alias rd='rmdir'                                  # Remove empty dirs
alias dp='rm -rf'                                 # DELETE PERMANENT - USE WITH CAUTION!

### Disk Usage - know your limits ###
alias df='df -h'                                  # Human disk free
alias du='du -ch'                                 # Readable dir usage with total
alias usage='du -ch | grep total'                 # Total dir usage
alias totalsize='df -h /'                         # Total fs usage
alias dud='du -d 1 -h'                            # Directory size 1 level deep

### File Permissions - control your shit ###
alias chmod='chmod -cv'                           # Verbose permission changes

### File Creation - test files when you need 'em ###
alias make1mb='if [[ "$OSTYPE" == "darwin"* ]]; then mkfile 1m ./1MB.dat; else dd if=/dev/zero of=./1MB.dat bs=1024 count=1024; fi'
alias make5mb='if [[ "$OSTYPE" == "darwin"* ]]; then mkfile 5m ./5MB.dat; else dd if=/dev/zero of=./5MB.dat bs=1024 count=5120; fi'
alias make10mb='if [[ "$OSTYPE" == "darwin"* ]]; then mkfile 10m ./10MB.dat; else dd if=/dev/zero of=./10MB.dat bs=1024 count=10240; fi'

# ---------------------------------
# 3. SEARCHING
# ---------------------------------

### File Search - find your stuff fast ###
alias search='fd'                               # Search by name
alias ff='fd -t f'                              # Find files only
alias fdir='fd -t d'                            # Find dirs only (renamed from fd to avoid conflict)

### Text Search - grep what you need ###
alias grep='rg --color=auto'                    # Colored grep with ripgrep
alias egrep='rg -E --color=auto'                # Extended regex grep
alias fgrep='rg -F --color=auto'                # Fixed string grep
alias hs='history | rg'                         # Search history with ripgrep

# ---------------------------------
# 4. PROCESS MANAGEMENT
# ---------------------------------

### Process Listing - see what's running ###
alias psa='ps aux'                                # All processes
alias psg='ps aux | rg'                           # Process search with ripgrep

### Resource Hogs - catch the bastards ###
# Memory hogs - top memory-eating processes
alias memHogsTop='if [[ "$OSTYPE" == "darwin"* ]]; then top -l 1 -o rsize | head -20; else ps --sort=-rss -eo pid,comm,pmem | head -20; fi'
alias memHogsPs='if [[ "$OSTYPE" == "darwin"* ]]; then ps wwaxm -o pid,stat,vsize,rss,time,command | head -10; else ps --sort=-rss -eo pid,stat,vsize,rss,cputime,cmd:50 | head -10; fi'

# CPU hogs - top CPU-eating processes
alias cpu_hogs='if [[ "$OSTYPE" == "darwin"* ]]; then ps wwaxr -o pid,stat,%cpu,time,command | head -10; else ps aux --sort=-%cpu | head -10; fi'
alias cpu_hogs_s='if [[ "$OSTYPE" == "darwin"* ]]; then ps wwaxr -o pid,stat,%cpu,time,command | head -10; else ps aux --sort=-%cpu | head -10 | cut -c 1-150; fi'

### Monitoring - watch your system ###
alias topForever='if [[ "$OSTYPE" == "darwin"* ]]; then top -l 9999999 -s 10 -o cpu; else watch -n 10 "ps aux --sort=-%cpu | head -10"; fi'

# ---------------------------------
# 5. NETWORKING
# ---------------------------------

### Connectivity - check your connection ###
alias myip='curl ifconfig.me; echo -e "\n"'       # Public IP address
alias ping='ping -c 4'                            # 4 pings then stop
alias publicip='curl ifconfig.me'                 # Another public IP

### Port Monitoring - see what's open ###
alias netCons='lsof -i'                           # All net connections
alias lsock='sudo lsof -i -P'                     # Open sockets
alias lsockU='sudo lsof -nP | grep UDP'           # UDP sockets
alias lsockT='sudo lsof -nP | grep TCP'           # TCP sockets
alias openPorts='sudo lsof -i | grep LISTEN'      # Listening ports
alias ports='netstat -tulanp'                     # All ports summary
alias psportlisten='sudo lsof -i -P -n | grep LISTEN' # Listening ports

### Firewall - watch your perimeter ###
alias iptlist='sudo /sbin/iptables -L -n -v --line-numbers'  # IPTables rules
alias firewall='sudo ufw status verbose'          # UFW status
alias show_blocked='if [[ "$OSTYPE" == "darwin"* ]]; then ipfw list; else sudo ufw status; fi'

### DNS - name resolution ###
alias flushDNS='dscacheutil -flushcache'          # Flush DNS cache

### Network Traffic - watch the data ###
alias httpdump='sudo tcpdump -i any -s 0 -A port 80' # Dump HTTP traffic
alias dnsdump='sudo tcpdump -i any -s 0 port 53'     # Dump DNS traffic
alias sshdump='sudo tcpdump -i any port 22'          # Dump SSH traffic

### Utilities - other network tools ###
alias speedtest='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -' # Internet speed test
alias netspeed='nethogs'                          # Show current network speed

# ---------------------------------
# 6. SYSTEM INFO & MONITORING
# ---------------------------------

### System Info - know your machine ###
alias now='date +"%T"'                            # Current time
alias nowdate='date +"%d-%m-%Y"'                  # Current date
alias meminfo='free -m -l -t -h'                  # Memory usage
alias psmem='ps auxf | sort -nr -k 4'             # Memory-hungry processes
alias pscpu='ps auxf | sort -nr -k 3'             # CPU-hungry processes

### File Counting - quick stats ###
alias nf='echo $(ls -1 | wc -l)'                  # Count files in dir
alias numfiles='fd -t f | wc -l'                  # Count files recursive

# ---------------------------------
# 7. SYSTEM OPERATIONS
# ---------------------------------

### Terminal Power Tools - get real shit done ###
alias sudo='sudo '                                # Allow aliases to work with sudo
alias fuck='sudo $(history -p \!\!)'              # Rerun last command with sudo
alias please='sudo $(history -p \!\!)'            # Polite version of fuck
alias fucking='sudo'                              # When you're really frustrated
alias watch='watch -n 1'                          # Watch with 1-second refresh
### Maintenance - keep it running ###
# Smart update that adapts to your OS
alias update='if [[ "$OSTYPE" == "darwin"* ]]; then brew update && brew upgrade; else sudo apt-get update && sudo apt-get upgrade; fi'
alias reboot='sudo reboot'                        # Reboot system
alias shutdown='sudo shutdown -h now'             # Shutdown system

### Mount Operations - filesystem control ###
alias mountReadWrite='sudo mount -uw /'           # Remount as read-write

# ---------------------------------
# 8. DEVELOPMENT TOOLS
# ---------------------------------

### Git Shortcuts - version control on steroids ###
alias gs='git status'                              # Git status
alias gd='git diff'                                # Git diff
alias gl='git log --oneline --graph --decorate'   # Git log pretty
alias ga='git add'                                 # Git add
alias gc='git commit -m'                           # Git commit
alias gpl='git pull'                               # Git pull
alias gps='git push'                               # Git push
alias gco='git checkout'                           # Git checkout
alias gb='git branch'                              # Git branch

### Docker - container management ###
alias docker-compose='docker compose'             # Modern docker compose
alias dcu='docker-compose up'                     # Start containers
alias dcd='docker-compose down'                   # Stop containers
alias dcb='docker-compose build'                  # Build containers

# ---------------------------------
# 9. EDITOR SHORTCUTS
# ---------------------------------

### Config Files - quick access ###
alias zshconfig="vim ~/.zshrc"                    # Edit ZSH config
alias bashconfig="vim ~/.bashrc"                  # Edit BASH config
alias aliasconfig="vim ~/.bash/aliases.sh"        # Edit aliases
alias funcconfig="vim ~/.bash/functions.sh"       # Edit functions
alias sshconfig='vim ~/.ssh/config'               # Edit SSH config
alias profileconfig='vim ~/.profile'              # Edit profile
alias vimrc='vim ~/.vimrc'                        # Edit vimrc
alias hostsfile='sudo vim /etc/hosts'             # Edit hosts file

# ---------------------------------
# 10. UTILITY ALIASES
# ---------------------------------

### System Utilities - misc helpers ###
alias timestamp='date "+%Y%m%d-%H%M%S"'           # File timestamp
alias which='type -a'                             # Show all locations

### Data Processing - command line data science ###
alias sumcol='awk '\''{ sum += $1 } END { print sum }'\''' # Sum first column
alias avgcol='awk '\''{ sum += $1 } END { print sum/NR }'\''' # Average first column
alias maxcol='sort -n | tail -1'                  # Max value in column
alias mincol='sort -n | head -1'                  # Min value in column

### Alert System - notification ###
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

### SSH - key management ###
alias ssh-list='ls -l ~/.ssh'                     # List SSH keys

### History Tools - mastering your past ###
alias hcount='history | awk '\''{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}'\'' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl |  head -n25'  # Show most used commands
