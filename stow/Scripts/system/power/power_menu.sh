#!/bin/bash

# Define the options with icons and Pango markup for colors
options="<span foreground='#33ff33'>󰤄 Suspend</span>\n<span foreground='#ff3333'>⭮ Reboot</span>\n<span foreground='#ff3333'>⏻ Shutdown</span>\n<span foreground='#ffff33'>⚡️ Power Save - Soft</span>\n<span foreground='#ffff33'>⚡️ Power Save - Aggressive</span>\n<span foreground='#ffff33'>⚡️ Power Save - Ultimate</span>\n<span foreground='#ffff33'>⚡️ Power Save - Normal</span>"

# Show wofi menu with power options
selected=$(echo -e "$options" | wofi --dmenu \
    --cache-file /dev/null \
    --style ~/.config/wofi/power_menu_style.css \
    --prompt "Power" \
    --width 600 \
    --height 150 \
    --location center \
    --hide-scroll \
    --allow-markup)

# Handle the selection
case "$selected" in
    "<span foreground='#33ff33' >󰤄 Suspend</span>")
        systemctl suspend
        ;;
    "<span foreground='#ff3333'>⭮ Reboot</span>")
        systemctl reboot
        ;;
    "<span foreground='#ff3333'>⏻ Shutdown</span>")
        systemctl poweroff
        ;;
    "<span foreground='#ffff33'>⚡️ Power Save - Soft</span>")
        pkexec /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_soft.sh
        ;;
    "<span foreground='#ffff33'>⚡️ Power Save - Aggressive</span>")
        pkexec /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_aggressive.sh
        ;;
    "<span foreground='#ffff33'>⚡️ Power Save - Ultimate</span>")
        pkexec /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_ultimate.sh
        ;;
    "<span foreground='#ffff33'>⚡️ Power Save - Normal</span>")
        pkexec /home/ensismoebius/dotfiles/stow/Scripts/system/power/power_save_normal.sh
        ;;
esac