# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "scikit-image",
# ]
# ///

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
# 2) The "Preserve Hue" function in LCh
##############################################################################

def ensure_min_ciede2000_distance_preserve_hue(r, g, b, min_dist=40.0):
    """
    Convert (r,g,b) -> Lab -> LCh, measure distance from white=(100,0,0).
    If < min_dist, do a binary search on L in [0..L_original], preserving
    the original C,h. This yields a color that is 'the same hue' but
    darker if needed.
    """
    # Convert the RGB to Lab
    lab_color = color.rgb2lab(np.array([[[r, g, b]]]))[0, 0]
    white_lab = np.array([100.0, 0.0, 0.0])

    # Check current distance
    dist = ciede2000_distance(lab_color, white_lab)
    if dist >= min_dist:
        # Already far enough; leave as-is
        return (r, g, b)

    # Convert Lab -> LCh
    lch_color = color.lab2lch(lab_color[np.newaxis, np.newaxis, :])[0, 0]
    L0, C0, H0 = lch_color  # L, C, H

    def distance_for_L(L_test):
        L_test = np.clip(L_test, 0.0, 100.0)
        test_lch = np.array([L_test, C0, H0])
        test_lab = color.lch2lab(test_lch[np.newaxis, np.newaxis, :])[0, 0]
        d = ciede2000_distance(test_lab, white_lab)
        return d, test_lab

    low, high = 0.0, L0
    best_lab = lab_color

    for _ in range(25):  # 25 binary search iterations
        mid = (low + high) / 2
        dmid, candidate_lab = distance_for_L(mid)
        if dmid < min_dist:
            # Still too close to white => go darker
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
# 3) Standard Xterm 256 color palette generation
##############################################################################
#
#   Indices 0..15: system colors (explicit).
#   Indices 16..231: 6x6x6 color cube (r,g,b each in 0..5).
#   Indices 232..255: grayscale ramp.
#
##############################################################################

def xterm_256_color_hex_list():
    """
    Returns a list of length 256, where index i is the #RRGGBB
    representation of the i-th color in the standard Xterm palette.
    """

    # First 16: from XTerm specification (or some distribution).
    # We'll match typical "modern" definitions as a reference:
    # (You can substitute your own if you have custom ones.)

    # 0-7 (normal)
    system_0_7 = [
        "#000000",  # 0 black
        "#c91b00",  # 1 red
        "#00c200",  # 2 green
        "#c7c400",  # 3 yellow
        "#0225c7",  # 4 blue
        "#ca30c7",  # 5 magenta
        "#00c5c7",  # 6 cyan
        "#c7c7c7",  # 7 white (light gray)
    ]
    # 8-15 (bright)
    system_8_15 = [
        "#686868",  # 8  bright black / gray
        "#ff6e67",  # 9  bright red
        "#5ffa68",  # 10 bright green
        "#fffc67",  # 11 bright yellow
        "#6871ff",  # 12 bright blue
        "#ff77ff",  # 13 bright magenta
        "#60fdff",  # 14 bright cyan
        "#ffffff",  # 15 bright white
    ]
    palette = system_0_7 + system_8_15

    # 16..231: 6x6x6 color cube
    for r in range(6):
        for g in range(6):
            for b in range(6):
                rr = int(round((r / 5.0) * 255))
                gg = int(round((g / 5.0) * 255))
                bb = int(round((b / 5.0) * 255))
                palette.append("#{:02x}{:02x}{:02x}".format(rr, gg, bb))

    # 232..255: grayscale ramp
    for i in range(24):
        # Range from 8 to 238 in steps of 10
        level = 8 + i * 10
        palette.append("#{:02x}{:02x}{:02x}".format(level, level, level))

    return palette[:256]

##############################################################################
# 4) Main: generate the palette, apply contrast fix, print results
##############################################################################

def main():
    MIN_DIST = 40.0
    xterm_palette = xterm_256_color_hex_list()

    for i, hexcolor in enumerate(xterm_palette):
        # Convert to float RGB
        (r, g, b) = hex_to_rgb01(hexcolor)

        new_r, new_g, new_b = ensure_min_ciede2000_distance_preserve_hue(r, g, b, MIN_DIST)

        # Convert back to hex
        new_hex = rgb01_to_hex(new_r, new_g, new_b)
        print(f"# {hexcolor} becomes {new_hex}")
        print(f"palette = {i}={new_hex}\n")

if __name__ == "__main__":
    main()
