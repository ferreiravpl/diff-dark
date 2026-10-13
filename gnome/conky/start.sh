#!/usr/bin/env bash
# Sobe o card de sistema do Diff-Dark no monitor principal.
export DIFF_KIT="$(cd "$(dirname "$0")/.." && pwd)"
CONKY="${CONKY:-$HOME/.local/bin/conky}"

# card de cota de IA (opcional): só com o ai-usagebar instalado. O autostart não tem
# ~/.cargo/bin no PATH, daí o caminho de fallback.
AI_BIN="${AI_USAGEBAR:-$(command -v ai-usagebar || echo "$HOME/.cargo/bin/ai-usagebar")}"
HEIGHT=214
if [ -x "$AI_BIN" ]; then export AI_USAGEBAR="$AI_BIN"; HEIGHT=330; else export AI_USAGEBAR=; fi

pkill -f "$DIFF_KIT/conky/.*\.conf" 2>/dev/null
sleep "${1:-0}"
"$CONKY" -q -c "$DIFF_KIT/conky/stats.conf" >/dev/null 2>&1 &
python3 -I "$DIFF_KIT/conky/place.py" diff-dark-stats 330 "$HEIGHT"
