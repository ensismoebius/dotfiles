
#!/bin/bash

# Start clipboard history watchers for wl-clipboard/wayland
# Ensure cache dir exists but DO NOT create an empty db file (that can corrupt sqlite)
DB_DIR="$HOME/.cache/cliphist"
DB_PATH="$DB_DIR/db"

mkdir -p "$DB_DIR"

# If cliphist cannot read the DB, try to restore from the newest backup. If none,
# move the corrupt DB out of the way and allow cliphist to create a fresh DB.
if command -v cliphist >/dev/null 2>&1; then
    if [ -f "$DB_PATH" ]; then
        if ! cliphist list >/dev/null 2>&1; then
            echo "cliphist: invalid DB detected at $DB_PATH" >&2
            # try to find latest backup
            latest_bak=$(ls -t "$DB_DIR"/db.bak.* 2>/dev/null | head -n1 || true)
            if [ -n "$latest_bak" ]; then
                echo "Restoring DB from backup $latest_bak" >&2
                cp -f "$latest_bak" "$DB_PATH"
                if cliphist list >/dev/null 2>&1; then
                    echo "cliphist: restored DB from backup." >&2
                else
                    echo "cliphist: backup also invalid, moving corrupt DB aside." >&2
                    mv "$DB_PATH" "$DB_PATH.corrupt.$(date +%s)"
                fi
            else
                echo "cliphist: no backup found, moving corrupt DB aside." >&2
                mv "$DB_PATH" "$DB_PATH.corrupt.$(date +%s)"
            fi
        fi
    fi
fi

# Start wl-paste watchers for text and images. They will create DB entries via cliphist.
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

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