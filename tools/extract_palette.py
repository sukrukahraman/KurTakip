#!/usr/bin/env python3
"""Propose color tokens from UI screenshots (PNG/JPG) for :core:designsystem.

Usage: extract_palette.py design/screens/*.png [--top 12]
Needs Pillow (pip3 install --user pillow). Output: JSON with the dominant colors across all
images, each with frequency, luminance, saturation and a suggested Material 3 role.
The roles are a starting point only — confirm them visually against the screenshots.
"""
import argparse
import colorsys
import json
import sys
from collections import Counter

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow missing: pip3 install --user pillow")

QUANT = 8  # bucket size per channel; merges anti-aliasing noise


def quantize(rgb):
    return tuple(min(255, (c // QUANT) * QUANT + QUANT // 2) for c in rgb)


def describe(rgb):
    r, g, b = (c / 255.0 for c in rgb)
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    lum = 0.2126 * r + 0.7152 * g + 0.0722 * b
    return {"hex": "#%02X%02X%02X" % rgb, "luminance": round(lum, 3), "saturation": round(s, 3), "hue": round(h * 360)}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("images", nargs="+")
    ap.add_argument("--top", type=int, default=12)
    args = ap.parse_args()

    counts = Counter()
    for path in args.images:
        img = Image.open(path).convert("RGB")
        img.thumbnail((400, 400))
        counts.update(quantize(px) for px in img.getdata())

    total = sum(counts.values())
    colors = []
    for rgb, n in counts.most_common(args.top * 4):
        d = describe(rgb)
        d["share"] = round(n / total, 4)
        colors.append(d)
    # drop near-duplicates (same hue family and close luminance)
    picked = []
    for c in colors:
        if all(abs(c["luminance"] - p["luminance"]) > 0.04 or abs(c["hue"] - p["hue"]) > 12 for p in picked):
            picked.append(c)
        if len(picked) == args.top:
            break

    roles = {}
    by_share = sorted(picked, key=lambda c: -c["share"])
    if by_share:
        roles["background/surface"] = by_share[0]["hex"]
        dark_bg = by_share[0]["luminance"] < 0.5
        text = [c for c in picked if (c["luminance"] > 0.8) == dark_bg and c["saturation"] < 0.2]
        if text:
            roles["onSurface (text)"] = text[0]["hex"]
    accents = sorted([c for c in picked if c["saturation"] > 0.35 and 0.15 < c["luminance"] < 0.85], key=lambda c: -c["share"])
    for role, c in zip(["primary", "secondary", "tertiary"], accents):
        roles[role] = c["hex"]
    errors = [c for c in picked if 340 <= c["hue"] or c["hue"] <= 10]
    if errors and errors[0]["saturation"] > 0.5:
        roles["error (guess)"] = errors[0]["hex"]

    print(json.dumps({"images": args.images, "suggested_roles": roles, "palette": picked}, indent=2))


if __name__ == "__main__":
    main()
