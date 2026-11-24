#!/usr/bin/env python3
"""Prepare text-free Atlas launcher artwork, preserving supplied PNGs."""
from pathlib import Path

import cairosvg
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "assets/logo/atlas_academy_logo.svg"
OUT = ROOT / "assets/icons"
OUT.mkdir(parents=True, exist_ok=True)

icon_path = OUT / "atlas_launcher_icon.png"
foreground_path = OUT / "atlas_launcher_foreground.png"

# Only create artwork that the academy has not supplied itself.
if not icon_path.exists() or not foreground_path.exists():
    rendered = OUT / "_atlas_emblem_render.png"
    cairosvg.svg2png(
        url=str(SVG), write_to=str(rendered),
        output_width=1024, output_height=1024,
    )
    emblem = Image.open(rendered).convert("RGBA")
    bbox = emblem.getchannel("A").getbbox()
    if bbox is None:
        raise SystemExit("The Atlas emblem SVG rendered as an empty image.")
    emblem = emblem.crop(bbox)
    emblem.thumbnail((850, 850), Image.Resampling.LANCZOS)

    foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    foreground.alpha_composite(
        emblem, ((1024 - emblem.width) // 2, (1024 - emblem.height) // 2)
    )
    if not foreground_path.exists():
        foreground.save(foreground_path)

    if not icon_path.exists():
        background = Image.new("RGBA", (1024, 1024), (11, 31, 58, 255))
        pixels = background.load()
        for y in range(1024):
            t = y / 1023
            color = (
                int(11 + 8 * t), int(31 + 31 * t),
                int(58 + 57 * t), 255,
            )
            for x in range(1024):
                pixels[x, y] = color
        background.alpha_composite(foreground)
        background.convert("RGB").save(icon_path, quality=95)
    rendered.unlink(missing_ok=True)

print("Launcher artwork ready; custom uploaded PNGs are preserved.")

# The Android app's actual launcher artwork is the source of truth.
# Copy that exact image into the web/PWA icon set (only resize to required dimensions).
android_launcher = ROOT / "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"
web_dir = ROOT / "web"
web_icons = web_dir / "icons"
web_icons.mkdir(parents=True, exist_ok=True)

launcher_icon = Image.open(android_launcher).convert("RGBA")
for size, filename in [
    (192, "Icon-192.png"),
    (512, "Icon-512.png"),
    (192, "Icon-maskable-192.png"),
    (512, "Icon-maskable-512.png"),
]:
    launcher_icon.resize((size, size), Image.Resampling.LANCZOS).save(
        web_icons / filename, format="PNG", optimize=True
    )

launcher_icon.resize((64, 64), Image.Resampling.LANCZOS).save(
    web_dir / "favicon.png", format="PNG", optimize=True
)
print("Website and PWA icons now use the exact Android mipmap launcher artwork.")
