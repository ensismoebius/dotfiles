#!/usr/bin/env python3
import gi
gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("GdkPixbuf", "2.0")

from gi.repository import Gtk, Gdk, GdkPixbuf, GLib
from pathlib import Path
import sys

THUMB_SIZE = 120
MARGIN = 8

def find_images_from_args(args):
    paths = []
    for a in args:
        p = Path(a)
        if not p.exists():
            continue
        if p.is_dir():
            for ext in ("*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif"):
                paths.extend(sorted(p.glob(ext)))
        else:
            paths.append(p)
    return [str(p) for p in paths if p.is_file()]

def pixbuf_to_texture(pixbuf):
    if not pixbuf:
        return None
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, pixbuf.get_width(), pixbuf.get_height())
    context = cairo.Context(surface)
    Gdk.cairo_set_source_pixbuf(context, pixbuf, 0, 0)
    context.paint()
    return Gdk.Texture.new_for_surface(surface)

def load_paintable_for_file(path, max_size=None):
    try:
        tex = Gdk.Texture.new_from_file(path)
        return tex
    except Exception:
        try:
            pix = GdkPixbuf.Pixbuf.new_from_file(path)
            if max_size is not None:
                w, h = pix.get_width(), pix.get_height()
                scale = min(1.0, max_size / max(w, h))
                if scale < 1.0:
                    new_w, new_h = int(w * scale), int(h * scale)
                    pix = pix.scale_simple(new_w, new_h, GdkPixbuf.InterpType.BILINEAR)
            return pix
        except Exception:
            return None

class ThumbButton(Gtk.Button):
    def __init__(self, path, size, index, on_click):
        super().__init__(hexpand=False, valign=Gtk.Align.CENTER)
        self.path = path
        self.index = index
        self.set_has_frame(False)
        self.add_css_class("thumb")
        self.connect("clicked", lambda *_: on_click(self.index))
        GLib.idle_add(self._load_thumb, size)

    def _load_thumb(self, size):
        p = load_paintable_for_file(self.path, size)
        if p is None:
            img = Gtk.Image.new_from_icon_name("image-missing")
        elif isinstance(p, GdkPixbuf.Pixbuf):
            img = Gtk.Picture.new_for_pixbuf(p)
        else:
            img = Gtk.Picture.new_for_paintable(p)
        self.set_child(img)
        return False

class ImageBrowser(Gtk.ApplicationWindow):
    def __init__(self, app, paths):
        super().__init__(application=app, title="Window Switcher / Image Browser")
        self.paths = paths
        self.index = 0
        self.thumb_buttons = []

        self.set_default_size(1000, 700)
        self.set_margin_top(MARGIN)
        self.set_margin_bottom(MARGIN)
        self.set_margin_start(MARGIN)
        self.set_margin_end(MARGIN)

        css = b"""
        .preview.selected { border: 6px solid #ff8800; border-radius: 6px; }
        button.thumb { background-color: transparent; }
        button.selected { outline: 3px solid #ff8800; }
        """
        provider = Gtk.CssProvider()
        provider.load_from_data(css)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

        vbox = Gtk.Box.new(Gtk.Orientation.VERTICAL, 6)
        self.set_child(vbox)

        self.preview = Gtk.Picture.new()
        frame = Gtk.Frame.new(None)
        frame.set_child(self.preview)
        frame.set_vexpand(True)
        frame.set_hexpand(True)
        vbox.append(frame)

        self.info = Gtk.Label.new("")
        vbox.append(self.info)

        scroll = Gtk.ScrolledWindow.new()
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.NEVER)
        vbox.append(scroll)
        hbox = Gtk.Box.new(Gtk.Orientation.HORIZONTAL, 6)
        scroll.set_child(hbox)

        for i, p in enumerate(paths):
            btn = ThumbButton(p, THUMB_SIZE, i, self.on_thumb_clicked)
            self.thumb_buttons.append(btn)
            hbox.append(btn)

        key_controller = Gtk.EventControllerKey()
        key_controller.connect("key-pressed", self.on_key_pressed)
        self.add_controller(key_controller)
        self.set_can_focus(True)
        self.update_preview()

    def on_thumb_clicked(self, idx):
        self.index = idx
        self.update_preview()

    def update_preview(self):
        if not self.paths:
            return
        path = self.paths[self.index]
        p = load_paintable_for_file(path)
        if isinstance(p, GdkPixbuf.Pixbuf):
            self.preview.set_pixbuf(p)
        elif isinstance(p, Gdk.Paintable):
            self.preview.set_paintable(p)
        self.info.set_text(f"{self.index + 1}/{len(self.paths)} — {path}")

        for i, b in enumerate(self.thumb_buttons):
            if i == self.index:
                b.add_css_class("selected")
            else:
                b.remove_css_class("selected")

    def on_key_pressed(self, controller, keyval, keycode, state):
        name = Gdk.keyval_name(keyval)
        if name in ("Right", "Tab"):
            self.index = (self.index + 1) % len(self.paths)
            self.update_preview()
            return True
        if name in ("Left",):
            self.index = (self.index - 1) % len(self.paths)
            self.update_preview()
            return True
        if name in ("Escape", "q"):
            self.get_application().quit()
            return True
        return False

class ImageBrowserApp(Gtk.Application):
    def __init__(self, paths):
        super().__init__()
        self.paths = paths

    def do_activate(self):
        win = ImageBrowser(self, self.paths)
        win.present()

def main(argv):
    if len(argv) < 2:
        print("usage: window-switcher.py <dir|file(s)>")
        sys.exit(1)
    paths = find_images_from_args(argv[1:])
    if not paths:
        print("no images found")
        sys.exit(1)
    app = ImageBrowserApp(paths)
    app.run()

if __name__ == "__main__":
    main(sys.argv)
