#!/usr/bin/env bash
#  ---------------------------------------------------------------------------
#
#  Description: Linux specific configuration and aliases
#
#  Sections:
#  1.  Environment Setup
#  2.  Package Management
#  3.  File & Folder Operations
#  4.  System Operations
#  5.  Process Management
#  6.  Networking
#
#  ---------------------------------------------------------------------------

#   -----------------------------
#   1. ENVIRONMENT SETUP
#   -----------------------------

# Set default editor
export EDITOR='vim'
export VISUAL='vim'

# If we have Snap, add it to PATH
[[ -d /snap/bin ]] && export PATH="/snap/bin:$PATH"

# If we have Go installed, set GOPATH
[[ -d $HOME/go ]] && export GOPATH="$HOME/go" && export PATH="$GOPATH/bin:$PATH"

#   -----------------------------
#   2. PACKAGE MANAGEMENT
#   -----------------------------

# Detect package manager and create aliases
if command -v apt-get &> /dev/null; then
    # Debian/Ubuntu
    alias update='sudo apt-get update && sudo apt-get upgrade'
    alias install='sudo apt-get install'
    alias remove='sudo apt-get remove'
    alias search='apt-cache search'
    alias autoremove='sudo apt-get autoremove'
    alias clean='sudo apt-get clean'
elif command -v dnf &> /dev/null; then
    # Fedora
    alias update='sudo dnf update'
    alias install='sudo dnf install'
    alias remove='sudo dnf remove'
    alias search='dnf search'
    alias autoremove='sudo dnf autoremove'
elif command -v pacman &> /dev/null; then
    # Arch Linux
    alias update='sudo pacman -Syu'
    alias install='sudo pacman -S'
    alias remove='sudo pacman -R'
    alias search='pacman -Ss'
    alias autoremove='sudo pacman -Rns $(pacman -Qtdq)'
else
    echo "No supported package manager found. Manual aliases may be needed."
fi

#   -------------------------------
#   3. FILE & FOLDER OPERATIONS
#   -------------------------------

# Safer rm alternatives
#if command -v trash-put &> /dev/null; then
#    alias rm='trash-put'                            # Use trash-cli if installed
#elif command -v gio &> /dev/null; then
#    alias rm='gio trash'                            # Use gio trash if available
#fi

# File listing with extra information
alias dirsize='du -sch .[!.]* * | sort -h'          # Directory sizes including hidden

# Permissions
alias chown_mine='sudo chown -R $(id -u):$(id -g)'  # Take ownership of files
alias chx='chmod +x'                                # Make file executable

#   ---------------------------------------
#   4. SYSTEM OPERATIONS
#   ---------------------------------------

# System information
alias distro='cat /etc/*-release'                   # Show Linux distribution
alias cpu='cat /proc/cpuinfo | grep "model name" | head -1'  # CPU info
alias meminfo='free -h'                             # Memory info
alias disk='df -h | grep -v "tmpfs\|udev"'          # Disk usage

# System maintenance
alias update_grub='sudo update-grub'                # Update GRUB
alias kernels='dpkg --list | grep linux-image'      # List installed kernels
alias services='systemctl list-units --type=service'  # List active services

# Power management
alias suspend='systemctl suspend'                   # Put system in suspend mode
alias poweroff='systemctl poweroff'                 # Power off the system
alias reboot='systemctl reboot'                     # Reboot the system

# System logs
alias journalctl_errors='journalctl -p 3 -xb'       # Show error messages from journal
alias syslog='tail -f /var/log/syslog'              # Show system log

#   ---------------------------
#   5. PROCESS MANAGEMENT
#   ---------------------------

# Service management
alias start='sudo systemctl start'                  # Start a systemd service
alias stop='sudo systemctl stop'                    # Stop a systemd service
alias restart='sudo systemctl restart'              # Restart a systemd service
alias status='systemctl status'                     # Check service status

# Memory optimization
alias drop_caches='sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"'  # Clear memory caches
alias memrelease='sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches; swapoff -a; swapon -a"'  # Release memory and reset swap

#   ---------------------------
#   6. NETWORKING
#   ---------------------------

# Firewall
alias ufw_status='sudo ufw status verbose'          # Show UFW status and rules
alias ufw_allow='sudo ufw allow'                    # Allow a port/service
alias ufw_deny='sudo ufw deny'                      # Deny a port/service
alias ufw_list='sudo ufw status numbered'           # List firewall rules with numbers

# Network tools
alias public_ip='curl -s ifconfig.me'               # Show public IP
alias listen='sudo netstat -tulanp | grep LISTEN'   # Show listening ports
alias connections='sudo netstat -tulanp'            # Show all connections
alias route_table='route -n'                        # Show routing table

# SSH utilities
alias ssh_restart='sudo systemctl restart ssh'      # Restart SSH service
alias sshd_restart='sudo systemctl restart sshd'    # Restart SSHD service
alias ssh_genkey='ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)-$(date +%Y-%m-%d)"'  # Generate SSH key with useful comment
