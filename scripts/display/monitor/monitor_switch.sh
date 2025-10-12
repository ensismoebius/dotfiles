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

    is_monitor2_connected() {
        hyprctl monitors all | grep -q "Monitor $MONITOR2"
    }

    case $CURRENT_STATE in
        1) # Mirrored -> Extended
            if is_monitor2_connected; then
                hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,preferred,auto,1"
                echo "2" > "$STATE_FILE"
            else
                notify-send "Warning" "Second monitor is not connected."
                hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,disable"
                echo "3" > "$STATE_FILE"
            fi
            ;;
        2) # Extended -> Main only
            hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,disable"
            echo "3" > "$STATE_FILE"
            ;;
        3) # Main only -> Second only
            if is_monitor2_connected; then
                hyprctl --batch "keyword monitor $MONITOR1,disable; keyword monitor $MONITOR2,preferred,auto,1"
                echo "4" > "$STATE_FILE"
            else
                notify-send "Warning" "Second monitor is not connected."
            fi
            ;;
        4) # Second only -> Mirrored
            if is_monitor2_connected; then
                hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,preferred,auto,1,mirror,$MONITOR1"
                echo "1" > "$STATE_FILE"
            else
                # This state should not be reachable if monitor2 is not connected.
                # As a fallback, go to state 3.
                notify-send "Warning" "Second monitor is not connected."
                hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,disable"
                echo "3" > "$STATE_FILE"
            fi
            ;;
    esac
    # Signal waybar to update
    pkill -RTMIN+8 waybar
}

# Function to show status for Waybar
show_status() {
    CURRENT_STATE=$(cat "$STATE_FILE")
    case $CURRENT_STATE in
        1) echo '''{"text": "=|=", "tooltip": "Layout: Mirrored"}''' ;;
        2) echo '''{"text": "→ | →", "tooltip": "Layout: Extended"}''' ;;
        3) echo '''{"text": "  |0 ", "tooltip": "Layout: Main Monitor Only"}''' ;;
        4) echo '''{"text": "0|  ", "tooltip": "Layout: Second Monitor Only"}''' ;;
    esac
}

# Main logic
if [ "$1" == "--switch" ]; then
    switch_layout
else
    show_status
fi
