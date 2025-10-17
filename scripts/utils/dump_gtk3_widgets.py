#!/usr/bin/env python3
# gtk3_widget_inventory.py
# Build a demo GTK3 window with many widgets and export a JSON inventory.
# Requires: python3 + PyGObject (GTK 3)

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, GObject, GLib
import json
import os
import sys
from datetime import datetime

OUTPUT_FILENAME = "gtk3_widgets_dump.json"

# --- utility inspection helpers -----------------------------------------------------
def safe_get_name(widget):
    try:
        return widget.get_name() or ""
    except Exception:
        return ""

def safe_style_classes(widget):
    try:
        sc = widget.get_style_context().list_classes()
        # list_classes returns a list-like; cast to plain list of str
        return [str(c) for c in sc] if sc else []
    except Exception:
        return []

def safe_state_flags(widget):
    try:
        sf = widget.get_state_flags()
        return str(sf)
    except Exception:
        # older versions: try get_state
        try:
            return str(widget.get_state())
        except Exception:
            return ""

def safe_visible(widget):
    try:
        return bool(widget.get_visible())
    except Exception:
        return None

def safe_sensitive(widget):
    try:
        return bool(widget.get_sensitive())
    except Exception:
        return None

def widget_basic_info(widget, parent_path):
    return {
        "type": widget.__class__.__name__,
        "name": safe_get_name(widget),
        "style_classes": safe_style_classes(widget),
        "state_flags": safe_state_flags(widget),
        "visible": safe_visible(widget),
        "sensitive": safe_sensitive(widget),
        "parent_path": parent_path
    }

def get_children_generic(widget):
    """
    Attempts to return a list of child widgets for a wide range of GTK3 widgets.
    Uses common container APIs: get_children(), get_child(), get_popup(), get_menu(),
    get_content_area(), get_items (for menu-like), etc.
    """
    children = []
    try:
        if hasattr(widget, "get_children"):
            c = widget.get_children()
            if c:
                children.extend(list(c))
    except Exception:
        pass

    # single-child containers (Bin-like)
    try:
        if hasattr(widget, "get_child"):
            c = widget.get_child()
            if c:
                children.append(c)
    except Exception:
        pass

    # dialog content_area
    try:
        if hasattr(widget, "get_content_area"):
            ca = widget.get_content_area()
            if ca:
                # content_area is a container
                if hasattr(ca, "get_children"):
                    children.extend(list(ca.get_children()))
                elif ca:
                    children.append(ca)
    except Exception:
        pass

    # popovers/menus
    try:
        if hasattr(widget, "get_popover"):
            pop = widget.get_popover()
            if pop:
                children.append(pop)
    except Exception:
        pass

    # for MenuShell / Menu
    try:
        if hasattr(widget, "get_children"):
            # already captured above
            pass
    except Exception:
        pass

    # filter duplicates and None
    children = [c for c in children if c is not None]
    # Some children may be the same object twice; keep unique preserving order
    seen = set()
    uniq = []
    for c in children:
        if id(c) not in seen:
            seen.add(id(c))
            uniq.append(c)
    return uniq

def traverse(widget, path=None, out=None):
    if out is None:
        out = []
    if path is None:
        path = []

    info = widget_basic_info(widget, "/".join(map(str, path[:-1])) if path else "")
    info["path"] = "/".join(map(str, path)) if path else "0"
    out.append(info)

    # try gtk.Container style children first (get_children), else try generic helpers
    try:
        children = get_children_generic(widget)
    except Exception:
        children = []

    # For widgets like Notebook, TreeView, etc, contents may not be reachable via get_children;
    # still, get_children_generic covers many cases.
    idx = 0
    for ch in children:
        traverse(ch, path + [idx], out)
        idx += 1

    return out

def dump_toplevels_json(toplevels, filename=OUTPUT_FILENAME):
    master = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "toplevels": []
    }
    for i, w in enumerate(toplevels):
        try:
            title = w.get_title() if hasattr(w, "get_title") else ""
        except Exception:
            title = ""
        toplevel_info = {
            "index": i,
            "type": w.__class__.__name__,
            "title": title,
            "name": safe_get_name(w),
            "widgets": traverse(w, path=[i])
        }
        master["toplevels"].append(toplevel_info)

    with open(filename, "w", encoding="utf-8") as f:
        json.dump(master, f, ensure_ascii=False, indent=2)

    print(f"[+] widget inventory saved to: {os.path.abspath(filename)}")
    return master

# --- demo UI creation: attempt to include most GTK3 widgets -------------------------
def build_demo_ui():
    win = Gtk.Window()
    win.set_title("GTK3 Widget Inventory Demo")
    win.set_default_size(1100, 750)
    win.set_name("main_window")

    vbox = Gtk.VBox(spacing=8)
    vbox.set_border_width(8)
    vbox.set_name("root_vbox")
    win.add(vbox)

    # header label
    lbl_title = Gtk.Label("GTK3 widget inventory demo")
    lbl_title.set_name("title_label")
    vbox.pack_start(lbl_title, False, False, 0)

    # Row: Label, Entry, TextView
    h1 = Gtk.HBox(spacing=8)
    h1.set_name("row1")
    lbl = Gtk.Label("Label example")
    lbl.set_name("sample_label")
    entry = Gtk.Entry()
    entry.set_text("text in entry")
    entry.set_name("sample_entry")
    tv = Gtk.TextView()
    try:
        buf = tv.get_buffer()
        buf.set_text("TextView multi-line text\nline 2")
    except Exception:
        pass
    tv.set_size_request(400, 120)
    tv.set_name("sample_textview")
    h1.pack_start(lbl, False, False, 0)
    h1.pack_start(entry, False, False, 0)
    h1.pack_start(tv, True, True, 0)
    vbox.pack_start(h1, False, False, 0)

    # Row: Buttons
    h2 = Gtk.HBox(spacing=8)
    h2.set_name("row2")
    btn_plain = Gtk.Button(label="Button")
    btn_plain.set_name("btn_plain")
    btn_suggested = Gtk.Button(label="Suggested")
    btn_suggested.set_name("btn_suggested")
    try:
        btn_suggested.get_style_context().add_class("suggested-action")
    except Exception:
        pass
    btn_toggle = Gtk.ToggleButton(label="Toggle")
    btn_toggle.set_name("btn_toggle")
    h2.pack_start(btn_plain, False, False, 0)
    h2.pack_start(btn_suggested, False, False, 0)
    h2.pack_start(btn_toggle, False, False, 0)
    vbox.pack_start(h2, False, False, 0)

    # Row: Menu / menubar
    menubar = Gtk.MenuBar()
    menubar.set_name("sample_menubar")
    filemenu = Gtk.Menu()
    filem = Gtk.MenuItem(label="File")
    filem.set_name("mi_file")
    sub1 = Gtk.MenuItem(label="Option A")
    sub1.set_name("mi_a")
    sub2 = Gtk.MenuItem(label="Option B")
    sub2.set_name("mi_b")
    filemenu.append(sub1)
    filemenu.append(sub2)
    try:
        filem.set_submenu(filemenu)
    except Exception:
        pass
    menubar.append(filem)
    vbox.pack_start(menubar, False, False, 0)

    # Row: Check / Switch / Radio
    h3 = Gtk.HBox(spacing=8)
    h3.set_name("row3")
    try:
        switch = Gtk.Switch()
        switch.set_name("sample_switch")
    except Exception:
        switch = Gtk.CheckButton(label="Switch fallback")
        switch.set_name("sample_switch_fallback")
    check = Gtk.CheckButton(label="Check")
    check.set_name("sample_check")
    # radio buttons
    try:
        rb1 = Gtk.RadioButton.new_with_label(None, "R1")
        rb1.set_name("rb1")
        rb2 = Gtk.RadioButton.new_with_label_from_widget(rb1, "R2")
        rb2.set_name("rb2")
    except Exception:
        rb1 = Gtk.ToggleButton(label="R1 (fallback)")
        rb1.set_name("rb1_fallback")
        rb2 = Gtk.ToggleButton(label="R2 (fallback)")
        rb2.set_name("rb2_fallback")
    h3.pack_start(switch, False, False, 0)
    h3.pack_start(check, False, False, 0)
    h3.pack_start(rb1, False, False, 0)
    h3.pack_start(rb2, False, False, 0)
    vbox.pack_start(h3, False, False, 0)

    # Row: ComboBoxText / ComboBox / SpinButton
    h4 = Gtk.HBox(spacing=8)
    h4.set_name("row4")
    try:
        comb = Gtk.ComboBoxText()
        comb.set_name("sample_combobox")
        comb.append_text("Item 1")
        comb.append_text("Item 2")
        comb.set_active(0)
    except Exception:
        comb = Gtk.Entry()
        comb.set_text("combo-fallback")
        comb.set_name("sample_combobox_fallback")
    spin = Gtk.SpinButton()
    spin.set_name("sample_spin")
    spin.set_range(0, 10)
    spin.set_value(3)
    h4.pack_start(comb, False, False, 0)
    h4.pack_start(spin, False, False, 0)
    vbox.pack_start(h4, False, False, 0)

    # Row: Scale and ProgressBar
    h5 = Gtk.HBox(spacing=8)
    h5.set_name("row5")
    scale = Gtk.HScale()
    scale.set_name("sample_scale")
    scale.set_range(0, 100)
    scale.set_value(42)
    progress = Gtk.ProgressBar()
    progress.set_name("sample_progress")
    progress.set_fraction(0.35)
    h5.pack_start(scale, True, True, 0)
    h5.pack_start(progress, True, True, 0)
    vbox.pack_start(h5, False, False, 0)

    # Row: TreeView (simple)
    h6 = Gtk.HBox(spacing=8)
    h6.set_name("row6")
    try:
        store = Gtk.ListStore(str, int)
        store.append(["row1", 1])
        store.append(["row2", 2])
        tree = Gtk.TreeView(store)
        tree.set_name("sample_treeview")
        renderer = Gtk.CellRendererText()
        col = Gtk.TreeViewColumn("Col A", renderer, text=0)
        tree.append_column(col)
        h6.pack_start(tree, True, True, 0)
    except Exception:
        lbl_tree = Gtk.Label("treeview-fallback")
        h6.pack_start(lbl_tree, False, False, 0)
    vbox.pack_start(h6, True, True, 0)

    # Notebook with tabs
    nb = Gtk.Notebook()
    nb.set_name("sample_notebook")
    nb_tab1 = Gtk.Label("Tab 1 content")
    nb_tab1.set_name("nb_tab1_content")
    nb_tab2 = Gtk.Label("Tab 2 content")
    nb_tab2.set_name("nb_tab2_content")
    nb.append_page(nb_tab1, Gtk.Label("Tab 1"))
    nb.append_page(nb_tab2, Gtk.Label("Tab 2"))
    vbox.pack_start(nb, False, False, 0)

    # Frame, Expander, Separator
    frame = Gtk.Frame(label="Frame")
    frame.set_name("sample_frame")
    exp = Gtk.Expander(label="Expander")
    exp.set_name("sample_expander")
    sep = Gtk.HSeparator()
    vbox.pack_start(frame, False, False, 0)
    vbox.pack_start(exp, False, False, 0)
    vbox.pack_start(sep, False, False, 0)

    # InfoBar (message area)
    try:
        ib = Gtk.InfoBar()
        ib.set_message_type(Gtk.MessageType.INFO)
        ib.set_name("sample_infobar")
        content = ib.get_content_area()
        content.pack_start(Gtk.Label("InfoBar message"), False, False, 0)
        vbox.pack_start(ib, False, False, 0)
    except Exception:
        pass

    # Statusbar
    try:
        sb = Gtk.Statusbar()
        sb.set_name("sample_statusbar")
        vbox.pack_end(sb, False, False, 0)
    except Exception:
        pass

    # Buttons at bottom: Dump JSON and Open Dialog
    bottom = Gtk.HBox(spacing=8)
    bottom.set_name("bottom_row")
    btn_dump = Gtk.Button(label="Dump JSON")
    btn_dump.set_name("btn_dump_json")
    bottom.pack_start(btn_dump, False, False, 0)

    def open_dialog_cb(btn):
        try:
            md = Gtk.MessageDialog(parent=win, flags=0, message_type=Gtk.MessageType.INFO,
                                   buttons=Gtk.ButtonsType.OK, text="Example dialog")
            md.format_secondary_text("Secondary text in dialog")
            md.set_name("example_dialog")
            md.run()
            md.destroy()
        except Exception:
            # fallback simple dialog
            d = Gtk.Dialog("Dialog fallback", win, 0, (Gtk.STOCK_OK, Gtk.ResponseType.OK))
            d.set_name("example_dialog_fallback")
            d.show_all()
            d.run()
            d.destroy()

    btn_dialog = Gtk.Button(label="Open Dialog")
    btn_dialog.set_name("btn_open_dialog")
    btn_dialog.connect("clicked", open_dialog_cb)
    bottom.pack_start(btn_dialog, False, False, 0)

    vbox.pack_end(bottom, False, False, 0)

    # connect dump button
    def on_dump_clicked(btn):
        toplevels = Gtk.Window.list_toplevels()
        master = dump_toplevels_json(toplevels, filename=OUTPUT_FILENAME)
        # show a simple info dialog
        try:
            md = Gtk.MessageDialog(parent=win, flags=0, message_type=Gtk.MessageType.INFO,
                                   buttons=Gtk.ButtonsType.OK, text=f"Inventory saved to {os.path.abspath(OUTPUT_FILENAME)}")
            md.run()
            md.destroy()
        except Exception:
            print(f"Inventory saved to {os.path.abspath(OUTPUT_FILENAME)}")

    btn_dump.connect("clicked", on_dump_clicked)

    # show all widgets
    win.show_all()
    return win

# --- main / application flow -------------------------------------------------------
def main():
    # create window with widgets
    win = build_demo_ui()

    # allow auto-dump via CLI
    if "--auto-dump" in sys.argv:
        # schedule dump after idle so widgets are realized
        def do_auto():
            toplevels = Gtk.Window.list_toplevels()
            dump_toplevels_json(toplevels, filename=OUTPUT_FILENAME)
            Gtk.main_quit()
            return False
        GLib.idle_add(do_auto)

    # start GTK main loop
    try:
        Gtk.main()
    except KeyboardInterrupt:
        pass
    return 0

if __name__ == "__main__":
    sys.exit(main())

