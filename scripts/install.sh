#!/bin/bash
#
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
# and installs all the necessary dependencies.

# Install dependencies
echo "Installing dependencies..."

# Check if yay is installed
if ! command -v yay &> /dev/null
then
    echo "yay could not be found, installing it now."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Install packages with yay
yay -S --needed --noconfirm hyprland waybar wofi kitty nautilus firefox mako swaybg polkit-kde-agent qt5ct qt6ct kvantum papirus-icon-theme ttf-jetbrains-mono noto-fonts ttf-font-awesome network-manager-applet bluez-utils pacman-contrib nwg-displays grim slurp wl-clipboard grimblast-git udiskie gnome-calendar gnome-online-accounts gnome-control-center jq

# variables

dir="$HOME/dotfiles/hyprland"    # dotfiles directory
olddir="$HOME/dotfiles_old"      # old dotfiles backup directory
files=(hypr waybar gtk-3.0 gtk-4.0 qt5ct qt6ct udiskie) # list of files/folders to symlink

# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles..."
mkdir -p "$olddir"
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd "$dir"
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
# Also back up the old hyprland config directory if it exists
echo "Backing up old ~/.config/hyprland directory if it exists..."
mv -f "$HOME/.config/hyprland" "$olddir/" 2>/dev/null || true

for file in "${files[@]}"; do
    config_path="$HOME/.config/$file"
    echo "Backing up existing config and creating symlink for $file..."
    mv -f "$config_path" "$olddir/" 2>/dev/null || true
    ln -sf "$dir/hyprland" "$config_path"
done
