# Diff Dark — GNOME

**English** · [Português](README.pt-BR.md)

Tested on **Ubuntu 22.04, GNOME 42, X11**. Everything goes into your home directory; no sudo
besides the prerequisite packages.

## Install

```bash
sudo apt install git curl unzip sassc x11-utils python3-gi python3-pil libfuse2 gnome-shell-extension-prefs
./install.sh
```

Then reload the Shell so newly installed extensions load: on X11, **Alt+F2 → `r` → Enter**
(windows stay open); on Wayland, log out and back in.

## Uninstall

```bash
./uninstall.sh
```

Restores every setting the theme touched to how it was before the install, and removes what the
installer downloaded or built (theme, icons, fonts, extensions, Conky). Anything that was already
on your machine stays.

## What changes

- **GTK 3/4 and Shell:** `Diff-Green-Dark` theme (Colloid recolored, rimless). libadwaita apps
  get it through `~/.config/gtk-4.0`.
- **Icons and fonts:** Colloid Grey Dark; Inter for the UI and JetBrains Mono for monospace.
- **Floating top bar:** no full-width strip; each group (menu and focused app, clock, indicators)
  is a pill as wide as its content, floating over the wallpaper.
- **Dock:** Ubuntu Dock pinned to the left, 28px icons, no background, a sage dot on the
  focused app.
- **Menu:** ArcMenu, "Eleven" layout, at the left of the top bar.
- **Terminal:** a `Diff` profile in gnome-terminal (22% transparent, JetBrains Mono, inner
  padding, header bar instead of the menu). Your old profile stays.
- **Widget:** a card with CPU, RAM and disk rings in the top-right corner of the primary monitor.
  If [`ai-usagebar`](https://crates.io/crates/ai-usagebar) is installed, a second card below it
  shows your AI quota: session (5h) and weekly bars, a tick marking how much of the time window
  has passed, and when each one resets.
- **Wallpaper:** your current one, nearly desaturated, darkened, with a sage veil in the shadows.
  The original file is left untouched. If the current wallpaper isn't an image, a generated
  landscape is used instead (layered grey ridges and a sage disc, no third-party image).

## Options

```bash
DIFF_WALLPAPER=~/Pictures/photo.jpg ./apply.sh          # grade another image (default: current wallpaper)
DIFF_WALLPAPER=default ./apply.sh                       # the generated landscape, sized to your monitor
DIFF_BUTTONS=':minimize,maximize,close' ./apply.sh      # window buttons on the right (default: left)
```

`apply.sh` only applies settings, so it is quick and safe to run again.

## Customize

| To change | Edit | Then run |
|---|---|---|
| Theme colors | `theme/palette.scss` | `./install.sh` |
| Top bar, dock spacing, other Shell details | `theme/shell-overrides.css` | `./apply.sh` |
| Widget drawing | `conky/diff.lua` | `conky/start.sh` |
| Widget default position | `conky/place.py` | `conky/start.sh` |
