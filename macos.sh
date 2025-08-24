#!/usr/bin/env bash
#  ---------------------------------------------------------------------------
#
#  Description: MacOS specific configuration and aliases
#
#  Sections:
#  1.  Environment Setup
#  2.  Applications & Tools
#  3.  File & Folder Operations
#  4.  Finder & GUI Integration
#  5.  System Operations
#  6.  Networking
#
#  ---------------------------------------------------------------------------

#   -----------------------------
#   1. ENVIRONMENT SETUP
#   -----------------------------

# Setup Homebrew if available
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
[[ -x /usr/local/bin/brew ]] && eval "$(/usr/local/bin/brew shellenv)"

# Set default editor
export EDITOR='vim'
export VISUAL='vim'

#   -----------------------------
#   2. APPLICATIONS & TOOLS
#   -----------------------------

# Application shortcuts
alias pycharm='open -b com.jetbrains.pycharm'       # Open PyCharm
alias intellij='open -b com.jetbrains.intellij'     # Open IntelliJ
alias webstorm='open -b com.jetbrains.webstorm'     # Open WebStorm
alias android='open -b com.jetbrains.android'       # Open Android Studio
alias vscode='open -b com.microsoft.VSCode'         # Open VS Code
alias chrome='open -a "Google Chrome"'              # Open Chrome
alias firefox='open -a Firefox'                     # Open Firefox

# Terminal enhancements
alias DT='tee ~/Desktop/terminalOut.txt'            # Pipe content to Desktop file
alias showFiles='defaults write com.apple.finder AppleShowAllFiles YES; killall Finder'  # Show hidden files
alias hideFiles='defaults write com.apple.finder AppleShowAllFiles NO; killall Finder'   # Hide hidden files

#   -------------------------------
#   3. FILE & FOLDER OPERATIONS
#   -------------------------------

# Safer trash than rm
# trash () { command mv "$@" ~/.Trash ; }             # Move to trash instead of delete
# alias rm='trash'                                    # Override rm with trash

# Quick Look file without opening
ql () { qlmanage -p "$*" >& /dev/null; }            # Quick Look preview

# Compress files
alias tgz='tar -czf'                                # Create gzipped tar archive
alias tbz='tar -cjf'                                # Create bzip2 tar archive

# Checksum
alias sha256='shasum -a 256'                        # Generate SHA-256 checksum
alias md5sum='md5'                                  # MD5 checksum (compatibility with Linux)

#   ---------------------------
#   4. FINDER & GUI INTEGRATION
#   ---------------------------

# Open Finder in current directory
alias f='open -a Finder ./'                         # Open Finder here

# cd to frontmost Finder window
cdf () {
    currFolderPath=$( /usr/bin/osascript <<EOT
        tell application "Finder"
            try
        set currFolder to (folder of the front window as alias)
            on error
        set currFolder to (path to desktop folder as alias)
            end try
            POSIX path of currFolder
        end tell
EOT
    )
    echo "cd to \"$currFolderPath\""
    cd "$currFolderPath" || return
}

# Reveal file in Finder
reveal() {
    [[ -e "$1" ]] && open -R "$1" || echo "File not found"
}

# Spotlight search
spotlight () { mdfind "kMDItemDisplayName == '$*' wc"; }     # Search by filename
spotlightContent () { mdfind -live "$@"; }                   # Search by content

#   ---------------------------------------
#   5. SYSTEM OPERATIONS
#   ---------------------------------------

# Cleanup operations
# Remove DS_Store files
if command -v fd >/dev/null 2>&1; then
    alias cleanupDS="fd -H '.DS_Store$' -t f -x rm {}"
else
    alias cleanupDS="find . -type f -name '*.DS_Store' -ls -delete"
fi

alias finderShowHidden='defaults write com.apple.finder ShowAllFiles TRUE; killall Finder'
alias finderHideHidden='defaults write com.apple.finder ShowAllFiles FALSE; killall Finder'
alias cleanupLS="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# Screen and power options
alias screensaverDesktop='/System/Library/Frameworks/ScreenSaver.framework/Resources/ScreenSaverEngine.app/Contents/MacOS/ScreenSaverEngine -background'
alias sleep_display='pmset displaysleepnow'         # Put display to sleep
alias lock='/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend'  # Lock screen

# System information
alias sysinfo='system_profiler SPHardwareDataType'  # Hardware info
alias battery='pmset -g batt'                       # Battery status

#   ---------------------------
#   6. NETWORKING
#   ---------------------------

# Network information
alias ipInfo0='ipconfig getpacket en0'              # Info on connections for en0
alias ipInfo1='ipconfig getpacket en1'              # Info on connections for en1
alias wifi_password='security find-generic-password -ga "AirPort" | grep "password:"'  # Show WiFi password
alias lsock_osx='sudo lsof -iTCP -sTCP:LISTEN -n -P'  # Display open sockets
alias wifi_scan='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/A/Resources/airport scan'  # Scan WiFi networks
