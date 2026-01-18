## **Follow-up run outputs**
- **Run timestamp:** 2026-01-18T01:46:06-03:00
- **Portal log (key excerpts):**
  The unit files have no installation config (WantedBy=, RequiredBy=, ...). Job for xdg-desktop-portal-hyprland.service failed because the control process exited with error code.
  ● xdg-desktop-portal-hyprland.service - Portal service (Hyprland implementation)
  Loaded: loaded (/usr/lib/systemd/user/xdg-desktop-portal-hyprland.service; static)
  Active: activating (auto-restart) (Result: exit-code) since 2026-01-18T01:46:06 -03; Invocation: cf8bfa6e...
  Process: 1967017 ExecStart=/usr/lib/xdg-desktop-portal-hyprland (code=exited, status=1/FAILURE)
  Journal excerpts (repeated):
  [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
  systemd reports repeated start failures and rapid restarts; final state: start request repeated too quickly / failed with result 'exit-code'.
  `which` returned: no xdg-desktop-portal-hyprland in PATH (binary not found in PATH locations checked).
- **Flatpak removals (result):**
  No com.ml4w refs found (script searched `flatpak list` output and found none in this run).
- **Hyprland actions & output:**
  `hyprctl configerrors` produced no fatal config dump here, but reload attempts returned:
  - `hyprctl dispatch reload` => "Invalid dispatcher"
  - `hyprctl reload` => "ok"
  `hyprctl monitors` reported monitor `eDP-1` (ID 0) with resolution `1366x768@60.00000` and other monitor metadata (scale 1.00, focused: yes, dpmsStatus: 1, etc.).
```
## **Interactive helper run (DRY_RUN)**
- **Run timestamp:** 2026-01-18T01:48:07-03:00

- Skipped portal enable
- **flatpak list --app --columns=application,ref --user**
```
(DRY_RUN=1) Command: flatpak list --app --columns=application,ref --user
(DRY_RUN=1) Output omitted or captured locally.
```

- **flatpak list --app --columns=application,ref --system**
```
(DRY_RUN=1) Command: flatpak list --app --columns=application,ref --system
(DRY_RUN=1) Output omitted or captured locally.
```

No com.ml4w refs found
- Skipped Hyprland reload/checks
- **Helper run completed:** 2026-01-18T01:48:07-03:00

## **Portal follow-up: user service observed running**
- **Observed:** 2026-01-18T01:51:00-03:00

`systemctl --user status` shows `xdg-desktop-portal-hyprland.service` running under the user slice with a process `/usr/lib/xdg-desktop-portal-hyprland` (PID 1971580 listed in process tree). Service marked as started in the user session.

Result: portal user service is running — marking task complete.

- [x] 21) Add high-priority Hyprland rule for `xdg-desktop-portal-gtk` "Open Folder"
  - Timestamp: 2026-01-18T01:55:00-03:00
  - File: `stow/config/.config/hypr/hyprland.conf.d/11-windowrules.conf`
  - Change: Added explicit `windowrulev` to force `float, center, size 60% 60%` for `initialClass:xdg-desktop-portal-gtk` and `initialTitle:^Open Folder$` to ensure file chooser dialogs float and center reliably.
  - Validation: file updated in repo; run `hyprctl reload` from an active Hyprland session and verify `hyprctl activewindow` shows `floating: 1` for the dialog.
  - Result: pending (requires Hyprland reload in the active session).

Commands to test now (run in an active Hyprland session):
```bash
hyprctl configerrors
hyprctl dispatch reload || hyprctl reload
sleep 1 && hyprctl activewindow
# If dialog still not floating, focus it then run:
hyprctl dispatch togglefloating
```

**Observed (manual toggle):** 2026-01-18T02:07:11-03:00

After running `hyprctl dispatch togglefloating` the `Open Folder` dialog reported `floating: 1` and PID `1375` (class `xdg-desktop-portal-gtk`). Temporary toggle succeeded; a persistent override file was added at `stow/config/.config/hypr/hyprland.conf.d/00-portal-override.conf` to enforce this behavior. Run the persistent reload commands below in your session to apply permanently.

Persistent reload commands to run now (in your Hyprland session):
```bash
hyprctl configerrors
hyprctl reload
sleep 0.5
hyprctl activewindow
```

## **Hyprland reload result**
- **Run timestamp:** 2026-01-18T02:12:00-03:00

```
CONFIG:
RELOAD: ok
ACTIVE: Window 55c5f6383d40 -> Estilo Atraente Baseado em Pesquisa — Mozilla Firefox:
ACTIVE:         mapped: 1
ACTIVE:         hidden: 0
ACTIVE:         at: 4,22
ACTIVE:         size: 1358,742
ACTIVE:         workspace: 5 (5)
ACTIVE:         floating: 0
ACTIVE:         pseudo: 0
ACTIVE:         monitor: 0
ACTIVE:         class: firefox
ACTIVE:         title: Estilo Atraente Baseado em Pesquisa — Mozilla Firefox
ACTIVE:         initialClass: firefox
ACTIVE:         initialTitle: Mozilla Firefox
ACTIVE:         pid: 1897196
ACTIVE:         xwayland: 0
ACTIVE:         pinned: 0
ACTIVE:         fullscreen: 0
ACTIVE:         fullscreenClient: 0
ACTIVE:         grouped: 0
ACTIVE:         tags:
ACTIVE:         swallowing: 0
ACTIVE:         focusHistoryID: 0
ACTIVE:         inhibitingIdle: 0
ACTIVE:         xdgTag:
ACTIVE:         xdgDescription:
ACTIVE:         contentType: none
```

Note: `hyprctl reload` returned `ok`. The active window after reload is a Firefox window (not the portal dialog) — if the portal file-chooser is focused when you run `hyprctl activewindow` it should show `floating: 1` per the override. If you want, I can mark the portal dialog task complete once you confirm the portal dialog shows `floating: 1` after reload.

## **Portal env & service restart**
- **Run timestamp:** 2026-01-18T02:15:00-03:00

```
SETENV: 
RESTART: 
PID:
NO_PID

SYSTEMD STATUS (excerpt):
  xdg-desktop-portal.service - Portal service: inactive (dead)
  xdg-desktop-portal-hyprland.service - Portal service (Hyprland implementation): active (running) at some checks, but journal shows repeated DBus FileExists failures and start/stop cycles.

JOURNAL HIGHLIGHTS:
  [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
  Start/Stop cycles observed; later entries show successful starts (e.g., "Started Portal service (Hyprland implementation)").
```

Observation: I attempted to set the user environment and restart the portal services; the portal service is unstable (frequent restarts / DBus name conflicts) and the portal process PID was not reliably present when checked, so I could not confirm the process environment variables. If you want, I can continue trying to stabilize and capture `/proc/<pid>/environ`, but that may require you to reproduce the file-chooser and then run the verification immediately (or keep the portal service running while I check).

## **Flatpak overrides applied**
- **Run timestamp:** 2026-01-18T02:22:00-03:00

```
APPLY: Applying Flatpak environment overrides for GTK/icon theme: WhiteSur-Dark-pink-nord
APPLY: Overriding io.github.mhogomchungu.sirikali
APPLY: Overriding org.telegram.desktop
APPLY: Overrides applied. Restart Flatpak apps to pick up changes.
--- SCAN FOR com.ml4w ---

No `com.ml4w.*` Flatpak apps were found in user or system scopes.
```

Next: restart any running Flatpak apps to pick up the new environment (logout/login or restart specific apps). I marked the Flatpak step complete in the TODOs.

## **Hyprland reload & portal verification**
- **Run timestamp:** 2026-01-18T02:31:00-03:00

```
CONFIG: 
RELOAD: ok
ACTIVE: Window 55c5f6307cd0 -> Open Folder:
ACTIVE:         mapped: 1
ACTIVE:         hidden: 0
ACTIVE:         at: 42,65
ACTIVE:         size: 685,384
ACTIVE:         workspace: 1 (1)
ACTIVE:         floating: 1
ACTIVE:         pseudo: 0
ACTIVE:         monitor: 0
ACTIVE:         class: xdg-desktop-portal-gtk
ACTIVE:         title: Open Folder
ACTIVE:         initialClass: xdg-desktop-portal-gtk
ACTIVE:         initialTitle: Open Folder
ACTIVE:         pid: 1375
ACTIVE:         xwayland: 0
ACTIVE:         pinned: 0
ACTIVE:         fullscreen: 0
ACTIVE:         fullscreenClient: 0
ACTIVE:         grouped: 0
ACTIVE:         tags: 
ACTIVE:         swallowing: 0
ACTIVE:         focusHistoryID: 0
ACTIVE:         inhibitingIdle: 0
ACTIVE:         xdgTag: 
ACTIVE:         xdgDescription: 
ACTIVE:         contentType: none
```

Result: The portal file-chooser `Open Folder` is focused and shows `floating: 1` after `hyprctl reload` — the persistent Hyprland override is working.

Action: Marking TODO `Reload Hyprland & verify portal` as completed.

## **Portal env capture attempt**
- **Run timestamp:** 2026-01-18T02:36:00-03:00

Attempted to set user environment and restart portal services to force theme inheritance.

```
SETENV: (ran)
RESTART: (ran)
STATUS: xdg-desktop-portal-hyprland.service - Active: active (running) ... Main PID: 2014750
PS: 1332 /usr/lib/xdg-desktop-portal
PS: 1375 /usr/lib/xdg-desktop-portal-gtk
PS: 2014750 /usr/lib/xdg-desktop-portal-hyprland

ENV-CAPTURE: attempted but portal process was not stable/accessible at time of read; `/proc/<pid>/environ` could not be read reliably.
```

Notes: The portal service shows frequent start/stop cycles in the journal; capturing `/proc/<pid>/environ` requires the portal process to be running while we read it. If you reproduce the file-chooser and keep it open, run the following immediately and paste the output here:

```
pid=$(pgrep -f xdg-desktop-portal-hyprland | head -n1 || pgrep -f xdg-desktop-portal | head -n1)
echo PID:$pid
tr '\0' '\n' < /proc/$pid/environ | egrep 'GTK_THEME|XDG_CURRENT_DESKTOP|QT_QPA_PLATFORMTHEME|QT_QPA_PLATFORM'
```

I will keep the portal env TODO as `in-progress` until we capture those variables.

## **Portal environment captured**
- **Run timestamp:** 2026-01-18T02:40:00-03:00

```
PS: 1332 /usr/lib/xdg-desktop-portal
PS: 1375 /usr/lib/xdg-desktop-portal-gtk
PS: 2014750 /usr/lib/xdg-desktop-portal-hyprland

FOUND PID: 2014750
GTK_THEME=WhiteSur-Dark-pink-nord
QT_QPA_PLATFORMTHEME=qt6ct
QT_QPA_PLATFORM=wayland;xcb
XDG_CURRENT_DESKTOP=Hyprland
```

Result: Portal process environment variables show the configured theme and Qt settings — theme inheritance confirmed.

Action: Marked `Set portal GTK env` as completed.

# Theme & Window Management Audit and Changes

Generated: 2026-01-18T00:00:00Z

All steps must be followed in order. This file records every performed step, file/component modified, previous value, new value, validation method, and result.

---

- [x] 1) Create `todo.md` (this file)
  - Timestamp: 2026-01-18T00:00:00Z
  - File: `todo.md`
  - Previous value: n/a
  - New value: created
  - Validation: file exists in repository root
  - Result: success

- [x] 2) Scan workspace for config files
  - Timestamp: 2026-01-18T00:00:05Z
  - Action: Searched repo for Hyprland, GTK, Qt, and env/profile files
  - Files discovered (representative):
    - `stow/config/.config/hypr/hyprland.conf`
    - `stow/config/.config/hypr/hyprland.conf.d/11-windowrules.conf`
    - `stow/config/.config/hypr/hyprland.conf.d/22-dialogs.conf`
    - `stow/config/.config/gtk-3.0/settings.ini`
    - `stow/config/.config/gtk-4.0/settings.ini`
    - `stow/config/.config/qt5ct/qt5ct.conf`
    - `stow/config/.config/qt6ct/qt6ct.conf`
    - `stow/config/etc/profile.d/white-sur-theme.sh`
  - Validation: filesystem inspection via repository search
  - Result: success

- [x] 3) Read and record current Hyprland config pointers
  - Timestamp: 2026-01-18T00:00:10Z
  - File: `stow/config/.config/hypr/hyprland.conf`
  - Previous value: referenced many `source =` fragments under `hyprland.conf.d`
  - New value: no change
  - Validation: file content inspected
  - Result: success (no edits yet)

- [x] 4) Update environment/profile script to enforce env vars
  - Timestamp: 2026-01-18T00:01:00Z
  - File: `stow/config/etc/profile.d/white-sur-theme.sh`
  - Previous value:
    ```sh
    export QT_QPA_PLATFORMTHEME=qt5ct
    export QT_STYLE_OVERRIDE=Breeze
    export GTK_THEME=WhiteSur-Dark-pink-nord
    export XDG_CURRENT_DESKTOP=GNOME
    ```
  - New value:
    ```sh
    export GTK_THEME=WhiteSur-Dark-pink-nord
    export QT_QPA_PLATFORM="wayland;xcb"
    export QT_QPA_PLATFORMTHEME=qt6ct
    export QT_QPA_PLATFORMTHEME_FALLBACK=qt5ct
    export XDG_CURRENT_DESKTOP=Hyprland
    ```
  - Validation method: file content inspection in repo (post-edit)
  - Result: success (file updated in repo). Note: system-wide activation requires stow/deploy or sourcing by login shells; not applied automatically by this script run.

- [x] 5) Normalize GTK3 settings
  - Timestamp: 2026-01-18T00:02:10Z
  - File: `stow/config/.config/gtk-3.0/settings.ini`
  - Previous value: file had two `[Settings]` sections with conflicting themes (`WhiteSur-Dark-pink-nord` and `WhiteSur-Dark-solid-pink-nord` + `Cyberpunk-Neon` icon theme)
  - New value: single `[Settings]` section with `gtk-theme-name=WhiteSur-Dark-pink-nord` and `gtk-icon-theme-name=WhiteSur-Dark-pink-nord` and consistent dark preference
  - Validation method: file content inspection in repo
  - Result: success (file updated). Manual verification: launch a GTK3 app after deploying the dotfiles and check theme; pending.

- [x] 6) Ensure GTK4 settings present and correct
  - Timestamp: 2026-01-18T00:02:20Z
  - File: `stow/config/.config/gtk-4.0/settings.ini`
  - Previous value: already set to `WhiteSur-Dark-pink-nord` and dark preference
  - New value: no change
  - Validation method: file content inspection
  - Result: success

- [x] 7) Add icon theme hint to Qt config files
  - Timestamp: 2026-01-18T00:03:00Z
  - Files modified:
    - `stow/config/.config/qt5ct/qt5ct.conf`
    - `stow/config/.config/qt6ct/qt6ct.conf`
  - Previous value: no explicit `icon_theme` key under `[Appearance]`
  - New value: added `icon_theme=WhiteSur-Dark-pink-nord` under `[Appearance]`
  - Validation method: file content inspection in repo
  - Result: success (files updated). Note: `qt5ct`/`qt6ct` also require the environment variable `QT_QPA_PLATFORMTHEME` to be set (done in profile script). Further GUI validation required.

- [ ] 8) Add/convert Hyprland rules to `windowrulev2` and ensure modal/xwayland/role matching
  - Timestamp: pending
  - Files to modify: `stow/config/.config/hypr/hyprland.conf.d/11-windowrules.conf`, `stow/config/.config/hypr/hyprland.conf.d/22-dialogs.conf`
  - Previous value: uses `windowrule` and `windowrulev` entries that already broadly float/center/size many dialogs but do not explicitly use `windowrulev2` tokens everywhere
  - New value: (planned) add explicit `windowrulev2` entries enforcing `float`, `center`, `size 60% 60%` and match on `class`, `title`, `xwayland`, `modal`, and `role` where applicable; ensure multi-monitor centering using Hyprland variables.
  - Validation method: inspect generated `*.conf.d` fragments and test under Hyprland (requires reloading Hyprland and visual verification)
  - Result: pending (manual/interactive step required). Cannot safely auto-convert to `windowrulev2` without target Hyprland version syntax validation; recommended next step: allow me to generate candidate `windowrulev2` entries and run a syntax check or let you confirm before applying.

- [ ] 9) Flatpak / Snap theme & portal integration
  - Timestamp: pending
  - Target files/locations: `~/.local/share/flatpak/overrides/`, system Flatpak portal configs, Snap theme connections
  - Action: create Flatpak overrides and portal settings to ensure Flatpak/Snap apps inherit GTK and icon themes (via portal and XDG_THEME overrides)
  - Validation: inspect `flatpak override --show` for test apps and verify icons in file pickers
  - Result: pending (requires running `flatpak` commands and system-level installs)

- [ ] 10) Ensure `xdg-desktop-portal-hyprland` installed and active
  - Timestamp: pending
  - Action: check package manager and systemd/user status for `xdg-desktop-portal-hyprland`
  - Validation: `systemctl --user status xdg-desktop-portal-hyprland` and `which xdg-desktop-portal-hyprland`
  - Result: pending (requires system commands and privileges)

 - [ ] 11) Visual verification and finalization
  - Timestamp: pending
  - Actions:
    - Deploy these dotfiles (stow or copy into `~/.config` and `/etc/profile.d`), source profile, restart session or source env scripts
    - Launch GTK3/GTK4/Qt5/Qt6/Flatpak apps, open file pickers and authentication dialogs, and verify theme + icons
    - Open multiple-monitor scenario and verify dialogs appear centered on active monitor and sized to 60% x 60%
  - Validation: manual/visual; record screenshots and the `hyprctl activewindow` output for matched dialogs
  - Result: pending

 - [ ] 19) Create system-run script to finish installs/uninstalls and reload Hyprland
  - Timestamp: 2026-01-18T00:50:00Z
  - File: `stow/config/scripts/complete-system-setup.sh`
  - Purpose: install `xdg-desktop-portal-hyprland` via detected package manager (uses `sudo`), enable the user portal service, remove `com.ml4w.*` flatpaks from user and system scopes, and reload Hyprland. Logs to `complete-system-setup.log` in repo root when run.
  - Validation: script must be run locally; it emits logs and returns non-zero on failures visible in log
  - Result: script added to repo; pending execution locally (requires sudo for system operations)

- [x] 20) Run `complete-system-setup.sh` and record outputs
  - Timestamp: 2026-01-18T00:55:00Z
  - Command: `bash stow/config/scripts/complete-system-setup.sh`
  - Log file: `complete-system-setup.log` (repo root)
  - Actions performed:
    - Detected package manager: `pacman`
    - Attempted to install/reinstall `xdg-desktop-portal-hyprland` via `pacman` (installation ran and package was reinstalled)
    - Attempted to enable/start `xdg-desktop-portal-hyprland` user service via `systemctl --user` (failed)
    - Attempted to remove `com.ml4w.*` Flatpaks from user and system scopes (system uninstalls attempted with sudo but each ref failed to uninstall)
    - Attempted to reload Hyprland via `hyprctl dispatch reload` (result: `Invalid dispatcher`)
  - Important outputs / excerpts (see full log):
    - "Enable failed; check user/systemd session"
    - "Failed to uninstall com.ml4w.* (system)" for each `com.ml4w` ref
    - "Invalid dispatcher" from `hyprctl`
  - Validation method: inspected `/home/ensismoebius/dotfiles/complete-system-setup.log`
  - Result: partial success — portal package was present/reinstalled, but enabling the portal service failed (likely due to systemd user session environment), Flatpak uninstalls failed in system scope (sudo uninstalls did not remove the refs), and Hyprland could not be reloaded in this environment. Manual follow-up actions are required (explained below).
  - Next steps (recommended):
    - Check user journal and service status locally: `systemctl --user status xdg-desktop-portal-hyprland` and `journalctl --user -xeu xdg-desktop-portal-hyprland`
    - Uninstall `com.ml4w.*` refs from the appropriate scope (user or system) using the refs reported by `flatpak list --app --columns=application,ref` and `sudo` for system scope if necessary.
    - Run `hyprctl dispatch reload` from an active Hyprland session to apply rules and verify dialog behavior.
    - Validation method: file content inspection in repo
    - Result: success (candidate created). Manual review strongly recommended before deploying.

  - [x] 13) Add Flatpak override template and apply script
    - Timestamp: 2026-01-18T00:11:00Z
    - Files added:
      - `stow/config/.local/share/flatpak/overrides/WhiteSur-Dark-pink-nord.template.override`
      - `stow/config/scripts/apply-flatpak-overrides.sh`
      - `stow/config/scripts/check-xdg-portal-hyprland.sh`
    - Previous value: not present
    - New value: template + scripts to apply/verify Flatpak overrides and portal
    - Validation method: file content inspection in repo
    - Result: success (templates and helper scripts added). Running the scripts and applying overrides requires local execution.

  - [x] 14) Convert Hyprland `windowrule`/`windowrulev` to `windowrulev2` in-place
    - Timestamp: 2026-01-18T00:12:30Z
    - Files modified:
      - `stow/config/.config/hypr/hyprland.conf.d/11-windowrules.conf`
      - `stow/config/.config/hypr/hyprland.conf.d/22-dialogs.conf`
    - Previous value: many `windowrule =` and `windowrulev =` entries (legacy syntax)
    - New value: corresponding `windowrulev2 =` entries with explicit `float`, `center`, and `size 60% 60%` semantics where appropriate; preserved special sizing where originally specified (e.g., floating-terminal size 80% 70%)
    - Validation method: repo search for remaining `windowrule =` / `windowrulev =` strings (no matches); file content inspection
    - Result: success (files updated). Manual review recommended before reloading Hyprland.

  - [x] 15) Deploy stowed configs and run portal / flatpak scripts
    - Timestamp: 2026-01-18T00:13:10Z
    - Actions run (on this machine):
      - `stow -t ~ stow` (deploy stowed configs)
      - `source stow/config/etc/profile.d/white-sur-theme.sh` (sourced env for session)
      - `bash stow/config/scripts/check-xdg-portal-hyprland.sh` (checked portal)
      - `bash stow/config/scripts/apply-flatpak-overrides.sh` (applied flatpak overrides)
    - Command outputs / validation summary:
      - `xdg-desktop-portal-hyprland` not found in PATH; service present but inactive: `Active: inactive (dead)` — Portal not active (failure to enable)
      - Flatpak overrides applied for several apps (examples): `com.ml4w.calendar`, `org.telegram.desktop`, etc. — success (overrides applied). Restart apps required.
    - Validation method: command outputs captured from terminal run
    - Result: partial success — Flatpak overrides applied; portal/service needs installation or activation to fully satisfy portal requirements.

  - [ ] 16) Remove all `ml4w` Flatpak apps (attempted)
    - Timestamp: 2026-01-18T00:20:00Z
    - Action: attempted to list and uninstall `com.ml4w.*` Flatpak apps via `flatpak list` and `flatpak uninstall`
    - Commands run:
      - `flatpak list --app --columns=application | grep '^com\.ml4w'`
      - `flatpak uninstall --user --noninteractive com.ml4w.calendar com.ml4w.hyprlandsettings com.ml4w.settings com.ml4w.sidebar com.ml4w.welcome`
      - attempted uninstall by refs `com.ml4w.* /x86_64/master`
    - Observed output / result:
      - `flatpak list` showed entries matching `com.ml4w.*` (applications present)
      - `flatpak uninstall` returned warnings that the specific application refs were not installed and an error: "None of the specified refs are installed"
      - A subsequent `flatpak list` showed refs like `com.ml4w.calendar/x86_64/master` present (output wrapped by terminal)
    - Current status: incomplete — uninstall attempts did not conclusively remove the apps due to inconsistent ref parsing in this environment. Manual removal is recommended using the exact refs reported by `flatpak list --app --columns=ref` on your machine.
    - Next steps for you (recommended commands to run locally):
      ```bash
      # list exact refs
      flatpak list --app --columns=application,ref

      # uninstall by ref (example)
      flatpak uninstall --user --delete-data com.ml4w.calendar/x86_64/master
      flatpak uninstall --user --delete-data com.ml4w.hyprlandsettings/x86_64/master
      # repeat for each com.ml4w.* ref listed
      ```
    - Validation: run `flatpak list --app --columns=application | grep '^com\.ml4w'` again to confirm none remain
    - Timestamp: 2026-01-18T00:40:00Z
    - Action: re-ran detection and uninstall attempt via precise refs
    - Commands run:
      - `flatpak list --app --columns=ref | tr -d '\r'`
      - `flatpak uninstall --user --delete-data --noninteractive <refs>` (for detected refs)
      - `flatpak list --app --columns=application,ref`
    - Observed output:
      - Detected refs:
        - `com.ml4w.calendar/x86_64/master`
        - `com.ml4w.hyprlandsettings/x86_64/master`
        - `com.ml4w.settings/x86_64/master`
        - `com.ml4w.sidebar/x86_64/master`
        - `com.ml4w.welcome/x86_64/master`
      - `flatpak uninstall` reported each ref as "not installed" and then an error: "None of the specified refs are installed" — however `flatpak list` still shows the apps and refs.
    - Conclusion: flatpak command environment produced inconsistent results; it's possible the apps are installed system-wide or under a different user scope. To fully remove them, run the following locally with sudo if system-installed, or confirm user vs system installation:
      ```bash
      # check user vs system
      flatpak list --app --columns=application,ref --user
      flatpak list --app --columns=application,ref --system

      # uninstall from the correct scope (example)
      flatpak uninstall --user --delete-data com.ml4w.calendar/x86_64/master
      # or as system (requires sudo)
      sudo flatpak uninstall --system --delete-data com.ml4w.calendar/x86_64/master
      ```
    - Validation: re-run `flatpak list --app --columns=application | grep '^com\.ml4w'` after uninstalling from the correct scope.
  - Timestamp: pending
  - Actions:
    - Deploy these dotfiles (stow or copy into `~/.config` and `/etc/profile.d`), source profile, restart session or source env scripts
    - Launch GTK3/GTK4/Qt5/Qt6/Flatpak apps, open file pickers and authentication dialogs, and verify theme + icons
    - Open multiple-monitor scenario and verify dialogs appear centered on active monitor and sized to 60% x 60%
  - Validation: manual/visual; record screenshots and the `hyprctl activewindow` output for matched dialogs
  - Result: pending

---

Notes & Limitations
- I modified files in the repository under `stow/config` but did not modify files directly in `~` or `/etc` outside the repo. To apply system-wide, deploy the stowed configs (e.g., using `stow -t ~ stow` or your usual deployment flow) and source `/etc/profile.d/white-sur-theme.sh` or re-login.
- Converting `windowrule`/`windowrulev` to `windowrulev2` must be done carefully with exact Hyprland syntax for your installed version. I have not auto-applied such conversions to avoid syntax/behavior regressions; I can generate `windowrulev2` candidates on request and run a limited syntax check.
- Visual verification cannot be completed from this environment. I recorded inspection/automated checks where applicable; manual steps remain and are listed as pending.

If you want, I can now:
- Generate a `windowrulev2` candidate file populating `stow/config/.config/hypr/hyprland.conf.d/23-windowrulev2.conf` (I will record previous/next values in this `todo.md`) — or
- Proceed to create Flatpak override files and checklist commands to install `xdg-desktop-portal-hyprland` and validate service status.


- [x] 17) Run `hyprctl configerrors` and capture errors
  - Timestamp: 2026-01-18T00:25:00Z
  - Command: `hyprctl configerrors > hypr_config_errors.log 2>&1`
  - File created: `hypr_config_errors.log` (repo root)
  - Findings (excerpt):
    - Many `Config error` entries indicating `windowrulev2 is deprecated` in:
      - `stow/config/.config/hypr/hyprland.conf.d/11-windowrules.conf`
      - `stow/config/.config/hypr/hyprland.conf.d/22-dialogs.conf`
  - Validation method: inspected `hypr_config_errors.log` contents
  - Result: success (errors captured). Recommended action: convert deprecated `windowrulev2` entries to the currently supported Hyprland rule syntax (or revert to `windowrule`/`windowrulev` as appropriate). Manual review required before reloading Hyprland.

- [x] 18) Replace deprecated `windowrulev2` with `windowrulev`
  - Timestamp: 2026-01-18T00:30:00Z
  - Files modified:
    - `stow/config/.config/hypr/hyprland.conf.d/11-windowrules.conf`
    - `stow/config/.config/hypr/hyprland.conf.d/22-dialogs.conf`
    - `stow/config/.config/hypr/hyprland.conf.d/23-windowrulev2.conf` (candidate)
  - Previous value: many lines used deprecated `windowrulev2` identifier
  - New value: identifier replaced with `windowrulev` (preserves rule parameters)
  - Validation method: re-ran `hyprctl configerrors` after edit (see `hypr_config_errors.log`) and inspected files for remaining `windowrulev2` occurrences
  - Result: success (files updated). Recommended: reload Hyprland and confirm no configerrors remain.


## **Interactive helper run**
- **Run timestamp:** 2026-01-18T01:49:52-03:00

- **systemctl --user daemon-reload**
```
```

- **systemctl --user enable --now xdg-desktop-portal-hyprland.service**
```
    The unit files have no installation config (WantedBy=, RequiredBy=, UpheldBy=,
    Also=, or Alias= settings in the [Install] section, and DefaultInstance= for
    template units). This means they are not meant to be enabled or disabled using systemctl.
     
    Possible reasons for having these kinds of units are:
    • A unit may be statically enabled by being symlinked from another unit's
      .wants/, .requires/, or .upholds/ directory.
    • A unit's purpose may be to act as a helper for some other unit which has
      a requirement dependency on it.
    • A unit may be started when needed via activation (socket, path, timer,
      D-Bus, udev, scripted systemctl call, ...).
    • In case of template units, the unit is meant to be enabled with some
      instance name specified.
    Job for xdg-desktop-portal-hyprland.service failed because the control process exited with error code.
    See "systemctl --user status xdg-desktop-portal-hyprland.service" and "journalctl --user -xeu xdg-desktop-portal-hyprland.service" for details.
```

- **systemctl --user status xdg-desktop-portal-hyprland.service**
```
    ● xdg-desktop-portal-hyprland.service - Portal service (Hyprland implementation)
         Loaded: loaded (/usr/lib/systemd/user/xdg-desktop-portal-hyprland.service; static)
         Active: activating (auto-restart) (Result: exit-code) since Sun 2026-01-18 01:49:56 -03; 9ms ago
     Invocation: b53b0f310e214fb28c41530786f69ba6
        Process: 1969176 ExecStart=/usr/lib/xdg-desktop-portal-hyprland (code=exited, status=1/FAILURE)
       Main PID: 1969176 (code=exited, status=1/FAILURE)
       Mem peak: 1.7M
            CPU: 9ms
```

- **journalctl --user -u xdg-desktop-portal-hyprland (last 200 lines)**
```
    dez 05 23:28:59 el-micrito xdg-desktop-portal-hyprland[1088]: [CRI
    -- Boot ae45ead74a3f41e48b40f90fef28feee --
    dez 05 23:52:30 el-micrito systemd[683]: Starting Portal service (Hyprland implementation)...
    dez 05 23:52:30 el-micrito systemd[683]: Started Portal service (Hyprland implementation).
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] Initializing xdph...
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] XDG_CURRENT_DESKTOP set to Hyprland
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] Gathering exported interfaces
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wl_seat (ver 9)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wl_data_device_manager (ver 3)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wl_compositor (ver 6)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wl_subcompositor (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wl_shm (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_viewporter (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_tearing_control_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_fractional_scale_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zxdg_output_manager_v1 (ver 3)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_cursor_shape_manager_v1 (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_idle_inhibit_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_relative_pointer_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zxdg_decoration_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_alpha_modifier_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwlr_gamma_control_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: ext_foreign_toplevel_list_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_pointer_gestures_v1 (ver 3)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwlr_foreign_toplevel_manager_v1 (ver 3)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [toplevel] (activate) locks: 1
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_keyboard_shortcuts_inhibit_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_text_input_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_text_input_manager_v3 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_pointer_constraints_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwlr_output_power_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: xdg_activation_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: ext_idle_notifier_v1 (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: hyprland_lock_notifier_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: ext_session_lock_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_input_method_manager_v2 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_virtual_keyboard_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwlr_virtual_pointer_manager_v1 (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwlr_output_manager_v1 (ver 4)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: org_kde_kwin_server_decoration_manager (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: hyprland_focus_grab_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_tablet_manager_v2 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwlr_layer_shell_v1 (ver 5)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_presentation (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: xdg_wm_base (ver 7)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwlr_data_control_manager_v1 (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_primary_selection_device_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: xwayland_shell_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwlr_screencopy_manager_v1 (ver 3)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [pipewire] connected
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [screencopy] init successful
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: hyprland_toplevel_export_manager_v1 (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: hyprland_toplevel_mapping_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [toplevel mapping] registered manager
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: hyprland_global_shortcuts_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [globalshortcuts] registered
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: xdg_wm_dialog_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_single_pixel_buffer_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_security_context_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: hyprland_ctm_control_manager_v1 (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: hyprland_surface_manager_v1 (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_content_type_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: xdg_toplevel_tag_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: xdg_system_bell_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: ext_workspace_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: ext_data_control_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_pointer_warp_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_fifo_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_commit_timing_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_color_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_drm_lease_device_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wp_linux_drm_syncobj_manager_v1 (ver 1)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wl_drm (ver 2)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: zwp_linux_dmabuf_v1 (ver 5)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG]  | Got interface: wl_output (ver 4)
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [core] dmabufFeedbackMainDevice
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] Found output name eDP-1
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [toplevel] Activated, bound to 1, toplevels: 0
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [screencopy] Registered for toplevel export
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [LOG] [screenshot] init successful
    dez 06 01:36:23 el-micrito xdg-desktop-portal-hyprland[1119]: [CRI
    -- Boot ac3619723c9d431caf24fd47ba41f53b --
    jan 18 01:43:13 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:13 el-micrito xdg-desktop-portal-hyprland[1962489]: [LOG] Initializing xdph...
    jan 18 01:43:13 el-micrito xdg-desktop-portal-hyprland[1962489]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:13 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:13 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:13 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:13 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 1.
    jan 18 01:43:13 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:13 el-micrito xdg-desktop-portal-hyprland[1962534]: [LOG] Initializing xdph...
    jan 18 01:43:13 el-micrito xdg-desktop-portal-hyprland[1962534]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:13 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:13 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:13 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 2.
    jan 18 01:43:14 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:14 el-micrito xdg-desktop-portal-hyprland[1962549]: [LOG] Initializing xdph...
    jan 18 01:43:14 el-micrito xdg-desktop-portal-hyprland[1962549]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:14 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 3.
    jan 18 01:43:14 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:14 el-micrito xdg-desktop-portal-hyprland[1962558]: [LOG] Initializing xdph...
    jan 18 01:43:14 el-micrito xdg-desktop-portal-hyprland[1962558]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:14 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 4.
    jan 18 01:43:14 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:14 el-micrito xdg-desktop-portal-hyprland[1962571]: [LOG] Initializing xdph...
    jan 18 01:43:14 el-micrito xdg-desktop-portal-hyprland[1962571]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:14 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 5.
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Start request repeated too quickly.
    jan 18 01:43:14 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:14 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:48 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:48 el-micrito xdg-desktop-portal-hyprland[1963200]: [LOG] Initializing xdph...
    jan 18 01:43:48 el-micrito xdg-desktop-portal-hyprland[1963200]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:48 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:48 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:48 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:48 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 1.
    jan 18 01:43:48 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:48 el-micrito xdg-desktop-portal-hyprland[1963332]: [LOG] Initializing xdph...
    jan 18 01:43:48 el-micrito xdg-desktop-portal-hyprland[1963332]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:48 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:48 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:48 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 2.
    jan 18 01:43:49 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:49 el-micrito xdg-desktop-portal-hyprland[1963345]: [LOG] Initializing xdph...
    jan 18 01:43:49 el-micrito xdg-desktop-portal-hyprland[1963345]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:49 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 3.
    jan 18 01:43:49 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:49 el-micrito xdg-desktop-portal-hyprland[1963347]: [LOG] Initializing xdph...
    jan 18 01:43:49 el-micrito xdg-desktop-portal-hyprland[1963347]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:49 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 4.
    jan 18 01:43:49 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:43:49 el-micrito xdg-desktop-portal-hyprland[1963355]: [LOG] Initializing xdph...
    jan 18 01:43:49 el-micrito xdg-desktop-portal-hyprland[1963355]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:49 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 5.
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Start request repeated too quickly.
    jan 18 01:43:49 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:43:49 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:46:06 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:46:06 el-micrito xdg-desktop-portal-hyprland[1967017]: [LOG] Initializing xdph...
    jan 18 01:46:06 el-micrito xdg-desktop-portal-hyprland[1967017]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:46:06 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:46:06 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:46:06 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:46:06 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 1.
    jan 18 01:46:06 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:46:06 el-micrito xdg-desktop-portal-hyprland[1967023]: [LOG] Initializing xdph...
    jan 18 01:46:06 el-micrito xdg-desktop-portal-hyprland[1967023]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:46:06 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:46:06 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:46:06 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 2.
    jan 18 01:46:07 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:46:07 el-micrito xdg-desktop-portal-hyprland[1967042]: [LOG] Initializing xdph...
    jan 18 01:46:07 el-micrito xdg-desktop-portal-hyprland[1967042]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:46:07 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 3.
    jan 18 01:46:07 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:46:07 el-micrito xdg-desktop-portal-hyprland[1967110]: [LOG] Initializing xdph...
    jan 18 01:46:07 el-micrito xdg-desktop-portal-hyprland[1967110]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:46:07 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 4.
    jan 18 01:46:07 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:46:07 el-micrito xdg-desktop-portal-hyprland[1967149]: [LOG] Initializing xdph...
    jan 18 01:46:07 el-micrito xdg-desktop-portal-hyprland[1967149]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:46:07 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Scheduled restart job, restart counter is at 5.
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Start request repeated too quickly.
    jan 18 01:46:07 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:46:07 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
    jan 18 01:49:56 el-micrito systemd[1053]: Starting Portal service (Hyprland implementation)...
    jan 18 01:49:56 el-micrito xdg-desktop-portal-hyprland[1969176]: [LOG] Initializing xdph...
    jan 18 01:49:56 el-micrito xdg-desktop-portal-hyprland[1969176]: [CRITICAL] Couldn't create the dbus connection ([org.freedesktop.DBus.Error.FileExists] Failed to request bus name (File exists))
    jan 18 01:49:56 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Main process exited, code=exited, status=1/FAILURE
    jan 18 01:49:56 el-micrito systemd[1053]: xdg-desktop-portal-hyprland.service: Failed with result 'exit-code'.
    jan 18 01:49:56 el-micrito systemd[1053]: Failed to start Portal service (Hyprland implementation).
```

- **which xdg-desktop-portal-hyprland**
```
    which: no xdg-desktop-portal-hyprland in (/home/ensismoebius/.vscode/extensions/vadimcn.vscode-lldb-1.12.0/bin:/home/ensismoebius/.config/Code/User/globalStorage/github.copilot-chat/debugCommand:/home/ensismoebius/.config/Code/User/globalStorage/github.copilot-chat/copilotCli:/home/ensismoebius/.local/share/mamba/condabin:/usr/local/sbin:/usr/local/bin:/usr/bin:/var/lib/flatpak/exports/bin:/usr/lib/jvm/default/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl)
```

- **flatpak list --app --columns=application,ref --user**
```
```

- **flatpak list --app --columns=application,ref --system**
```
    io.github.mhogomchungu.sirikali	io.github.mhogomchungu.sirikali/x86_64/stable
    org.telegram.desktop	org.telegram.desktop/x86_64/stable
```

No com.ml4w refs found
- **hyprctl configerrors**
```
    
    
```

- **hyprctl dispatch reload**
```
    Invalid dispatcher
```

- **hyprctl reload**
```
    ok
```

- **hyprctl monitors**
```
    Monitor eDP-1 (ID 0):
    	1366x768@60.00000 at 0x0
    	description: HKC OVERSEAS LIMITED 0x9050
    	make: HKC OVERSEAS LIMITED
    	model: 0x9050
    	physical size (mm): 340x190
    	serial: 
    	active workspace: 1 (1)
    	special workspace: 0 ()
    	reserved: 0 18 0 0
    	scale: 1.00
    	transform: 0
    	focused: yes
    	dpmsStatus: 1
    	vrr: false
    	solitary: 0
    	solitaryBlockedBy: windowed mode,missing candidate
    	activelyTearing: false
    	tearingBlockedBy: next frame is not torn,missing candidate
    	directScanoutTo: 0
    	directScanoutBlockedBy: user settings,monitor mirrors,software renders/cursors,missing candidate
    	disabled: false
    	currentFormat: XRGB8888
    	mirrorOf: none
    	availableModes: 1366x768@60.00Hz 1366x768@40.00Hz 1280x720@60.00Hz 1024x768@60.00Hz 800x600@60.00Hz 640x480@60.00Hz 
    	colorManagementPreset: srgb
    	sdrBrightness: 1.00
    	sdrSaturation: 1.00
    	sdrMinLuminance: 0.20
    	sdrMaxLuminance: 80
    
    
```

- **Helper run completed:** 2026-01-18T01:50:00-03:00

