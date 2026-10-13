"""Coloca o card do Diff-Dark no canto superior direito do monitor principal.
Uso: place.py <título> <largura> <altura>

Com alignment 'none' o Conky não posiciona nem dimensiona a janela (ela nasce
com poucos pixels), então os dois ficam a cargo deste script."""
import re, subprocess, sys, time
import gi
gi.require_version("Gdk", "3.0")
gi.require_version("GdkX11", "3.0")
from gi.repository import Gdk, GdkX11

TITLE = sys.argv[1]
WIDTH, HEIGHT = int(sys.argv[2]), int(sys.argv[3])
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


def target(width):
    display = Gdk.Display.get_default()
    mon = display.get_primary_monitor() or display.get_monitor(0)
    wa = mon.get_workarea()  # já desconta a barra do topo
    return (wa.x + wa.width - (width - CARD_INSET_X) - GAP,
            wa.y + GAP - CARD_INSET_Y)


def geometry():
    out = subprocess.run(["xwininfo", "-name", TITLE], capture_output=True, text=True).stdout
    nums = [re.search(rf"{k}:\s+(-?\d+)", out) for k in ("Absolute upper-left X", "Absolute upper-left Y", "Width", "Height")]
    return tuple(int(m.group(1)) for m in nums) if all(nums) else None


# o Conky ainda acerta a própria janela logo depois de criá-la: reaplica até a
# posição se manter por duas leituras seguidas
wid = window_id()
want = (*target(WIDTH), WIDTH, HEIGHT)
display = Gdk.Display.get_default()
win = GdkX11.X11Window.foreign_new_for_display(display, wid)
stable = 0
for _ in range(40):
    if geometry() == want:
        stable += 1
        if stable == 2:
            break
    else:
        stable = 0
        win.move_resize(*want)
        display.sync()
    time.sleep(0.25)
