#!/usr/bin/env python3
"""
High-Quality Asset & Movement Space Overhaul
1. Downsamples all room plates from raw 2752x1536 JPG to 480x270 PNG using Lanczos with full 24-bit color.
2. Generates smooth, anti-aliased 100px native character sprites for Silas Crowe and NPCs.
"""

from pathlib import Path
from PIL import Image, ImageOps
import numpy as np
from collections import deque

BASE_DIR = Path(__file__).resolve().parent.parent
RAW_PLATES_DIR = BASE_DIR / "assets" / "source" / "plates"
PLATES_DIR = BASE_DIR / "assets" / "plates"
CHARS_DIR = BASE_DIR / "assets" / "sprites" / "characters"
SLICES_DIR = BASE_DIR / "assets" / "slices"

CANVAS_W = 64
CANVAS_H = 104
FEET_Y = 100

def clean_and_resize_char(src_path: Path, target_height: int = 100) -> Image.Image:
    raw = Image.open(src_path).convert("RGBA")
    arr = np.array(raw)
    h_raw, w_raw, _ = arr.shape
    
    # 1. Detect magenta chroma
    r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
    is_mag = (r > 115) & (b > 115) & (g < 110) & (r - g > 20) & (b - g > 20)
    arr[is_mag, 3] = 0
    
    # Flood-fill fringe removal from exterior
    visited = np.zeros((h_raw, w_raw), dtype=bool)
    q = deque()
    for x in range(w_raw):
        if is_mag[0, x] or a[0, x] < 50: visited[0, x] = True; q.append((0, x))
        if is_mag[h_raw-1, x] or a[h_raw-1, x] < 50: visited[h_raw-1, x] = True; q.append((h_raw-1, x))
    for y in range(h_raw):
        if is_mag[y, 0] or a[y, 0] < 50: visited[y, 0] = True; q.append((y, 0))
        if is_mag[y, w_raw-1] or a[y, w_raw-1] < 50: visited[y, w_raw-1] = True; q.append((y, w_raw-1))
        
    while q:
        cy, cx = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h_raw and 0 <= nx < w_raw and not visited[ny, nx]:
                if is_mag[ny, nx] or (r[ny,nx] > 85 and b[ny,nx] > 85 and g[ny,nx] < 115 and (r[ny,nx]-g[ny,nx] > 20) and (b[ny,nx]-g[ny,nx] > 20)):
                    visited[ny, nx] = True
                    q.append((ny, nx))
                    
    arr[visited, 3] = 0
    
    # De-spill subtle magenta border pixels
    edge_mag = (r > 100) & (b > 100) & (g < 120) & (r - g > 15) & (b - g > 15) & (arr[:,:,3] > 0)
    if np.any(edge_mag):
        arr[edge_mag, 0] = (arr[edge_mag, 0].astype(int) + arr[edge_mag, 1].astype(int)) // 2
        arr[edge_mag, 2] = (arr[edge_mag, 2].astype(int) + arr[edge_mag, 1].astype(int)) // 2

    clean_img = Image.fromarray(arr, mode="RGBA")
    bbox = clean_img.getbbox()
    if not bbox:
        return Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    clean_cropped = clean_img.crop(bbox)
    
    # 2. Downscale using Lanczos for clean, anti-aliased character
    scale = target_height / float(clean_cropped.height)
    new_w = max(1, int(round(clean_cropped.width * scale)))
    down_img = clean_cropped.resize((new_w, target_height), Image.Resampling.LANCZOS)
    
    # 3. Canvas placement
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    paste_x = (CANVAS_W - new_w) // 2
    paste_y = FEET_Y - target_height
    canvas.paste(down_img, (paste_x, paste_y), down_img)
    return canvas

def process_all_plates():
    plate_map = [
        ("ana_hol.jpg", "bg_main_hall.png"),
        ("calisma_odasi.jpg", "bg_study.png"),
        ("kutuphane.jpg", "bg_library.png"),
        ("yemek_odasi.jpg", "bg_dining_room.png"),
        ("mutfak.jpg", "bg_kitchen.png"),
        ("bilardo_odasi.jpg", "bg_billiard_room.png"),
        ("ust_kat_koridoru.jpg", "bg_upper_floor.png"),
        ("silasin_ofisi.jpg", "bg_hub_office.png"),
        ("harlowun_yatak_odasi.jpg", "bg_harlow_bedroom.png"),
        ("julianın_odasi.jpg", "bg_julian_room.png"),
        ("pikein_odasi.jpg", "bg_pike_room.png"),
    ]
    for src_name, dst_name in plate_map:
        src = RAW_PLATES_DIR / src_name
        if not src.exists():
            continue
        dst = PLATES_DIR / dst_name
        raw = Image.open(src).convert("RGB")
        high_q = raw.resize((480, 270), Image.Resampling.LANCZOS)
        high_q.save(dst, "PNG")
        print(f"Exported High-Q plate: {dst_name} (480x270 RGB)")

def process_silas_sprites():
    silas_slices = SLICES_DIR / "A1_silas_pozlar"
    frame_map = {
        "silas_idle_right.png": ("item_02_158x442.png", 100),
        "silas_walk_right_1.png": ("item_03_158x443.png", 100),
        "silas_walk_right_2.png": ("item_04_215x442.png", 100),
        "silas_walk_right_3.png": ("item_05_228x442.png", 100),
        "silas_walk_right_4.png": ("item_06_200x442.png", 100),
        "silas_walk_right_5.png": ("item_07_199x441.png", 100),
        "silas_walk_right_6.png": ("item_08_237x441.png", 100),
        "silas_phone.png": ("item_12_197x444.png", 100),
        "silas_inspect.png": ("item_09_280x406.png", 92),
        "silas_notebook.png": ("item_11_172x439.png", 100),
        "silas_shudder.png": ("item_13_232x444.png", 100),
    }
    
    for filename, (slice_name, th) in frame_map.items():
        src = silas_slices / slice_name
        if not src.exists():
            continue
        img = clean_and_resize_char(src, th)
        img.save(CHARS_DIR / filename, "PNG")
        if "right" in filename:
            left_fn = filename.replace("right", "left")
            img_left = ImageOps.mirror(img)
            img_left.save(CHARS_DIR / left_fn, "PNG")
            
    # Idle & walk fallbacks
    idle_r = Image.open(CHARS_DIR / "silas_idle_right.png")
    idle_r.save(CHARS_DIR / "silas_idle_down.png")
    idle_r.save(CHARS_DIR / "silas_idle_up.png")
    for i in range(1, 5):
        Image.open(CHARS_DIR / f"silas_walk_right_{i}.png").save(CHARS_DIR / f"silas_walk_down_{i}.png")
    for i in range(1, 3):
        Image.open(CHARS_DIR / f"silas_walk_right_{i}.png").save(CHARS_DIR / f"silas_walk_up_{i}.png")
    print("Exported High-Q Silas Crowe sprites.")

def process_npc_sprites():
    npc_map = {
        "margaret_idle_down.png": (SLICES_DIR / "B1_Margaret_Doyle" / "item_13_163x410.png", 92),
        "julian_idle_down.png": (SLICES_DIR / "B2_Julian_Harlow" / "item_01_164x467.png", 98),
        "pike_idle_down.png": (SLICES_DIR / "B3_Raymond_Pike" / "item_01_258x508.png", 102),
        "hale_idle_down.png": (SLICES_DIR / "B4_Dr_Victor_Hale" / "item_01_220x508.png", 98),
        "edmund_idle_down.png": (SLICES_DIR / "B5_Edmund_Harlow" / "item_01_198x558.png", 100),
    }
    for filename, (src, th) in npc_map.items():
        if not src.exists():
            continue
        img = clean_and_resize_char(src, th)
        img.save(CHARS_DIR / filename, "PNG")
        base_name = filename.replace("_down.png", "")
        img.save(CHARS_DIR / f"{base_name}_right.png", "PNG")
        ImageOps.mirror(img).save(CHARS_DIR / f"{base_name}_left.png", "PNG")
    print("Exported High-Q NPC sprites.")

def main():
    print("1. Processing high-quality plates...")
    process_all_plates()
    print("2. Processing high-quality Silas Crowe sprites...")
    process_silas_sprites()
    print("3. Processing high-quality NPC sprites...")
    process_npc_sprites()
    print("Done!")

if __name__ == "__main__":
    main()
