#!/usr/bin/env bash
# Diff Dark (IntelliJ) — gera o plugin de tema a partir do IDE instalado e coloca
# no diretório de plugins do perfil dele. Não depende da parte GNOME.
#
#   ./install.sh                     detecta o IDE aberto
#   ./install.sh /opt/idea-IU-...    usa esse IDE (pode estar fechado)
#   ./install.sh --uninstall [IDE]   remove o plugin
#
# Requer IntelliJ IDEA (ou outro IDE JetBrains) 2025.3+ no Linux e python3.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
JAR_NAME="diff-dark-theme.jar"

UNINSTALL=false
if [ "${1:-}" = "--uninstall" ]; then UNINSTALL=true; shift; fi
IDE="${1:-}"

# IDE aberto: diretório e perfil vêm da linha de comando do processo
PID=$(pgrep -f 'jbr/bin/java.*com.intellij.idea.Main' | head -1 || true)
FROM_PID=false
if [ -z "$IDE" ] && [ -n "$PID" ]; then
  FROM_PID=true
  IDE=$(tr '\0' '\n' < "/proc/$PID/cmdline" | grep -m1 -oP '^-Didea\.home\.path=\K.*' || true)
  [ -z "$IDE" ] && IDE=$(dirname "$(dirname "$(dirname "$(readlink -f "/proc/$PID/exe")")")")
fi
if [ -z "$IDE" ] || [ ! -d "$IDE/lib" ]; then
  echo "IDE não encontrado. Abra o IntelliJ ou passe o diretório de instalação, por exemplo:"
  ls -d /opt/*idea* "$HOME"/.local/share/JetBrains/Toolbox/apps/*/ 2>/dev/null | sed 's/^/  .\/install.sh /' || true
  exit 1
fi

# o perfil (ex.: IntelliJIdea2026.2) é o que define a pasta de plugins
profile_from_build() { # IU-253.29346.138 → IntelliJIdea2025.3
  local code=${1%%-*} build=${1#*-}; build=${build%%.*}
  local name
  case "$code" in
    IU) name=IntelliJIdea ;; IC) name=IdeaIC ;; WS) name=WebStorm ;; PY) name=PyCharm ;;
    PC) name=PyCharmCE ;; GO) name=GoLand ;; CL) name=CLion ;; PS) name=PhpStorm ;;
    RM) name=RubyMine ;; DB) name=DataGrip ;; RD) name=Rider ;; *) return 1 ;;
  esac
  echo "${name}20${build:0:2}.${build:2:1}"
}
if [ -f "$IDE/product-info.json" ]; then
  PROFILE=$(python3 -I -c 'import json, sys; print(json.load(open(sys.argv[1]))["dataDirectoryName"])' "$IDE/product-info.json")
else
  PROFILE=$(profile_from_build "$(cat "$IDE/build.txt")") || { echo "não reconheci o IDE em $IDE"; exit 1; }
fi
if $FROM_PID; then  # o processo pode rodar com outro perfil (-Didea.paths.selector)
  RUNNING=$(tr '\0' '\n' < "/proc/$PID/cmdline" | grep -m1 -oP '^-Didea\.paths\.selector=\K.*' || true)
  PROFILE="${RUNNING:-$PROFILE}"
fi
PLUGINS="$HOME/.local/share/JetBrains/$PROFILE"

if $UNINSTALL; then
  rm -f "$PLUGINS/$JAR_NAME"
  echo "removido de $PLUGINS. Reinicie o IDE (ele volta para o tema padrão)."
  exit 0
fi

mkdir -p "$PLUGINS"
python3 -I "$HERE/build.py" "$IDE" "$PLUGINS/$JAR_NAME"
echo "instalado em $PLUGINS"
echo "Reinicie o IDE e escolha em Settings › Appearance › Theme: Diff Dark"
