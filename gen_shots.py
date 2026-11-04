#!/usr/bin/env python3
"""Generate Shooting Stars sprites: glowing shot orbs (Hot=red / Cool=blue /
White=neutral) for levels 1-11, plus a starfield background.
Run: python3 gen_stars.py  (writes into assets/images/)"""
import math, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = "/home/hatch/workspace/shooting-stars-godot"
RADII = [19, 25, 31, 38, 45, 53, 61, 71, 80, 91, 102]  # ids 0..10 = levels 1..11
PAD = 10
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

TYPES = {
    "hot":   ((255, 220, 212), (255, 90, 78), (184, 48, 36)),
    "cool":  ((216, 236, 255), (58, 160, 255), (22, 99, 184)),
    "white": ((255, 255, 255), (232, 236, 244), (154, 163, 181)),
}

def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def grad_color(tint, base, shade, t):
    # t: 0 at centre -> 1 at rim
    if t < 0.45:
        return lerp(tint, base, t / 0.45)
    return lerp(base, shade, (t - 0.45) / 0.55)

def make_star(kind_name, tint, base, shade, lvl, r):
    S = 2 * (r + PAD)
    c = S / 2.0
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # glow
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([c - r - 6, c - r - 6, c + r + 6, c + r + 6], fill=base + (90,))
    img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(7)))
    # orb: concentric circles, light centre offset up-left
    d = ImageDraw.Draw(img)
    lx, ly = c - r * 0.18, c - r * 0.20
    steps = 48
    for i in range(steps, 0, -1):
        rr = r * i / steps
        col = grad_color(tint, base, shade, i / steps)
        d.ellipse([lx - rr, ly - rr, lx + rr, ly + rr], fill=col + (255,))
    # clip to true circle (offset circles can overhang on the far side)
    mask = Image.new("L", (S, S), 0)
    md = ImageDraw.Draw(mask)
    md.ellipse([c - r, c - r, c + r, c + r], fill=255)
    img.putalpha(Image.composite(img.getchannel("A"), Image.new("L", (S, S), 0), mask))
    d = ImageDraw.Draw(img)
    d.ellipse([c - r, c - r, c + r, c + r], outline=(10, 12, 24, 160), width=2)
    # sparkle heart (four-point), upper centre
    s = r * 0.36
    sx, sy = c, c - r * 0.28
    pts = [(sx, sy - s), (sx + s * 0.22, sy - s * 0.22), (sx + s, sy),
           (sx + s * 0.22, sy + s * 0.22), (sx, sy + s),
           (sx - s * 0.22, sy + s * 0.22), (sx - s, sy),
           (sx - s * 0.22, sy - s * 0.22)]
    d.polygon(pts, fill=(255, 255, 255, 235))
    # level number, lower centre
    fs = max(10, int(r * 0.62))
    font = ImageFont.truetype(FONT, fs)
    txt = str(lvl + 1)
    box = d.textbbox((0, 0), txt, font=font)
    tw, th = box[2] - box[0], box[3] - box[1]
    d.text((c - tw / 2 - box[0], c + r * 0.38 - th / 2 - box[1]), txt,
           font=font, fill=(16, 19, 28, 255))
    out = f"{ROOT}/assets/images/shots/{kind_name}_{lvl}.png"
    img.save(out)
    return out

def make_bg():
    W, H = 1152, 648
    img = Image.new("RGB", (W, H), (6, 10, 24))
    d = ImageDraw.Draw(img, "RGBA")
    for y in range(H):
        t = y / H
        col = lerp((6, 10, 24), (13, 20, 48), t)
        d.line([(0, y), (W, y)], fill=col)
    neb = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    nd = ImageDraw.Draw(neb)
    nd.ellipse([120, 60, 520, 340], fill=(106, 61, 240, 42))
    nd.ellipse([700, 300, 1120, 600], fill=(28, 111, 196, 40))
    nd.ellipse([430, 380, 760, 620], fill=(255, 90, 78, 22))
    img.paste(Image.alpha_composite(img.convert("RGBA"), neb.filter(ImageFilter.GaussianBlur(60))).convert("RGB"), (0, 0))
    d = ImageDraw.Draw(img, "RGBA")
    rng = random.Random(7)
    for _ in range(280):
        x, y = rng.uniform(0, W), rng.uniform(0, H)
        r = rng.choice([1, 1, 1, 2, 2, 3])
        a = rng.randint(70, 230)
        tint = rng.choice([(255, 255, 255), (200, 220, 255), (255, 230, 200)])
        d.ellipse([x - r, y - r, x + r, y + r], fill=tint + (a,))
    img.save(f"{ROOT}/assets/images/bg.png")

if __name__ == "__main__":
    import os
    os.makedirs(f"{ROOT}/assets/images/shots", exist_ok=True)
    for name, (tint, base, shade) in TYPES.items():
        for lvl, r in enumerate(RADII):
            make_star(name, tint, base, shade, lvl, r)
    make_bg()
    print("shots + bg generated")
