"""Gradua um wallpaper para a paleta Diff-Dark: quase sem cor, escurecido,
com um véu sálvia bem leve nas sombras e grão fino."""
import sys
from PIL import Image, ImageEnhance, ImageFilter, ImageChops
import random

def grade(src, dst, size=(3440, 1440), sat=0.12, bright=0.72, tint=(143, 179, 157), tint_amt=0.07, blur=0.0):
    im = Image.open(src).convert("RGB")
    # crop-to-fill
    w, h = im.size; tw, th = size
    s = max(tw / w, th / h)
    im = im.resize((round(w * s), round(h * s)), Image.LANCZOS)
    l = (im.width - tw) // 2; t = (im.height - th) // 2
    im = im.crop((l, t, l + tw, t + th))
    im = ImageEnhance.Color(im).enhance(sat)
    im = ImageEnhance.Brightness(im).enhance(bright)
    im = ImageEnhance.Contrast(im).enhance(0.92)
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    # véu sálvia, mais forte nas sombras
    lum = im.convert("L").point(lambda v: int(255 * (1 - v / 255) * tint_amt * 4) if tint_amt else 0)
    veil = Image.new("RGB", im.size, tint)
    im = Image.composite(veil, im, lum.point(lambda v: min(v, int(255 * tint_amt * 2.5))))
    # grão
    random.seed(7)
    noise = Image.effect_noise(im.size, 18).convert("RGB")
    im = ImageChops.blend(im, ImageChops.overlay(im, noise), 0.06)
    im.save(dst, quality=94)

if __name__ == "__main__":
    grade(sys.argv[1], sys.argv[2], blur=float(sys.argv[3]) if len(sys.argv) > 3 else 0.0)
