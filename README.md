# 🚀 Hyprland Configuration

![Hyprland Logo](https://hyprland.org/img/logo.png)

A modern, cyberpunk-themed Hyprland configuration featuring dynamic workspaces, intelligent app launching, and seamless integration with Waybar.

[Features](#features) • [Installation](#installation) • [Keybindings](#keybindings) • [Customization](#customization) • [Scripts](#scripts)

## Features

### Core Components

- 🖥️ **Hyprland** - A dynamic tiling Wayland compositor
- 🎨 **Custom Cyberpunk Theme** - Neon-inspired color scheme with custom icons
- 🎯 **Smart App Launcher** - Wofi-based launcher with most used apps prioritization
- 📊 **Enhanced Waybar** - Custom modules for system monitoring
- 🔔 **Modern Notifications** - Using Mako with stylish appearance

### Advanced Features

- 🎵 **Advanced Audio Control** - Independent volume controls for speaker and microphone
- 🖼️ **Dynamic Wallpaper** - Wallpaper management with waypaper
- 📱 **Device Integration** - Bluetooth and network management
- 🔄 **Workspace Management** - Dynamic workspace handling with intuitive controls
- 📎 **Clipboard History** - Persistent clipboard with search functionality

## Installation

### Prerequisites

```bash
# Install required packages
yay -S hyprland waybar wofi kitty nautilus firefox dunst
```

### Quick Start

1. Clone this repository:

   ```bash
   git clone "https://github.com/ensismoebius/dotfiles.git"
   cd dotfiles
   ```

2. Run the installer:
   \`\`\`bash
   ./install.sh
   \`\`\`

## Keybindings

### Essential Controls

- \`Super + D\` - App launcher (with smart ordering)
- \`Super + Return\` - Launch terminal
- \`Super + Q\` - Close active window
- \`Super + M\` - Toggle fullscreen
- \`Super + T\` - Toggle floating window

### Workspace Navigation

- \`Super + [1-0]\` - Switch to workspace 1-10
- \`Super + Shift + [1-0]\` - Move window to workspace 1-10
- \`Super + Mouse Scroll\` - Cycle through workspaces

### Media & Volume

- Volume controls in Waybar
- Independent microphone controls
- Bluetooth device management

### Special Features

- \`Super + .\` - Emoji picker
- \`Super + V\` - Clipboard history
- \`Super + =\` - Toggle zoom

## Customization

### Theme Configuration

The setup includes a cyberpunk-inspired theme with:

- Custom Neon icon theme
- Dynamic color schemes
- Customizable Waybar modules

### Directory Structure

<pre>
~/.config/hypr/
│
├── hyprland.conf.d/        # Modular Hyprland configuration
│   ├── 01-monitors.conf    # Monitor configuration
│   ├── 02-env.conf        # Environment variables
│   ├── 03-autostart.conf  # Autostart applications
│   ├── 04-input.conf      # Input device settings
│   └── ...                # Other configurations
│
├── waybar/                 # Waybar configuration and styling
│   ├── config             # Main configuration
│   └── style.css          # Waybar styling
│
├── scripts/               # Utility scripts organized by category
│   ├── ui/               # User interface scripts
│   │   ├── app-menu/     # Application launcher scripts
│   │   ├── clipboard/    # Clipboard management
│   │   └── window/       # Window management
│   │
│   ├── system/           # System management scripts
│   │   ├── power/       # Power management
│   │   └── updates/     # System updates
│   │
│   ├── audio/           # Audio control scripts
│   │   └── bluetooth/   # Bluetooth audio
│   │
│   └── display/         # Display management scripts
│       └── monitor/     # Monitor configuration
│
└── themes/                # Theme-related configurations
    ├── movie.conf        # Main theme configuration
    └── movie-gtk-theme/  # GTK theme files
</pre>

### Installation Details

The `install.sh` script automates the entire setup process:

#### Script Features

- 📦 Installs all required packages using yay
- 🔗 Creates symbolic links for configuration files
- 🎨 Sets up themes and icons
- 🛠️ Configures system components:
  - GTK/Qt themes
  - Icon themes
  - Font configuration
  - MIME types
  - Terminal configuration
  - Scripts and utilities

#### What it Sets Up

1. **Core Components**
   - Hyprland and related utilities
   - Waybar status bar
   - Terminal emulator (Kitty)
   - Application launcher (Wofi)
   - File manager (Nautilus)

2. **System Integration**
   - Notification system (Dunst)
   - Bluetooth support
   - Network management
   - Audio controls
   - USB device handling

3. **Development Tools**
   - Vim/Neovim configuration
   - Development utilities
   - Personal scripts (symlinked to ~/Scripts)

4. **Theming**
   - GTK/Qt themes
   - Movie theme configuration
   - Custom styling
   - Font configuration

#### Usage

```bash
$ chmod +x install.sh  # Make the script executable
$ ./install.sh        # Run the installer
```

## 🛠️ Scripts

### Utility Scripts
Located in \`~/Scripts\` (symlinked from \`~/.config/hypr/scripts/utils\`):
- System configuration utilities
- Hardware management tools
- Network configuration helpers
- Audio/Video utilities

### Core Scripts

- **App Menu**: Smart application launcher with usage tracking
- **Workspace Management**: Dynamic workspace handling
- **System Controls**: Volume, brightness, and power management
- **UI Utilities**: Screenshot, clipboard, and notification tools

## Contributing

Feel free to:

- Report bugs
- Suggest enhancements
- Submit pull requests

## License

MIT License - Feel free to use and modify as you wish!

---

Made with ❤️ by [@ensismoebius](https://github.com/ensismoebius)

[⬆ Back to top](#hyprland-configuration)
