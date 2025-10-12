#!/bin/bash

USAGE_FILE="$HOME/.config/hypr/scripts/ui/app-menu/app-usage.txt"
USAGE_DIR="$(dirname "$USAGE_FILE")"

# Create directory if it doesn't exist
mkdir -p "$USAGE_DIR"

# Create usage file if it doesn't exist
touch "$USAGE_FILE"

if [ "$1" = "record" ] && [ -n "$2" ]; then
    # Record app usage
    desktop_file="$2"
    echo "$desktop_file" >> "$USAGE_FILE"
elif [ "$1" = "list" ]; then
    # Create a temporary file for sorted applications
    TEMP_FILE=$(mktemp)
    
    # Get sorted list of apps based on frequency
    if [ -s "$USAGE_FILE" ]; then
        sort "$USAGE_FILE" | uniq -c | sort -rn | awk '{$1=""; print substr($0,2)}' > "$USAGE_DIR/sorted-apps.txt"
    fi
    
    # First add frequently used apps if they exist
    if [ -f "$USAGE_DIR/sorted-apps.txt" ]; then
        while IFS= read -r app; do
            grep "^$app$" /usr/share/applications/*.desktop 2>/dev/null | sed 's/.*://' >> "$TEMP_FILE"
        done < "$USAGE_DIR/sorted-apps.txt"
    fi
    
    # Then add all other apps
    find /usr/share/applications -name "*.desktop" >> "$TEMP_FILE"
    
    # Output unique entries
    cat "$TEMP_FILE" | sort -u
    
    # Clean up
    rm -f "$TEMP_FILE"
fi