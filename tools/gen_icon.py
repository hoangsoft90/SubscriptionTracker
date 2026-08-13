#!/usr/bin/env python3
"""Generates the SubTrack app icon.

Design (Material 3 teal seed #00696D, "calm financial awareness"):
- diagonal gradient teal background (full-bleed, safe for adaptive masking)
- a large coin with a check mark — "track subscriptions, keep your money"
- two soft list bars under the coin (subscription list)

Draws at 1024x1024 (supersampled) and downsamples for anti-aliasing, then
writes icon.png (512) + every Android mipmap density.
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
OUT_ROOT = os.path.join(os.path.dirname(__file__), "..")


def lerp(a, b, t):
    return a + (b - a) * t


def gradient(size, c1, c2):
    """Diagonal gradient image from top-left c1 to bottom-right c2."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            px[x, y] = (
                int(lerp(c1[0], c2[0], t)),
                int(lerp(c1[1], c2[1], t)),
                int(lerp(c1[2], c2[2], t)),
            )
    return img


def rounded_rect(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def main():
    img = gradient(SIZE, (0, 122, 128), (0, 60, 66))  # #007A80 -> #003C42
    draw = ImageDraw.Draw(img)

    cx, cy = SIZE / 2, SIZE / 2

    # --- soft ambient glow behind the coin --------------------------------
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse(
        [cx - 300, cy - 290, cx + 300, cy + 290],
        fill=(255, 255, 255, 26),
    )
    img = Image.alpha_composite(img.convert("RGBA"), glow)
    draw = ImageDraw.Draw(img)

    # --- coin --------------------------------------------------------------
    coin_box = [cx - 225, cy - 225, cx + 225, cy + 225]
    draw.ellipse(coin_box, fill=(255, 255, 255, 255))
    # subtle inner ring for depth
    ring = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse(
        [cx - 190, cy - 190, cx + 190, cy + 190],
        outline=(0, 60, 66, 60),
        width=14,
    )
    img = Image.alpha_composite(img, ring)
    draw = ImageDraw.Draw(img)

    # --- check mark --------------------------------------------------------
    # Bold check inside the coin, drawn as thick polylines.
    check = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    cd = ImageDraw.Draw(check)
    pts = [
        (cx - 120, cy + 5),
        (cx - 35, cy + 95),
        (cx + 125, cy - 90),
    ]
    cd.line(pts, fill=(0, 105, 109, 255), width=72, joint="curve")
    # round the joins by drawing circles at each vertex
    for p in pts:
        cd.ellipse(
            [p[0] - 36, p[1] - 36, p[0] + 36, p[1] + 36],
            fill=(0, 105, 109, 255),
        )
    img = Image.alpha_composite(img, check)
    draw = ImageDraw.Draw(img)

    # --- two soft list bars under the coin (subscription list) ------------
    bar_w, bar_h, gap = 330, 34, 26
    x0 = cx - bar_w / 2
    for i, (bx, by) in enumerate(
        [(x0, cy + 300), (x0, cy + 300 + bar_h + gap)]
    ):
        bar = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        bd = ImageDraw.Draw(bar)
        rounded_rect(
            bd,
            [bx, by, bx + bar_w, by + bar_h],
            radius=17,
            fill=(255, 255, 255, 90 if i == 0 else 55),
        )
        img = Image.alpha_composite(img, bar)
        draw = ImageDraw.Draw(img)

    img = img.convert("RGB")

    # --- write outputs ------------------------------------------------------
    out = os.path.abspath(OUT_ROOT)
    img.resize((512, 512), Image.LANCZOS).save(os.path.join(out, "icon.png"))
    mipmaps = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, px in mipmaps.items():
        path = os.path.join(
            out, "android", "app", "src", "main", "res", folder, "ic_launcher.png"
        )
        img.resize((px, px), Image.LANCZOS).save(path)
    print("wrote icon.png + mipmaps")


if __name__ == "__main__":
    sys.exit(main())
