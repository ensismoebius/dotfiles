#!/bin/bash

# Initialize swww if it's not already running
if ! pgrep -x swww-daemon > /dev/null; then
    swww-daemon &
    sleep 0.5 # Give it a moment to start
fi

# Get the wallpaper path from the waypaper config
WALLPAPER_PATH=$(grep '^wallpaper' ~/.config/hypr/waypaper/config.ini | sed 's/wallpaper = //')

# Expand the tilde (~) to the full home directory path
eval WALLPAPER_PATH="$WALLPAPER_PATH"

# Set the wallpaper using swww
swww img "$WALLPAPER_PATH" --transition-type any --transition-duration 2