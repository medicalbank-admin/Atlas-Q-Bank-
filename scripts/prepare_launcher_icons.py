#!/usr/bin/env python3
"""Build web/PWA icons from the academy's supplied launcher foreground artwork."""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/icons"
FOREGROUND = OUT / "atlas_launcher_foreground.png"
ICON = OUT / "atlas_launcher_icon.png"
WEB = ROOT / "web"
WEB_ICONS = WEB / "icons"

if not FOREGROUND.is_file():
    raise SystemExit(f"Missing supplied launcher artwork: {FOREGROUND}")

# Use the supplied Atlas launcher foreground exactly; only add the branded
# launcher background behind its transparent pixels to make a full app icon.
foreground = Image.open(FOREGROUND).convert("RGBA")
if foreground.size != (1024, 1024):
    foreground = foreground.resize((1024, 1024), Image.Resampling.LANCZOS)

background = Image.new("RGBA", (1024, 1024), (11, 31, 58, 255))
pixels = background.load()
for y in range(1024):
    t = y / 1023
    color = (int(11 + 8 * t), int(31 + 31 * t), int(58 + 57 * t), 255)
    for x in range(1024):
        pixels[x, y] = color
background.alpha_composite(foreground)
background.convert("RGB").save(ICON, format="PNG", optimize=True)

WEB_ICONS.mkdir(parents=True, exist_ok=True)
for size, filename in [
    (192, "Icon-192.png"),
    (512, "Icon-512.png"),
    (192, "Icon-maskable-192.png"),
    (512, "Icon-maskable-512.png"),
]:
    background.resize((size, size), Image.Resampling.LANCZOS).save(
        WEB_ICONS / filename, format="PNG", optimize=True
    )

background.resize((64, 64), Image.Resampling.LANCZOS).save(
    WEB / "favicon.png", format="PNG", optimize=True
)

print("Website and PWA icons built from assets/icons/atlas_launcher_foreground.png.")
