Clipboard manager helper scripts
================================

What I changed
--------------
- Removed accidental Markdown code fences from the shell scripts so they are valid.
- Made `start_clipboard.sh` resilient to a corrupt `cliphist` database: it will try to restore from the newest backup, or move the corrupt DB aside so a fresh one can be created.

Files
-----
- `clipboard_manager.sh` - wofi-based UI to browse, select and clear clipboard history.
- `start_clipboard.sh` - starts `wl-paste` watchers that feed `cliphist`.

Dependencies
------------
Make sure these are installed (package names vary by distro):

- wl-clipboard (provides `wl-copy` and `wl-paste`)
- cliphist
- wofi
- libnotify (provides `notify-send`)

Quick tests
-----------
Manually start the watchers (use this to test or if autostart didn't run):

    ~/.config/hypr/scripts/ui/clipboard/start_clipboard.sh

Copy a test string and check cliphist:

    echo 'clip-test-123' | wl-copy
    sleep 0.5
    cliphist list | tail -n 10

Check that wl-paste watchers are running:

    ps aux | grep -E 'wl-paste' | grep -v grep

If cliphist complains about an invalid DB, the start script will attempt to restore from the newest backup in `~/.cache/cliphist/`. If it can't, it will rename the corrupt DB to `db.corrupt.<timestamp>` so a fresh DB can be created.

Notes
-----
- The autostart entry in `~/.config/hypr/hyprland.conf.d/03-autostart.conf` already calls the start script. If clipboard history still doesn't populate after login, run the start script manually and check the output.
- If you prefer automatic backgrounding you can change the autostart line to append an ampersand or ensure hypr's `exec-once` starts scripts in the session environment.
