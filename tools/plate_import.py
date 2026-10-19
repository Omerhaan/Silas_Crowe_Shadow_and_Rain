#!/usr/bin/env python3
"""
Plate Import Tool for Gölge ve Yağmur
Usage:
    python tools/plate_import.py [input_path] [output_path] [palette_path] [width] [height]

Default:
    input: assets/source/plates/hub_office_raw.jpg
    output: assets/plates/bg_hub_office.png
    palette: data/palette/noir40.hex
    resolution: 480x270

Downscaling Method:
    Block-dominant color pooling (blok başına baskın renk yöntemi).
    Quantizes raw pixels into the shared noir40 palette, then takes the
    mode/dominant palette color for each target pixel block.
    Ensures zero blurring, zero anti-aliasing interpolation, and 100% strict palette fidelity.
"""

import sys
from pathlib import Path
import numpy as np
from PIL import Image

BASE_DIR = Path(__file__).resolve().parent.parent

def load_palette(palette_path: Path) -> np.ndarray:
    with open(palette_path, "r", encoding="utf-8") as f:
        hex_lines = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    colors = []
    for h in hex_lines:
        h = h.lstrip("#")
        r = int(h[0:2], 16)
        g = int(h[2:4], 16)
        b = int(h[4:6], 16)
        colors.append([r, g, b])
    return np.array(colors, dtype=np.int32)

def import_plate(
    input_path: Path,
    output_path: Path,
    palette_path: Path,
    target_w: int = 480,
    target_h: int = 270
) -> None:
    print(f"Loading raw plate: {input_path}")
    if not input_path.exists():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    raw_img = Image.open(input_path).convert("RGB")
    raw_arr = np.array(raw_img, dtype=np.int32)
    h_raw, w_raw, _ = raw_arr.shape
    print(f"Raw dimensions: {w_raw}x{h_raw}")

    palette = load_palette(palette_path)
    num_colors = len(palette)
    print(f"Loaded palette with {num_colors} colors from {palette_path}")

    # Vectorized nearest palette color index computation
    # Memory: (h_raw, w_raw, num_colors)
    print("Mapping raw image pixels to nearest palette entries...")
    diff = raw_arr[:, :, None, :] - palette[None, None, :, :]
    dist_sq = np.sum(diff ** 2, axis=-1)
    pal_indices = np.argmin(dist_sq, axis=-1)

    print(f"Downscaling to {target_w}x{target_h} via block dominant color pooling...")
    out_arr = np.zeros((target_h, target_w, 3), dtype=np.uint8)

    # Compute block boundary coordinates
    x_bounds = [int(round(x * w_raw / target_w)) for x in range(target_w + 1)]
    y_bounds = [int(round(y * h_raw / target_h)) for y in range(target_h + 1)]

    for y in range(target_h):
        y0 = y_bounds[y]
        y1 = max(y0 + 1, y_bounds[y + 1])
        for x in range(target_w):
            x0 = x_bounds[x]
            x1 = max(x0 + 1, x_bounds[x + 1])
            block = pal_indices[y0:y1, x0:x1].flatten()

            # Find dominant color (mode) in the block
            counts = np.bincount(block, minlength=num_colors)
            dominant_idx = int(np.argmax(counts))
            out_arr[y, x] = palette[dominant_idx]

    output_path.parent.mkdir(parents=True, exist_ok=True)
    out_img = Image.fromarray(out_arr, mode="RGB")
    out_img.save(output_path, "PNG")
    print(f"Plate saved successfully: {output_path} ({target_w}x{target_h})")

def main():
    input_path = Path(sys.argv[1]) if len(sys.argv) > 1 else BASE_DIR / "assets" / "source" / "plates" / "hub_office_raw.jpg"
    output_path = Path(sys.argv[2]) if len(sys.argv) > 2 else BASE_DIR / "assets" / "plates" / "bg_hub_office.png"
    palette_path = Path(sys.argv[3]) if len(sys.argv) > 3 else BASE_DIR / "data" / "palette" / "noir40.hex"
    tw = int(sys.argv[4]) if len(sys.argv) > 4 else 480
    th = int(sys.argv[5]) if len(sys.argv) > 5 else 270

    import_plate(input_path, output_path, palette_path, tw, th)

if __name__ == "__main__":
    main()
