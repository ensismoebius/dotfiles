#!/bin/bash

# This script creates symbolic links from the home directory to the configuration files in this directory.

# Directory where the configuration files are located
CONFIG_DIR=$(cd "$(dirname "$0")" && pwd)

# Files and directories to link
FILES_TO_LINK=(
    ".bash_profile"
    ".vim"
    ".zshrc"
    ".vimrc"
    ".oh-my-zsh"
    ".p10k.zsh"
)

# Create symbolic links
for file in "${FILES_TO_LINK[@]}"; do
    source_file="$CONFIG_DIR/$file"
    target_link="$HOME/$file"

    echo "Creating link for $file at $target_link"
    ln -sf "$source_file" "$target_link"
done

echo "Done."
