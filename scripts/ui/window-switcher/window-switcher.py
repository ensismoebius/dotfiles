#!/usr/bin/env python3
"""
A window switcher for Hyprland using GTK4.

This application displays a list of open windows with thumbnails and allows
switching between them, similar to the Windows Alt-Tab functionality.

It uses `hyprctl` to get the list of windows and `grim` to capture
window thumbnails. For windows on inactive workspaces, it uses cached
thumbnails or a generic placeholder icon.
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
import tempfile
import shutil

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
    def __init__(self, tmp_dir):
        self.tmp_dir = tmp_dir

    def get_windows(self):
        """
        Gets a list of open windows from Hyprland.
        """
        try:
            result = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, check=True)
            windows = json.loads(result.stdout)
            # Filter out floating windows and windows with no title
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
        Captures a thumbnail of a window and saves it to a temporary file.
        """
        address = window["address"]
        x, y = window["at"]
        width, height = window["size"]
        geometry = f"{x},{y} {width}x{height}"
        path = self.tmp_dir / f"{address}.png"

        try:
            subprocess.run(["grim", "-g", geometry, str(path)], check=True)
            return str(path)
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"Error capturing window thumbnail: {e}", file=sys.stderr)
            return None

    def focus_window(self, window):
        """
        Focuses the specified window.
        """
        address = window["address"]
        try:
            subprocess.run(["hyprctl", "dispatch", "focuswindow", f"address:{address}"], check=True)
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"Error focusing window: {e}", file=sys.stderr)

# --- Helper Functions ---

def load_paintable(path, max_size=None):
    """
    Loads an image from a file and returns it as a Gdk.Paintable.
    The image can be scaled down to a maximum size.
    """
    try:
        pixbuf = GdkPixbuf.Pixbuf.new_from_file(path)
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
        print(f"Error loading image {path}: {e}")
        return None

# --- UI Components ---

class ThumbButton(Gtk.Button):
    """
    A button that displays a thumbnail of a window.
    """
    def __init__(self, window_info, thumb_path, size, index, on_click):
        super().__init__(hexpand=False, valign=Gtk.Align.CENTER)
        self.window_info = window_info
        self.thumb_path = thumb_path
        self.index = index
        self.set_has_frame(False)
        self.add_css_class("thumb")
        self.connect("clicked", lambda *_: on_click(self.index))
        GLib.idle_add(self._load_thumbnail, size)

    def _load_thumbnail(self, size):
        """
        Loads the thumbnail image in the background.
        """
        paintable = load_paintable(self.thumb_path, size) if self.thumb_path else None
        if paintable is None:
            image = Gtk.Image.new_from_icon_name(APP_CONFIG["placeholder_icon"])
            image.set_icon_size(Gtk.IconSize.LARGE)
        else:
            image = Gtk.Picture.new_for_paintable(paintable)
        self.set_child(image)
        return False

class WindowSwitcherWindow(Gtk.ApplicationWindow):
    """
    The main window of the window switcher application.
    """
    def __init__(self, app, windows, thumb_paths):
        super().__init__(application=app, title=APP_CONFIG["window_title"])
        self.windows = windows
        self.thumb_paths = thumb_paths
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

        # Preview area
        self.preview = Gtk.Picture.new()
        frame = Gtk.Frame.new(None)
        frame.set_child(self.preview)
        frame.set_vexpand(True)
        frame.set_hexpand(True)
        main_vbox.append(frame)

        # Info label
        self.info_label = Gtk.Label.new("")
        main_vbox.append(self.info_label)

        # Thumbnail bar
        scrolled_window = Gtk.ScrolledWindow.new()
        scrolled_window.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
        main_vbox.append(scrolled_window)
        thumb_hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 6)
        scrolled_window.set_child(thumb_hbox)

        for i, (window, thumb_path) in enumerate(zip(self.windows, self.thumb_paths)):
            btn = ThumbButton(window, thumb_path, APP_CONFIG["thumb_size"], i, self.on_thumb_clicked)
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
        self.get_application().quit()


    def update_preview(self):
        """Updates the preview image and info label."""
        if not self.windows:
            return

        window = self.windows[self.current_index]
        thumb_path = self.thumb_paths[self.current_index]
        paintable = load_paintable(thumb_path) if thumb_path else None

        if paintable is not None:
            self.preview.set_paintable(paintable)
        else:
            placeholder = Gtk.Image.new_from_icon_name(APP_CONFIG["placeholder_icon"])
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
            self.get_application().quit()
            return True
        elif key_name in ("Escape", "q"):
            self.get_application().quit()
            return True
        return False

class WindowSwitcherApp(Gtk.Application):
    """
    The main GTK application class.
    """
    def __init__(self, windows, thumb_paths, hyprland):
        super().__init__()
        self.windows = windows
        self.thumb_paths = thumb_paths
        self.hyprland = hyprland

    def do_activate(self):
        """Activates the application by creating and showing the main window."""
        win = WindowSwitcherWindow(self, self.windows, self.thumb_paths)
        win.present()

def main():
    """
    The main entry point of the application.
    """
    tmp_dir = Path(tempfile.mkdtemp())
    cache_dir = Path.home() / ".cache" / "hypr-window-switcher"
    cache_dir.mkdir(parents=True, exist_ok=True)

    hyprland = Hyprland(tmp_dir)
    active_workspace = hyprland.get_active_workspace()
    windows = hyprland.get_windows()

    if not windows:
        print("No open windows found on Hyprland.", file=sys.stderr)
        shutil.rmtree(tmp_dir)
        sys.exit(1)

    thumb_paths = []
    for window in windows:
        if window["workspace"]["id"] == active_workspace:
            thumb_path = hyprland.capture_window_thumbnail(window)
            if thumb_path:
                shutil.copy(thumb_path, cache_dir / f"{window['address']}.png")
                thumb_paths.append(thumb_path)
            else:
                thumb_paths.append(None)
        else:
            cached_thumb = cache_dir / f"{window['address']}.png"
            if cached_thumb.exists():
                thumb_paths.append(str(cached_thumb))
            else:
                thumb_paths.append(None)

    app = WindowSwitcherApp(windows, thumb_paths, hyprland)
    app.connect("shutdown", lambda app: shutil.rmtree(tmp_dir))
    app.run()

if __name__ == "__main__":
    main()