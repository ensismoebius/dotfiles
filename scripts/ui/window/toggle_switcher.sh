#!/bin/bash

# Define paths for history file
HISTORY_FILE="/tmp/hyprland_window_mru_history"
MAX_HISTORY=10

# Function to save history on exit
save_history() {
    printf "%s\n" "${HISTORY[@]}" > "$HISTORY_FILE"
}
trap save_history EXIT

# Get the address of the currently active window
CURRENT_ACTIVE_ADDRESS=$(hyprctl activewindow -j | jq -r '.address')

# Read existing history or initialize an empty array
if [ -f "$HISTORY_FILE" ]; then
    readarray -t HISTORY < "$HISTORY_FILE"
else
    HISTORY=()
fi

# --- Update History (Most Recently Used logic) ---
TEMP_HISTORY=()
for addr in "${HISTORY[@]}"; do
    if [ "$addr" != "$CURRENT_ACTIVE_ADDRESS" ]; then
        TEMP_HISTORY+=("$addr")
    fi
done
HISTORY=("${TEMP_HISTORY[@]}")

HISTORY=("$CURRENT_ACTIVE_ADDRESS" "${HISTORY[@]}")

VALID_CLIENTS=$(hyprctl clients -j | jq -r '.[].address')
FILTERED_HISTORY=()
for addr in "${HISTORY[@]}"; do
    if echo "$VALID_CLIENTS" | grep -q "^$addr$"; then
        FILTERED_HISTORY+=("$addr")
    fi
done
HISTORY=("${FILTERED_HISTORY[@]:0:$MAX_HISTORY}")

# --- Determine Next Window to Focus (Toggle logic) ---
if [ ${#HISTORY[@]} -ge 2 ]; then
    NEXT_WINDOW_ADDRESS="${HISTORY[1]}"
    hyprctl dispatch focuswindow "address:$NEXT_WINDOW_ADDRESS"
else
    echo "Not enough windows in history to toggle."
fi
