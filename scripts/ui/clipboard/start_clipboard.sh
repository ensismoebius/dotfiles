#!/bin/bash

# Create cache directory if it doesn't exist
mkdir -p ~/.cache/cliphist

# Ensure the database exists
touch ~/.cache/cliphist/db

# Trim history to keep only the last 50 entries
if [ -f ~/.cache/cliphist/db ]; then
    # Get line count
    lines=$(wc -l < ~/.cache/cliphist/db)
    if [ "$lines" -gt 50 ]; then
        # Keep only the last 50 lines
        tail -n 50 ~/.cache/cliphist/db > ~/.cache/cliphist/db.tmp
        mv ~/.cache/cliphist/db.tmp ~/.cache/cliphist/db
    fi
fi

# Start wl-paste for both text and images
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &