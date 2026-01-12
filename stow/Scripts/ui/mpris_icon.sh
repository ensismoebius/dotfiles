#!/bin/bash

# This script outputs the current mpris player icon and tooltip.
# It is designed to be used with Waybar as a separate module.

# --- Icon Configuration ---
PLAYER_ICON_MPV="♬"
STATUS_ICON_PLAYING="▶ "
STATUS_ICON_PAUSED="❚❚ "

PLAYER_STATUS=$(playerctl status 2>/dev/null)

ICON=""
TOOLTIP="Player stopped"

if [ "$PLAYER_STATUS" = "Playing" ] || [ "$PLAYER_STATUS" = "Paused" ]; then
    PLAYER_NAME=$(playerctl metadata --format '''{{playerName}}''' 2>/dev/null)
    METADATA=$(playerctl metadata --format '''{{artist}} - {{title}}''' 2>/dev/null)
    TOOLTIP="$METADATA"

    if [ "$PLAYER_STATUS" = "Playing" ]; then
        ICON=$STATUS_ICON_PLAYING
    elif [ "$PLAYER_STATUS" = "Paused" ]; then
        ICON=$STATUS_ICON_PAUSED
    fi

    # Override with player-specific icon if defined
    case $PLAYER_NAME in
        "mpv")
            ICON=$PLAYER_ICON_MPV
            ;; 
    esac
fi

# Escape tooltip for JSON and print
ESCAPED_TOOLTIP=$(echo "$TOOLTIP" | sed 's#\\#\\\\#g; s#"#\"#g' | tr -d '\n')
echo "{\"text\": \"$ICON\", \"tooltip\": \"$ESCAPED_TOOLTIP\"}"