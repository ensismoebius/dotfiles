#!/bin/bash

AUDIO_DIR="$HOME/dotfiles/stow/Audios"

# Function to generate menu entries for wofi
generate_wofi_menu() {
    # Find all .mp3 files and loop through them
    find "$AUDIO_DIR" -type f -name "*.mp3" | while read -r file; do
        filename=$(basename "$file")
        # Generate a user-friendly description:
        # 1. Remove the .mp3 extension
        # 2. Replace hyphens with spaces
        # 3. Replace underscores with spaces
        # 4. Capitalize the first letter of each word (simple approach)
        description=$(echo "$filename" | sed 's/\.mp3$//' | sed 's/-/ /g' | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1))tolower(substr($i,2));}1')

        echo "$filename - $description"
    done
}

# Display wofi menu and get user selection
# --show dmenu: use dmenu mode (text input)
# --prompt: set the prompt text
chosen_entry=$(generate_wofi_menu | wofi --show dmenu --prompt "Choose an audio file:")

# Check if a file was chosen (wofi returns empty if canceled)
if [ -n "$chosen_entry" ]; then
    # Extract just the original filename from the chosen string
    # Assuming format "filename.mp3 - Description"
    filename_only=$(echo "$chosen_entry" | awk -F ' - ' '{print $1}')
    audio_path="$AUDIO_DIR/$filename_only"

    # Check if the file exists before attempting to play
    if [ -f "$audio_path" ]; then
        # Play the audio file using mpv in the background
        # --no-video: ensure no video window opens
        # --really-quiet: suppress most mpv output
        mpv --no-video --really-quiet "$audio_path" &
    else
        # Optional: notify user if file not found
        notify-send "Audio Player" "Error: Audio file not found: $filename_only"
    fi
fi
