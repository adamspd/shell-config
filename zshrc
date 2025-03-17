#!/usr/bin/env zsh
# Path to the bash config directory
BASH_CONFIG_DIR="$HOME/.bash"

# Source core configuration files
for file in "$BASH_CONFIG_DIR"/env_vars.sh \
            "$BASH_CONFIG_DIR"/functions.sh \
            "$BASH_CONFIG_DIR"/aliases.sh; do
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
    [[ -r "$BASH_CONFIG_DIR/modules/${module}.sh" ]] && source "$BASH_CONFIG_DIR/modules/${module}.sh"
done

# Local overrides (last to override anything)
[[ -r "$HOME/.zsh_local" ]] && source "$HOME/.zsh_local"

# ZSH-specific settings not covered in env_vars.sh
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{green}%n@%m%f:%F{blue}%~%f%F{yellow}${vcs_info_msg_0_}%f$ '