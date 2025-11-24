#!/bin/bash

# Path to the state file
STATE_FILE="/tmp/hypr_monitor_state"

# Monitor names
MONITOR1="eDP-1"
MONITOR2="HDMI-A-1"

# User-defined preferred resolutions
# These will be prioritized if available in the monitor's supported modes
PREFERRED_RESOLUTION_EDP="1366x768@60.0Hz"
PREFERRED_RESOLUTION_HDMI="1440x900@59.9Hz"

# Function to get the best supported resolution for a given monitor
# Arguments: monitor_name
get_best_resolution() {
    local monitor_name=$1
    local preferred_res=""
    if [ "$monitor_name" == "$MONITOR1" ]; then
        preferred_res="$PREFERRED_RESOLUTION_EDP"
    elif [ "$monitor_name" == "$MONITOR2" ]; then
        preferred_res="$PREFERRED_RESOLUTION_HDMI"
    fi

    # Get available modes from hyprctl
    local monitors_info=$(hyprctl monitors)
    local available_modes=$(echo "$monitors_info" | awk "/Monitor $monitor_name/,/availableModes:/" | sed -n 's/.*availableModes: *//p')

    # 1. Try for an exact match for the preferred resolution
    if [ -n "$preferred_res" ]; then
        if echo "$available_modes" | grep -qw "$preferred_res"; then
            echo "$preferred_res"
            return
        fi
    fi

    # 2. If no exact match, try for the same resolution with the highest refresh rate
    if [ -n "$preferred_res" ]; then
        local res_part=$(echo "$preferred_res" | cut -d'@' -f1)
        # Find all modes with the same resolution, sort by refresh rate, and pick the best
        local best_match=$(echo "$available_modes" | tr ' ' '\n' | grep "^${res_part}@" | sort -t'@' -k2 -g -r | head -n1)
        if [ -n "$best_match" ]; then
            echo "$best_match"
            return
        fi
    fi

    # 3. If no preferred resolution match, find the highest resolution available
    local best_res=""
    local max_pixels=0
    for mode in $available_modes; do
        local res=$(echo "$mode" | cut -d'@' -f1)
        local width=$(echo "$res" | cut -d'x' -f1)
        local height=$(echo "$res" | cut -d'x' -f2)
        local pixels=$((width * height))
        if (( pixels > max_pixels )); then
            max_pixels=$pixels
            best_res="$mode"
        fi
    done

    if [ -n "$best_res" ]; then
        echo "$best_res"
        return
    fi
    
    # 4. As a last resort, if no resolution could be determined from hyprctl,
    # fall back to the user-defined preferred resolution. This handles cases
    # where parsing `hyprctl monitors` might fail, but we still want to try setting a mode.
    if [ -n "$preferred_res" ]; then
        notify-send "Monitor Switch" "Could not auto-determine a resolution for ${monitor_name}. Falling back to preferred: ${preferred_res}"
        echo "$preferred_res"
    fi
}

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
        1) # Mirrored -> Extended (right)
            if is_monitor2_connected; then
                hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,preferred,auto,1"
                echo "2" > "$STATE_FILE"
            else
                notify-send "Warning" "Second monitor is not connected."
                hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,disable"
                echo "3" > "$STATE_FILE"
            fi
            ;;
        2) # Extended (right) -> Main only
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
        4) # Second only -> Extended (left)
            if is_monitor2_connected; then
                local res_monitor1=$(get_best_resolution "$MONITOR1")
                local res_monitor2=$(get_best_resolution "$MONITOR2")
                
                # Check if resolutions were found
                if [ -z "$res_monitor1" ] || [ -z "$res_monitor2" ]; then
                    notify-send "Error" "Could not determine optimal resolutions for monitors."
                    # Fallback to a safe state if resolutions can't be determined
                    hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,disable"
                    echo "3" > "$STATE_FILE"
                    return
                fi

                # MONITOR2 (HDMI-A-1) is on the left, MONITOR1 (eDP-1) is on the right
                # Position MONITOR2 at 0x0
                # Position MONITOR1 at (width of MONITOR2)x0
                local monitor2_width=$(echo "$res_monitor2" | cut -d'x' -f1)
                
                hyprctl --batch "keyword monitor $MONITOR2,$res_monitor2,0x0,1; keyword monitor $MONITOR1,$res_monitor1,${monitor2_width}x0,1"
                echo "5" > "$STATE_FILE"
            else
                # This state should not be reachable if monitor2 is not connected.
                # As a fallback, go to state 3.
                notify-send "Warning" "Second monitor is not connected."
                hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,disable"
                echo "3" > "$STATE_FILE"
            fi
            ;;
        5) # Extended (left) -> Mirrored
            if is_monitor2_connected; then
                hyprctl --batch "keyword monitor $MONITOR1,preferred,auto,1; keyword monitor $MONITOR2,preferred,auto,1,mirror,$MONITOR1"
                echo "1" > "$STATE_FILE"
            else
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
        2) echo '''{"text": "→ | →", "tooltip": "Layout: Extended (right)"}''' ;;
        3) echo '''{"text": "  |0 ", "tooltip": "Layout: Main Monitor Only"}''' ;;
        4) echo '''{"text": "0|  ", "tooltip": "Layout: Second Monitor Only"}''' ;;
        5) echo '''{"text": "← | ←", "tooltip": "Layout: Extended (left)"}''' ;;
    esac
}

# Main logic
if [ "$1" == "--switch" ]; then
    switch_layout
else
    show_status
fi
