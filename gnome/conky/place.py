"""Coloca o card do Diff-Dark na última posição salva ou, sem ela, no canto
superior direito do monitor principal. Uso: place.py <título> <largura> <altura>

Com alignment 'none' o Conky não posiciona nem dimensiona a janela (ela nasce
com poucos pixels), então os dois ficam a cargo deste script."""
import os, re, subprocess, sys, time
import gi
gi.require_version("Gdk", "3.0")
gi.require_version("GdkX11", "3.0")
from gi.repository import Gdk, GdkX11

TITLE = sys.argv[1]
WIDTH, HEIGHT = int(sys.argv[2]), int(sys.argv[3])
POS_FILE = os.path.expanduser("~/.local/share/diff-dark/stats-pos")
GAP = 24          # distância visível do card até a borda do monitor e até a barra do topo
CARD_INSET_X = 20  # o card é desenhado a 20px da lateral da janela (diff.lua)
CARD_INSET_Y = 1


def window_id():
    for _ in range(50):
        out = subprocess.run(["xwininfo", "-name", TITLE], capture_output=True, text=True).stdout
        m = re.search(r"Window id: (0x[0-9a-f]+)", out)
        if m:
            return int(m.group(1), 16)
        time.sleep(0.2)
    sys.exit(f"janela {TITLE!r} não apareceu")


def on_some_monitor(display, x, y):
    for i in range(display.get_n_monitors()):
        g = display.get_monitor(i).get_geometry()
        if g.x <= x < g.x + g.width and g.y <= y < g.y + g.height:
            return True
    return False


def target(width):
    display = Gdk.Display.get_default()
    try:
        x, y = (int(v) for v in open(POS_FILE).read().split()[:2])
        if on_some_monitor(display, x, y):  # monitor pode ter saído (notebook desencaixado)
            return x, y
    except (OSError, ValueError):
        pass
    mon = display.get_primary_monitor() or display.get_monitor(0)
    wa = mon.get_workarea()  # já desconta a barra do topo
    return (wa.x + wa.width - (width - CARD_INSET_X) - GAP,
            wa.y + GAP - CARD_INSET_Y)


wid = window_id()
x, y = target(WIDTH)
display = Gdk.Display.get_default()
GdkX11.X11Window.foreign_new_for_display(display, wid).move_resize(x, y, WIDTH, HEIGHT)
display.sync()
