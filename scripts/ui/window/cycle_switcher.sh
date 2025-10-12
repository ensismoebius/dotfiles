#!/bin/bash

# Define paths for history and index files
HISTORY_FILE="/tmp/hyprland_window_mru_history"
CURRENT_INDEX_FILE="/tmp/hyprland_window_mru_index"
MAX_HISTORY=10 # Maximum number of windows to keep in history

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

# Read current index or initialize to 0
if [ -f "$CURRENT_INDEX_FILE" ]; then
    CURRENT_INDEX=$(cat "$CURRENT_INDEX_FILE")
else
    CURRENT_INDEX=0
fi

# --- Update History (Most Recently Used logic) ---

# 1. Remove the current active window from history if it already exists
TEMP_HISTORY=()
for addr in "${HISTORY[@]}"; do
    if [ "$addr" != "$CURRENT_ACTIVE_ADDRESS" ]; then
        TEMP_HISTORY+=("$addr")
    fi
done
HISTORY=("${TEMP_HISTORY[@]}")

# 2. Add the current active window to the beginning of the history
HISTORY=("$CURRENT_ACTIVE_ADDRESS" "${HISTORY[@]}")

# 3. Filter out non-existent windows and trim the history to MAX_HISTORY
VALID_CLIENTS=$(hyprctl clients -j | jq -r '.[].address')
FILTERED_HISTORY=()
for addr in "${HISTORY[@]}"; do
    # Check if the window address still corresponds to an active client
    if echo "$VALID_CLIENTS" | grep -q "^$addr$"; then
        FILTERED_HISTORY+=("$addr")
    fi
done
HISTORY=("${FILTERED_HISTORY[@]:0:$MAX_HISTORY}")

# If history is empty after filtering, there are no valid windows to switch to
if [ ${#HISTORY[@]} -eq 0 ]; then
    echo "No valid windows in history."
    echo 0 > "$CURRENT_INDEX_FILE" # Reset index
    exit 0
fi

# --- Determine Next Window to Focus ---

NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#HISTORY[@]} ))
NEXT_WINDOW_ADDRESS="${HISTORY[$NEXT_INDEX]}"

# If the next window to focus is the same as the current active one,
# and there are other windows in history, advance the index one more time
# to ensure actual cycling. This handles cases where the current window
# might also be the next in the MRU list.
if [ "$NEXT_WINDOW_ADDRESS" == "$CURRENT_ACTIVE_ADDRESS" ] && [ ${#HISTORY[@]} -gt 1 ]; then
    NEXT_INDEX=$(( (NEXT_INDEX + 1) % ${#HISTORY[@]} ))
    NEXT_WINDOW_ADDRESS="${HISTORY[$NEXT_INDEX]}"
fi

# If after all checks, the next window is still the current active one,
# and it's the only window in history, then there's nothing to switch to.
if [ "$NEXT_WINDOW_ADDRESS" == "$CURRENT_ACTIVE_ADDRESS" ] && [ ${#HISTORY[@]} -eq 1 ]; then
    echo "Only one window, already focused."
    echo 0 > "$CURRENT_INDEX_FILE" # Reset index
    exit 0
fi

# Focus the determined next window
if [ -n "$NEXT_WINDOW_ADDRESS" ]; then
    hyprctl dispatch focuswindow "address:$NEXT_WINDOW_ADDRESS"
    echo "$NEXT_INDEX" > "$CURRENT_INDEX_FILE" # Save the new index
else
    echo "Could not determine next window to focus."
    echo 0 > "$CURRENT_INDEX_FILE" # Reset index
fi

# Write the updated history back to the file
printf "%s\n" "${HISTORY[@]}" > "$HISTORY_FILE"
