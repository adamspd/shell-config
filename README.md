# Shell Configuration Framework

A transparent, modular shell environment setup that puts you in control. No frameworks, no magic, just clean shell configuration that you can understand and customize.

## Quick Install

```bash
curl --proto '=https' --tlsv1.2 -sSf https://shell-config.adamspierredavid.com | bash -s -- -fvv
```

## Features

- **Shell Choice**: Support for both Bash and Zsh with identical functionality
- **Modular Design**: Organized into logical sections (aliases, functions, environment variables)
- **Platform Support**: Linux (Debian/Ubuntu) and macOS with platform-specific optimizations
- **Modern Tools**: Includes fd-find, ripgrep, jq, yq for enhanced productivity
- **Transparent**: Every configuration file is readable and editable
- **No Lock-in**: Standard shell configuration that works everywhere

## What Gets Installed

### Core Tools
- **fd-find**: Fast file finder (replaces `find`)
- **ripgrep**: Lightning-fast text search (replaces `grep`)
- **jq 1.7.1**: JSON processor
- **yq 4.45.1**: YAML processor
- **Rust toolchain**: For building the above tools

### Shell Configuration
- **200+ aliases**: Productivity shortcuts for common tasks
- **50+ functions**: Advanced shell operations
- **Environment optimization**: History, colors, and shell behavior
- **Platform modules**: OS-specific enhancements
- **Development modules**: Django, web development shortcuts

### Directory Structure
```
~/.bash/                    # Bash configuration
├── aliases.sh              # All aliases organized by category
├── functions.sh            # Shell functions for complex operations
├── env_vars.sh             # Environment variables and shell settings
├── platform/
│   ├── linux.sh           # Linux-specific configuration
│   └── macos.sh            # macOS-specific configuration
└── modules/
    ├── django.sh           # Django development shortcuts
    └── web_dev.sh          # Web development tools

~/.zsh/                     # Zsh configuration (if selected)
├── [same structure as above]
```

## Installation Options

### Basic Installation
```bash
curl -sSf https://shell-config.adamspierredavid.com | bash
```

### Verbose Installation
```bash
# Show important operations
curl -sSf https://shell-config.adamspierredavid.com | bash -s -- -v

# Show all operations
curl -sSf https://shell-config.adamspierredavid.com | bash -s -- -vv

# Debug mode (show commands)
curl -sSf https://shell-config.adamspierredavid.com | bash -s -- -vvv

# Trace mode (show everything)
curl -sSf https://shell-config.adamspierredavid.com | bash -s -- -vvvv
```

### Force Reinstall
```bash
# Reinstall everything
curl -sSf https://shell-config.adamspierredavid.com | bash -s -- -f

# Force with verbose output
curl -sSf https://shell-config.adamspierredavid.com | bash -s -- -fvv
```

### Manual Installation
```bash
git clone https://github.com/adamspd/shell-config.git ~/.shell-config
cd ~/.shell-config
./install.sh -v
```

## Key Aliases

### Navigation
- `..`, `...`, `.3`, `.4`, `.5`, `.6` - Navigate up directory levels
- `~` - Go to home directory
- `c`, `clr` - Clear screen

### File Operations
- `ll` - Detailed file listing with colors
- `la` - Show hidden files
- `dp` - Delete permanently (use with caution!)
- `md` - Create directories with parents

### Search (Modern Tools)
- `grep` → `rg` (ripgrep with colors)
- `ff` - Find files (using fd)
- `fdir` - Find directories
- `hs` - Search command history

### System Monitoring
- `memHogsTop` - Top memory-consuming processes
- `cpu_hogs` - Top CPU-consuming processes
- `openPorts` - Show listening ports
- `myip` - Show public IP address

### Git Shortcuts
- `gs` - Git status
- `gd` - Git diff
- `gl` - Pretty git log
- `ga` - Git add
- `gc` - Git commit with message

### Development
- `pm` - Django manage.py wrapper
- `pmr` - Django runserver
- `servehere` - HTTP server in current directory
- `killport` - Stop process on specific port

## Key Functions

### File Management
- `extract` - Extract any archive format
- `zipf` - Create ZIP archive
- `mkcd` - Create directory and cd into it

### Search & Find
- `ff` - Find files by name
- `mans` - Search man pages
- `json_pretty` - Pretty print JSON

### System Operations
- `up N` - Go up N directory levels
- `ii` - Show system information
- `resource` - Reload shell configuration

### Development
- `gcb` - Git commit with branch prefix
- `killport` - Stop process on port
- `httpHeaders` - Get HTTP headers

## Customization

### Local Configuration
Add machine-specific settings to `~/.bash_local` or `~/.zsh_local`:

```bash
# Example local configuration
export PATH="$PATH:/custom/path"
alias myserver="ssh user@myserver.com"
export PROJECT_DIR="/path/to/projects"
```

### Module Development
Create custom modules in `~/.bash/modules/` or `~/.zsh/modules/`:

```bash
# ~/.bash/modules/my_project.sh
alias deploy="./deploy.sh"
alias logs="tail -f /var/log/myapp.log"

function project_status() {
    echo "Checking project status..."
    # Your custom logic here
}
```

## Platform-Specific Features

### Linux
- Package manager detection (apt, dnf, pacman)
- Systemd service management
- UFW firewall shortcuts
- Network diagnostic tools

### macOS
- Homebrew integration
- Application shortcuts (PyCharm, VS Code, etc.)
- Finder integration
- Quick Look support

## Requirements

- **Operating System**: Linux (Debian/Ubuntu) or macOS
- **Network**: Internet connection for downloading tools
- **Shell**: Bash 4.0+ or Zsh 5.0+
- **Disk Space**: ~50MB for all tools

## Troubleshooting

### History Not Working
If command history isn't working properly:
```bash
# Check history configuration
echo $HISTFILE
echo $HISTSIZE

# Reload configuration
source ~/.bashrc  # or ~/.zshrc
```

### Tools Not Found
If fd or rg commands aren't found:
```bash
# Check if Rust tools are in PATH
echo $PATH | grep cargo

# Manually source Rust environment
source ~/.cargo/env
```

### Permission Issues
If you get permission errors:
```bash
# The script should not be run as root
# If you need sudo access, the script will prompt for it
```

## Philosophy

This configuration framework follows these principles:

1. **Transparency**: Every file is readable and documented
2. **No Magic**: No hidden frameworks or complex abstractions
3. **Modularity**: Features are organized into logical, optional modules
4. **Compatibility**: Works on standard shell environments
5. **Performance**: Fast startup times and efficient operations
6. **Control**: You decide what gets installed and configured

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on both Linux and macOS if possible
5. Submit a pull request

## License

MIT License - Use this configuration however you want.

## Support

- **Issues**: [GitHub Issues](https://github.com/adamspd/shell-config/issues)
- **Documentation**: This README and inline comments
- **Philosophy**: If you can't understand it, it doesn't belong here