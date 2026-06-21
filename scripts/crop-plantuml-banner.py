"""Crop PlantUML yellow disclaimer strip from rendered PNG."""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image


def crop_banner(src: Path, dest: Path) -> int:
    img = Image.open(src).convert("RGB")
    w, h = img.size
    crop_top = 0
    for y in range(min(100, h)):
        row = img.crop((0, y, w, y + 1))
        colors = row.getcolors(maxcolors=99999) or []
        if not colors:
            continue
        total = sum(c[0] for c in colors)
        r = sum(c[0] * c[1][0] for c in colors) / total
        g = sum(c[0] * c[1][1] for c in colors) / total
        b = sum(c[0] * c[1][2] for c in colors) / total
        if g > 210 and r > 210 and b < 200:
            crop_top = y + 1
        elif crop_top > 10:
            break
    if crop_top < 5:
        crop_top = 42
    img.crop((0, crop_top, w, h)).save(dest, optimize=True)
    return crop_top


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: python crop-plantuml-banner.py <input.png> <output.png>")
        raise SystemExit(1)
    src, dest = Path(sys.argv[1]), Path(sys.argv[2])
    n = crop_banner(src, dest)
    print(f"Cropped {n}px -> {dest}")


if __name__ == "__main__":
    main()
