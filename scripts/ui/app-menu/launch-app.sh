#!/bin/bash

APP_USAGE_SCRIPT="$HOME/.config/hypr/scripts/ui/app-menu/app-usage.sh"

# Get the selected application
selected_app=$(wofi --show drun)

if [ -n "$selected_app" ]; then
    # Extract the desktop file name from the command
    desktop_file=$(echo "$selected_app" | awk -F "'" '{print $2}' | sed 's|.*/||')
    
    if [ -n "$desktop_file" ]; then
        # Record the usage
        $APP_USAGE_SCRIPT record "$desktop_file"
    fi
    
    # Execute the command
    eval "$selected_app"
fi