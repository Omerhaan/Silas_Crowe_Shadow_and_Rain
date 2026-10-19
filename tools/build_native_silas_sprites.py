#!/usr/bin/env python3
"""
Build Native 1:1 Pixel Art Sprites for Detective Silas Crowe (100px)
Source: assets/slices/A1_silas_pozlar/
Output: assets/sprites/characters/
Palette: data/palette/noir40.hex

Pipeline:
1. De-fringe magenta chroma key artifacts.
2. Scale to exact 100px native height (1:1 texel density).
3. Apply crisp 1px dark charcoal silhouette contour matching room objects.
4. Quantize to shared noir40 palette with warm amber rim lighting from banker lamp.
5. Save idle, 6-frame walk cycle (left & right), phone, inspect, notebook, and shudder.
6. Center on uniform 60x104 canvas with feet anchored at y=100.
"""

from pathlib import Path
from PIL import Image, ImageOps
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent
SLICES_DIR = BASE_DIR / "assets" / "slices" / "A1_silas_pozlar"
OUT_DIR = BASE_DIR / "assets" / "sprites" / "characters"
PALETTE_PATH = BASE_DIR / "data" / "palette" / "noir40.hex"

CANVAS_W = 60
CANVAS_H = 104
FEET_Y = 100

def load_noir40():
    with open(PALETTE_PATH, "r", encoding="utf-8") as f:
        hexes = [l.strip().lstrip("#") for l in f if l.strip() and not l.startswith("#")]
    colors = []
    for h in hexes:
        colors.append([int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)])
    return np.array(colors, dtype=np.int32)

def clean_and_process_slice(src_path: Path, palette: np.ndarray, target_height: int = 100) -> Image.Image:
    raw = Image.open(src_path).convert("RGBA")
    arr = np.array(raw)
    
    # 1. Clean magenta fringe
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    is_magenta = (r > 70) & (b > 70) & (g < 110) & (r - g > 30) & (b - g > 30)
    is_bg = is_magenta | (a < 60)
    arr[is_bg, 3] = 0
    
    clean_raw = Image.fromarray(arr, mode="RGBA")
    bbox = clean_raw.getbbox()
    if not bbox:
        return Image.new("RGBA", (CANVAS_W, CANVAS_H), (0,0,0,0))
    clean_cropped = clean_raw.crop(bbox)
    
    # 2. Downscale to target height maintaining aspect ratio
    w_orig, h_orig = clean_cropped.size
    scale = target_height / float(h_orig)
    new_w = max(1, int(round(w_orig * scale)))
    new_h = target_height
    
    scaled = clean_cropped.resize((new_w, new_h), Image.Resampling.BOX)
    s_arr = np.array(scaled)
    
    # 3. Clean alpha threshold
    alpha = s_arr[:, :, 3]
    visible = alpha > 110
    
    # 4. Color grading: slightly deepen shadows, add warm rim on right side (banker lamp)
    rgb = s_arr[:, :, :3].astype(np.float32)
    
    # Warm amber rim on right side: x columns in rightmost 25% of character
    for y in range(new_h):
        row_vis = np.where(visible[y])[0]
        if len(row_vis) > 0:
            rx = row_vis[-1] # Rightmost visible pixel in this row
            # Apply golden/amber warmth
            rgb[y, rx, 0] = min(255.0, rgb[y, rx, 0] * 1.18 + 15.0)
            rgb[y, rx, 1] = min(255.0, rgb[y, rx, 1] * 1.10 + 10.0)
            rgb[y, rx, 2] = rgb[y, rx, 2] * 0.90
            if rx - 1 >= row_vis[0]:
                rgb[y, rx - 1, 0] = min(255.0, rgb[y, rx - 1, 0] * 1.08 + 8.0)
                rgb[y, rx - 1, 1] = min(255.0, rgb[y, rx - 1, 1] * 1.04 + 5.0)

    # 5. Quantize visible pixels to noir40 palette
    rgb_int = np.clip(rgb, 0, 255).astype(np.int32)
    diff = rgb_int[:, :, None, :] - palette[None, None, :, :]
    dist_sq = np.sum(diff ** 2, axis=-1)
    pal_indices = np.argmin(dist_sq, axis=-1)
    quant_rgb = palette[pal_indices].astype(np.uint8)
    
    # 6. Apply 1px dark charcoal contour outline
    # Boundary detection via numpy shift
    vis_pad = np.pad(visible, 1, mode='constant', constant_values=False)
    boundary = np.zeros_like(visible)
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dy == 0 and dx == 0:
                continue
            shifted = vis_pad[1+dy:1+dy+new_h, 1+dx:1+dx+new_w]
            boundary |= (visible & ~shifted)
            
    # Dark charcoal outline color: #161720 (index in noir40 or deep charcoal)
    dark_outline = np.array([22, 23, 32], dtype=np.uint8)
    
    char_rgba = np.zeros((new_h, new_w, 4), dtype=np.uint8)
    char_rgba[visible, :3] = quant_rgb[visible]
    # Set dark outline on extreme perimeter
    char_rgba[boundary, :3] = dark_outline
    char_rgba[visible, 3] = 255
    
    char_img = Image.fromarray(char_rgba, mode="RGBA")
    
    # 7. Center on uniform canvas (CANVAS_W x CANVAS_H)
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    paste_x = (CANVAS_W - new_w) // 2
    paste_y = FEET_Y - new_h
    canvas.paste(char_img, (paste_x, paste_y), char_img)
    
    return canvas

def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    palette = load_noir40()
    print(f"Loaded {len(palette)} colors from {PALETTE_PATH}")
    
    # Frame mapping
    frames = {
        "silas_idle_right.png": "item_02_158x442.png",
        "silas_walk_right_1.png": "item_03_158x443.png",
        "silas_walk_right_2.png": "item_04_215x442.png",
        "silas_walk_right_3.png": "item_05_228x442.png",
        "silas_walk_right_4.png": "item_06_200x442.png",
        "silas_walk_right_5.png": "item_07_199x441.png",
        "silas_walk_right_6.png": "item_08_237x441.png",
        "silas_inspect.png": "item_09_280x406.png",
        "silas_notebook.png": "item_11_172x439.png",
        "silas_phone.png": "item_12_197x444.png",
        "silas_shudder.png": "item_13_232x444.png",
    }
    
    for filename, slice_name in frames.items():
        src = SLICES_DIR / slice_name
        if not src.exists():
            print(f"Warning: {src} not found!")
            continue
        
        target_h = 100
        if "inspect" in filename:
            target_h = 88 # Crouch
        
        processed = clean_and_process_slice(src, palette, target_h)
        dest_right = OUT_DIR / filename
        processed.save(dest_right, "PNG")
        print(f"Generated {filename} ({processed.size})")
        
        # Also generate corresponding left-facing frames
        if "right" in filename:
            left_filename = filename.replace("right", "left")
            processed_left = ImageOps.mirror(processed)
            dest_left = OUT_DIR / left_filename
            processed_left.save(dest_left, "PNG")
            print(f"Generated {left_filename} (mirrored)")
        elif filename == "silas_phone.png":
            # Idle down/up fallbacks using idle_right
            pass

    # Fallback idle_down and idle_up
    idle_r = Image.open(OUT_DIR / "silas_idle_right.png")
    idle_r.save(OUT_DIR / "silas_idle_down.png")
    idle_r.save(OUT_DIR / "silas_idle_up.png")
    
    # 4-frame walk down/up fallbacks
    w1 = Image.open(OUT_DIR / "silas_walk_right_1.png")
    w2 = Image.open(OUT_DIR / "silas_walk_right_2.png")
    w3 = Image.open(OUT_DIR / "silas_walk_right_3.png")
    w4 = Image.open(OUT_DIR / "silas_walk_right_4.png")
    w1.save(OUT_DIR / "silas_walk_down_1.png")
    w2.save(OUT_DIR / "silas_walk_down_2.png")
    w3.save(OUT_DIR / "silas_walk_down_3.png")
    w4.save(OUT_DIR / "silas_walk_down_4.png")
    w1.save(OUT_DIR / "silas_walk_up_1.png")
    w2.save(OUT_DIR / "silas_walk_up_2.png")

    print("\nAll Silas Crowe 1:1 native sprites built successfully!")

if __name__ == "__main__":
    main()
