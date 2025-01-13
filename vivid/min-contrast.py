#!/usr/bin/env -S uv run --quiet
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "scikit-image",
# ]
# ///

import sys
import json
import numpy as np
from skimage import color

##############################################################################
# 1) Utilities
##############################################################################

def rgb01_to_hex(r, g, b):
    """
    Convert (r, g, b) in [0..1] to #RRGGBB.
    """
    return "#{:02X}{:02X}{:02X}".format(
        int(round(r * 255)),
        int(round(g * 255)),
        int(round(b * 255))
    )

def hex_to_rgb01(h):
    """
    Convert #RRGGBB to (r, g, b) in [0..1].
    """
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) / 255.0 for i in (0, 2, 4))

def ciede2000_distance(lab1, lab2):
    """
    Return the CIEDE2000 color difference between two Lab colors.
    Each labX is a 1D array [L, a, b].
    skimage.color.deltaE_ciede2000 requires shape (M, N, 3).
    """
    lab1_3d = lab1[np.newaxis, np.newaxis, :]
    lab2_3d = lab2[np.newaxis, np.newaxis, :]
    return color.deltaE_ciede2000(lab1_3d, lab2_3d)[0, 0]

##############################################################################
# 2) The "Preserve Hue" function in LCh, adapted to ensure distance from BG
##############################################################################

def ensure_min_ciede2000_distance_preserve_hue_to_bg(
    fg_rgb,
    bg_rgb,
    min_dist=40.0
):
    """
    Given:
      - fg_rgb = (r, g, b) in [0..1], the foreground color
      - bg_rgb = (r, g, b) in [0..1], the background color
      - min_dist (float), the minimum CIEDE2000 distance required

    Returns:
      A new (r, g, b) for the foreground that preserves hue
      but ensures ciede2000_distance >= min_dist from bg_rgb,
      by darkening the foreground if needed.
    """

    # Convert the background to Lab
    bg_lab = color.rgb2lab(np.array([[[bg_rgb[0], bg_rgb[1], bg_rgb[2]]]]))[0, 0]

    # Convert the FG to Lab
    fg_lab = color.rgb2lab(np.array([[[fg_rgb[0], fg_rgb[1], fg_rgb[2]]]]))[0, 0]

    # Check current distance
    dist = ciede2000_distance(fg_lab, bg_lab)
    if dist >= min_dist:
        # Already far enough; leave as-is
        return fg_rgb

    # Convert Lab -> LCh
    lch_color = color.lab2lch(fg_lab[np.newaxis, np.newaxis, :])[0, 0]
    L0, C0, H0 = lch_color  # L, C, H

    # We'll binary-search L in [0..L0], so we can only darken.
    # If you'd prefer to lighten, you'd do [L0..100], or a more
    # advanced approach deciding which direction to go.
    def distance_for_L(L_test):
        L_test = np.clip(L_test, 0.0, 100.0)
        test_lch = np.array([L_test, C0, H0])
        test_lab = color.lch2lab(test_lch[np.newaxis, np.newaxis, :])[0, 0]
        d = ciede2000_distance(test_lab, bg_lab)
        return d, test_lab

    low, high = 0.0, L0
    best_lab = fg_lab

    for _ in range(25):  # 25 binary search iterations
        mid = (low + high) / 2
        dmid, candidate_lab = distance_for_L(mid)
        if dmid < min_dist:
            # Still too close to background => go darker
            high = mid
        else:
            # This candidate is valid => record it, try going lighter
            low = mid
            best_lab = candidate_lab

    # Convert best_lab -> sRGB, clamp
    new_rgb = color.lab2rgb(best_lab[np.newaxis, np.newaxis, :])[0, 0]
    new_rgb = np.clip(new_rgb, 0.0, 1.0)
    return tuple(new_rgb)

##############################################################################
# 3) Main
##############################################################################

def main():
    # Minimal usage
    if len(sys.argv) < 3:
        print("Usage: python min-contrast.py <background_hex> <foreground_hex> [<min_dist>]", file=sys.stderr)
        print("Example: python min-contrast.py #ffffff #66d9ef 40.0", file=sys.stderr)
        sys.exit(1)

    bg_hex = sys.argv[1]
    fg_hex = sys.argv[2]
    min_dist = 40.0
    if len(sys.argv) >= 4:
        try:
            min_dist = float(sys.argv[3])
        except ValueError:
            print(f"Invalid <min_dist> value: {sys.argv[3]}", file=sys.stderr)
            sys.exit(1)

    # Convert to (r, g, b) in [0..1]
    fg_rgb = hex_to_rgb01(fg_hex)
    bg_rgb = hex_to_rgb01(bg_hex)

    new_fg_rgb = ensure_min_ciede2000_distance_preserve_hue_to_bg(
        fg_rgb, bg_rgb, min_dist=min_dist
    )

    new_fg_hex = rgb01_to_hex(*new_fg_rgb)

    print(json.dumps({
        "background": bg_hex,
        "foreground": fg_hex,
        "minimum_distance": min_dist,
        "new_foreground": new_fg_hex
    }, indent=4))

if __name__ == "__main__":
    main()
