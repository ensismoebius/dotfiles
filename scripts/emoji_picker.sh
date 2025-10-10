#!/bin/bash
emoji=$(wofi -dmenu -p "Select Emoji" < "$HOME/dotfiles/hyprland/scripts/emojis.txt")
if [ -n "$emoji" ]; then
  echo -n "$emoji" | wl-copy
fi
