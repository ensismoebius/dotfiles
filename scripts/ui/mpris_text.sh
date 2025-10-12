#!/bin/bash

# Waybar module for scrolling playerctl metadata text

# --- Configuration ---
MAX_LEN=20          # Max length of the text to show
INTERVAL=0.5        # Update interval in seconds

# --- Script Internals ---

# Function to safely escape text for JSON
safe_escape() {
    echo "$1" | sed 's#\\#\\\\#g; s#"#\"#g' | tr -d '\n'
}

LAST_METADATA=""
scroll_pos=0

# --- Main Loop ---
while true; do
    PLAYER_STATUS=$(playerctl status 2>/dev/null)
    
    if [ "$PLAYER_STATUS" = "Playing" ] || [ "$PLAYER_STATUS" = "Paused" ]; then
        METADATA=$(playerctl metadata --format '''{{artist}} - {{title}}''')
    else
        if [ "$LAST_METADATA" != "" ]; then
            scroll_pos=0
            echo '{"text": ""}'
        fi
        LAST_METADATA=""
        sleep 1
        continue
    fi

    # --- Reset scroll if metadata changed ---
    if [ "$METADATA" != "$LAST_METADATA" ]; then
        scroll_pos=0
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
    if [ "$PLAYER_STATUS" = "Paused" ]; then
        TEXT_TO_SHOW=$(echo "$METADATA" | cut -c 1-$AVAILABLE_LEN)
        ESCAPED_TEXT=$(safe_escape "$TEXT_TO_SHOW")
        echo "{\"text\": \"$ESCAPED_TEXT\"}"
        sleep 1
        continue
    fi
    
PADDED_METADATA="$METADATA   " # Padding for seamless scroll
LEN=${#PADDED_METADATA}

SCROLLING_TEXT=$(echo "$PADDED_METADATA$PADDED_METADATA" | cut -c $((scroll_pos + 1))-$((scroll_pos + AVAILABLE_LEN)))

    # Update scroll position for next iteration
    scroll_pos=$(( (scroll_pos + 1) % LEN ))

    ESCAPED_TEXT=$(safe_escape "$SCROLLING_TEXT")
    echo "{\"text\": \"$ESCAPED_TEXT\"}"

    sleep $INTERVAL
done
