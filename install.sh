#!/bin/bash

# This script creates symbolic links from the home directory to the configuration files in this directory.

# Directory where the configuration files are located
CONFIG_DIR=$(cd "$(dirname "$0")" && pwd)

# Files and directories to link to $HOME
FILES_TO_LINK=(
    ".bash_profile"
    ".vim"
    ".zshrc"
    ".vimrc"
    ".oh-my-zsh"
    ".p10k.zsh"
    ".gtkrc-2.0"
    ".Xresources"
)

# XDG config directories to link to ~/.config
XDG_CONFIG_DIRS_TO_LINK=(
    "dunst"
    "gtk-3.0"
    "gtk-4.0"
    "kitty"
    "qt5ct"
    "qt6ct"
    "rofi"
    "swaync"
    "udiskie"
    "waybar"
    "waypaper"
    "wlogout"
)

# Create symbolic links for files in $HOME
echo "Creating symbolic links for files in $HOME..."
for file in "${FILES_TO_LINK[@]}"; do
    source_file="$CONFIG_DIR/$file"
    target_link="$HOME/$file"

    echo "Creating link for $file at $target_link"
    ln -sf "$source_file" "$target_link"
done

# Create symbolic links for directories in ~/.config
echo "Creating symbolic links for directories in ~/.config..."
mkdir -p "$HOME/.config"
for dir in "${XDG_CONFIG_DIRS_TO_LINK[@]}"; do
    source_dir="$CONFIG_DIR/$dir"
    target_link="$HOME/.config/$dir"

    if [ -d "$source_dir" ]; then
        # If the target exists as a directory or a link, remove it first.
        if [ -e "$target_link" ]; then
            echo "Removing existing file/directory at $target_link"
            rm -rf "$target_link"
        fi
        echo "Creating link for $dir at $target_link"
        ln -s "$source_dir" "$target_link"
    else
        echo "Warning: Source directory $source_dir does not exist. Skipping."
    fi
done


# Set up XDG MIME handling for Nautilus
echo "Setting up XDG MIME handling for Nautilus..."

# Create necessary directories
mkdir -p ~/.local/share/applications/

# Create Nautilus desktop entry
cat > ~/.local/share/applications/nautilus-folder-handler.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Nautilus File Manager
GenericName=File Manager
Comment=Open folders with Nautilus
Icon=system-file-manager
Exec=nautilus %U
Terminal=false
MimeType=inode/directory;application/x-gnome-saved-search;
Categories=GNOME;GTK;System;Utility;Core;FileManager;
StartupNotify=true
EOF

# Create or update mimeapps.list
mkdir -p ~/.config
cat > ~/.config/mimeapps.list << 'EOF'
[Default Applications]
inode/directory=nautilus-folder-handler.desktop
x-scheme-handler/file=nautilus-folder-handler.desktop

[Added Associations]
inode/directory=nautilus-folder-handler.desktop;
x-scheme-handler/file=nautilus-folder-handler.desktop;
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications

echo "XDG MIME configuration for Nautilus completed."
echo "Done."
