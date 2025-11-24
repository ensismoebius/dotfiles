GTK2 theme for Cyberpunk Neon (gtk-2.0)

What this is
------------
This folder contains a GTK2-compatible theme mapping (gtkrc) that approximates
the look-and-feel defined in `gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` in this
repo. GTK2 does not understand CSS; instead it uses the `gtkrc` format and an
engine (usually "pixmap" or engines like Murrine/RC) to draw widgets.

Files created
-------------
- `gtkrc` : The actual GTK2 theme file. Drop this in `~/.config/gtk-2.0/gtkrc`
- `gtk.css`: A read-only reference file explaining the color mapping (GTK2
  doesn't use it; included for parity and reference).

Install / enable
----------------
Option A (per-user - recommended):
  mkdir -p ~/.config/gtk-2.0
  cp path/to/this/repo/gtk-2.0/gtkrc ~/.config/gtk-2.0/gtkrc
  # Create ~/.gtkrc-2.0 which GTK2 apps also read:
  printf "include \"%s/.config/gtk-2.0/gtkrc\"\n" "$HOME" > ~/.gtkrc-2.0

Option B (system-wide):
  Copy the `gtkrc` to the system GTK2 theme directory (requires root). Not
  recommended unless you know what you're doing.

Notes & limitations
-------------------
- GTK2 has fewer styling primitives and no CSS, so certain effects (box-shadows,
  alpha/transparency, keyframe animations, etc.) cannot be reproduced exactly.
- Colors, padding and radii are approximations. Widgets will look close but not
  pixel-identical to GTK3/4.
- If you want more accurate GTK2 theming, consider installing a GTK2 engine
  like `murrine` and converting the colors into an engine-compatible theme.

If you'd like, I can:
- Add a `murrine` engine theme variant (requires more work but looks better),
- Generate a small screenshot/example showing GTK2 vs GTK3/4 behavior,
- Tweak specific widgets you care about (e.g., Nautilus, Thunar, xchat).
