#!/usr/bin/env python3
# dump_gtk4_widgets.py
# Gera uma janela com muitos widgets GTK4 e permite exportar um inventário JSON da árvore de widgets.
# Versão resiliente: trata widgets ausentes nas bindings (ex.: RadioButton ausente)
# Requer: python3 + pygobject + GTK4

import gi
gi.require_version("Gtk", "4.0")
from gi.repository import Gtk, GLib, GObject
import json
import os
import sys
from datetime import datetime

OUTPUT_FILENAME = "gtk4_widgets_dump.json"

# --- funções utilitárias de inspeção -------------------------------------------------
def safe_get_name(w):
    try:
        return w.get_name() or ""
    except Exception:
        return ""

def safe_get_css_classes(w):
    try:
        classes = w.get_css_classes()
        if classes:
            return list(classes)
    except Exception:
        pass
    return []

def safe_get_state_flags(w):
    try:
        sf = w.get_state_flags()
        return str(sf)
    except Exception:
        return ""

def widget_info_dict(widget, parent_path):
    return {
        "type": widget.__class__.__name__,
        "name": safe_get_name(widget),
        "css_classes": safe_get_css_classes(widget),
        "state_flags": safe_get_state_flags(widget),
        "visible": bool(widget.get_visible()) if hasattr(widget, "get_visible") else None,
        "sensitive": bool(widget.get_sensitive()) if hasattr(widget, "get_sensitive") else None,
        "parent_path": parent_path
    }

def traverse_widget(widget, path=None, out_list=None):
    if out_list is None:
        out_list = []
    if path is None:
        path = []

    info = widget_info_dict(widget, "/".join(map(str, path[:-1])) if path else "")
    info["path"] = "/".join(map(str, path)) if path else "0"
    out_list.append(info)

    try:
        child = widget.get_first_child()
        idx = 0
        while child:
            traverse_widget(child, path + [idx], out_list)
            idx += 1
            child = child.get_next_sibling()
    except Exception:
        pass

    return out_list

def dump_widgets_json(toplevels, filename=OUTPUT_FILENAME):
    master = {
        "generated_at": datetime.utcnow().isoformat() + "Z",
        "toplevels": []
    }
    for i, w in enumerate(toplevels):
        toplevel_info = {
            "index": i,
            "type": w.__class__.__name__,
            "title": getattr(w, "get_title", lambda: "")(),
            "name": safe_get_name(w),
            "widgets": traverse_widget(w, path=[i])
        }
        master["toplevels"].append(toplevel_info)
    with open(filename, "w", encoding="utf-8") as f:
        json.dump(master, f, ensure_ascii=False, indent=2)
    print(f"[+] widget inventory saved to: {os.path.abspath(filename)}")
    return master

# --- ajuda: factory segura para widgets que podem faltar -----------------------------
def safe_radio_button_new_with_label(group, label_text):
    """
    Tenta criar Gtk.RadioButton; se não existir (binding), cria Gtk.ToggleButton como fallback.
    Retorna o widget criado.
    """
    try:
        RadioButton = getattr(Gtk, "RadioButton")
        # GTK4 pode expor construtor diferente; tentar ambos
        if hasattr(RadioButton, "new_with_label"):
            return RadioButton.new_with_label(group, label_text)
        else:
            # fallback construtor direto
            return RadioButton(label=label_text)
    except Exception:
        # fallback: ToggleButton com marcação para distinguir
        tb = Gtk.ToggleButton(label=label_text)
        # marca para identificação no inventário
        try:
            tb.set_name(f"radio_fallback_{label_text}")
            tb.set_tooltip_text("radio-fallback")
        except Exception:
            pass
        return tb

# --- UI: cria muitos widgets de exemplo ----------------------------------------------
def build_demo_ui(app):
    win = Gtk.ApplicationWindow(application=app)
    win.set_title("GTK4 Widget Inventory Demo")
    win.set_default_size(1000, 700)
    win.set_name("main_window")

    hb = Gtk.HeaderBar()
    hb.set_show_title_buttons(True)
    win.set_titlebar(hb)

    title_label = Gtk.Label(label="GTK4 Widget Inventory")
    title_label.set_name("title_label")
    hb.pack_start(title_label)

    btn_dump = Gtk.Button(label="Dump JSON")
    btn_dump.set_name("btn_dump_json")
    hb.pack_end(btn_dump)

    scroller = Gtk.ScrolledWindow()
    scroller.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
    scroller.set_name("main_scroller")

    root_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
    root_box.set_margin_top(8)
    root_box.set_margin_bottom(8)
    root_box.set_margin_start(8)
    root_box.set_margin_end(8)
    root_box.set_name("root_box")

    # Linha 1: labels, entry, textview
    row1 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
    row1.set_name("row1")
    lbl = Gtk.Label(label="Label de exemplo")
    lbl.set_name("sample_label")
    entry = Gtk.Entry()
    entry.set_text("texto em entry")
    entry.set_name("sample_entry")
    tv = Gtk.TextView()
    try:
        tv.get_buffer().set_text("Texto de várias linhas no TextView.\nLinha 2.")
    except Exception:
        # em alguns bindings TextView API pode variar; ignorar se falhar
        pass
    tv.set_size_request(300, 100)
    tv.set_name("sample_textview")

    row1.append(lbl)
    row1.append(entry)
    row1.append(tv)
    root_box.append(row1)

    # Linha 2: botões variados
    row2 = Gtk.Box(spacing=8)
    row2.set_name("row2")
    btn = Gtk.Button(label="Button")
    btn.set_name("btn_plain")
    btn_suggested = Gtk.Button(label="Suggested")
    btn_suggested.set_name("btn_suggested")
    try:
        btn_suggested.add_css_class("suggested-action")
    except Exception:
        pass
    toggle = Gtk.ToggleButton(label="Toggle")
    toggle.set_name("btn_toggle")
    row2.append(btn)
    row2.append(btn_suggested)
    row2.append(toggle)
    root_box.append(row2)

    # Linha 3: menus & menubutton (GTK4: usar Popover ou menu_model/Gio.Menu)
    row3 = Gtk.Box(spacing=8)
    row3.set_name("row3")
    menu_button = Gtk.MenuButton()
    menu_button.set_name("menu_button_example")

    pop = Gtk.Popover()
    pop_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
    mi1_btn = Gtk.Button(label="Opção A")
    mi1_btn.set_name("mi_a")
    mi2_btn = Gtk.Button(label="Opção B")
    mi2_btn.set_name("mi_b")
    pop_box.append(mi1_btn)
    pop_box.append(mi2_btn)
    pop.set_child(pop_box)
    try:
        menu_button.set_popover(pop)
    except Exception:
        # fallback: pack pop inside a container and show/hide manually
        pass

    row3.append(menu_button)
    root_box.append(row3)

    # Linha 4: switches, check, radio (Radio pode não existir: usar fábrica segura)
    row4 = Gtk.Box(spacing=8)
    row4.set_name("row4")
    switch = Gtk.Switch()
    try:
        switch.set_name("sample_switch")
    except Exception:
        pass
    check = None
    try:
        check = Gtk.CheckButton(label="Check")
        check.set_name("sample_check")
    except Exception:
        # fallback: ToggleButton
        check = Gtk.ToggleButton(label="Check (fallback)")
        try:
            check.set_name("sample_check_fallback")
        except Exception:
            pass

    # radio buttons: usar wrapper seguro
    rb1 = safe_radio_button_new_with_label(None, "R1")
    try:
        rb1.set_name("rb1")
    except Exception:
        pass
    rb2 = safe_radio_button_new_with_label(rb1 if hasattr(rb1, "get_group") else None, "R2")
    try:
        rb2.set_name("rb2")
    except Exception:
        pass

    row4.append(switch)
    row4.append(check)
    row4.append(rb1)
    row4.append(rb2)
    root_box.append(row4)

    # Linha 5: combo / comboboxtext
    row5 = Gtk.Box(spacing=8)
    row5.set_name("row5")
    try:
        combo = Gtk.ComboBoxText.new()
        combo.set_name("sample_combobox")
        combo.append_text("Item 1")
        combo.append_text("Item 2")
        combo.set_active(0)
    except Exception:
        # fallback: simple drop-down simulated by MenuButton + Popover
        combo = Gtk.MenuButton()
        try:
            combo.set_name("sample_combobox_fallback")
        except Exception:
            pass
    row5.append(combo)
    root_box.append(row5)

    # Linha 6: sliders / scales / progress
    row6 = Gtk.Box(spacing=8)
    row6.set_name("row6")
    try:
        scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
        scale.set_name("sample_scale")
        scale.set_value(25)
    except Exception:
        # fallback: use a Gtk.Scale if available, else just a Label
        try:
            scale = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0, 100, 1)
            scale.set_name("sample_scale_fallback")
        except Exception:
            scale = Gtk.Label(label="scale-fallback")
            try:
                scale.set_name("sample_scale_label_fallback")
            except Exception:
                pass
    progress = Gtk.ProgressBar()
    try:
        progress.set_fraction(0.4)
        progress.set_name("sample_progress")
    except Exception:
        pass
    row6.append(scale)
    row6.append(progress)
    root_box.append(row6)

    # Linha 7: ListBox
    row7 = Gtk.Box(spacing=8)
    row7.set_name("row7")
    try:
        listbox = Gtk.ListBox()
        listbox.set_name("sample_listbox")
        for i in range(4):
            li = Gtk.Label(label=f"Item {i+1}")
            try:
                li.set_name(f"list_label_{i+1}")
            except Exception:
                pass
            listbox.append(li)
    except Exception:
        listbox = Gtk.Label(label="listbox-fallback")
        try:
            listbox.set_name("sample_listbox_fallback")
        except Exception:
            pass
    row7.append(listbox)
    root_box.append(row7)

    # Linha 8: dialogs (botão que abre dialog)
    def open_dialog(_btn):
        try:
            dlg = Gtk.MessageDialog(transient_for=win, modal=True, message_type=Gtk.MessageType.INFO,
                                    buttons=Gtk.ButtonsType.OK, text="Dialog de exemplo")
            dlg.set_secondary_text("Segunda linha do dialog")
            dlg.set_name("example_dialog")
            dlg.show()
        except Exception:
            # fallback simples: criar Gtk.Dialog manualmente
            try:
                dlg = Gtk.Dialog(transient_for=win)
                dlg.set_title("Dialog fallback")
                content = Gtk.Label(label="Dialog de exemplo (fallback)")
                box = dlg.get_content_area()
                box.append(content)
                dlg.show()
            except Exception:
                pass

    row8 = Gtk.Box(spacing=8)
    row8.set_name("row8")
    open_dlg_btn = Gtk.Button(label="Open Dialog")
    open_dlg_btn.set_name("btn_open_dialog")
    open_dlg_btn.connect("clicked", open_dialog)
    row8.append(open_dlg_btn)
    root_box.append(row8)

    # Linha 9: headerbar actions e search entry
    row9 = Gtk.Box(spacing=8)
    row9.set_name("row9")
    try:
        search = Gtk.SearchEntry()
        search.set_placeholder_text("Pesquisar...")
        search.set_name("sample_searchentry")
    except Exception:
        search = Gtk.Entry()
        try:
            search.set_name("sample_searchentry_fallback")
        except Exception:
            pass
    row9.append(search)
    root_box.append(row9)

    bottom = Gtk.Box(spacing=8)
    bottom.set_name("bottom_row")
    info_lbl = Gtk.Label(label="Clique em Dump JSON para gerar o inventário de widgets (arquivo ./gtk4_widgets_dump.json)")
    info_lbl.set_name("info_label")
    bottom.append(info_lbl)
    root_box.append(bottom)

    scroller.set_child(root_box)
    win.set_child(scroller)

    # --- Conexões: dump por botão e atalho ---------------------------------------
    def on_dump_clicked(_btn):
        toplevels = Gtk.Window.list_toplevels()
        master = dump_widgets_json(toplevels, filename=OUTPUT_FILENAME)
        try:
            dlg = Gtk.MessageDialog(transient_for=win, modal=True, message_type=Gtk.MessageType.INFO,
                                    buttons=Gtk.ButtonsType.OK, text=f"Inventory salvo em {os.path.abspath(OUTPUT_FILENAME)}")
            dlg.show()
        except Exception:
            print(f"Inventory salvo em {os.path.abspath(OUTPUT_FILENAME)}")

    btn_dump.connect("clicked", on_dump_clicked)

    if "--auto-dump" in sys.argv:
        GLib.idle_add(lambda: (on_dump_clicked(None), Gtk.main_quit())[1])

    return win

# --- aplicação ---------------------------------------------------------------------
class DemoApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="org.example.gtk4.widget-inventory")

    def do_activate(self):
        win = None
        toplevels = Gtk.Window.list_toplevels()
        for w in toplevels:
            if isinstance(w, Gtk.ApplicationWindow) and w.get_application() is self:
                win = w
                break
        if not win:
            win = build_demo_ui(self)
        win.present()

def main():
    app = DemoApp()
    return app.run(sys.argv)

if __name__ == "__main__":
    sys.exit(main())

