#!/bin/bash

# Configuration
WOFI_CONFIG="$HOME/.config/hypr/wofi/clipboard.css"

# Create config directory if it doesn't exist
mkdir -p "$(dirname "$WOFI_CONFIG")"

# Create wofi style configuration if it doesn't exist
if [ ! -f "$WOFI_CONFIG" ]; then
    cat > "$WOFI_CONFIG" << 'EOF'
@keyframes scanline {
    0% {
        background-position: 0 0;
    }
    100% {
        background-position: 0 100%;
    }
}

@keyframes glow {
    0% {
        box-shadow: 0 0 5px #00FF41, 0 0 10px #00FF41, 0 0 15px #008F11;
    }
    100% {
        box-shadow: 0 0 10px #00FF41, 0 0 20px #00FF41, 0 0 30px #008F11;
    }
}

window {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 13px;
    margin: 0px;
    border: 2px solid #00FF41;
    border-radius: 2px;
    background-color: rgba(13, 2, 8, 0.95);
    background-image: repeating-linear-gradient(
        0deg,
        rgba(0, 255, 65, 0.03) 0px,
        rgba(0, 255, 65, 0.03) 1px,
        transparent 1px,
        transparent 2px
    );
    animation: scanline 10s linear infinite;
    box-shadow: 0 0 15px #00FF41, 0 0 30px #008F11;
    animation: glow 2s ease-in-out infinite alternate;
}

#input {
    margin: 5px;
    border: 1px solid #00FF41;
    border-radius: 2px;
    color: #00FF41;
    background-color: rgba(13, 2, 8, 0.95);
    box-shadow: inset 0 0 5px #00FF41;
    animation: glow 2s ease-in-out infinite alternate;
}

#inner-box {
    margin: 5px;
    border: none;
    background-color: transparent;
}

#outer-box {
    margin: 5px;
    border: none;
    background-color: transparent;
}

#scroll {
    margin: 0px;
    border: none;
}

#text {
    margin: 5px;
    color: #00FF41;
    text-shadow: 0 0 5px #00FF41;
}

#entry {
    padding: 5px;
    border: none;
    transition: all 0.2s ease;
}

#entry:selected {
    background-color: rgba(0, 143, 17, 0.5);
    border-radius: 2px;
    border-left: 2px solid #00FF41;
    box-shadow: inset 0 0 10px #00FF41;
}

#entry:hover {
    background-color: rgba(0, 255, 65, 0.1);
    border-radius: 2px;
    border-left: 2px solid #008F11;
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