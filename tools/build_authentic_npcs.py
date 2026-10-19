#!/usr/bin/env python3
"""
Build Authentic 1:1 Native Pixel Art Sprites for NPCs
Sources: assets/slices/B1_Margaret_Doyle, B2_Julian_Harlow, B3_Raymond_Pike, B4_Dr_Victor_Hale, B5_Edmund_Harlow
Destination: assets/sprites/characters/
"""

from pathlib import Path
from PIL import Image, ImageOps
import numpy as np
from collections import deque

BASE_DIR = Path(__file__).resolve().parent.parent
SLICES_DIR = BASE_DIR / "assets" / "slices"
OUT_DIR = BASE_DIR / "assets" / "sprites" / "characters"

CANVAS_W = 64
CANVAS_H = 104
FEET_Y = 100

DARK_OUTLINE = np.array([24, 22, 28], dtype=np.uint8)

def process_slice(src_path: Path, target_height: int = 100) -> Image.Image:
    raw = Image.open(src_path).convert("RGBA")
    arr = np.array(raw)
    h_raw, w_raw, _ = arr.shape
    
    # Clean magenta chroma fringe from outer background using flood fill
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    is_pure_mag = (r > 115) & (b > 115) & (g < 110) & (r - g > 20) & (b - g > 20)
    is_mag_bg = is_pure_mag | (a < 30)
    
    arr[is_pure_mag, 3] = 0
    
    visited_bg = np.zeros((h_raw, w_raw), dtype=bool)
    q = deque()
    for x in range(w_raw):
        if is_mag_bg[0, x]: visited_bg[0, x] = True; q.append((0, x))
        if is_mag_bg[h_raw-1, x]: visited_bg[h_raw-1, x] = True; q.append((h_raw-1, x))
    for y in range(h_raw):
        if is_mag_bg[y, 0]: visited_bg[y, 0] = True; q.append((y, 0))
        if is_mag_bg[y, w_raw-1]: visited_bg[y, w_raw-1] = True; q.append((y, w_raw-1))
        
    while q:
        cy, cx = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h_raw and 0 <= nx < w_raw and not visited_bg[ny, nx]:
                if is_mag_bg[ny, nx] or ((r[ny,nx] > 80) and (b[ny,nx] > 80) and (g[ny,nx] < 100) and (r[ny,nx]-g[ny,nx] > 25) and (b[ny,nx]-g[ny,nx] > 25)):
                    visited_bg[ny, nx] = True
                    q.append((ny, nx))
                    
    arr[visited_bg, 3] = 0
    clean_img = Image.fromarray(arr, mode="RGBA")
    bbox = clean_img.getbbox()
    if not bbox:
        return Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    clean_cropped = clean_img.crop(bbox)
    
    w_orig, h_orig = clean_cropped.size
    scale = target_height / float(h_orig)
    new_w = max(1, int(round(w_orig * scale)))
    new_h = target_height
    
    down_box = clean_cropped.resize((new_w, new_h), Image.Resampling.BOX)
    b_arr = np.array(down_box)
    visible = b_arr[:, :, 3] >= 110
    
    H, W = visible.shape
    is_outside = np.zeros((H+2, W+2), dtype=bool)
    pad_vis = np.pad(visible, 1, mode='constant', constant_values=False)
    
    q_out = deque([(0, 0)])
    is_outside[0, 0] = True
    while q_out:
        cy, cx = q_out.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < H+2 and 0 <= nx < W+2:
                if not is_outside[ny, nx] and not pad_vis[ny, nx]:
                    is_outside[ny, nx] = True
                    q_out.append((ny, nx))
                    
    solid_visible = ~is_outside[1:-1, 1:-1]
    filled_holes = solid_visible & ~visible
    if np.any(filled_holes):
        b_arr[filled_holes] = [40, 30, 36, 255]
        
    outer_boundary = np.zeros((H, W), dtype=bool)
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dy == 0 and dx == 0: continue
            out_shifted = is_outside[1+dy:1+dy+H, 1+dx:1+dx+W]
            outer_boundary |= (solid_visible & out_shifted)
            
    b_arr[outer_boundary, :3] = DARK_OUTLINE
    b_arr[solid_visible, 3] = 255
    b_arr[~solid_visible, :] = 0
    
    char_img = Image.fromarray(b_arr, mode="RGBA")
    
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    paste_x = (CANVAS_W - new_w) // 2
    paste_y = FEET_Y - new_h
    canvas.paste(char_img, (paste_x, paste_y), char_img)
    
    return canvas

def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    
    npc_map = {
        "margaret_idle_down.png": (SLICES_DIR / "B1_Margaret_Doyle" / "item_13_163x410.png", 92),
        "julian_idle_down.png": (SLICES_DIR / "B2_Julian_Harlow" / "item_01_164x467.png", 98),
        "pike_idle_down.png": (SLICES_DIR / "B3_Raymond_Pike" / "item_01_258x508.png", 102),
        "hale_idle_down.png": (SLICES_DIR / "B4_Dr_Victor_Hale" / "item_01_220x508.png", 98),
        "edmund_idle_down.png": (SLICES_DIR / "B5_Edmund_Harlow" / "item_01_198x558.png", 100),
    }
    
    for filename, (slice_path, target_h) in npc_map.items():
        if not slice_path.exists():
            print(f"Warning: {slice_path} not found")
            continue
        img = process_slice(slice_path, target_h)
        dest = OUT_DIR / filename
        img.save(dest, "PNG")
        print(f"Saved {filename} ({img.size}) at height {target_h}")
        
        # Save side poses if needed
        base_name = filename.replace("_down.png", "")
        img_right = img
        img_right.save(OUT_DIR / f"{base_name}_right.png", "PNG")
        img_left = ImageOps.mirror(img)
        img_left.save(OUT_DIR / f"{base_name}_left.png", "PNG")

    print("\nAll 1:1 authentic NPC sprites successfully generated.")

if __name__ == "__main__":
    main()
