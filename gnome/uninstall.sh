#!/usr/bin/env bash
# Diff Dark (GNOME) — desinstala. Volta as configurações para como estavam antes
# da instalação e remove o que o install.sh baixou ou gerou. O que já existia na
# máquina (temas, extensões, fontes do usuário) fica onde está.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
STATE="$HOME/.local/share/diff-dark"
BACKUP="$STATE/backup"
MANIFEST="$STATE/installed"
TERM_UUID="d1ff0dac-0000-4000-8000-00000000d1ff"
[ -f "$BACKUP/dconf-full.ini" ] || { echo "Diff Dark não está instalado (sem $BACKUP)"; exit 1; }

say() { printf '\033[38;2;143;179;157m▸\033[0m %s\n' "$*"; }

say "widget"
pkill -f "$HERE/conky/.*\.conf" 2>/dev/null || true
rm -f "$HOME/.config/autostart/diff-dark-conky.desktop"

say "configurações de antes da instalação"
dconf reset -f "/org/gnome/terminal/legacy/profiles:/:$TERM_UUID/"
python3 -I - "$BACKUP/dconf-full.ini" <<'PY'
import ast, sys, subprocess, configparser

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

# extensões: desfaz só o que o apply.sh mudou (ligou as do tema e tirou elas da lista
# de desligadas); extensões que o usuário mexeu depois da instalação ficam como estão
THEME_EXTS = {"user-theme@gnome-shell-extensions.gcampax.github.com", "arcmenu@arcmenu.com",
              "blur-my-shell@aunetx", "ubuntu-dock@ubuntu.com"}

def strv(text):
    text = (text or "").strip().removeprefix("@as ")
    return ast.literal_eval(text) if text else []

def current(key):
    return strv(subprocess.run(["dconf", "read", key], capture_output=True, text=True).stdout)

def before(key):
    return strv(cp.get("org/gnome/shell", key)) if cp.has_option("org/gnome/shell", key) else []

on_before, off_before = before("enabled-extensions"), before("disabled-extensions")
on = [u for u in current("/org/gnome/shell/enabled-extensions")
      if u not in THEME_EXTS or u in on_before]
off = current("/org/gnome/shell/disabled-extensions")
off += [u for u in off_before if u in THEME_EXTS and u not in off]
subprocess.run(["dconf", "write", "/org/gnome/shell/enabled-extensions", repr(on)], check=True)
subprocess.run(["dconf", "write", "/org/gnome/shell/disabled-extensions", repr(off)], check=True)

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
mkdir -p "$HOME/.config/gtk-4.0"
cp -a "$BACKUP/gtk-4.0/." "$HOME/.config/gtk-4.0/"

say "removendo o que foi instalado"
if [ -f "$MANIFEST" ]; then
  while IFS= read -r item; do
    case "$item" in
      extension:*) gnome-extensions uninstall "${item#extension:}" 2>/dev/null || true ;;
      "$HOME"/?*)  rm -rf -- "$item" ;;
    esac
  done < "$MANIFEST"
  fc-cache -f >/dev/null 2>&1 || true
fi
rm -rf -- "$STATE" "${XDG_CACHE_HOME:-$HOME/.cache}/diff-dark"

say "pronto. Apps que já estavam abertos voltam ao visual antigo quando forem reabertos."
