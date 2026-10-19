#!/usr/bin/env python3
"""
Pixelize tool for Gölge ve Yağmur Noir Detective Game.
Pipeline:
  1. Background keying (magenta #FF00FF by default) -> transparent
  2. Bounding-box crop & aspect-ratio fit to target size
  3. Clean downscaling (Lanczos + Nearest)
  4. Hard alpha threshold (>= 128 -> 255, else 0)
  5. Optional 1px outline (0b0f1a)
  6. Palette quantization to noir24.hex (nearest or Floyd-Steinberg dither)
  7. 4x nearest upscale preview output
  8. Single file or batch mode
"""

import sys
import os
import argparse
from pathlib import Path
from PIL import Image
import numpy as np


def parse_hex_color(hex_str: str) -> tuple[int, int, int]:
    clean = hex_str.strip().lstrip("#")
    if len(clean) == 6:
        return (int(clean[0:2], 16), int(clean[2:4], 16), int(clean[4:6], 16))
    elif len(clean) == 3:
        return (int(clean[0] * 2, 16), int(clean[1] * 2, 16), int(clean[2] * 2, 16))
    raise ValueError(f"Invalid hex color: {hex_str}")


def load_palette(palette_path: str) -> list[tuple[int, int, int]]:
    colors = []
    with open(palette_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            # Each line might contain multiple space-separated hex codes
            parts = line.split()
            for p in parts:
                p = p.strip()
                if p:
                    colors.append(parse_hex_color(p))
    if not colors:
        raise ValueError(f"No valid colors found in palette: {palette_path}")
    return colors


def get_key_color(key_name_or_hex: str) -> tuple[int, int, int]:
    named = {
        "magenta": (255, 0, 255),
        "green": (0, 255, 0),
        "blue": (0, 0, 255),
        "white": (255, 255, 255),
        "black": (0, 0, 0),
    }
    low = key_name_or_hex.lower()
    if low in named:
        return named[low]
    return parse_hex_color(key_name_or_hex)


def remove_background(img: Image.Image, key_color: tuple[int, int, int], tolerance: int = 45) -> Image.Image:
    rgba = img.convert("RGBA")
    arr = np.array(rgba, dtype=np.int32)
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]

    kr, kg, kb = key_color
    # Euclidean color distance
    dist = np.sqrt((r - kr) ** 2 + (g - kg) ** 2 + (b - kb) ** 2)

    # Where color is close to key, set alpha to 0
    mask = dist <= tolerance
    arr[:, :, 3] = np.where(mask, 0, a)

    # Clamp and convert back
    arr = np.clip(arr, 0, 255).astype(np.uint8)
    return Image.fromarray(arr, mode="RGBA")


def crop_and_fit(img: Image.Image, target_w: int, target_h: int) -> Image.Image:
    # Find bounding box of non-transparent content
    arr = np.array(img)
    alpha = arr[:, :, 3]
    nonzero = np.where(alpha > 20)

    if len(nonzero[0]) == 0 or len(nonzero[1]) == 0:
        # Fully transparent, return empty image
        return Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))

    min_y, max_y = nonzero[0].min(), nonzero[0].max()
    min_x, max_x = nonzero[1].min(), nonzero[1].max()

    cropped = img.crop((min_x, min_y, max_x + 1, max_y + 1))
    cw, ch = cropped.size

    # Fit into target_w, target_h keeping aspect ratio
    scale = min(target_w / cw, target_h / ch)
    new_w = max(1, int(round(cw * scale)))
    new_h = max(1, int(round(ch * scale)))

    # Use Lanczos for downscaling
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)

    # Place in center of target canvas
    canvas = Image.new("RGBA", (target_w, target_h), (0, 0, 0, 0))
    pos_x = (target_w - new_w) // 2
    pos_y = target_h - new_h # Align to bottom for characters/props
    canvas.paste(resized, (pos_x, pos_y), resized)

    return canvas


def apply_hard_alpha(img: Image.Image, threshold: int = 128) -> Image.Image:
    arr = np.array(img)
    alpha = arr[:, :, 3]
    arr[:, :, 3] = np.where(alpha >= threshold, 255, 0)
    return Image.fromarray(arr, mode="RGBA")


def add_outline(img: Image.Image, outline_color: tuple[int, int, int] = (11, 15, 26)) -> Image.Image:
    arr = np.array(img)
    alpha = arr[:, :, 3] == 255
    h, w = alpha.shape

    # Find transparent pixels that touch an opaque pixel (4-connected)
    outline_mask = np.zeros_like(alpha, dtype=bool)

    # Shift up, down, left, right
    up = np.zeros_like(alpha)
    up[0:-1, :] = alpha[1:, :]
    down = np.zeros_like(alpha)
    down[1:, :] = alpha[0:-1, :]
    left = np.zeros_like(alpha)
    left[:, 0:-1] = alpha[:, 1:]
    right = np.zeros_like(alpha)
    right[:, 1:] = alpha[:, 0:-1]

    neighbor_opaque = up | down | left | right
    outline_mask = neighbor_opaque & (~alpha)

    # Apply outline color
    arr[outline_mask, 0] = outline_color[0]
    arr[outline_mask, 1] = outline_color[1]
    arr[outline_mask, 2] = outline_color[2]
    arr[outline_mask, 3] = 255

    return Image.fromarray(arr, mode="RGBA")


def quantize_to_palette(
    img: Image.Image,
    palette_colors: list[tuple[int, int, int]],
    dither: bool = False
) -> Image.Image:
    pal_arr = np.array(palette_colors, dtype=np.float32) # shape: (N, 3)

    if not dither:
        arr = np.array(img, dtype=np.float32)
        rgb = arr[:, :, :3]
        alpha = arr[:, :, 3]

        h, w, _ = rgb.shape
        flat_rgb = rgb.reshape(-1, 3) # shape: (P, 3)

        # Weighted perceptual distance: 0.299 * dr^2 + 0.587 * dg^2 + 0.114 * db^2
        weights = np.array([0.299, 0.587, 0.114], dtype=np.float32)

        # Calculate distances to all palette colors
        # (P, 1, 3) - (1, N, 3) -> (P, N, 3)
        diff = flat_rgb[:, np.newaxis, :] - pal_arr[np.newaxis, :, :]
        weighted_sq_dist = np.sum((diff ** 2) * weights, axis=2) # (P, N)
        closest_indices = np.argmin(weighted_sq_dist, axis=1) # (P,)

        quant_flat = pal_arr[closest_indices]
        quant_rgb = quant_flat.reshape(h, w, 3).astype(np.uint8)

        out_arr = np.zeros((h, w, 4), dtype=np.uint8)
        out_arr[:, :, :3] = quant_rgb
        out_arr[:, :, 3] = np.where(alpha >= 128, 255, 0).astype(np.uint8)
        return Image.fromarray(out_arr, mode="RGBA")
    else:
        # Floyd-Steinberg error diffusion
        arr = np.array(img, dtype=np.float32)
        h, w, _ = arr.shape
        weights = np.array([0.299, 0.587, 0.114], dtype=np.float32)

        for y in range(h):
            for x in range(w):
                if arr[y, x, 3] < 128:
                    arr[y, x, 3] = 0
                    continue

                old_p = arr[y, x, :3]
                diff = old_p - pal_arr
                dist = np.sum((diff ** 2) * weights, axis=1)
                best_idx = np.argmin(dist)
                new_p = pal_arr[best_idx]
                arr[y, x, :3] = new_p
                arr[y, x, 3] = 255

                err = old_p - new_p
                # Distribute error to neighbors
                if x + 1 < w:
                    arr[y, x + 1, :3] += err * (7.0 / 16.0)
                if y + 1 < h:
                    if x - 1 >= 0:
                        arr[y + 1, x - 1, :3] += err * (3.0 / 16.0)
                    arr[y + 1, x, :3] += err * (5.0 / 16.0)
                    if x + 1 < w:
                        arr[y + 1, x + 1, :3] += err * (1.0 / 16.0)

        out_arr = np.clip(arr, 0, 255).astype(np.uint8)
        return Image.fromarray(out_arr, mode="RGBA")


def process_image(
    input_path: str,
    output_path: str,
    target_size: tuple[int, int],
    palette_colors: list[tuple[int, int, int]],
    key_color: tuple[int, int, int] | None,
    tolerance: int,
    outline: bool,
    dither: bool
) -> str:
    img = Image.open(input_path).convert("RGBA")

    # 1. Remove background if key color given
    if key_color is not None:
        img = remove_background(img, key_color, tolerance)

    # 2. Crop & fit to target size
    img = crop_and_fit(img, target_size[0], target_size[1])

    # 3. Hard alpha threshold
    img = apply_hard_alpha(img, threshold=128)

    # 4. Add optional outline
    if outline:
        img = add_outline(img, outline_color=(11, 15, 26))

    # 5. Quantize to palette
    img = quantize_to_palette(img, palette_colors, dither=dither)

    # Save output
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    img.save(output_path, "PNG")

    # 6. Save 4x preview
    stem = Path(output_path).stem
    out_dir = Path(output_path).parent
    preview_path = str(out_dir / f"{stem}_preview.png")
    preview = img.resize((target_size[0] * 4, target_size[1] * 4), Image.Resampling.NEAREST)
    preview.save(preview_path, "PNG")

    return preview_path


def main():
    parser = argparse.ArgumentParser(description="Gölge ve Yağmur Pixelize Tool")
    parser.add_argument("input", nargs="?", help="Input image file")
    parser.add_argument("output", nargs="?", help="Output image file")
    parser.add_argument("--size", default="32x48", help="Target size (WxH, default: 32x48)")
    parser.add_argument("--palette", default="data/palette/noir24.hex", help="Path to .hex palette file")
    parser.add_argument("--key", default="magenta", help="Background key color (magenta, green, or hex e.g. #FF00FF)")
    parser.add_argument("--tolerance", type=int, default=45, help="Color tolerance for background keying")
    parser.add_argument("--no-key", action="store_true", help="Disable background keying (e.g. if already transparent)")
    parser.add_argument("--outline", action="store_true", help="Add 1px dark contour (0b0f1a)")
    parser.add_argument("--dither", action="store_true", help="Enable Floyd-Steinberg dithering")
    parser.add_argument("--batch", help="Batch mode: folder containing images to process")
    parser.add_argument("--batch-out", help="Batch mode output folder (default: batch folder + /processed)")

    args = parser.parse_args()

    # Parse target size
    parts = args.size.lower().split("x")
    if len(parts) != 2:
        print(f"Error: Invalid size format: {args.size}. Use WxH (e.g. 32x48)")
        sys.exit(1)
    target_w, target_h = int(parts[0]), int(parts[1])

    # Load palette
    if not os.path.exists(args.palette):
        print(f"Error: Palette file not found: {args.palette}")
        sys.exit(1)
    palette_colors = load_palette(args.palette)

    key_col = None if args.no_key else get_key_color(args.key)

    if args.batch:
        in_dir = Path(args.batch)
        if not in_dir.is_dir():
            print(f"Error: Batch directory does not exist: {args.batch}")
            sys.exit(1)
        out_dir = Path(args.batch_out) if args.batch_out else (in_dir / "processed")
        out_dir.mkdir(parents=True, exist_ok=True)

        supported_exts = {".png", ".jpg", ".jpeg", ".webp", ".bmp"}
        processed_count = 0
        for f in in_dir.iterdir():
            if f.is_file() and f.suffix.lower() in supported_exts and not f.stem.endswith("_preview"):
                dest = out_dir / f"{f.stem}.png"
                print(f"Processing: {f.name} -> {dest.name}")
                process_image(
                    str(f),
                    str(dest),
                    (target_w, target_h),
                    palette_colors,
                    key_col,
                    args.tolerance,
                    args.outline,
                    args.dither
                )
                processed_count += 1
        print(f"Batch completed: {processed_count} images processed in {out_dir}")
    else:
        if not args.input or not args.output:
            parser.print_help()
            sys.exit(1)
        print(f"Processing {args.input} -> {args.output} ({target_w}x{target_h})...")
        preview = process_image(
            args.input,
            args.output,
            (target_w, target_h),
            palette_colors,
            key_col,
            args.tolerance,
            args.outline,
            args.dither
        )
        print(f"Success! Output: {args.output}")
        print(f"Preview: {preview}")


if __name__ == "__main__":
    main()
