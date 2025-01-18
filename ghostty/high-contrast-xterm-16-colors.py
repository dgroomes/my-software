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

def xterm_system_colors():
    """
    Returns a list of length 16, each element is a tuple:
      (hex, name, min_contrast)
    """
    # Normal colors (indices 0..7)
    system_0_7 = [
        ("#000000", "black",        40),
        ("#C91B00", "red",          40),
        ("#00C200", "green",        40),
        ("#C7C400", "yellow",       40),
        ("#0225C7", "blue",         40),
        ("#CA30C7", "magenta",      40),
        ("#00C5C7", "cyan",         40),
        ("#C7C7C7", "light_gray",   40),
    ]

    # Bright colors (indices 8..15)
    system_8_15 = [
        ("#686868", "bright_black",   30),
        ("#FF6E67", "bright_red",     30),
        ("#5FFA68", "bright_green",   30),
        ("#FFFC67", "bright_yellow",  30),
        ("#6871FF", "bright_blue",    30),
        ("#FF77FF", "bright_magenta", 30),
        ("#60FDFF", "bright_cyan",    30),
        ("#FFFFFF", "white",           0),
    ]
    return system_0_7 + system_8_15

##############################################################################
# 4) Main: generate the palette, apply contrast fix, print results
##############################################################################

def main():
    xterm_palette = xterm_system_colors()

    for i, (hexcolor, desc, min_contrast) in enumerate(xterm_palette):
        print(f"# {desc}: min contrast {min_contrast}")

        # Convert to float RGB
        (r, g, b) = hex_to_rgb01(hexcolor)
        new_r, new_g, new_b = ensure_min_ciede2000_distance_preserve_hue(r, g, b, min_contrast)

        # Convert back to hex
        new_hex = rgb01_to_hex(new_r, new_g, new_b)

        if hexcolor == new_hex:
            print(f"# {hexcolor} (no change)")
        else:
            print(f"# {hexcolor} becomes {new_hex}")

        print(f"palette = {i}={new_hex}\n")

if __name__ == "__main__":
    main()
