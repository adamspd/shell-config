#!/usr/bin/env bash
# Adams' Environment Setup Script
# Version 1.0.0

set -eo pipefail  # Better error handling

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default settings
VERBOSE=0
FORCE=0

# Parse command line options
usage() {
    echo "Usage: $(basename "$0") [-v] [-f]"
    echo "  -v    Verbose mode (shows detailed logs)"
    echo "  -f    Force reinstall everything"
    echo "  -h    Show this help message"
}

while getopts "vfh" opt; do
  case $opt in
    v) VERBOSE=1 ;;
    f) FORCE=1 ;;
    h) usage; exit 0 ;;
    \?) usage; exit 1 ;;
  esac
done
shift $((OPTIND -1))

# Enable verbose mode if requested
[ $VERBOSE -eq 1 ] && set -x

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║                                               ║"
echo "║      Adams' Environment Setup Script          ║"
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Function to print status messages
print_status() {
    if [ $VERBOSE -eq 1 ] || [ -n "$2" ]; then
        echo -e "${GREEN}[+] $1${NC}"
    fi
}

print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

print_error() {
    echo -e "${RED}[!] $1${NC}"
}

print_verbose() {
    [ $VERBOSE -eq 1 ] && echo -e "${BLUE}[*] $1${NC}"
}

# Check if running as root (we don't want that)
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root!"
    exit 1
fi

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi

    case $OS in
        debian|ubuntu)
            OS="debian"
            print_status "Debian/Ubuntu detected"
            ;;
        fedora)
            OS="fedora"
            print_status "Fedora detected"
            ;;
        macos|darwin)
            OS="macos"
            print_status "MacOS detected"
            ;;
        *)
            OS="unknown"
            print_warning "Unknown OS detected, some features may not work"
            ;;
    esac
}

# Ask user which shell they want to use
select_shell() {
    echo -e "${YELLOW}Which shell do you want to use?${NC}"
    echo "1) bash"
    echo "2) zsh"
    while true; do
        read -rp "#? " choice < /dev/tty
        case $choice in
            1)
                SHELL_CHOICE="bash"
                print_status "Using bash as primary shell"
                break
                ;;
            2)
                SHELL_CHOICE="zsh"
                print_status "Using zsh as primary shell"
                break
                ;;
            *)
                print_error "Invalid choice, please select 1 for bash or 2 for zsh"
                ;;
        esac
    done
}

# Check for sudo and install if needed
ensure_sudo() {
    if ! command -v sudo &> /dev/null; then
        print_warning "sudo is not installed. Installing..."

        if [[ "$OS" == "debian" ]]; then
            su -c "apt-get update && apt-get install -y sudo && echo \"$USER ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/$USER && chmod 0440 /etc/sudoers.d/$USER && sudo -u $USER bash $0 $([ $VERBOSE -eq 1 ] && echo '-v') $([ $FORCE -eq 1 ] && echo '-f')"
            exit 0
        else
            print_error "Cannot automatically install sudo on this OS."
            exit 1
        fi
    fi

    print_verbose "sudo is available on this system"
}

# Install dependencies based on OS
install_dependencies() {
    print_status "Installing dependencies..." true

    if [[ "$OS" == "debian" ]]; then
        ensure_sudo

        # Update and install packages
        print_status "Updating package lists..." true
        sudo apt-get update

        print_status "Installing essential packages..." true
        if [ $FORCE -eq 1 ]; then
            # Force reinstall by explicitly adding --reinstall flag
            sudo apt-get install -y --reinstall \
                vim git curl wget nethogs \
                lsof net-tools build-essential \
                python3 python3-pip
            print_status "Forced reinstallation of packages" true
        else
            sudo apt-get install -y \
                vim git curl wget nethogs \
                lsof net-tools build-essential \
                python3 python3-pip
        fi

        # Install ZSH if selected
        if [[ "$SHELL_CHOICE" == "zsh" ]]; then
            print_status "Installing ZSH..." true
            # shellcheck disable=SC2046
            sudo apt-get install -y $([ $FORCE -eq 1 ] && echo "--reinstall") zsh
        fi

    elif [[ "$OS" == "macos" ]]; then
        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            print_status "Installing Homebrew..." true
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

            # Add Homebrew to PATH
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            print_verbose "Homebrew is already installed"
        fi

        print_status "Installing essential packages with Homebrew..." true
        if [ $FORCE -eq 1 ]; then
            brew reinstall vim git curl wget python3 lsof
        else
            brew install vim git curl wget python3 lsof
        fi

        # Install ZSH if selected
        if [[ "$SHELL_CHOICE" == "zsh" && ! -f /bin/zsh ]]; then
            print_status "Installing ZSH..." true
            if [ $FORCE -eq 1 ]; then
                brew reinstall zsh
            else
                brew install zsh
            fi
        fi

    else
        print_warning "Cannot automatically install packages on this OS."
        print_warning "Please manually install: vim, git, curl, wget, and other essential tools."
    fi

    print_status "Dependencies installation complete" true
}

install_yq_jq() {
    print_status "Installing yq and jq..." true

    # Install jq version 1.7.1
    if [[ "$OS" == "debian" ]]; then
        ensure_sudo
        JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64"
        sudo wget -q "$JQ_URL" -O /usr/bin/jq && sudo chmod +x /usr/bin/jq
    elif [[ "$OS" == "macos" ]]; then
        JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-macos-amd64"
        wget -q "$JQ_URL" -O /usr/local/bin/jq && chmod +x /usr/local/bin/jq
    fi

    # Install yq version 4.45.1
    YQ_VERSION="4.45.1"
    if [[ "$OS" == "debian" ]]; then
        YQ_BINARY="yq_linux_amd64"
        ensure_sudo
        wget "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" -O - | \
            sudo tar xz && sudo mv ${YQ_BINARY} /usr/bin/yq && sudo chmod +x /usr/bin/yq
    elif [[ "$OS" == "macos" ]]; then
        YQ_BINARY="yq_darwin_amd64"
        wget "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" -O - | \
            tar xz && mv ${YQ_BINARY} /usr/local/bin/yq && chmod +x /usr/local/bin/yq
    fi

    # Verify installations
    if command -v jq &> /dev/null && command -v yq &> /dev/null; then
        print_status "jq $(jq --version) and yq version ${YQ_VERSION} installed successfully" true
    else
        print_error "Failed to install jq or yq"
    fi
}

# Install Rust tools (fd-find and ripgrep)
install_rust_tools() {
    print_status "Setting up Rust environment..." true

    # Check if Rust is already installed
    if ! command -v rustup &> /dev/null || [ $FORCE -eq 1 ]; then
        print_status "Installing Rust..." true
        if [ $FORCE -eq 1 ] && [ -d "$HOME/.cargo" ]; then
            print_verbose "Removing existing Rust installation for force reinstall"
            rm -rf "$HOME/.cargo"
            rm -rf "$HOME/.rustup"
        fi

        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

        # Source Rust environment
        . "$HOME/.cargo/env"
    else
        print_verbose "Rust is already installed, sourcing environment"
        . "$HOME/.cargo/env"
    fi

    # Check and install fd-find
    if ! command -v fd &> /dev/null || [ $FORCE -eq 1 ]; then
        print_status "Installing fd-find..." true
        # shellcheck disable=SC2046
        cargo install $([ $FORCE -eq 1 ] && echo "--force") fd-find
    else
        print_verbose "fd-find is already installed"
    fi

    # Check and install ripgrep
    if ! command -v rg &> /dev/null || [ $FORCE -eq 1 ]; then
        print_status "Installing ripgrep..." true
        # shellcheck disable=SC2046
        cargo install $([ $FORCE -eq 1 ] && echo "--force") ripgrep
    else
        print_verbose "ripgrep is already installed"
    fi

    print_status "Rust tools installation complete" true
}

# Clone dotfiles repository
setup_dotfiles() {
    local dotfiles_dir="$HOME/.shell-config"
    local bash_config_dir="$HOME/.bash"

    print_status "Setting up the shell config..." true

    # Clone repository if it doesn't exist
    if [[ ! -d "$dotfiles_dir" ]]; then
        print_status "Cloning shell-config repository..." true
        # Replace with your actual repository URL
        git clone https://github.com/adamspd/shell-config.git "$dotfiles_dir"
    else
        print_status "shell-config repository already exists..." true
        if [ $FORCE -eq 1 ]; then
            print_status "Force resetting dotfiles repository..." true
            (cd "$dotfiles_dir" && git fetch && git reset --hard origin/main && git clean -fd)
            print_status "Force reset complete" true
        else
            print_verbose "Updating existing repository"
            (cd "$dotfiles_dir" && git pull)
        fi
    fi

    # Create config directory structure
    mkdir -p "$bash_config_dir/platform" "$bash_config_dir/modules"

    # Copy or symlink files
    print_status "Setting up configuration files..." true

    # Backup existing files
    # shellcheck disable=SC2155
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    # Backup and setup shell config
    if [[ "$SHELL_CHOICE" == "bash" ]]; then
        if [[ -f "$HOME/.bashrc" && ! -L "$HOME/.bashrc" ]]; then
            print_status "Backing up existing .bashrc to .bashrc.bak.$timestamp" true
            mv "$HOME/.bashrc" "$HOME/.bashrc.bak.$timestamp"
        fi
        cp "$dotfiles_dir/bashrc" "$HOME/.bashrc"
    else # zsh
        if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
            print_status "Backing up existing .zshrc to .zshrc.bak.$timestamp" true
            mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$timestamp"
        fi
        cp "$dotfiles_dir/zshrc" "$HOME/.zshrc"
    fi

    # Copy core files
    print_verbose "Copying core configuration files"
    cp "$dotfiles_dir/aliases.sh" "$bash_config_dir/"
    cp "$dotfiles_dir/functions.sh" "$bash_config_dir/"
    cp "$dotfiles_dir/env_vars.sh" "$bash_config_dir/"

    # Copy platform-specific files
    print_verbose "Copying platform-specific configuration files"
    cp "$dotfiles_dir/linux.sh" "$bash_config_dir/platform/"
    cp "$dotfiles_dir/macos.sh" "$bash_config_dir/platform/"

    # Copy module files
    print_verbose "Copying module configuration files"
    cp "$dotfiles_dir/django.sh" "$bash_config_dir/modules/"
    cp "$dotfiles_dir/web_dev.sh" "$bash_config_dir/modules/"

    # Set permissions
    print_verbose "Setting file permissions"
    chmod +x "$bash_config_dir"/*.sh
    chmod +x "$bash_config_dir/platform"/*.sh
    chmod +x "$bash_config_dir/modules"/*.sh

    print_status "Configuration files setup complete" true
}

# Change default shell if needed
change_shell() {
    if [[ "$SHELL_CHOICE" == "zsh" ]]; then
        # shellcheck disable=SC2155
        local zsh_path=$(which zsh)

        if [[ "$SHELL" != "$zsh_path" ]]; then
            print_status "Setting up ZSH as default shell..." true
            if grep -q "$zsh_path" /etc/shells; then
                print_status "Changing default shell to ZSH..." true
                sudo chsh -s "$zsh_path" "$USER"
            else
                print_warning "ZSH not found in /etc/shells. To change your default shell, run:"
                echo "   sudo sh -c \"echo $zsh_path >> /etc/shells\" && chsh -s $zsh_path"
            fi
        else
            print_verbose "ZSH is already your default shell"
        fi
    elif [[ "$SHELL_CHOICE" == "bash" ]]; then
        # shellcheck disable=SC2155
        local bash_path=$(which bash)

        if [[ "$SHELL" != "$bash_path" ]]; then
            print_status "Setting up BASH as default shell..." true
            if grep -q "$bash_path" /etc/shells; then
                print_status "Changing default shell to Bash..." true
                sudo chsh -s "$bash_path" "$USER"
            else
                print_warning "Bash not found in /etc/shells. To change your default shell, run:"
                echo "   sudo sh -c \"echo $bash_path >> /etc/shells\" && chsh -s $bash_path"
            fi
        else
            print_verbose "Bash is already your default shell"
        fi
    fi
}

# Generate local config file for machine-specific settings
create_local_config() {
    if [[ "$SHELL_CHOICE" == "bash" ]]; then
        local local_config="$HOME/.bash_local"
    else
        local local_config="$HOME/.zsh_local"
    fi

    if [[ ! -f "$local_config" ]] || [ $FORCE -eq 1 ]; then
        print_status "Creating local config file at $local_config" true
        cat > "$local_config" << EOF
# Machine-specific configuration
# Add your custom overrides here

# Example:
# export PATH="\$PATH:/custom/path"
EOF
    else
        print_verbose "Local config file already exists at $local_config"
    fi
}

# Print final instructions
print_final_instructions() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}       Installation Complete!        ${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo -e "\nNext steps:"
    echo -e "1. Restart your terminal or run: source ~/.${SHELL_CHOICE}rc"
    echo -e "2. Customize your local config at: ~/.${SHELL_CHOICE}_local"

    if [[ "$SHELL_CHOICE" != "${SHELL##*/}" ]]; then
        echo -e "3. Your default shell has been changed. Log out and log back in for it to take effect."
    fi
}

# Main installation process
main() {
    # Detect OS first
    detect_os

    # Select shell preference
    select_shell

    # Run installation steps
    install_dependencies
    install_yq_jq
    install_rust_tools
    setup_dotfiles
    change_shell
    create_local_config

    # In force mode, print what was forcibly reinstalled
    if [ $FORCE -eq 1 ]; then
        echo -e "\n${GREEN}Force mode was active. The following were forcibly reinstalled:${NC}"
        echo -e "- ${YELLOW}System packages${NC} (vim, git, curl, etc.)"
        [ -d "$HOME/.cargo" ] && echo -e "- ${YELLOW}Rust and cargo tools${NC} (fd-find, ripgrep)"
        echo -e "- ${YELLOW}Shell configurations${NC} (dotfiles, aliases, functions)"
    fi

    # Print final instructions
    print_final_instructions
}

# Start the installation
main
