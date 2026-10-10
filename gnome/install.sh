#!/usr/bin/env bash
# Diff Dark (GNOME) — instala tudo o que o apply.sh precisa e aplica.
#
#   tema GTK/Shell/libadwaita  Colloid compilado com theme/palette.scss
#   ícones                     Colloid (pastas cinza)
#   fontes                     Inter + JetBrains Mono
#   extensões                  User Themes, ArcMenu, Blur my Shell
#   widget                     Conky (AppImage) com o card de CPU/RAM/disco
#
# Tudo vai para o diretório do usuário; não usa sudo. Downloads e builds ficam
# em ~/.cache/diff-dark. Testado no Ubuntu 22.04 (GNOME 42, X11).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/diff-dark"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
FONT_DIR="$HOME/.local/share/fonts/diff-dark"

# versões fixas: o mesmo commit gera sempre o mesmo tema
COLLOID_GTK_REV="fe11342f37f124f1b29d44cf33e9a06053f4bba2"
COLLOID_ICONS_REV="ceac6608ecd0e40025cbc2ebbd32bf0e0f4ebc6a"
CONKY_URL="https://github.com/brndnmtthws/conky/releases/download/v1.25.3/conky-x86_64-v1.25.3.AppImage"
JBMONO_URL="https://github.com/JetBrains/JetBrainsMono/releases/download/v2.304/JetBrainsMono-2.304.zip"
INTER_URL="https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
EXTENSIONS=(
  "user-theme@gnome-shell-extensions.gcampax.github.com"
  "arcmenu@arcmenu.com"
  "blur-my-shell@aunetx"
)

say()  { printf '\033[38;2;143;179;157m▸\033[0m %s\n' "$*"; }
fail() { printf '\033[38;2;217;136;128m✗\033[0m %s\n' "$*" >&2; exit 1; }

# ── 0. pré-requisitos ─────────────────────────────────────────────────────
say "conferindo pré-requisitos"
missing=()
for cmd in git curl unzip sassc gnome-shell gnome-extensions gsettings dconf xwininfo xrandr python3; do
  command -v "$cmd" >/dev/null || missing+=("$cmd")
done
python3 -c 'import gi; gi.require_version("Gdk", "3.0")' 2>/dev/null || missing+=("python3-gi")
python3 -c 'import PIL' 2>/dev/null || missing+=("python3-pil")
# grep sem -q: com pipefail, o -q fecha o pipe cedo e o SIGPIPE vira falso negativo
ldconfig -p | grep 'libfuse.so.2' >/dev/null || missing+=("libfuse2")
if [ ${#missing[@]} -gt 0 ]; then
  fail "faltando: ${missing[*]}
  No Ubuntu: sudo apt install git curl unzip sassc x11-utils python3-gi python3-pil libfuse2 gnome-shell-extension-prefs"
fi
[ "${XDG_SESSION_TYPE:-}" = "x11" ] || say "aviso: sessão ${XDG_SESSION_TYPE:-?}; o widget só se posiciona direito no X11"
SHELL_MAJOR=$(gnome-shell --version | grep -oP '\d+' | head -1)
mkdir -p "$CACHE"

clone_at() { # url dir rev
  if [ ! -d "$2/.git" ]; then git clone -q "$1" "$2"; fi
  git -C "$2" fetch -q origin "$3" 2>/dev/null || git -C "$2" fetch -q origin
  git -C "$2" checkout -q --force "$3"
}

# o build do Colloid escreve em ~/.config/gtk-4.0: salva o estado original antes
"$HERE/apply.sh" --backup-only

# ── 1. tema GTK + Shell + libadwaita ──────────────────────────────────────
say "compilando o tema (Colloid + paleta Diff Dark)"
clone_at https://github.com/vinceliuice/Colloid-gtk-theme.git "$CACHE/Colloid-gtk-theme" "$COLLOID_GTK_REV"
cp "$HERE/theme/palette.scss" "$CACHE/Colloid-gtk-theme/src/sass/_color-palette-default.scss"
(cd "$CACHE/Colloid-gtk-theme" && ./install.sh -n Diff -t green -c dark --tweaks rimless -l fixed >/dev/null)
git -C "$CACHE/Colloid-gtk-theme" checkout -q -- src/sass/_color-palette-default.scss

# ── 2. ícones ─────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.local/share/icons/Colloid-Grey-Dark" ]; then
  say "instalando ícones Colloid (cinza)"
  clone_at https://github.com/vinceliuice/Colloid-icon-theme.git "$CACHE/Colloid-icon-theme" "$COLLOID_ICONS_REV"
  (cd "$CACHE/Colloid-icon-theme" && ./install.sh -t grey -s default >/dev/null)
fi

# ── 3. fontes ─────────────────────────────────────────────────────────────
if [ ! -f "$FONT_DIR/Inter-Regular.ttf" ] || [ ! -f "$FONT_DIR/JetBrainsMono-Regular.ttf" ]; then
  say "instalando fontes Inter e JetBrains Mono"
  mkdir -p "$FONT_DIR" "$CACHE/fonts"
  curl -fsSL -o "$CACHE/fonts/jbmono.zip" "$JBMONO_URL"
  curl -fsSL -o "$CACHE/fonts/inter.zip" "$INTER_URL"
  unzip -oq "$CACHE/fonts/jbmono.zip" -d "$CACHE/fonts/jbmono"
  unzip -oq "$CACHE/fonts/inter.zip" -d "$CACHE/fonts/inter"
  cp "$CACHE"/fonts/jbmono/fonts/ttf/JetBrainsMono-{Regular,Medium,Bold,Italic}.ttf "$FONT_DIR/"
  cp "$CACHE"/fonts/inter/extras/ttf/Inter-{Light,Regular,Italic,Medium,SemiBold,Bold}.ttf "$FONT_DIR/"
  fc-cache -f "$FONT_DIR" >/dev/null
fi

# ── 4. extensões do Shell ─────────────────────────────────────────────────
for uuid in "${EXTENSIONS[@]}"; do
  if gnome-extensions info "$uuid" >/dev/null 2>&1 || [ -d "$EXT_DIR/$uuid" ] || [ -d "/usr/share/gnome-shell/extensions/$uuid" ]; then
    continue
  fi
  say "baixando extensão $uuid (GNOME $SHELL_MAJOR)"
  url=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$SHELL_MAJOR" \
        | python3 -c 'import sys, json; print(json.load(sys.stdin)["download_url"])') \
    || fail "$uuid não tem versão para o GNOME $SHELL_MAJOR"
  curl -fsSL -o "$CACHE/$uuid.zip" "https://extensions.gnome.org$url"
  gnome-extensions install --force "$CACHE/$uuid.zip"
done

# ── 5. Conky ──────────────────────────────────────────────────────────────
if [ ! -x "$HOME/.local/bin/conky" ]; then
  say "baixando Conky (AppImage)"
  mkdir -p "$HOME/.local/bin"
  curl -fsSL -o "$HOME/.local/bin/conky" "$CONKY_URL"
  chmod +x "$HOME/.local/bin/conky"
fi

# ── 6. aplicar ────────────────────────────────────────────────────────────
"$HERE/apply.sh"

cat <<'MSG'

Extensões recém-instaladas só carregam depois de recarregar o Shell:
  X11:     Alt+F2, digite r, Enter
  Wayland: sair e entrar de novo na sessão
MSG
