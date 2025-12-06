# 🚀 Hyprland Configuration

![Hyprland Logo](https://hyprland.org/img/logo.png)

A modern, cyberpunk-themed Hyprland configuration, now managed with a clean, modular structure using GNU Stow. Features dynamic workspaces, intelligent app launching, and seamless integration with Waybar.

[Features](#features) • [Installation](#installation) • [How It Works](#how-it-works) • [Directory Structure](#directory-structure) • [Keybindings](#keybindings) • [Customization](#customization) • [Scripts](#scripts)

## Features

### Core Components

- 🖥️ **Hyprland** - A dynamic tiling Wayland compositor
- 🎨 **Custom Cyberpunk Theme** - Neon-inspired color scheme with custom icons
- 🎯 **Smart App Launcher** - Wofi-based launcher
- 📊 **Enhanced Waybar** - Custom modules for system monitoring
- 🔔 **Modern Notifications** - Using SwayNC and Mako with a stylish appearance

### Advanced Features

- 🎵 **Advanced Audio Control** - Independent volume controls for speaker and microphone
- 🖼️ **Dynamic Wallpaper** - Wallpaper management with waypaper
- 📱 **Device Integration** - Bluetooth and network management
- 🔄 **Workspace Management** - Dynamic workspace handling with intuitive controls
- 📎 **Clipboard History** - Persistent clipboard with search functionality

## Installation

The `install.sh` script automates the entire setup process. It installs all required packages and then uses GNU Stow to correctly place configuration files.

1.  **Clone the repository:**
    ```bash
    git clone "https://github.com/ensismoebius/dotfiles.git"
    cd dotfiles
    ```

2.  **Run the installer:**
    The script will list all packages to be installed and ask for confirmation before proceeding.
    ```bash
    ./install.sh
    ```

## How It Works

This repository uses **GNU Stow** to manage dotfiles. All configurations are organized into modular "packages" inside the `stow/` directory.

The `install.sh` script does two main things:
1.  **Installs Dependencies**: It uses `yay` to ensure all necessary applications (like Hyprland, Waybar, etc.) and tools (including `stow` itself) are installed on your system.
2.  **Stows Configurations**: It automatically runs `stow` on every package in the `stow/` directory. Stow then creates symbolic links from this repository to the correct locations in your home directory (e.g., linking `stow/shell/.zshrc` to `~/.zshrc`).

This approach keeps the repository clean and makes managing configurations much easier. Adding a new configuration is as simple as creating a new folder in `stow/` with the correct internal structure.

## Directory Structure

All configurations are located within the `stow/` directory, organized by package. The structure inside each package mirrors the structure of your home directory (`$HOME`).

```
.
├── install.sh
├── README.md
└── stow/
    ├── shell/
    │   ├── .bashrc
    │   ├── .zshrc
    │   └── .oh-my-zsh/
    │
    ├── config/
    │   └── .config/
    foot/
    │       ├── waybar/
    │       ├── mako/
    │       └── ...
    │
    ├── hypr/
    │   └── .config/
    │       └── hypr/
    │           ├── hyprland.conf
    │           └── hyprland.conf.d/
    │
    ├── vim/
    │   ├── .vim/
    │   └── .vimrc
    │
    └── ... (other packages for gimp, icons, scripts, etc.)
```

## Keybindings

### Essential Controls

- `Super + D` - App launcher (with smart ordering)
- `Super + Return` - Launch terminal
- `Super + Q` - Close active window
- `Super + M` - Toggle fullscreen
- `Super + T` - Toggle floating window

### Workspace Navigation

- `Super + [1-0]` - Switch to workspace 1-10
- `Super + Shift + [1-0]` - Move window to workspace 1-10
- `Super + Mouse Scroll` - Cycle through workspaces

### Media & Volume

- Volume controls in Waybar
- Independent microphone controls
- Bluetooth device management

### Special Features

- `Super + .` - Emoji picker
- `Super + V` - Clipboard history
- `Super + =` - Toggle zoom

## Customization

The setup includes a cyberpunk-inspired theme with:

- Custom Neon icon theme
- Dynamic color schemes
- Customizable Waybar modules

To customize a component, simply edit the corresponding files within the `stow/` directory. For example, to change your foot terminal settings, you would edit `stow/config/.config/foot/foot.ini`. After saving the change, the symlink in your home directory will automatically reflect the new configuration.

## 🛠️ Scripts

Utility scripts are located in the `stow/scripts/` package, which links them to `~/Scripts/`. These include tools for system configuration, hardware management, and more.

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