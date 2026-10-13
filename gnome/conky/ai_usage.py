"""Lê a cota de uso de IA do `ai-usagebar` e grava um resumo que o diff.lua desenha
embaixo do card de sistema. Roda em segundo plano (o diff.lua chama a cada 2 min),
porque a consulta pode ir à rede e o Conky não pode travar esperando.

Saída em ~/.cache/diff-dark/ai-usage.tsv, uma linha por campo, separada por tab:
    provider  <nome>
    session   <percent>  <reset_epoch>  <window_secs>
    week      <percent>  <reset_epoch>  <window_secs>
Sem o binário ou sem dados, o arquivo é apagado e o card some."""
import json, os, re, subprocess, sys
from datetime import datetime

BIN = os.environ.get("AI_USAGEBAR", "")
OUT = os.path.expanduser("~/.cache/diff-dark/ai-usage.tsv")


def drop():
    try:
        os.remove(OUT)
    except FileNotFoundError:
        pass
    sys.exit(0)


if not (BIN and os.access(BIN, os.X_OK)):
    drop()
try:
    raw = subprocess.run([BIN, "usage", "--json"], capture_output=True, text=True, timeout=30).stdout
    entries = json.loads(raw).get("entries", [])
except (OSError, subprocess.TimeoutExpired, ValueError):
    sys.exit(0)  # falha passageira (rede): mantém o último resumo

entry = next((e for e in entries if e.get("metrics")), None)
if not entry:
    drop()

lines = [f"provider\t{entry.get('display_name', 'IA')}"]
for m in entry["metrics"]:
    label = m.get("label", "")
    kind = "week" if re.search(r"week|7d", label, re.I) else \
           "session" if re.search(r"5h|session", label, re.I) else None
    if not kind or m.get("percent") is None:
        continue
    try:
        reset = int(datetime.fromisoformat(m["reset_at"].replace("Z", "+00:00")).timestamp())
    except (KeyError, ValueError):
        reset = 0
    lines.append(f"{kind}\t{m['percent']}\t{reset}\t{m.get('window_secs', 0)}")

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT + ".tmp", "w") as f:
    f.write("\n".join(lines) + "\n")
os.replace(OUT + ".tmp", OUT)
