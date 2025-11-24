#!/bin/bash

# Get the directory of the script
SCRIPT_DIR=$(dirname "$0")

# Path to the emoji file
EMOJI_FILE="$SCRIPT_DIR/emojis.txt"

# Check if the emoji file exists
if [ ! -f "$EMOJI_FILE" ]; then
    notify-send "Error" "Emoji file not found at $EMOJI_FILE"
    exit 1
fi

# Let the user select an emoji with wofi
# The -dmenu flag tells wofi to work as a dynamic menu
# The -p flag sets the prompt text
selected_line=$(wofi -dmenu -p "Select Emoji" < "$EMOJI_FILE")

# If the user selected an emoji (the line is not empty)
if [ -n "$selected_line" ]; then
  # Extract the emoji (the first word on the line)
  emoji=$(echo "$selected_line" | cut -d' ' -f1)
  
  # Copy the emoji to the clipboard using wl-copy
  echo -n "$emoji" | wl-copy
  
  # Optional: send a notification that the emoji was copied
  notify-send "Copied to clipboard" "$emoji"
fi