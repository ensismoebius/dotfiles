#!/bin/bash

# Configuration
NORMAL_COLOR="#00FF41"
CRITICAL_COLOR="#FF0000"
BG_COLOR="#0D0208AA"

# Function to create a notification with a "glowing" effect
send_notification() {
    local urgency=$1
    local title=$2
    local message=$3
    local color=""
    local frame_color=""
    
    if [ "$urgency" == "critical" ]; then
        color=$CRITICAL_COLOR
        frame_color=$CRITICAL_COLOR
    else
        color=$NORMAL_COLOR
        frame_color=$NORMAL_COLOR
    fi
    
    # Create a notification with HTML formatting for the glow effect
    notify-send "$title" "<span foreground='$color' weight='bold'>$message</span>" \
        -u "$urgency" \
        -h string:frame-color:$frame_color \
        -h string:bgcolor:$BG_COLOR \
        -h string:hlcolor:$color
}

# Example usage:
# ./notify.sh normal "Normal Message" "This is a normal notification"
# ./notify.sh critical "Critical Message" "This is a critical notification"