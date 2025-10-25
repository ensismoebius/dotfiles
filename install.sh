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
swaylock: Screen locker

--- System & Theming ---
swww: Wallpaper daemon
waypaper: Wallpaper selector GUI
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
playerctl: For media player control
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
yay -S --needed hyprland waybar wofi kitty nautilus firefox swww polkit-kde-agent qt5ct qt6ct kvantum papirus-icon-theme ttf-jetbrains-mono noto-fonts ttf-font-awesome network-manager-applet bluez-utils udiskie pipewire-pulse pavucontrol grim slurp wl-clipboard jq zsh hyprcursor wlogout xdg-utils grimblast swaync waypaper catppuccin-cursors-mocha vim neovim ccls swaylock playerctl

# Function: ensure murrine engine is installed for GTK2 visual improvements
install_murrine_if_missing() {
    if pkg-config --exists murrine-gtk-theme 2>/dev/null || [ -f /usr/lib/gtk-2.0/2.10.0/engines/libmurrine.so ] || [ -f /usr/lib64/gtk-2.0/2.10.0/engines/libmurrine.so ]; then
        echo "Murrine engine already installed."
        return 0
    fi

    echo "Murrine GTK2 engine (gtk-engines-murrine) not found. Attempting to install..."

    # Detect package manager and try to install
    if command -v pacman &>/dev/null; then
        echo "Detected pacman. Installing gtk-engine-murrine via pacman/yay..."
        # Try official first, then AUR via yay
        sudo pacman -S --needed --noconfirm gtk-engine-murrine || yay -S --needed --noconfirm gtk-engine-murrine
        return $?
    elif command -v apt &>/dev/null; then
        echo "Detected apt. Installing libmurrine-gtk-theme (Debian/Ubuntu naming may vary)..."
        sudo apt update && sudo apt install -y gtk2-engines-murrine || sudo apt install -y libmurrine-gtk-theme || true
        return $?
    elif command -v dnf &>/dev/null; then
        echo "Detected dnf. Installing gtk-murrine engine..."
        sudo dnf install -y gtk-murrine-engine || true
        return $?
    else
        echo "Could not detect package manager. Please install the Murrine GTK2 engine manually."
        echo "Common package names: gtk-engines-murrine, gtk2-engines-murrine, libmurrine-gtk-theme"
        return 1
    fi
}

# Try to install murrine now (non-fatal if it fails)
install_murrine_if_missing || echo "Continuing without Murrine engine. See README for manual install instructions."

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
    ".oh-my-zsh"
    ".p10k.zsh"
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
    "gtk-3.0"
    "gtk-4.0"
    "gtk-2.0"
    "icons"
    "kitty"
    "qt5ct"
    "qt6ct"
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

# Set up GIMP theme
echo "Setting up GIMP theme..."
GIMP3_THEME_DIR="$HOME/.config/GIMP/3.0/themes"

mkdir -p "$GIMP3_THEME_DIR"
if [ -e "$GIMP3_THEME_DIR/Cyberpunk-Neon" ]; then
    rm -rf "$GIMP3_THEME_DIR/Cyberpunk-Neon"
fi
ln -s "$CONFIG_DIR/gimp/themes/Cyberpunk-Neon" "$GIMP3_THEME_DIR/"
echo "GIMP 3.0 theme setup completed."



# If we linked a gtk-2.0 directory, ensure GTK2 apps read the theme by creating
# a per-user ~/.gtkrc-2.0 that includes the gtk-2.0/gtkrc in ~/.config.
if [ -d "$HOME/.config/gtk-2.0" ]; then
    GTKRC_PATH="$HOME/.config/gtk-2.0/gtkrc"
    if [ -f "$GTKRC_PATH" ]; then
        echo "Creating ~/.gtkrc-2.0 include to point to ~/.config/gtk-2.0/gtkrc"
        cat > ~/.gtkrc-2.0 <<EOF
include "$GTKRC_PATH"
EOF
    else
        echo "Note: ~/.config/gtk-2.0 exists but no gtkrc file found at $GTKRC_PATH"
    fi
fi


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

# Set up icon theme
echo "Setting up Cyberpunk-Neon icon theme..."
mkdir -p ~/.local/share/icons
# Create symbolic link for icons directory
if [ -e ~/.local/share/icons/Cyberpunk-Neon ]; then
    rm -rf ~/.local/share/icons/Cyberpunk-Neon
fi
ln -sf ~/.config/hypr/icons/Cyberpunk-Neon ~/.local/share/icons/

# Update icon cache
gtk-update-icon-cache -f ~/.config/hypr/icons/Cyberpunk-Neon

echo "Icon theme setup completed."

# Set up personal scripts
echo "Setting up personal scripts..."
mkdir -p ~/Scripts
# Remove existing files if any
rm -f ~/Scripts/*
# Create symbolic links for utility scripts
ln -sf ~/.config/hypr/scripts/utils/* ~/Scripts/

echo "Personal scripts setup completed."
echo "Done."
