#!/usr/bin/env python3
"""
A window switcher for Hyprland using GTK4, running as a background process.

This application displays a list of open windows with thumbnails and allows
switching between them. It is designed to be launched on startup and then
shown with a keybinding.

To show the switcher, send a SIGUSR1 signal to the process:
    pkill -f -SIGUSR1 window-switcher.py

It uses `hyprctl` to get the list of windows and `grim` to capture
window thumbnails. Thumbnails are stored in memory. For windows on
inactive workspaces, it uses cached thumbnails from memory or the
application's icon.
"""

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("GdkPixbuf", "2.0")

from gi.repository import Gtk, Gdk, GdkPixbuf, GLib
from pathlib import Path
import sys
import subprocess
import json
import re
import signal
import os

# --- Configuration ---

APP_CONFIG = {
    "thumb_size": 120,
    "margin": 8,
    "window_title": "Window Switcher",
    "default_width": 1000,
    "default_height": 700,
    "css": b"""
        .preview.selected {
            border: 6px solid #ff8800;
            border-radius: 6px;
        }
        button.thumb {
            background-color: transparent;
        }
        button.selected {
            outline: 3px solid #ff8800;
        }
    """,
    "placeholder_icon": "computer-symbolic",
}

# --- Hyprland Interaction ---

class Hyprland:
    """
    A helper class to interact with Hyprland using hyprctl.
    """
    def get_windows(self):
        """
        Gets a list of open windows from Hyprland.
        """
        try:
            result = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, check=True)
            windows = json.loads(result.stdout)
            return [w for w in windows if not w.get("floating") and w.get("title")]
        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Error getting Hyprland windows: {e}", file=sys.stderr)
            return []

    def get_active_workspace(self):
        """
        Gets the active workspace from Hyprland.
        """
        try:
            result = subprocess.run(["hyprctl", "activeworkspace", "-j"], capture_output=True, text=True, check=True)
            return json.loads(result.stdout).get("id")
        except (subprocess.CalledProcessError, FileNotFoundError, json.JSONDecodeError) as e:
            print(f"Error getting active workspace: {e}", file=sys.stderr)
            return None

    def capture_window_thumbnail(self, window):
        """
        Captures a thumbnail of a window and returns the raw PNG data.
        """
        x, y = window["at"]
        width, height = window["size"]
        geometry = f"{x},{y} {width}x{height}"

        try:
            result = subprocess.run(["grim", "-g", geometry, "-"], capture_output=True, check=True)
            return result.stdout
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"Error capturing window thumbnail: {e}", file=sys.stderr)
            return None

    def focus_window(self, window):
        """
        Focuses the specified window.
        """
        address = window["address"]
        workspace_id = window["workspace"]["id"]
        active_workspace_id = self.get_active_workspace()

        try:
            # Batch commands for efficiency
            batch_commands = []
            if workspace_id != active_workspace_id:
                batch_commands.append(f"dispatch workspace {workspace_id}")
            
            batch_commands.append(f"dispatch focuswindow address:{address}")

            command_string = ";".join(batch_commands)
            subprocess.run(
                ["hyprctl", "-b", command_string],
                check=True,
                capture_output=True,
                text=True
            )

            print(f"Focused window {address} on workspace {workspace_id}", flush=True)
            print(f"Batch command executed: hyprctl -b {command_string}", flush=True)

        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"Error focusing window: {e.stdout} {e.stderr}", file=sys.stderr)

# --- Helper Functions ---

def get_icon_name_for_class(app_class):
    """
    Finds the icon name for a given application class by looking up
    the .desktop file.
    """
    if not app_class:
        return None

    desktop_dirs = [
        Path("/usr/share/applications"),
        Path.home() / ".local/share/applications"
    ]
    desktop_file = None

    for directory in desktop_dirs:
        files = list(directory.glob(f"**/{app_class.lower()}.desktop"))
        if not files:
            files = list(directory.glob(f"**/{app_class}.desktop"))

        if files:
            desktop_file = files[0]
            break

    if not desktop_file or not desktop_file.exists():
        return None

    try:
        with open(desktop_file, "r") as f:
            content = f.read()
            match = re.search(r"^Icon=(.*)$", content, re.MULTILINE)
            if match:
                return match.group(1).strip()
    except (IOError, OSError):
        return None

    return None

def load_paintable_from_data(data, max_size=None):
    """
    Loads an image from raw data and returns it as a Gdk.Paintable.
    """
    try:
        loader = GdkPixbuf.PixbufLoader.new()
        loader.write(data)
        loader.close()
        pixbuf = loader.get_pixbuf()

        if max_size is not None:
            width, height = pixbuf.get_width(), pixbuf.get_height()
            scale = min(1.0, max_size / max(width, height))
            if scale < 1.0:
                new_width, new_height = int(width * scale), int(height * scale)
                pixbuf = pixbuf.scale_simple(new_width, new_height, GdkPixbuf.InterpType.BILINEAR)

        success, buffer = pixbuf.save_to_bufferv("png", [], [])
        if not success:
            return None
        byte_data = GLib.Bytes.new(buffer)
        return Gdk.Texture.new_from_bytes(byte_data)
    except Exception as e:
        print(f"Error loading image from data: {e}")
        return None

# --- UI Components ---

class ThumbButton(Gtk.Button):
    """
    A button that displays a thumbnail of a window.
    """
    def __init__(self, window_info, thumb_source, size, index, on_click):
        super().__init__(hexpand=False, valign=Gtk.Align.CENTER)
        self.window_info = window_info
        self.thumb_source = thumb_source
        self.index = index
        self.set_has_frame(False)
        self.add_css_class("thumb")
        self.connect("clicked", lambda *_: on_click(self.index))
        GLib.idle_add(self._load_thumbnail, size)

    def _load_thumbnail(self, size):
        """
        Loads the thumbnail image in the background.
        """
        paintable = None
        if isinstance(self.thumb_source, bytes):
            paintable = load_paintable_from_data(self.thumb_source, size)

        if paintable:
            image = Gtk.Picture.new_for_paintable(paintable)
        else:
            icon_name = self.thumb_source or APP_CONFIG["placeholder_icon"]
            image = Gtk.Image.new_from_icon_name(icon_name)
            image.set_icon_size(Gtk.IconSize.LARGE)

        self.set_child(image)
        return False

class WindowSwitcherWindow(Gtk.ApplicationWindow):
    """
    The main window of the window switcher application.
    """
    def __init__(self, app, windows, thumb_sources):
        super().__init__(application=app, title=APP_CONFIG["window_title"])
        self.windows = windows
        self.thumb_sources = thumb_sources
        self.current_index = 0
        self.thumb_buttons = []

        self._setup_window()
        self._setup_css()
        self._setup_widgets()
        self._setup_key_controller()

        self.update_preview()

    def _setup_window(self):
        """Sets up the main window properties."""
        self.set_default_size(APP_CONFIG["default_width"], APP_CONFIG["default_height"])
        margin = APP_CONFIG["margin"]
        self.set_margin_top(margin)
        self.set_margin_bottom(margin)
        self.set_margin_start(margin)
        self.set_margin_end(margin)
        self.set_modal(True)
        self.set_transient_for(self.get_application().get_active_window())


    def _setup_css(self):
        """Applies the custom CSS to the application."""
        provider = Gtk.CssProvider()
        provider.load_from_data(APP_CONFIG["css"])
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def _setup_widgets(self):
        """Creates and arranges the widgets in the main window."""
        main_vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 6)
        self.set_child(main_vbox)

        self.preview = Gtk.Picture.new()
        frame = Gtk.Frame.new(None)
        frame.set_child(self.preview)
        frame.set_vexpand(True)
        frame.set_hexpand(True)
        main_vbox.append(frame)

        self.info_label = Gtk.Label.new("")
        main_vbox.append(self.info_label)

        scrolled_window = Gtk.ScrolledWindow.new()
        scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
        main_vbox.append(scrolled_window)
        thumb_hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 6)
        scrolled_window.set_child(thumb_hbox)

        for i, (window, thumb_source) in enumerate(zip(self.windows, self.thumb_sources)):
            btn = ThumbButton(window, thumb_source, APP_CONFIG["thumb_size"], i, self.on_thumb_clicked)
            self.thumb_buttons.append(btn)
            thumb_hbox.append(btn)

    def _setup_key_controller(self):
        """Sets up the keyboard event controller."""
        key_controller = Gtk.EventControllerKey()
        key_controller.connect("key-pressed", self.on_key_pressed)
        self.add_controller(key_controller)
        self.set_can_focus(True)

    def on_thumb_clicked(self, index):
        """Handles clicks on the thumbnail buttons."""
        self.current_index = index
        self.update_preview()
        self.get_application().hyprland.focus_window(self.windows[self.current_index])
        self.close()

    def update_preview(self):
        """Updates the preview image and info label."""
        if not self.windows:
            return

        window = self.windows[self.current_index]
        thumb_source = self.thumb_sources[self.current_index]

        paintable = None
        if isinstance(thumb_source, bytes):
            paintable = load_paintable_from_data(thumb_source)

        if paintable:
            self.preview.set_paintable(paintable)
        else:
            icon_name = thumb_source or APP_CONFIG["placeholder_icon"]
            placeholder = Gtk.Image.new_from_icon_name(icon_name)
            placeholder.set_pixel_size(256)
            self.preview.set_paintable(placeholder.get_paintable())

        self.info_label.set_text(f"{self.current_index + 1}/{len(self.windows)} — {window['title']}")

        for i, button in enumerate(self.thumb_buttons):
            if i == self.current_index:
                button.add_css_class("selected")
            else:
                button.remove_css_class("selected")

    def on_key_pressed(self, controller, keyval, keycode, state):
        """Handles key press events."""
        key_name = Gdk.keyval_name(keyval)
        num_windows = len(self.windows)

        if key_name in ("Right", "Tab"):
            self.current_index = (self.current_index + 1) % num_windows
            self.update_preview()
            return True
        elif key_name == "Left":
            self.current_index = (self.current_index - 1 + num_windows) % num_windows
            self.update_preview()
            return True
        elif key_name == "Return":
            self.get_application().hyprland.focus_window(self.windows[self.current_index])
            self.close()
            return True
        elif key_name in ("Escape", "q"):
            self.close()
            return True
        return False

class WindowSwitcherApp(Gtk.Application):
    """
    The main GTK application class.
    """
    def __init__(self):
        super().__init__(application_id="org.dedira.WindowSwitcher")
        print("Initializing WindowSwitcherApp", flush=True)
        self.hold()
        self.hyprland = Hyprland()
        self.thumbnail_cache = {}
        self.window = None
        self.connect("shutdown", self.on_shutdown)

    def on_shutdown(self, *args):
        print("WindowSwitcherApp shutting down", flush=True)

    def do_activate(self):
        print("WindowSwitcherApp activated", flush=True)
        pass

    def show_switcher(self, *args):
        print("show_switcher called", flush=True)
        if self.window and self.window.is_visible():
            self.window.destroy()
            self.window = None
            return True

        active_workspace = self.hyprland.get_active_workspace()
        windows = self.hyprland.get_windows()

        if not windows:
            print("No open windows found on Hyprland.", file=sys.stderr, flush=True)
            return True

        thumb_sources = []
        for window in windows:
            address = window["address"]
            if window["workspace"]["id"] == active_workspace:
                thumb_data = self.hyprland.capture_window_thumbnail(window)
                if thumb_data:
                    self.thumbnail_cache[address] = thumb_data
                    thumb_sources.append(thumb_data)
                else:
                    thumb_sources.append(get_icon_name_for_class(window.get("class")))
            else:
                if address in self.thumbnail_cache:
                    thumb_sources.append(self.thumbnail_cache[address])
                else:
                    thumb_sources.append(get_icon_name_for_class(window.get("class")))

        self.window = WindowSwitcherWindow(self, windows, thumb_sources)
        self.window.present()
        return True

def main():
    """
    The main entry point of the application.
    """
    print(f"Starting Window Switcher with PID: {os.getpid()}", flush=True)
    app = WindowSwitcherApp()
    GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, signal.SIGUSR1, app.show_switcher)
    app.run(sys.argv)

if __name__ == "__main__":
    main()