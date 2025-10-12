#!/bin/bash

# --- Dependency Installation ---
echo "This script will install all necessary software for the Hyprland configuration."
echo "The following packages will be installed:"
echo "
--- Core Components ---
hyprland: The Wayland compositor
waybar: Status bar
dunst: Notification daemon
wofi: Application launcher
wofi: Used for emoji picker
kitty: Terminal emulator
nautilus: File manager
wlogout: Logout menu

--- System & Theming ---
swww: Wallpaper daemon
polkit-kde-agent: PolicyKit authentication agent
qt5ct qt6ct kvantum: For Qt theming
papirus-icon-theme: Icon theme
ttf-jetbrains-mono noto-fonts ttf-font-awesome: Fonts
hyprcursor: For cursor theming
catppuccin-cursors-mocha (AUR): Cursor theme

--- Utilities ---
firefox: Web browser
network-manager-applet: Network manager GUI
bluez-utils: For Bluetooth
udiskie: Automounter for removable media
pipewire-pulse: For audio control (pactl)
pavucontrol: Volume control panel
grim slurp grimblast (AUR): Screenshot tools
wl-clipboard: Clipboard utilities
jq: JSON processor for scripts
zsh: The Z shell
swaync (AUR): Notification center
waypaper (AUR): Wallpaper selector GUI
xdg-utils: For opening files and URLs
git base-devel: For installing AUR packages

"
read -p "Do you want to proceed with the installation? (y/N) " choice
case "$choice" in
  y|Y ) echo "Starting installation...";;
  * ) echo "Installation aborted." && exit 0;;
esac

# Check if yay is installed, if not, install it
if ! command -v yay &> /dev/null; then
    echo "yay could not be found, installing it now."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    (cd yay && makepkg -si --noconfirm)
    rm -rf yay
fi

# Install all packages with yay
yay -S --needed hyprland waybar wofi rofi kitty nautilus firefox dunst swww polkit-kde-agent qt5ct qt6ct kvantum papirus-icon-theme ttf-jetbrains-mono noto-fonts ttf-font-awesome network-manager-applet bluez-utils udiskie pipewire-pulse pavucontrol grim slurp wl-clipboard jq zsh hyprcursor wlogout xdg-utils grimblast swaync waypaper catppuccin-cursors-mocha vim neovim ccls

# Install vim-plug for plugin management
echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "All dependencies installed successfully."
echo ""

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

# Vim specific configuration
echo "Setting up Vim configuration..."
# Create necessary vim directories
mkdir -p ~/.vim/autoload
mkdir -p ~/.config/coc

# Link vim configuration files
ln -sf "$CONFIG_DIR/vim/.vimrc" ~/.vimrc
ln -sf "$CONFIG_DIR/vim/coc-settings.json" ~/.vim/coc-settings.json

# Install coc-clangd for C/C++ support
echo "Please run ':PlugInstall' when you first open Vim"
echo "After plugins are installed, run ':CocInstall coc-clangd' for C/C++ support"

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
    "wofi"
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
