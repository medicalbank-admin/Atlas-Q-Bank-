#!/usr/bin/env python3
"""Render the text-free Atlas book/emblem SVG into launcher icon source PNGs."""
from pathlib import Path

import cairosvg
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "assets/logo/atlas_academy_logo.svg"
OUT = ROOT / "assets/icons"
OUT.mkdir(parents=True, exist_ok=True)

rendered = OUT / "_atlas_emblem_render.png"
cairosvg.svg2png(url=str(SVG), write_to=str(rendered), output_width=1024, output_height=1024)

emblem = Image.open(rendered).convert("RGBA")
alpha = emblem.getchannel("A")
bbox = alpha.getbbox()
if bbox is None:
    raise SystemExit("The Atlas emblem SVG rendered as an empty image.")
emblem = emblem.crop(bbox)
emblem.thumbnail((850, 850), Image.Resampling.LANCZOS)

foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
foreground.alpha_composite(emblem, ((1024 - emblem.width) // 2, (1024 - emblem.height) // 2))
foreground_path = OUT / "atlas_launcher_foreground.png"\nif not foreground_path.exists():\n    foreground.save(foreground_path)

# A subtle navy-to-blue background keeps the book/emblem legible at small sizes.
icon_path = OUT / "atlas_launcher_icon.png"\nif not icon_path.exists():\n    background = Image.new("RGBA", (1024, 1024), (11, 31, 58, 255))
pixels = background.load()
for y in range(1024):
    t = y / 1023
    color = (
        int(11 + 8 * t),
        int(31 + 31 * t),
        int(58 + 57 * t),
        255,
    )
    for x in range(1024):
        pixels[x, y] = color
background.alpha_composite(foreground)
background.convert("RGB").save(OUT / "atlas_launcher_icon.png", quality=95)
rendered.unlink(missing_ok=True)
print("Prepared launcher icon artwork; existing user-supplied PNG files are preserved.")
