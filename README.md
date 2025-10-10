# Hyprland Dotfiles

A modular, Arch-based dotfiles setup for Hyprland, Waybar, and related tools. Includes scripts for updates, emoji picker, and Bluetooth toggle.

## Features

- Hyprland configuration with custom keybindings and layouts
- Waybar status bar with custom modules
- GTK/Qt theming
- Scripts for system updates, emoji picker, and Bluetooth toggle
- Automated install script for dependencies and symlinks

## Requirements

- Arch Linux or derivative (uses `yay`, `pacman`)
- Hyprland, Waybar, Wofi, Kitty, Nautilus, Mako, swaybg, polkit-kde-agent, qt5ct, qt6ct, kvantum, Papirus icon theme, JetBrains Mono, FontAwesome, network-manager-applet, bluez-utils, pacman-contrib, nwg-displays, grim, slurp, wl-clipboard, grimblast-git, udiskie, gnome-calendar, gnome-online-accounts, gnome-control-center
- For scripts: `bluetoothctl`, `checkupdates`, `yay`, `flatpak`, `wofi`, `wl-copy`

## Setup

1. Clone this repo to `~/dotfiles/hyprland`.
2. Run the install script:

   ```sh
   cd ~/dotfiles/hyprland/scripts
   ./install.sh
   ```

   This will install dependencies and symlink configs to `~/.config`.

## Scripts

- `scripts/check_updates.sh`: Shows available updates (system, AUR, Flatpak)
- `scripts/toggle_bluetooth.sh`: Toggles Bluetooth power
- `scripts/emoji_picker.sh`: Emoji picker using Wofi and wl-copy

## Notes

- The install script is Arch-specific. For other distros, adapt as needed.
- All scripts require their dependencies to be installed.
- Backups of existing configs are stored in `~/dotfiles_old`.

## License

MIT
