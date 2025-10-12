# 🚀 Hyprland Configuration

<div align="center">

![Hyprland Logo](https://hyprland.org/img/logo.png)

A modern, cyberpunk-themed Hyprland configuration featuring dynamic workspaces, intelligent app launching, and seamless integration with Waybar.

[Features](#-features) • [Installation](#-installation) • [Keybindings](#-keybindings) • [Customization](#-customization) • [Scripts](#-scripts)

</div>

## ✨ Features

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

## 🚀 Installation

### Prerequisites
\`\`\`bash
# Arch Linux (using yay)
yay -S hyprland waybar wofi kitty nautilus firefox dunst
\`\`\`

### Quick Start
1. Clone this repository:
   \`\`\`bash
   git clone https://github.com/ensismoebius/dotfiles.git
   cd dotfiles
   \`\`\`

2. Run the installer:
   \`\`\`bash
   ./install.sh
   \`\`\`

## ⌨️ Keybindings

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

## 🎨 Customization

### Theme Configuration
The setup includes a cyberpunk-inspired theme with:
- Custom Neon icon theme
- Dynamic color schemes
- Customizable Waybar modules

### Directory Structure
\`\`\`
~/.config/hypr/
├── hyprland.conf.d/    # Modular Hyprland configuration
├── waybar/             # Waybar configuration and styling
├── scripts/           # Utility scripts organized by category
│   ├── ui/            # User interface scripts
│   ├── system/        # System management scripts
│   ├── audio/         # Audio control scripts
│   └── display/       # Display management scripts
└── themes/            # Theme-related configurations
\`\`\`

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

## 🤝 Contributing

Feel free to:
- 🐛 Report bugs
- 💡 Suggest enhancements
- 🔧 Submit pull requests

## 📝 License

MIT License - Feel free to use and modify as you wish!

---
<div align="center">
Made with ❤️ by ensismoebius

[⬆ Back to top](#-hyprland-configuration)
</div>
