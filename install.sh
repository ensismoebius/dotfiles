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
# read -p "Do you want to proceed with the installation? (y/N) " choice
# case "$choice" in
#   y|Y ) echo "Starting installation...";;
#   * ) echo "Installation aborted." && exit 0;;
# esac

# Check if yay is installed, if not, install it
if ! command -v yay &> /dev/null; then
    echo "yay could not be found, installing it now."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    (cd yay && makepkg -si --noconfirm)
    rm -rf yay
fi

# Install all packages with yay
yay -S --needed hyprland waybar wofi kitty nautilus firefox swww polkit-kde-agent qt5ct qt6ct kvantum papirus-icon-theme ttf-jetbrains-mono noto-fonts ttf-font-awesome network-manager-applet bluez-utils udiskie pipewire-pulse pavucontrol grim slurp wl-clipboard jq zsh hyprcursor wlogout xdg-utils grimblast swaync waypaper catppuccin-cursors-mocha vim ccls swaylock playerctl stow gimp mako

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


echo ""

# --- Oh My Zsh Installation ---
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
if [ ! -d "$OH_MY_ZSH_DIR" ]; then
    echo "Installing Oh My Zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
else
    echo "Oh My Zsh is already installed."
fi

# --- Powerlevel10k Theme Installation ---
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
    echo "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
    echo "Powerlevel10k theme is already installed."
fi

# --- Zsh Plugins Installation ---
# zsh-autosuggestions
AS_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [ ! -d "$AS_DIR" ]; then
    echo "Installing zsh-autosuggestions plugin..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$AS_DIR"
else
    echo "zsh-autosuggestions plugin is already installed."
fi

# zsh-syntax-highlighting
SH_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
if [ ! -d "$SH_DIR" ]; then
    echo "Installing zsh-syntax-highlighting plugin..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$SH_DIR"
else
    echo "zsh-syntax-highlighting plugin is already installed."
fi
echo ""

# --- Configuration Symlinking ---
echo "Stowing configuration files into home directory..."

# Function to backup existing conflicting files
backup_conflicting_files() {
    BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    echo "Backing up conflicting files to $BACKUP_DIR..."

    # List of common dotfiles/directories stow might target
    CONFLICTING_TARGETS=(
        ".config"
        ".local/share/icons"
        ".local/bin"
        ".bash_profile"
        ".bashrc"
        ".gtkrc-2.0"
        ".p10k.zsh"
        ".zshrc"
        ".vim"
        ".vimrc"
        ".Xresources"
        ".themes"
    )

    for target in "${CONFLICTING_TARGETS[@]}"; do
        FULL_PATH="$HOME/$target"
        if [ -e "$FULL_PATH" ] || [ -L "$FULL_PATH" ]; then # Check if it exists, including as a symlink
            echo "  Moving $FULL_PATH to $BACKUP_DIR/"
            mv "$FULL_PATH" "$BACKUP_DIR/"
        fi
    done
    echo "Backup complete."
}

# Call the backup function before stowing
backup_conflicting_files

# The directory where this script is located, which is the root of our dotfiles repo
CONFIG_DIR=$(cd "$(dirname "$0")" && pwd)
STOW_DIR="$CONFIG_DIR/stow"

# Remove the problematic empty .oh-my-zsh directory from the stow package
echo "Removing problematic stow/shell/.oh-my-zsh directory..."
rm -rf "$STOW_DIR/shell/.oh-my-zsh"

# Unstow any packages first to avoid conflicts
for pkg in $(ls "$STOW_DIR"); do
    stow -D -v -d "$STOW_DIR" -t "$HOME" "$pkg"
done

# Stow all packages.
echo "Creating ~/Scripts directory if it doesn't exist..."
mkdir -p "$HOME/Scripts"

for pkg in $(ls "$STOW_DIR"); do
    if [ "$pkg" == "Scripts" ]; then
        echo "Stowing Scripts to ~/Scripts..."
        stow --restow -v -d "$STOW_DIR" -t "$HOME/Scripts" "$pkg"
    else
        echo "Stowing $pkg to ~..."
        stow --restow -v -d "$STOW_DIR" -t "$HOME" "$pkg"
    fi
done

echo "Stowing complete."

# Update icon cache
if [ -d "$HOME/.local/share/icons/Cyberpunk-Neon" ]; then
    echo "Updating icon cache..."
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/Cyberpunk-Neon"
fi

# Install vim-plug for plugin management
echo "Installing vim-plug..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "All dependencies installed successfully."

# Update desktop database
if [ -d "$HOME/.local/share/applications" ]; then
    echo "Updating desktop database..."
    update-desktop-database "$HOME/.local/share/applications"
fi

echo "Setup complete."
echo "Done."
