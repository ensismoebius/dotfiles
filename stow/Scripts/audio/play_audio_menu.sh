#!/bin/bash

AUDIO_DIR="$HOME/dotfiles/stow/Audios"

# Declare an associative array to map descriptions to filenames
declare -A audio_map
# Declare an array to hold menu descriptions for wofi
declare -a menu_descriptions

# Populate the map and description array
while read -r file; do
    filename=$(basename "$file")
    description=$(echo "$filename" | sed 's/\.mp3$//' | sed 's/-/ /g' | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1))tolower(substr($i,2));}1')

    audio_map["$description"]="$filename"
    menu_descriptions+=("$description")
done < <(find "$AUDIO_DIR" -type f -name "*.mp3") # Use process substitution to keep 'audio_map' in current shell

# Convert the array of descriptions into a newline-separated string for wofi
wofi_input=$(printf "%s\n" "${menu_descriptions[@]}")

# Display wofi menu and get user selection
chosen_entry=$(echo "$wofi_input" | wofi --show dmenu --prompt "Choose an audio file:")

# Check if a file was chosen (wofi returns empty if canceled)
if [ -n "$chosen_entry" ]; then
    # Retrieve the original filename using the chosen description
    filename_only="${audio_map["$chosen_entry"]}"
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
