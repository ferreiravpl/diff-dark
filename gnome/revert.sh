#!/usr/bin/env bash
# Diff Dark (GNOME) — volta ao estado salvo antes da instalação.
# Restaura só o que o projeto mexe; o resto do dconf fica como está.
# Tema, ícones, fontes, extensões e Conky continuam instalados (só desligados).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
BACKUP="$HOME/.local/share/diff-dark/backup"
TERM_UUID="d1ff0dac-0000-4000-8000-00000000d1ff"
[ -f "$BACKUP/dconf-full.ini" ] || { echo "sem backup em $BACKUP"; exit 1; }

say() { printf '\033[38;2;143;179;157m▸\033[0m %s\n' "$*"; }

say "widgets"
pkill -f "$HERE/conky/.*\.conf" 2>/dev/null || true
rm -f "$HOME/.config/autostart/diff-dark-conky.desktop" "$HOME/.local/share/diff-dark/stats-pos"
rm -f "$HOME/.local/share/diff-dark/wallpaper-source"

say "dconf (caminhos do kit)"
dconf reset -f "/org/gnome/terminal/legacy/profiles:/:$TERM_UUID/"
python3 -I - "$BACKUP/dconf-full.ini" <<'PY'
import sys, subprocess, configparser

# caminhos inteiros: zera e recarrega do backup
PATHS = [
    "org/gnome/desktop/interface",
    "org/gnome/desktop/wm/preferences",
    "org/gnome/desktop/background",
    "org/gnome/desktop/screensaver",
    "org/gnome/shell/extensions/dash-to-dock",
    "org/gnome/shell/extensions/arcmenu",
    "org/gnome/shell/extensions/blur-my-shell",
    "org/gnome/shell/extensions/user-theme",
]
# chaves soltas dentro de caminhos que têm outras coisas do usuário
KEYS = {
    "org/gnome/shell": ["enabled-extensions", "disabled-extensions"],
    "org/gnome/terminal/legacy": ["theme-variant", "default-show-menubar", "headerbar"],
    "org/gnome/terminal/legacy/profiles:": ["list", "default"],
}

cp = configparser.RawConfigParser(strict=False)
cp.optionxform = str
cp.read(sys.argv[1], encoding="utf-8")

def under(section, path):
    return section == path or section.startswith(path + "/")

for p in PATHS:
    subprocess.run(["dconf", "reset", "-f", f"/{p}/"], check=True)
    frag = []
    for sec in cp.sections():
        if under(sec, p):
            frag.append(f"[{sec}]")
            frag += [f"{k}={v}" for k, v in cp.items(sec)]
            frag.append("")
    if frag:
        subprocess.run(["dconf", "load", "/"], input="\n".join(frag), text=True, check=True)

for sec, keys in KEYS.items():
    for k in keys:
        key = f"/{sec}/{k}"
        if cp.has_section(sec) and cp.has_option(sec, k):
            subprocess.run(["dconf", "write", key, cp.get(sec, k)], check=True)
        else:
            subprocess.run(["dconf", "reset", key], check=True)
PY

say "GTK"
GTK3CSS="$HOME/.config/gtk-3.0/gtk.css"
[ -f "$GTK3CSS" ] && sed -i '/\/\* diff-dark:begin \*\//,/\/\* diff-dark:end \*\//d' "$GTK3CSS"
[ -f "$GTK3CSS" ] && [ ! -s "$GTK3CSS" ] && [ ! -f "$BACKUP/gtk-3.0/gtk.css" ] && rm -f "$GTK3CSS"
# o build do libadwaita escreve gtk.css/gtk-dark.css/assets em gtk-4.0
rm -rf "$HOME/.config/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk-dark.css" "$HOME/.config/gtk-4.0/assets"
cp -a "$BACKUP/gtk-4.0/." "$HOME/.config/gtk-4.0/"

say "pronto. Recarregue o Shell: Alt+F2, digite r, Enter."
echo "  (tema, ícones, fontes e extensões continuam instalados; o apply.sh liga tudo de novo)"
