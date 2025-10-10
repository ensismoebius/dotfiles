#!/bin/bash

# Path to the state file
STATE_FILE="/tmp/hypr_monitor_state"

# Monitor names
MONITOR1="eDP-1"
MONITOR2="HDMI-A-1"

# Initialize state if not present, start with mirrored view.
if [ ! -f "$STATE_FILE" ]; then
    echo "1" > "$STATE_FILE"
fi

# Function to handle the switch
switch_layout() {
    CURRENT_STATE=$(cat "$STATE_FILE")
    case $CURRENT_STATE in
        1) # Mirrored -> Extended
            hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,preferred,auto,1"
            echo "2" > "$STATE_FILE"
            ;;
        2) # Extended -> Main only
            hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,disable"
            echo "3" > "$STATE_FILE"
            ;;
        3) # Main only -> Second only
            hyprctl --batch "keyword monitor $MONITOR1,disable; keyword monitor $MONITOR2,preferred,auto,1"
            echo "4" > "$STATE_FILE"
            ;;
        4) # Second only -> Mirrored
            hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,preferred,auto,1,mirror,$MONITOR1"
            echo "1" > "$STATE_FILE"
            ;;
    esac
    # Signal waybar to update
    pkill -RTMIN+8 waybar
}

# Function to show status for Waybar
show_status() {
    CURRENT_STATE=$(cat "$STATE_FILE")
    case $CURRENT_STATE in
        1) echo '''{"text": "󰍺", "tooltip": "Layout: Mirrored"}''' ;;
        2) echo '''{"text": "󰡦", "tooltip": "Layout: Extended"}''' ;;
        3) echo '''{"text": "󰍹", "tooltip": "Layout: Main Monitor Only"}''' ;;
        4) echo '''{"text": "󰍹", "tooltip": "Layout: Second Monitor Only"}''' ;;
    esac
}

# Main logic
if [ "$1" == "--switch" ]; then
    switch_layout
else
    show_status
fi
