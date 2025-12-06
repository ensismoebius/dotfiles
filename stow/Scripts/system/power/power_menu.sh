#!/bin/bash

# Define the options with icons and Pango markup for colors
options="<span foreground='#33ff33'>󰤄 Suspend</span>\n<span foreground='#ff3333'>⭮ Reboot</span>\n<span foreground='#ff3333'>⏻ Shutdown</span>\n<span foreground='#ffff33'>⚡️ Power Save - Soft</span>\n<span foreground='#ffff33'>⚡️ Power Save - Aggressive</span>\n<span foreground='#ffff33'>⚡️ Power Save - Ultimate</span>"

# Show wofi menu with power options
selected=$(echo -e "$options" | wofi --dmenu \
    --cache-file /dev/null \
    --style ~/.config/wofi/style.css \
    --prompt "Power" \
    --width 1093 \
    --height 614 \
    --location center \
    --hide-scroll \
    --allow-markup)

# Handle the selection
case "$selected" in
    "<span foreground='#33ff33'>󰤄 Suspend</span>")
        systemctl suspend
        ;;
    "<span foreground='#ff3333'>⭮ Reboot</span>")
        systemctl reboot
        ;;
    "<span foreground='#ff3333'>⏻ Shutdown</span>")
        systemctl poweroff
        ;;
    "<span foreground='#ffff33'>⚡️ Power Save - Soft</span>")
        /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_soft.sh
        ;;
    "<span foreground='#ffff33'>⚡️ Power Save - Aggressive</span>")
        /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_aggressive.sh
        ;;
    "<span foreground='#ffff33'>⚡️ Power Save - Ultimate</span>")
        /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_ultimate.sh
        ;;
esac