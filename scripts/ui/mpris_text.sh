#!/bin/bash

# Waybar module for scrolling playerctl metadata text

# --- Configuration ---
MAX_LEN=20          # Max length of the text to show
INTERVAL=0.2        # Update interval in seconds

# --- Script Internals ---
POS_FILE="/tmp/waybar_mpris_text_scroll_pos" # Use a new position file

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
    
    # We only want to show text if player is playing or paused
    if [ "$PLAYER_STATUS" = "Playing" ] || [ "$PLAYER_STATUS" = "Paused" ]; then
        METADATA=$(playerctl metadata --format '''{{artist}} - {{title}}''')
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

    # --- Reset scroll if metadata changed ---
    if [ "$METADATA" != "$LAST_METADATA" ]; then
        reset_scroll
        LAST_METADATA="$METADATA"
    fi

    # --- Prepare Output ---
    AVAILABLE_LEN=$MAX_LEN

    # If metadata fits, display it statically
    if [ ${#METADATA} -le $AVAILABLE_LEN ]; then
        TEXT_TO_SHOW="$METADATA"
        ESCAPED_TEXT=$(safe_escape "$TEXT_TO_SHOW")
        echo "{\"text\": \"$ESCAPED_TEXT\"}"
        sleep 1
        continue
    fi

    # --- Scrolling Logic (if text is too long) ---
    # Don't scroll if paused
    if [ "$PLAYER_STATUS" = "Paused" ]; then
        # Just show the truncated text
        TEXT_TO_SHOW=$(echo "$METADATA" | cut -c 1-$AVAILABLE_LEN)
        ESCAPED_TEXT=$(safe_escape "$TEXT_TO_SHOW")
        echo "{\"text\": \"$ESCAPED_TEXT\"}"
        sleep 1
        continue
    fi

    POS=$(cat "$POS_FILE")
    
    PADDED_METADATA="$METADATA   " # Padding for seamless scroll
    LEN=${#PADDED_METADATA}

    SCROLLING_TEXT=$(echo "$PADDED_METADATA$PADDED_METADATA" | cut -c $((POS + 1))-$((POS + AVAILABLE_LEN)))

    NEW_POS=$(( (POS + 1) % LEN ))
    echo $NEW_POS > "$POS_FILE"

    ESCAPED_TEXT=$(safe_escape "$SCROLLING_TEXT")
    echo "{\"text\": \"$ESCAPED_TEXT\"}"

    sleep $INTERVAL
done