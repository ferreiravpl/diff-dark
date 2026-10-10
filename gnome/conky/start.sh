#!/usr/bin/env bash
# Sobe o card de sistema do Diff-Dark no monitor principal.
export DIFF_KIT="$(cd "$(dirname "$0")/.." && pwd)"
CONKY="${CONKY:-$HOME/.local/bin/conky}"
pkill -f "$DIFF_KIT/conky/.*\.conf" 2>/dev/null
sleep "${1:-0}"
"$CONKY" -q -c "$DIFF_KIT/conky/stats.conf" >/dev/null 2>&1 &
python3 -I "$DIFF_KIT/conky/place.py" diff-dark-stats 330 214
