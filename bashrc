#!/usr/bin/env bash
# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Path to the bash config directory
BASH_CONFIG_DIR="$HOME/.bash"

# Source core configuration files
for file in "$BASH_CONFIG_DIR"/env_vars.sh \
            "$BASH_CONFIG_DIR"/functions.sh \
            "$BASH_CONFIG_DIR"/aliases.sh; do
    # shellcheck disable=SC1090
    [[ -r "$file" ]] && source "$file"
done

# Load platform-specific configuration
if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ -r "$BASH_CONFIG_DIR/platform/macos.sh" ]] && source "$BASH_CONFIG_DIR/platform/macos.sh"
else
    [[ -r "$BASH_CONFIG_DIR/platform/linux.sh" ]] && source "$BASH_CONFIG_DIR/platform/linux.sh"
fi

# Load modules (only if they exist)
for module in django web_dev; do
    # shellcheck disable=SC1090
    [[ -r "$BASH_CONFIG_DIR/modules/${module}.sh" ]] && source "$BASH_CONFIG_DIR/modules/${module}.sh"
done

# Local overrides (last to override anything)
[[ -r "$HOME/.bash_local" ]] && source "$HOME/.bash_local"

# BASH-specific prompt (not covered in env_vars.sh)
if [[ -n "$PS1" ]]; then
    # Colors
    RESET="\[\033[0m\]"
    GREEN="\[\033[1;32m\]"
    BLUE="\[\033[1;34m\]"
    YELLOW="\[\033[1;33m\]"

    # Git branch in prompt
    parse_git_branch() {
        git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
    }

    # Set the prompt: user@host:dir [git branch] $
    PS1="${GREEN}\u@\h${RESET}:${BLUE}\w${YELLOW}\$(parse_git_branch)${RESET}\$ "
fi
