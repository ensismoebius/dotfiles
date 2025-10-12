#!/bin/bash

# Define the options with icons
options="󰤄 Suspend\n⭮ Reboot\n⏻ Shutdown"

# Show wofi menu with power options
selected=$(echo -e "$options" | wofi --dmenu \
    --cache-file /dev/null \
    --style ~/.config/hypr/wofi/style.css \
    --prompt "Power" \
    --width 120 \
    --height 105 \
    --location center \
    --lines 3 \
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
esac