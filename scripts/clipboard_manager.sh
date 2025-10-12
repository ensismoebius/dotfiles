#!/bin/bash

# Configuration
WOFI_CONFIG="$HOME/.config/hypr/wofi/clipboard.css"

# Create config directory if it doesn't exist
mkdir -p "$(dirname "$WOFI_CONFIG")"

# Create wofi style configuration if it doesn't exist
if [ ! -f "$WOFI_CONFIG" ]; then
    cat > "$WOFI_CONFIG" << 'EOF'
window {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 13px;
    margin: 0px;
    border: 2px solid #008F11;
    border-radius: 5px;
    background-color: #0D0208;
}

#input {
    margin: 5px;
    border: 2px solid #008F11;
    border-radius: 5px;
    color: #00FF41;
    background-color: #0D0208;
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: #0D0208;
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: #0D0208;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    color: #00FF41;
}

#entry {
    padding: 5px;
    border: none;
}

#entry:selected {
    background-color: #008F11;
    border-radius: 5px;
}
EOF
fi

# Function to show the menu
show_menu() {
    cliphist list | wofi --dmenu \
        --style "$WOFI_CONFIG" \
        --width 600 \
        --height 400 \
        --prompt "Search clipboard..." \
        --matching "fuzzy" \
        --allow-markup \
        --location center \
        --no-actions \
        --lines 10 \
        --cache-file /dev/null \
        --define "content-halign=start" \
        "$@"
}

# Show menu and get selection
case ${1:-show} in
    show)
        # Show menu and copy selection
        selected=$(show_menu)
        if [ -n "$selected" ]; then
            echo "$selected" | cliphist decode | wl-copy
        fi
        ;;
    delete)
        # Show menu and delete selection
        selected=$(show_menu --prompt "Select to delete...")
        if [ -n "$selected" ]; then
            echo "$selected" | cliphist delete
        fi
        ;;
    clear)
        # Clear entire history
        cliphist wipe
        notify-send "Clipboard" "History cleared!"
        ;;
esac