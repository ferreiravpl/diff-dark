"""Gera o wallpaper padrão do Diff Dark: cumes em camadas de cinza com névoa e
um disco claro sálvia-acinzentado. Procedural, sem imagem de terceiros.

Uso: python3 generate.py <saída.jpg> [largura altura]
"""
import random
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter

OUT = sys.argv[1]
W, H = (int(sys.argv[2]), int(sys.argv[3])) if len(sys.argv) > 3 else (3840, 2160)
SEED = 11

SKY_TOP, SKY_BOTTOM = (13, 15, 14), (30, 34, 32)
DISC = (178, 190, 182)
# camadas do fundo para a frente: (altura base, amplitude, cor, desfoque)
RIDGES = [
    (0.58, 0.14, (44, 49, 47), 6),
    (0.67, 0.16, (33, 37, 35), 3),
    (0.77, 0.13, (22, 25, 24), 1.5),
    (0.89, 0.09, (12, 14, 13), 0),
]


def ridge(rng, base, amp, points=513):
    """Midpoint displacement: perfil de cume suave e irregular."""
    ys = [0.0] * points
    ys[0], ys[-1] = rng.uniform(-1, 1), rng.uniform(-1, 1)
    step, scale = points - 1, 1.0
    while step > 1:
        half = step // 2
        for i in range(half, points - 1, step):
            ys[i] = (ys[i - half] + ys[i + half]) / 2 + rng.uniform(-1, 1) * scale
        step, scale = half, scale * 0.55
    lo, hi = min(ys), max(ys)
    return [(i / (points - 1) * W, (base - amp * ((y - lo) / (hi - lo) - 0.5)) * H) for i, y in enumerate(ys)]


def main():
    rng = random.Random(SEED)

    sky = Image.new("RGB", (1, H))
    for y in range(H):
        t = y / (H - 1)
        sky.putpixel((0, y), tuple(round(a + (b - a) * t) for a, b in zip(SKY_TOP, SKY_BOTTOM)))
    img = sky.resize((W, H))

    # disco com halo
    cx, cy, r = W * 0.68, H * 0.34, H * 0.095
    glow = Image.new("L", (W, H), 0)
    ImageDraw.Draw(glow).ellipse((cx - r * 2.6, cy - r * 2.6, cx + r * 2.6, cy + r * 2.6), fill=40)
    glow = glow.filter(ImageFilter.GaussianBlur(r * 1.2))
    img = Image.composite(Image.new("RGB", (W, H), (143, 179, 157)), img, glow)
    disc = Image.new("L", (W, H), 0)
    ImageDraw.Draw(disc).ellipse((cx - r, cy - r, cx + r, cy + r), fill=235)
    img = Image.composite(Image.new("RGB", (W, H), DISC), img, disc.filter(ImageFilter.GaussianBlur(1.5)))

    for base, amp, color, blur in RIDGES:
        mask = Image.new("L", (W, H), 0)
        ImageDraw.Draw(mask).polygon(ridge(rng, base, amp) + [(W, H), (0, H)], fill=255)
        if blur:
            mask = mask.filter(ImageFilter.GaussianBlur(blur))
        img = Image.composite(Image.new("RGB", (W, H), color), img, mask)
        # névoa logo acima de cada camada
        haze = mask.filter(ImageFilter.GaussianBlur(H * 0.04)).point(lambda v: min(v, 60))
        img = Image.composite(Image.new("RGB", (W, H), (58, 64, 61)), img, ImageChops.subtract(haze, mask))

    noise = Image.effect_noise((W, H), 24).convert("RGB")
    img = ImageChops.blend(img, ImageChops.overlay(img, noise), 0.07)
    img.save(OUT, quality=94)


if __name__ == "__main__":
    main()
