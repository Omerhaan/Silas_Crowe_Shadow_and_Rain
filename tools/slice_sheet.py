#!/usr/bin/env python3
"""
Slice sheet tool for 'Gölge ve Yağmur'.
Automatically detects items on a solid background (default: magenta #FF00FF),
crops each item into a separate transparent PNG, and creates an indexed
contact sheet with numbers for easy identification.

Usage:
  python tools/slice_sheet.py input_sheet.png --out-dir assets/slices/group_a
"""

import sys
import os
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np

def parse_hex(hex_str: str) -> tuple[int, int, int]:
    clean = hex_str.strip().lstrip("#")
    return (int(clean[0:2], 16), int(clean[2:4], 16), int(clean[4:6], 16))

def slice_sheet(
    image_path: str,
    output_dir: str,
    key_hex: str = "#FF00FF",
    tolerance: int = 50,
    min_area: int = 64,
    padding: int = 2
) -> list[dict]:
    img = Image.open(image_path).convert("RGB")
    arr = np.array(img, dtype=np.int32)
    kr, kg, kb = parse_hex(key_hex)

    # Color distance to background key
    dist = np.sqrt((arr[:, :, 0] - kr)**2 + (arr[:, :, 1] - kg)**2 + (arr[:, :, 2] - kb)**2)
    fg_mask = (dist > tolerance).astype(np.uint8)

    h, w = fg_mask.shape

    # Simple 2D connected components using disjoint-set or scanline flood
    visited = np.zeros((h, w), dtype=bool)
    boxes = []

    # Grid search for unvisited foreground pixels
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if fg_mask[y, x] and not visited[y, x]:
                # Flood fill / BFS component
                min_x, max_x = x, x
                min_y, max_y = y, y
                queue = [(x, y)]
                visited[y, x] = True
                pixel_count = 0

                while queue:
                    cx, cy = queue.pop()
                    pixel_count += 1
                    if cx < min_x: min_x = cx
                    if cx > max_x: max_x = cx
                    if cy < min_y: min_y = cy
                    if cy > max_y: max_y = cy

                    # 4-neighbors
                    for dx, dy in [(1, 0), (-1, 0), (0, 1), (0, -1)]:
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h:
                            if fg_mask[ny, nx] and not visited[ny, nx]:
                                visited[ny, nx] = True
                                queue.append((nx, ny))

                if pixel_count >= min_area:
                    bw = max_x - min_x + 1
                    bh = max_y - min_y + 1
                    if bw >= 6 and bh >= 6:
                        boxes.append({
                            "x1": max(0, min_x - padding),
                            "y1": max(0, min_y - padding),
                            "x2": min(w, max_x + 1 + padding),
                            "y2": min(h, max_y + 1 + padding),
                            "w": bw,
                            "h": bh
                        })

    # Sort boxes top-to-bottom, left-to-right
    boxes.sort(key=lambda b: (b["y1"] // 60, b["x1"]))

    os.makedirs(output_dir, exist_ok=True)
    out_items = []

    # Create contact sheet image for reference
    contact = img.copy()
    draw = ImageDraw.Draw(contact)

    rgba_img = img.convert("RGBA")
    rgba_arr = np.array(rgba_img)
    # Set transparent pixels where dist <= tolerance
    rgba_arr[dist <= tolerance, 3] = 0
    clean_rgba = Image.fromarray(rgba_arr, mode="RGBA")

    for i, box in enumerate(boxes):
        item_crop = clean_rgba.crop((box["x1"], box["y1"], box["x2"], box["y2"]))
        fname = f"item_{i+1:02d}_{box['w']}x{box['h']}.png"
        fpath = os.path.join(output_dir, fname)
        item_crop.save(fpath, "PNG")

        box["id"] = i + 1
        box["file"] = fpath
        box["name"] = fname
        out_items.append(box)

        # Draw red bounding box on contact sheet
        draw.rectangle([box["x1"], box["y1"], box["x2"], box["y2"]], outline=(255, 0, 0), width=2)
        # Draw index tag
        tag = str(i + 1)
        draw.rectangle([box["x1"], box["y1"], box["x1"] + 16, box["y1"] + 12], fill=(0, 0, 0))
        draw.text((box["x1"] + 3, box["y1"] + 1), tag, fill=(255, 255, 255))

    contact_path = os.path.join(output_dir, "contact_sheet.png")
    contact.save(contact_path, "PNG")

    print(f"Sliced {len(out_items)} items to {output_dir}")
    print(f"Contact sheet saved to: {contact_path}")
    return out_items

def main():
    parser = argparse.ArgumentParser(description="Slice sprite sheet on solid background")
    parser.add_argument("input", help="Path to input sprite sheet image")
    parser.add_argument("--out-dir", default="assets/slices", help="Output directory")
    parser.add_argument("--key", default="#FF00FF", help="Key background color (default: #FF00FF)")
    parser.add_argument("--tolerance", type=int, default=50, help="Color tolerance")
    parser.add_argument("--min-area", type=int, default=64, help="Min pixels for a prop")

    args = parser.parse_args()
    if not os.path.exists(args.input):
        print(f"Error: File not found: {args.input}")
        sys.exit(1)

    slice_sheet(args.input, args.out_dir, key_hex=args.key, tolerance=args.tolerance, min_area=args.min_area)

if __name__ == "__main__":
    main()
