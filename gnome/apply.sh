#!/usr/bin/env bash
# Diff Dark (GNOME) — aplica tema, dock, menu, terminal, widget e wallpaper.
# Idempotente: pode rodar quantas vezes quiser. Requer o que o install.sh instala.
#
#   ./apply.sh                  aplica tudo
#   ./apply.sh --backup-only    só salva o estado atual (o install.sh chama antes de tudo)
#
# Variáveis opcionais:
#   DIFF_WALLPAPER=/caminho/img.jpg   imagem a graduar (padrão: o wallpaper atual)
#   DIFF_WALLPAPER=default            paisagem gerada (wallpaper/generate.py)
#   DIFF_BUTTONS=':minimize,maximize,close'   botões de janela à direita
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
STATE="$HOME/.local/share/diff-dark"
BACKUP="$STATE/backup"
THEME="Diff-Green-Dark"
ICONS="Colloid-Grey-Dark"
SAGE="#8fb39d"
TERM_UUID="d1ff0dac-0000-4000-8000-00000000d1ff"
PROFILE="/org/gnome/terminal/legacy/profiles:/:$TERM_UUID/"

say()  { printf '\033[38;2;143;179;157m▸\033[0m %s\n' "$*"; }
skip() { printf '\033[38;2;107;113;110m·\033[0m %s\n' "$*"; }
has_ext() { gnome-extensions info "$1" >/dev/null 2>&1 \
  || [ -d "$HOME/.local/share/gnome-shell/extensions/$1" ] \
  || [ -d "/usr/share/gnome-shell/extensions/$1" ]; }

# ── 0. backup do estado original (uma vez só; o uninstall.sh volta a ele) ─
if [ ! -f "$BACKUP/dconf-full.ini" ]; then
  say "backup do estado atual em $BACKUP"
  mkdir -p "$BACKUP" "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
  dconf dump / > "$BACKUP/dconf-full.ini"
  cp -a "$HOME/.config/gtk-3.0" "$BACKUP/gtk-3.0"
  cp -a "$HOME/.config/gtk-4.0" "$BACKUP/gtk-4.0"
fi
[ "${1:-}" = "--backup-only" ] && exit 0

for need in "$HOME/.themes/$THEME" "$HOME/.local/share/icons/$ICONS"; do
  [ -e "$need" ] || { echo "faltando: $need (rode o install.sh)"; exit 1; }
done

# ── 1. wallpaper: o atual (ou DIFF_WALLPAPER) graduado pra paleta; sem imagem
#       utilizável, a paisagem gerada pelo wallpaper/generate.py ──────────────
WP_DIR="$STATE/wallpapers"
set_wallpaper() {
  gsettings set org.gnome.desktop.background picture-uri "file://$1"
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$1"
  gsettings set org.gnome.desktop.background picture-options 'zoom'
  gsettings set org.gnome.desktop.screensaver picture-uri "file://$1"
}
generated_wallpaper() {
  local size w h
  size=$(xrandr --current | grep -oP 'primary \K\d+x\d+' || true)
  w=${size%x*}; h=${size#*x}
  [ -n "$size" ] || { w=3840; h=2160; }
  local wp="$WP_DIR/diff-dark-${w}x${h}.jpg"
  mkdir -p "$WP_DIR"
  if [ ! -f "$wp" ]; then
    say "gerando wallpaper ${w}x${h}"
    python3 -I "$HERE/wallpaper/generate.py" "$wp" "$w" "$h"
  fi
  rm -f "$STATE/wallpaper-source"
  set_wallpaper "$wp"
}

current=$(gsettings get org.gnome.desktop.background picture-uri-dark | tr -d "'")
current="${current#file://}"
if [ -n "${DIFF_WALLPAPER:-}" ]; then
  src="$DIFF_WALLPAPER"
elif [ -f "$STATE/wallpaper-source" ]; then
  src=$(cat "$STATE/wallpaper-source")       # reaplicando: gradua de novo a original
else
  src="$current"
fi
case "$src" in
  default) generated_wallpaper ;;
  "$WP_DIR"/*) skip "wallpaper do Diff Dark já aplicado; use DIFF_WALLPAPER=... para trocar" ;;
  *.jpg|*.jpeg|*.png|*.webp|*.JPG|*.JPEG|*.PNG)
    if [ -f "$src" ]; then
      WP="$WP_DIR/$(basename "${src%.*}")-diff.jpg"
      mkdir -p "$WP_DIR"
      if [ ! -f "$WP" ]; then
        say "graduando wallpaper: $(basename "$src")"
        python3 -I "$HERE/wallpaper/grade.py" "$src" "$WP"
      fi
      echo "$src" > "$STATE/wallpaper-source"
      set_wallpaper "$WP"
    else
      generated_wallpaper
    fi ;;
  *) generated_wallpaper ;;  # ex.: wallpaper animado (.xml) ou cor sólida
esac

# ── 2. aparência ──────────────────────────────────────────────────────────
say "tema $THEME, ícones $ICONS, fontes Inter / JetBrains Mono"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme "$THEME"
gsettings set org.gnome.desktop.interface icon-theme "$ICONS"
gsettings set org.gnome.desktop.interface font-name 'Inter 10'
gsettings set org.gnome.desktop.interface document-font-name 'Inter 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11'
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.interface font-hinting 'slight'
gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Inter Semi-Bold 10'
gsettings set org.gnome.desktop.wm.preferences button-layout "${DIFF_BUTTONS:-close,minimize,maximize:}"

# ajustes nossos por cima do CSS gerado do Shell (reinjetados a cada apply)
SHELLCSS="$HOME/.themes/$THEME/gnome-shell/gnome-shell.css"
sed -i '/\/\* diff-dark:begin \*\//,/\/\* diff-dark:end \*\//d' "$SHELLCSS"
{ echo '/* diff-dark:begin */'; cat "$HERE/theme/shell-overrides.css"; echo '/* diff-dark:end */'; } >> "$SHELLCSS"
# trocar o nome força o User Themes a recarregar o stylesheet sem reload do Shell
dconf write /org/gnome/shell/extensions/user-theme/name "''"
sleep 1
dconf write /org/gnome/shell/extensions/user-theme/name "'$THEME'"

# GTK3: respiro interno no terminal (o VTE não tem opção de padding)
GTK3CSS="$HOME/.config/gtk-3.0/gtk.css"
touch "$GTK3CSS"
sed -i '/\/\* diff-dark:begin \*\//,/\/\* diff-dark:end \*\//d' "$GTK3CSS"
cat >> "$GTK3CSS" <<'CSS'
/* diff-dark:begin */
vte-terminal { padding: 10px 14px; }
/* diff-dark:end */
CSS

# ── 3. extensões ──────────────────────────────────────────────────────────
WANT=(user-theme@gnome-shell-extensions.gcampax.github.com)
has_ext arcmenu@arcmenu.com && WANT+=(arcmenu@arcmenu.com)
has_ext blur-my-shell@aunetx && WANT+=(blur-my-shell@aunetx)
has_ext ubuntu-dock@ubuntu.com && WANT+=(ubuntu-dock@ubuntu.com)
say "extensões: ${WANT[*]%%@*}"
python3 -I - "${WANT[@]}" <<'PY'
import sys
from gi.repository import Gio
s = Gio.Settings.new("org.gnome.shell")
on = list(s.get_strv("enabled-extensions"))
off = list(s.get_strv("disabled-extensions"))
for u in sys.argv[1:]:
    if u not in on: on.append(u)
    if u in off: off.remove(u)
s.set_strv("enabled-extensions", on)
s.set_strv("disabled-extensions", off)
Gio.Settings.sync()
PY
# o Ubuntu Dock é carregado pela sessão: liga na hora, sem reload do Shell
has_ext ubuntu-dock@ubuntu.com && gnome-extensions enable ubuntu-dock@ubuntu.com 2>/dev/null || true

# dock fixo à esquerda, pequeno, sem fundo (só os ícones) (Ubuntu Dock / Dash to Dock)
if has_ext ubuntu-dock@ubuntu.com || has_ext dash-to-dock@micxgx.gmail.com; then
  dconf load /org/gnome/shell/extensions/dash-to-dock/ <<INI
[/]
dock-position='LEFT'
dock-fixed=true
autohide=false
intellihide=false
extend-height=false
height-fraction=0.9
dash-max-icon-size=28
custom-theme-shrink=true
apply-custom-theme=false
transparency-mode='FIXED'
background-color='#161817'
custom-background-color=true
background-opacity=0.0
running-indicator-style='DOTS'
custom-theme-customize-running-dots=true
custom-theme-running-dots-color='$SAGE'
custom-theme-running-dots-border-width=0
unity-backlit-items=false
show-apps-at-top=true
disable-overview-on-startup=true
INI
else
  skip "sem Ubuntu Dock / Dash to Dock; dock não configurado"
fi

dconf load /org/gnome/shell/extensions/arcmenu/ <<'INI'
[/]
menu-layout='Eleven'
position-in-panel='Left'
menu-button-icon='Custom_Icon'
custom-menu-button-icon='view-app-grid-symbolic'
custom-menu-button-icon-size=18.0
menu-button-hover-bg-color=(true, 'rgba(255,255,255,0.08)')
menu-button-active-bg-color=(true, 'rgba(143,179,157,0.18)')
menu-button-border-radius=(true, 8)
override-menu-theme=true
menu-background-color='rgba(27,29,28,0.96)'
menu-foreground-color='rgb(220,223,221)'
menu-border-color='rgb(42,45,44)'
menu-border-width=1
menu-border-radius=16
menu-separator-color='rgba(255,255,255,0.06)'
menu-item-hover-bg-color='rgb(42,45,44)'
menu-item-hover-fg-color='rgb(236,238,237)'
menu-item-active-bg-color='rgba(143,179,157,0.22)'
menu-item-active-fg-color='rgb(236,238,237)'
menu-font-size=11
menu-height=620
search-entry-border-radius=(true, 10)
INI

# blur: só no overview. A barra do topo são ilhas sem fundo próprio, e o terminal fica
# só com a transparência do perfil.
dconf load /org/gnome/shell/extensions/blur-my-shell/ <<'INI'
[panel]
blur=false

[applications]
blur=false
INI

# ── 4. terminal ───────────────────────────────────────────────────────────
if command -v gnome-terminal >/dev/null; then
  say "perfil 'Diff' no gnome-terminal (78% opaco, JetBrains Mono)"
  python3 -I - "$TERM_UUID" <<'PY'
import sys
from gi.repository import Gio
uuid = sys.argv[1]
s = Gio.Settings.new("org.gnome.Terminal.ProfilesList")
lst = list(s.get_strv("list"))
if uuid not in lst: lst.append(uuid)
s.set_strv("list", lst)
s.set_string("default", uuid)
Gio.Settings.sync()
PY
  dconf load "$PROFILE" <<'INI'
[/]
visible-name='Diff'
use-theme-colors=false
background-color='rgb(22,24,23)'
foreground-color='rgb(212,216,214)'
bold-color-same-as-fg=true
bold-is-bright=false
cursor-colors-set=true
cursor-background-color='rgb(143,179,157)'
cursor-foreground-color='rgb(22,24,23)'
cursor-shape='ibeam'
highlight-colors-set=true
highlight-background-color='rgb(58,62,60)'
highlight-foreground-color='rgb(236,238,237)'
palette=['rgb(42,45,44)', 'rgb(217,136,128)', 'rgb(143,179,157)', 'rgb(214,192,142)', 'rgb(147,173,192)', 'rgb(179,160,196)', 'rgb(139,188,174)', 'rgb(191,195,193)', 'rgb(78,83,81)', 'rgb(227,162,155)', 'rgb(169,201,181)', 'rgb(226,209,168)', 'rgb(173,195,211)', 'rgb(198,183,212)', 'rgb(166,206,194)', 'rgb(236,238,237)']
use-transparent-background=true
use-theme-transparency=false
background-transparency-percent=22
use-system-font=false
font='JetBrains Mono 11'
cell-height-scale=1.08
scrollbar-policy='never'
audible-bell=false
INI
  dconf write /org/gnome/terminal/legacy/theme-variant "'dark'"
  dconf write /org/gnome/terminal/legacy/default-show-menubar false
  dconf write /org/gnome/terminal/legacy/headerbar '@mb true'
else
  skip "gnome-terminal não instalado; perfil não criado"
fi

# ── 5. widget ─────────────────────────────────────────────────────────────
if [ -x "$HOME/.local/bin/conky" ]; then
  say "widget (Conky): CPU/RAM/disco no canto superior direito"
  mkdir -p "$HOME/.config/autostart"
  cat > "$HOME/.config/autostart/diff-dark-conky.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=Diff Dark widget
Exec=$HERE/conky/start.sh 6
X-GNOME-Autostart-enabled=true
NoDisplay=true
DESK
  "$HERE/conky/start.sh"
else
  skip "Conky não encontrado em ~/.local/bin; widget não instalado"
fi

say "pronto. Se alguma extensão acabou de ser instalada: Alt+F2, r, Enter (X11)."
