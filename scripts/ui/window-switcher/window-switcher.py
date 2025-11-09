#!/usr/bin/env python3
"""
A simple image browser and window switcher using GTK4.

This application displays a collection of images from a given directory or
a list of files. It shows a preview of the selected image and a row of
thumbnails for all available images.

Usage:
    ./window-switcher.py <directory|file(s)>
"""

import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("GdkPixbuf", "2.0")

from gi.repository import Gtk, Gdk, GdkPixbuf, GLib
from pathlib import Path
import sys

# --- Configuration ---

APP_CONFIG = {
    "thumb_size": 120,
    "margin": 8,
    "window_title": "Window Switcher / Image Browser",
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
    "image_extensions": ("*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif"),
}

# --- Helper Functions ---

def find_image_paths(args):
    """
    Finds all image paths from the given command-line arguments.
    Arguments can be directories or individual files.
    """
    paths = []
    for arg in args:
        path = Path(arg)
        if not path.exists():
            continue
        if path.is_dir():
            for ext in APP_CONFIG["image_extensions"]:
                paths.extend(sorted(path.glob(ext)))
        else:
            paths.append(path)
    return [str(p) for p in paths if p.is_file()]

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
    A button that displays a thumbnail of an image.
    """
    def __init__(self, path, size, index, on_click):
        super().__init__(hexpand=False, valign=Gtk.Align.CENTER)
        self.path = path
        self.index = index
        self.set_has_frame(False)
        self.add_css_class("thumb")
        self.connect("clicked", lambda *_: on_click(self.index))
        GLib.idle_add(self._load_thumbnail, size)

    def _load_thumbnail(self, size):
        """
        Loads the thumbnail image in the background.
        """
        paintable = load_paintable(self.path, size)
        if paintable is None:
            image = Gtk.Image.new_from_icon_name("image-missing")
        else:
            image = Gtk.Picture.new_for_paintable(paintable)
        self.set_child(image)
        return False

class ImageBrowserWindow(Gtk.ApplicationWindow):
    """
    The main window of the image browser application.
    """
    def __init__(self, app, paths):
        super().__init__(application=app, title=APP_CONFIG["window_title"])
        self.paths = paths
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

        for i, path in enumerate(self.paths):
            btn = ThumbButton(path, APP_CONFIG["thumb_size"], i, self.on_thumb_clicked)
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

    def update_preview(self):
        """Updates the preview image and info label."""
        if not self.paths:
            return

        path = self.paths[self.current_index]
        paintable = load_paintable(path)
        if paintable is not None:
            self.preview.set_paintable(paintable)

        self.info_label.set_text(f"{self.current_index + 1}/{len(self.paths)} — {path}")

        for i, button in enumerate(self.thumb_buttons):
            if i == self.current_index:
                button.add_css_class("selected")
            else:
                button.remove_css_class("selected")

    def on_key_pressed(self, controller, keyval, keycode, state):
        """Handles key press events."""
        key_name = Gdk.keyval_name(keyval)
        num_paths = len(self.paths)

        if key_name in ("Right", "Tab"):
            self.current_index = (self.current_index + 1) % num_paths
            self.update_preview()
            return True
        elif key_name == "Left":
            self.current_index = (self.current_index - 1 + num_paths) % num_paths
            self.update_preview()
            return True
        elif key_name in ("Escape", "q"):
            self.get_application().quit()
            return True
        return False

class ImageBrowserApp(Gtk.Application):
    """
    The main GTK application class.
    """
    def __init__(self, paths):
        super().__init__()
        self.paths = paths

    def do_activate(self):
        """Activates the application by creating and showing the main window."""
        win = ImageBrowserWindow(self, self.paths)
        win.present()

def main():
    """
    The main entry point of the application.
    """
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <dir|file(s)>")
        sys.exit(1)

    image_paths = find_image_paths(sys.argv[1:])
    if not image_paths:
        print("No images found.")
        sys.exit(1)

    app = ImageBrowserApp(image_paths)
    app.run()

if __name__ == "__main__":
    main()