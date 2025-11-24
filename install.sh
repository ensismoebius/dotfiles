#!/bin/bash

# --- Dependency Installation ---
echo "This script will install all necessary software for the Hyprland configuration."
echo "The following packages will be installed:"
echo "
--- Core Components ---
hyprland: The Wayland compositor
waybar: Status bar
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
yay -S --needed hyprland waybar wofi kitty nautilus firefox swww polkit-kde-agent qt5ct qt6ct kvantum papirus-icon-theme ttf-jetbrains-mono noto-fonts ttf-font-awesome network-manager-applet bluez-utils udiskie pipewire-pulse pavucontrol grim slurp wl-clipboard jq zsh hyprcursor wlogout xdg-utils grimblast swaync waypaper catppuccin-cursors-mocha vim neovim ccls swaylock playerctl stow gimp mako

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

# --- Configuration Symlinking ---
echo "Stowing configuration files into home directory..."

# The directory where this script is located, which is the root of our dotfiles repo
CONFIG_DIR=$(cd "$(dirname "$0")" && pwd)
STOW_DIR="$CONFIG_DIR/stow"

# Unstow any packages first to avoid conflicts
for pkg in $(ls "$STOW_DIR"); do
    stow -D -v -d "$STOW_DIR" -t "$HOME" "$pkg"
done

# Stow all packages.
for pkg in $(ls "$STOW_DIR"); do
    stow -v -d "$STOW_DIR" -t "$HOME" "$pkg"
done

echo "Stowing complete."

# --- Post-Stow Setup ---
echo "Running post-setup tasks..."

# If we linked a gtk-2.0 directory, ensure GTK2 apps read the theme.
if [ -d "$HOME/.config/gtk-2.0" ]; then
    GTKRC_PATH="$HOME/.config/gtk-2.0/gtkrc"
    if [ -f "$GTKRC_PATH" ] && ! grep -q "include \"$GTKRC_PATH\"" ~/.gtkrc-2.0 2>/dev/null; then
        echo "Creating ~/.gtkrc-2.0 include to point to ~/.config/gtk-2.0/gtkrc"
        # Ensure the .gtkrc-2.0 file exists before appending
        touch ~/.gtkrc-2.0
        # Add include if it's not already there
        echo "include \"$GTKRC_PATH\"" >> ~/.gtkrc-2.0
    fi
fi

# Update icon cache
if [ -d "$HOME/.local/share/icons/Cyberpunk-Neon" ]; then
    echo "Updating icon cache..."
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Cyberpunk-Neon"
fi

# Update desktop database
if [ -d "$HOME/.local/share/applications" ]; then
    echo "Updating desktop database..."
    update-desktop-database "$HOME/.local/share/applications"
fi

echo "Setup complete."
echo "Done."
