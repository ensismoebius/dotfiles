#!/bin/bash

# Define the options with icons
options="󰤄 Suspend\n⭮ Reboot\n⏻ Shutdown\n⚡️ Power Save - Soft\n⚡️ Power Save - Aggressive\n⚡️ Power Save - Ultimate"

# Show wofi menu with power options
selected=$(echo -e "$options" | wofi --dmenu \
    --cache-file /dev/null \
    --style ~/.config/hypr/wofi/style.css \
    --prompt "Power" \
    --width 120 \
    --height 200 \
    --location center \
    --lines 6 \
    --hide-scroll \
    --columns 1)

# Handle the selection
case "$selected" in
    "󰤄 Suspend")
        systemctl suspend
        ;;
    "⭮ Reboot")
        systemctl reboot
        ;;
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "⚡️ Power Save - Soft")
        /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_soft.sh
        ;;
    "⚡️ Power Save - Aggressive")
        /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_aggressive.sh
        ;;
    "⚡️ Power Save - Ultimate")
        /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_ultimate.sh
        ;;
esac