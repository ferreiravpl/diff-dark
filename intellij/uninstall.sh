#!/usr/bin/env bash
# Diff Dark (IntelliJ) — remove o plugin de tema. Mesmos argumentos do install.sh:
#   ./uninstall.sh                   IDE aberto
#   ./uninstall.sh /opt/idea-IU-...  esse IDE
exec "$(cd "$(dirname "$0")" && pwd)/install.sh" --uninstall "$@"
