#!/usr/bin/env bash
# Adams' Environment Setup Script
# Version 1.1.1

set -eo pipefail  # Better error handling

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log output formatting templates - define once, use many times
LOG_STATUS="${GREEN}[+]${NC}"
LOG_WARNING="${YELLOW}[!]${NC}"
LOG_ERROR="${RED}[!]${NC}"
LOG_INFO="${BLUE}[*]${NC}"
LOG_DEBUG="${YELLOW}[DEBUG]${NC}"

# Default settings
VERBOSE=0
FORCE=0

# Parse command line options
usage() {
    echo "Usage: $(basename "$0") [-v|-vv|-vvv|-vvvv] [-f]"
    echo "  -v      Basic verbose mode (shows important operations)"
    echo "  -vv     Detailed verbose mode (shows all operations)"
    echo "  -vvv    Debug mode (shows commands being executed)"
    echo "  -vvvv   Trace mode (shows everything, including variables)"
    echo "  -f      Force reinstall everything"
    echo "  -h      Show this help message"
}

# Process all arguments to handle stacked options like -vvv
for arg in "$@"; do
    case $arg in
        -v)
            VERBOSE=1
            ;;
        -vv)
            VERBOSE=2
            ;;
        -vvv)
            VERBOSE=3
            ;;
        -vvvv)
            VERBOSE=4
            ;;
        -f)
            FORCE=1
            ;;
        -h)
            usage
            exit 0
            ;;
        -*)
            # Check for combined options like -vf
            if [[ $arg == *v*f* ]]; then
                VERBOSE=1
                FORCE=1
            elif [[ $arg == *vv*f* ]]; then
                VERBOSE=2
                FORCE=1
            elif [[ $arg == *vvv*f* ]]; then
                VERBOSE=3
                FORCE=1
            elif [[ $arg == *vvvv*f* ]]; then
                VERBOSE=4
                FORCE=1
            elif [[ $arg == *v* ]]; then
                # Count v's in the argument
                V_COUNT=$(echo "$arg" | grep -o "v" | wc -l)
                VERBOSE=$V_COUNT
            else
                usage
                exit 1
            fi
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# Enable appropriate verbosity levels
if [ "$VERBOSE" -ge 4 ]; then
    # Trace mode - show everything
    set -xv
elif [ "$VERBOSE" -ge 3 ]; then
    # Debug mode - show commands
    set -x
fi

# Banner (always shown)
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════╗"
echo "║                                               ║"
echo "║      Adams' Environment Setup Script          ║"
echo "║                                               ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$VERBOSE" -ge 1 ]; then
    echo "Verbosity level: $VERBOSE"
fi

if [ $FORCE -eq 1 ]; then
    echo -e "${YELLOW}Force mode activated - will reinstall everything${NC}"
fi

# Optimized logging functions with verbosity levels
print_status() {
    local message="$1"
    local level=${2:-1}
    local force=${3:-0}

    # Early return pattern for efficiency
    [[ $force -eq 0 && $VERBOSE -lt $level ]] && return 0

    # Using printf instead of echo for better performance and portability
    printf "%b %s\n" "$LOG_STATUS" "$message"
}

print_warning() {
    printf "%b %s\n" "$LOG_WARNING" "$1"
}

print_error() {
    printf "%b %s\n" "$LOG_ERROR" "$1"
}

print_info() {
    local message="$1"
    local level=${2:-2}

    [[ $VERBOSE -lt $level ]] && return 0
    printf "%b %s\n" "$LOG_INFO" "$message"
}

print_debug() {
    [[ $VERBOSE -lt 3 ]] && return 0
    printf "%b %s\n" "$LOG_DEBUG" "$1"
}

# Helper function to print titles/headers consistently
print_title() {
    printf "\n%b%s%b\n" "${BLUE}" "$1" "${NC}"
}

# Helper function for drawing progress bars
print_progress() {
    # Only show progress bars in verbose level 2+
    [[ $VERBOSE -lt 2 ]] && return 0

    local percent=$1
    local width=${2:-50}
    local completed=$((percent * width / 100))
    local remaining=$((width - completed))

    # Draw the progress bar
    printf "\r[%b%${completed}s%b%${remaining}s%b] %d%%" \
           "$GREEN" "" "$YELLOW" "" "$NC" "$percent"

    # Print newline if 100%
    [[ $percent -eq 100 ]] && echo
}

# Check if running as root (we don't want that)
if [ "$(id -u)" -eq 0 ]; then
    print_error "This script should not be run as root!"
    exit 1
fi

# Check if component is already installed
is_installed() {
    local component="$1"
    case "$component" in
        "rust")
            command -v rustup &> /dev/null && command -v cargo &> /dev/null
            ;;
        "fd")
            command -v fd &> /dev/null
            ;;
        "ripgrep")
            command -v rg &> /dev/null
            ;;
        "jq")
            command -v jq &> /dev/null && [[ "$(jq --version 2>/dev/null)" == "jq-1.7.1" ]]
            ;;
        "yq")
            command -v yq &> /dev/null && [[ "$(yq --version 2>/dev/null)" == *"4.45.1"* ]]
            ;;
        "homebrew")
            command -v brew &> /dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif command -v lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi

    case $OS in
        debian|ubuntu)
            OS="debian"
            print_status "Debian/Ubuntu detected" 1 1
            ;;
        fedora)
            OS="fedora"
            print_status "Fedora detected" 1 1
            ;;
        macos|darwin)
            OS="macos"
            print_status "MacOS detected" 1 1
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
                print_status "Using bash as primary shell" 1 1
                break
                ;;
            2)
                SHELL_CHOICE="zsh"
                print_status "Using zsh as primary shell" 1 1
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
            print_status "Attempting to install sudo" 1 1

            # Check if we have su command available
            if command -v su &> /dev/null; then
                su -c "apt-get update && apt-get install -y sudo && echo \"$USER ALL=(ALL) NOPASSWD:ALL\" > /etc/sudoers.d/$USER && chmod 0440 /etc/sudoers.d/$USER"

                # Check if sudo was installed successfully
                if command -v sudo &> /dev/null; then
                    print_status "sudo installed successfully" 1 1
                    # Re-execute the script with the same arguments
                    # shellcheck disable=SC2046
                    sudo -u "$USER" bash "$0" $([ "$VERBOSE" -ge 1 ] && echo "-$(printf 'v%.0s' $(seq 1 "$VERBOSE"))") $([ $FORCE -eq 1 ] && echo '-f')
                    exit 0
                else
                    print_error "Failed to install sudo"
                    exit 1
                fi
            else
                print_error "Neither sudo nor su is available. Cannot continue."
                exit 1
            fi
        else
            print_error "Cannot automatically install sudo on this OS."
            exit 1
        fi
    fi

    print_info "sudo is available on this system" 2
}

# Install dependencies based on OS
install_dependencies() {
    print_status "Installing dependencies..." 1 1

    if [[ "$OS" == "debian" ]]; then
        ensure_sudo

        # Update and install packages
        print_status "Updating package lists..." 1
        if [ "$VERBOSE" -ge 3 ]; then
            sudo apt-get update
        else
            if sudo apt-get update -qq >/dev/null; then
                print_status "Package lists updated successfully" 1
            else
                print_error "Failed to update package lists"
                return 1
            fi
        fi

        print_status "Installing essential packages..." 1

        # Check what packages are already installed
        print_info "Checking existing packages" 2
        PACKAGES="vim git curl wget nethogs lsof net-tools build-essential python3 python3-pip dnsutils"

        # Add ZSH if selected
        if [[ "$SHELL_CHOICE" == "zsh" ]]; then
            PACKAGES="$PACKAGES zsh"
        fi

        if [ $FORCE -eq 1 ]; then
            # Force reinstall by explicitly adding --reinstall flag
            print_status "Force reinstalling packages..." 1
            if [ "$VERBOSE" -ge 3 ]; then
                sudo apt-get install -y --reinstall $PACKAGES
            else
                if sudo apt-get install -y --reinstall $PACKAGES >/dev/null; then
                    print_status "Packages reinstalled successfully" 1
                else
                    print_error "Failed to reinstall packages"
                    return 1
                fi
            fi
        else
            print_info "Installing only missing packages" 2
            if [ "$VERBOSE" -ge 3 ]; then
                sudo apt-get install -y $PACKAGES
            else
                if sudo apt-get install -y $PACKAGES >/dev/null; then
                    print_status "Packages installed successfully" 1
                else
                    print_error "Failed to install packages"
                    return 1
                fi
            fi
        fi

    elif [[ "$OS" == "macos" ]]; then
        # Check if Homebrew is installed
        if ! is_installed "homebrew" || [ $FORCE -eq 1 ]; then
            if [ $FORCE -eq 1 ] && is_installed "homebrew"; then
                print_status "Force mode: Homebrew already installed, continuing..." 1
            else
                print_status "Installing Homebrew..." 1 1
                if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
                    print_error "Failed to install Homebrew"
                    return 1
                fi
            fi

            # Add Homebrew to PATH
            if [[ -f /opt/homebrew/bin/brew ]]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [[ -f /usr/local/bin/brew ]]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
        else
            print_info "Homebrew is already installed" 2
        fi

        print_status "Installing essential packages with Homebrew..." 1
        PACKAGES="vim git curl wget python3 lsof"

        # Add ZSH if selected and not present
        if [[ "$SHELL_CHOICE" == "zsh" && ! -f /bin/zsh ]]; then
            PACKAGES="$PACKAGES zsh"
        fi

        if [ $FORCE -eq 1 ]; then
            print_status "Force reinstalling packages..." 1
            if ! brew reinstall $PACKAGES; then
                print_error "Failed to reinstall packages with Homebrew"
                return 1
            fi
        else
            print_info "Installing only missing packages" 2
            if ! brew install $PACKAGES; then
                print_error "Failed to install packages with Homebrew"
                return 1
            fi
        fi

    else
        print_warning "Cannot automatically install packages on this OS."
        print_warning "Please manually install: vim, git, curl, wget, and other essential tools."
    fi

    print_status "Dependencies installation complete" 1 1
}

install_yq_jq() {
    print_status "Installing yq and jq..." 1 1

    # Install jq version 1.7.1
    if ! is_installed "jq" || [ $FORCE -eq 1 ]; then
        print_status "Installing jq 1.7.1..." 1
        if [[ "$OS" == "debian" ]]; then
            ensure_sudo
            JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64"
            if [ "$VERBOSE" -ge 3 ]; then
                if ! (curl -fsSL "$JQ_URL" -o /tmp/jq && sudo mv /tmp/jq /usr/bin/jq && sudo chmod +x /usr/bin/jq); then
                    print_error "Failed to install jq"
                    return 1
                fi
            else
                if ! (curl -fsSL "$JQ_URL" -o /tmp/jq >/dev/null 2>&1 && sudo mv /tmp/jq /usr/bin/jq && sudo chmod +x /usr/bin/jq); then
                    print_error "Failed to install jq"
                    return 1
                fi
            fi
        elif [[ "$OS" == "macos" ]]; then
            JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-macos-amd64"
            if [ "$VERBOSE" -ge 3 ]; then
                if ! (curl -fsSL "$JQ_URL" -o /tmp/jq && mv /tmp/jq /usr/local/bin/jq && chmod +x /usr/local/bin/jq); then
                    print_error "Failed to install jq"
                    return 1
                fi
            else
                if ! (curl -fsSL "$JQ_URL" -o /tmp/jq >/dev/null 2>&1 && mv /tmp/jq /usr/local/bin/jq && chmod +x /usr/local/bin/jq); then
                    print_error "Failed to install jq"
                    return 1
                fi
            fi
        fi
    else
        print_info "jq 1.7.1 is already installed" 2
    fi

    # Install yq version 4.45.1
    if ! is_installed "yq" || [ $FORCE -eq 1 ]; then
        print_status "Installing yq 4.45.1..." 1
        YQ_VERSION="4.45.1"
        if [[ "$OS" == "debian" ]]; then
            YQ_BINARY="yq_linux_amd64"
            ensure_sudo
            if [ "$VERBOSE" -ge 3 ]; then
                if ! (curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" | tar xz -C /tmp && sudo mv "/tmp/${YQ_BINARY}" /usr/bin/yq && sudo chmod +x /usr/bin/yq); then
                    print_error "Failed to install yq"
                    return 1
                fi
            else
                if ! (curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" 2>/dev/null | tar xz -C /tmp && sudo mv "/tmp/${YQ_BINARY}" /usr/bin/yq && sudo chmod +x /usr/bin/yq); then
                    print_error "Failed to install yq"
                    return 1
                fi
            fi
        elif [[ "$OS" == "macos" ]]; then
            YQ_BINARY="yq_darwin_amd64"
            if [ "$VERBOSE" -ge 3 ]; then
                if ! (curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" | tar xz -C /tmp && mv "/tmp/${YQ_BINARY}" /usr/local/bin/yq && chmod +x /usr/local/bin/yq); then
                    print_error "Failed to install yq"
                    return 1
                fi
            else
                if ! (curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/${YQ_BINARY}.tar.gz" 2>/dev/null | tar xz -C /tmp && mv "/tmp/${YQ_BINARY}" /usr/local/bin/yq && chmod +x /usr/local/bin/yq); then
                    print_error "Failed to install yq"
                    return 1
                fi
            fi
        fi
    else
        print_info "yq 4.45.1 is already installed" 2
    fi

    # Verify installations
    if command -v jq &> /dev/null && command -v yq &> /dev/null; then
        print_status "jq $(jq --version) and yq $(yq --version) verified successfully" 1 1
    else
        print_error "Failed to verify jq or yq installation"
        return 1
    fi
}

# Install Rust tools (fd-find and ripgrep)
install_rust_tools() {
    print_status "Setting up Rust environment..." 1 1

    # Check if Rust is already installed
    if ! is_installed "rust" || [ $FORCE -eq 1 ]; then
        if [ $FORCE -eq 1 ] && is_installed "rust"; then
            print_status "Force removing existing Rust installation..." 1
            rm -rf "$HOME/.cargo" "$HOME/.rustup"
        fi

        print_status "Installing Rust..." 1
        if [ "$VERBOSE" -ge 3 ]; then
            if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
                print_error "Failed to install Rust"
                return 1
            fi
        else
            if ! curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1; then
                print_error "Failed to install Rust"
                return 1
            fi
        fi
    else
        print_info "Rust is already installed" 2
    fi

    # Source Rust environment (preserve existing PATH)
    if [[ -f "$HOME/.cargo/env" ]]; then
        # shellcheck source=/dev/null
        . "$HOME/.cargo/env"
    else
        export PATH="$HOME/.cargo/bin:$PATH"
    fi

    # Verify Rust installation
    if ! command -v cargo &> /dev/null; then
        print_error "Rust installation failed - cargo not found"
        return 1
    fi

    # Check and install fd-find
    if ! is_installed "fd" || [ $FORCE -eq 1 ]; then
        print_status "Installing fd-find..." 1
        if [ $FORCE -eq 1 ]; then
            if ! cargo install --force fd-find; then
                print_error "Failed to install fd-find"
                return 1
            fi
        else
            if ! cargo install fd-find; then
                print_error "Failed to install fd-find"
                return 1
            fi
        fi
        
        # Verify installation
        if ! command -v fd &> /dev/null; then
            print_error "fd-find installation verification failed"
            return 1
        fi
    else
        print_info "fd-find is already installed" 2
    fi

    # Check and install ripgrep
    if ! is_installed "ripgrep" || [ $FORCE -eq 1 ]; then
        print_status "Installing ripgrep..." 1
        if [ $FORCE -eq 1 ]; then
            if ! cargo install --force ripgrep; then
                print_error "Failed to install ripgrep"
                return 1
            fi
        else
            if ! cargo install ripgrep; then
                print_error "Failed to install ripgrep"
                return 1
            fi
        fi
        
        # Verify installation
        if ! command -v rg &> /dev/null; then
            print_error "ripgrep installation verification failed"
            return 1
        fi
    else
        print_info "ripgrep is already installed" 2
    fi

    print_status "Rust tools installation complete" 1 1
}

# Clone dotfiles repository
setup_dotfiles() {
    local dotfiles_dir="$HOME/.shell-config"
    local config_dir="$HOME/.${SHELL_CHOICE}"

    print_status "Setting up the shell config..." 1 1

    # Clone repository if it doesn't exist
    if [[ ! -d "$dotfiles_dir" ]]; then
        print_status "Cloning shell-config repository..." 1
        if [ "$VERBOSE" -ge 3 ]; then
            if ! git clone https://github.com/adamspd/shell-config.git "$dotfiles_dir"; then
                print_error "Failed to clone repository"
                return 1
            fi
        else
            if ! git clone -q https://github.com/adamspd/shell-config.git "$dotfiles_dir" 2>/dev/null; then
                print_error "Failed to clone repository"
                return 1
            fi
        fi
    else
        print_status "Shell-config repository already exists" 1
        if [ $FORCE -eq 1 ]; then
            print_status "Force resetting dotfiles repository..." 1
            if [ "$VERBOSE" -ge 3 ]; then
                if ! (cd "$dotfiles_dir" && git fetch && git reset --hard origin/main && git clean -fd); then
                    print_error "Failed to reset repository"
                    return 1
                fi
            else
                if ! (cd "$dotfiles_dir" && git fetch -q && git reset -q --hard origin/main && git clean -q -fd) 2>/dev/null; then
                    print_error "Failed to reset repository"
                    return 1
                fi
            fi
            print_status "Force reset complete" 1
        else
            print_info "Updating existing repository" 2
            if [ "$VERBOSE" -ge 3 ]; then
                (cd "$dotfiles_dir" && git pull)
            else
                (cd "$dotfiles_dir" && git pull -q) 2>/dev/null
            fi
        fi
    fi

    # Create config directory structure
    mkdir -p "$config_dir/platform" "$config_dir/modules"

    # Copy or symlink files
    print_status "Setting up configuration files..." 1

    # Backup existing files
    local timestamp=$(date +"%Y%m%d_%H%M%S")

    # Backup and setup shell config
    if [[ "$SHELL_CHOICE" == "bash" ]]; then
        if [ $FORCE -eq 1 ] || [[ -f "$HOME/.bashrc" ]]; then
            if [[ -f "$HOME/.bashrc" ]]; then
                print_status "Backing up existing .bashrc to .bashrc.bak.$timestamp" 1
                mv "$HOME/.bashrc" "$HOME/.bashrc.bak.$timestamp"
            fi
            cp "$dotfiles_dir/bashrc" "$HOME/.bashrc"
            print_status "Installed new .bashrc" 1
        fi
    else # zsh
        if [ $FORCE -eq 1 ] || [[ -f "$HOME/.zshrc" ]]; then
            if [[ -f "$HOME/.zshrc" ]]; then
                print_status "Backing up existing .zshrc to .zshrc.bak.$timestamp" 1
                mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$timestamp"
            fi
            cp "$dotfiles_dir/zshrc" "$HOME/.zshrc"
            
            # Update zshrc to use correct config directory
            sed -i.bak "s|BASH_CONFIG_DIR=\"\$HOME/\.bash\"|BASH_CONFIG_DIR=\"\$HOME/.${SHELL_CHOICE}\"|g" "$HOME/.zshrc"
            rm "$HOME/.zshrc.bak"
            
            print_status "Installed new .zshrc" 1
        fi
    fi

    # Copy core files (with force option)
    print_info "Copying core configuration files" 2
    cp "$dotfiles_dir/aliases.sh" "$config_dir/"
    cp "$dotfiles_dir/functions.sh" "$config_dir/"
    cp "$dotfiles_dir/env_vars.sh" "$config_dir/"

    # Copy platform-specific files
    print_info "Copying platform-specific configuration files" 2
    cp "$dotfiles_dir/linux.sh" "$config_dir/platform/"
    cp "$dotfiles_dir/macos.sh" "$config_dir/platform/"

    # Copy module files
    print_info "Copying module configuration files" 2
    cp "$dotfiles_dir/django.sh" "$config_dir/modules/"
    cp "$dotfiles_dir/web_dev.sh" "$config_dir/modules/"

    # Set permissions
    print_info "Setting file permissions" 2
    chmod +x "$config_dir"/*.sh "$config_dir/platform"/*.sh "$config_dir/modules"/*.sh

    print_status "Configuration files setup complete" 1 1
}

# Change default shell if needed
change_shell() {
    local current_shell
    current_shell=$(basename "$SHELL")
    
    if [[ "$SHELL_CHOICE" == "$current_shell" ]] && [ $FORCE -eq 0 ]; then
        print_info "$SHELL_CHOICE is already your default shell" 2
        return 0
    fi

    local shell_path
    shell_path=$(command -v "$SHELL_CHOICE")
    
    if [[ -z "$shell_path" ]]; then
        print_error "Could not find $SHELL_CHOICE executable"
        return 1
    fi

    print_status "Setting up $SHELL_CHOICE as default shell..." 1
    
    if grep -q "$shell_path" /etc/shells; then
        print_status "Changing default shell to $SHELL_CHOICE..." 1
        if sudo chsh -s "$shell_path" "$USER"; then
            print_status "Default shell changed successfully. You'll need to log out and back in for it to take effect." 1
        else
            print_warning "Failed to change default shell. You can change it manually with: chsh -s $shell_path"
        fi
    else
        print_warning "$SHELL_CHOICE not found in /etc/shells. To change your default shell, run:"
        echo "   sudo sh -c \"echo $shell_path >> /etc/shells\" && chsh -s $shell_path"
    fi
}

# Generate local config file for machine-specific settings
create_local_config() {
    local local_config="$HOME/.${SHELL_CHOICE}_local"

    # Don't overwrite existing local config, even with force
    if [[ ! -f "$local_config" ]]; then
        print_status "Creating local config file at $local_config" 1
        cat > "$local_config" << EOF
# Machine-specific configuration
# Add your custom overrides here

# Example:
# export PATH="\$PATH:/custom/path"
EOF
        print_status "Local config file created" 1
    else
        print_info "Local config file already exists at $local_config" 2
    fi
}

# Print final instructions
print_final_instructions() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}       Installation Complete!        ${NC}"
    echo -e "${GREEN}=====================================${NC}"

    # In force mode, print what was forcibly reinstalled
    if [ $FORCE -eq 1 ]; then
        echo -e "\n${GREEN}Force mode was active - the following were reinstalled:${NC}"
        echo -e "- ${YELLOW}System packages${NC} (vim, git, curl, etc.)"
        [ -d "$HOME/.cargo" ] && echo -e "- ${YELLOW}Rust and cargo tools${NC} (fd-find, ripgrep)"
        echo -e "- ${YELLOW}Shell configurations${NC} (dotfiles, aliases, functions)"
        echo -e "- ${YELLOW}jq and yq${NC} (latest versions)"
    fi

    echo -e "\nNext steps:"
    echo -e "1. Restart your terminal or run: source ~/.${SHELL_CHOICE}rc"
    echo -e "2. Customize your local config at: ~/.${SHELL_CHOICE}_local"

    if [[ "$SHELL_CHOICE" != "$(basename "$SHELL")" ]]; then
        echo -e "3. Your default shell has been changed. Log out and log back in for it to take effect."
    fi
    
    echo -e "\n${BLUE}For more information, visit: https://github.com/adamspd/shell-config${NC}"
    echo -e "${BLUE}Quick install: curl --proto '=https' --tlsv1.2 -sSf https://shell-config.adamspierredavid.com | bash -s -- -fvv${NC}"
}

# Main installation process
main() {
    # Detect OS first
    detect_os

    # Select shell preference
    select_shell

    # Run installation steps
    install_dependencies || { print_error "Dependencies installation failed"; exit 1; }
    install_yq_jq || { print_error "jq/yq installation failed"; exit 1; }
    install_rust_tools || { print_error "Rust tools installation failed"; exit 1; }
    setup_dotfiles || { print_error "Dotfiles setup failed"; exit 1; }
    change_shell
    create_local_config

    # Print final instructions
    print_final_instructions
}

# Start the installation
main