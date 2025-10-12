#!/bin/bash

# Waybar module for scrolling playerctl metadata with icons

# --- Configuration ---
MAX_LEN=20          # Total max length of the module
INTERVAL=0.2        # Update interval in seconds

# --- Icon Configuration ---
PLAYER_ICON_DEFAULT="▶"
PLAYER_ICON_MPV="🎵"
# Add more player-specific icons here, e.g., PLAYER_ICON_SPOTIFY=""

STATUS_ICON_PLAYING="▶"
STATUS_ICON_PAUSED="⏸"

# --- Script Internals ---
POS_FILE="/tmp/waybar_mpris_scroll_pos"

# Initialize position file
if [ ! -f "$POS_FILE" ]; then
    echo 0 > "$POS_FILE"
fi

reset_scroll() {
    echo 0 > "$POS_FILE"
}

# Function to safely escape text for JSON
safe_escape() {
    echo "$1" | sed 's#\\#\\\\#g; s#"#\"#g' | tr -d '\n'
}

LAST_METADATA=""

# --- Main Loop ---
while true; do
    PLAYER_STATUS=$(playerctl status 2>/dev/null)
    
    if [ "$PLAYER_STATUS" = "Playing" ] || [ "$PLAYER_STATUS" = "Paused" ]; then
        METADATA=$(playerctl metadata --format '''{{artist}} - {{title}}''')
        PLAYER_NAME=$(playerctl metadata --format '''{{playerName}}''')
    else
        # Player is stopped or not running
        if [ "$LAST_METADATA" != "" ]; then
            reset_scroll
            echo '{"text": ""}'
        fi
        LAST_METADATA=""
        sleep 1
        continue
    fi

    # --- Determine Icon ---
    ICON=""
    if [ "$PLAYER_STATUS" = "Playing" ]; then
        ICON=$STATUS_ICON_PLAYING
    elif [ "$PLAYER_STATUS" = "Paused" ]; then
        ICON=$STATUS_ICON_PAUSED
    fi

    case $PLAYER_NAME in
        "mpv")
            ICON=$PLAYER_ICON_MPV
            ;; 
    esac

    # --- Reset scroll if metadata changed ---
    if [ "$METADATA" != "$LAST_METADATA" ]; then
        reset_scroll
        LAST_METADATA="$METADATA"
    fi

    # --- Prepare Output ---
    ICON_LEN=${#ICON}
    AVAILABLE_LEN=$((MAX_LEN - ICON_LEN - 1))

    # If metadata fits, display it statically
    if [ ${#METADATA} -le $AVAILABLE_LEN ]; then
        TEXT_TO_SHOW="$ICON $METADATA"
        ESCAPED_TEXT=$(safe_escape "$TEXT_TO_SHOW")
        echo "{\"text\": \"$ESCAPED_TEXT\"}"
        sleep 1
        continue
    fi

    # --- Scrolling Logic (if text is too long) ---
    POS=$(cat "$POS_FILE")
    
    PADDED_METADATA="$METADATA   "
    LEN=${#PADDED_METADATA}

    SCROLLING_TEXT=$(echo "$PADDED_METADATA$PADDED_METADATA" | cut -c $((POS + 1))-$((POS + AVAILABLE_LEN)))

    NEW_POS=$(( (POS + 1) % LEN ))
    echo $NEW_POS > "$POS_FILE"

    FINAL_TEXT="$ICON $SCROLLING_TEXT"

    ESCAPED_TEXT=$(safe_escape "$FINAL_TEXT")
    echo "{\"text\": \"$ESCAPED_TEXT\"}"

    sleep $INTERVAL
done
