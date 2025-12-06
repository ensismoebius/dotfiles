Firefox Chrome CSS (userChrome / userContent)

What these files do:
- `userChrome.css` forces the Firefox chrome (address bar autocomplete, suggestion popups) to use a bright neon selection background and black text so suggestions are visible on dark/neon themes.
- `userContent.css` forces web page `::selection` to the same neon background + black text so selected text is readable on web pages. Note: this may override some sites' intended selection colors.

How to enable and apply
1. Open Firefox and go to `about:config`.
2. Set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true`.
3. Locate your profile folder (in Firefox, go to `about:support` and click "Profile Folder" > "Open Folder").
4. Inside the profile folder create a folder named `chrome` (if it doesn't exist).
5. Copy or symlink the two files from this repo into that `chrome` folder:
   - `userChrome.css`
   - `userContent.css`

   Example (replace `<profile>` with your real profile path):

   ```bash
   mkdir -p "~/.mozilla/firefox/<profile>/chrome"
   cp /path/to/dotfiles/stow/firefox/chrome/userChrome.css "~/.mozilla/firefox/<profile>/chrome/"
   cp /path/to/dotfiles/stow/firefox/chrome/userContent.css "~/.mozilla/firefox/<profile>/chrome/"
   ```

6. Restart Firefox completely (quit all windows and relaunch).

Notes and troubleshooting
- If you still see transparency or unreadable text after enabling and copying, try toggling the theme off (switch to default Firefox theme) to check whether the window manager/GTK theme is still overriding chrome styling.
- Extensions that style the UI (e.g., custom themes or extension UI mods) can interfere; try in Troubleshoot Mode (Help → Troubleshoot Mode) to identify extension conflicts.
- `userContent.css` affects website rendering and might break some sites. If you only need address-bar fixes, you can skip `userContent.css`.

If you want, I can also:
- Automatically attempt to find your active Firefox profile path and create symlinks for you (I will not modify files inside `~/.mozilla/firefox` without your permission).
- Tweak the exact hex for selection (cyan vs neon green) and re-run tests.

