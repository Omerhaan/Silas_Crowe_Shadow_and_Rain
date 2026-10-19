#!/usr/bin/env python3
"""
Generate a clean 320x180 background plate for Silas Office.
Uses authentic elements from the concept art (lamp, window, rug, colors)
with pristine pixel-art rendering: zero repeated artifacts, zero baked furniture.
"""

from pathlib import Path
from PIL import Image, ImageDraw
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent
CONCEPT_PATH = Path(r"C:\Users\omerh\.gemini\antigravity\brain\5c6894fa-1020-4a71-85b7-176bca5fdccd\.user_uploaded\media_1791553833755_9957dd0b.png")
OUT_BG_PATH = BASE_DIR / "assets" / "sprites" / "backgrounds" / "bg_silas_office.png"
ARTIFACT_DIR = Path(r"C:\Users\omerh\.gemini\antigravity\brain\5c6894fa-1020-4a71-85b7-176bca5fdccd")

def build_pristine_bg():
    orig = Image.open(CONCEPT_PATH).convert("RGBA")
    
    # 320x180 native canvas
    bg = Image.new("RGBA", (320, 180), (14, 15, 20, 255))
    
    # Color palette directly sampled from concept art:
    WALL_DARK = (28, 25, 33)       # Dark vignette wallpaper
    WALL_LIGHT = (48, 43, 54)      # Lamp-illuminated wallpaper
    WALL_MOTIF = (38, 34, 44)      # Damask motif color
    WAIN_DARK = (20, 18, 24)       # Dark wainscot wood
    WAIN_MID = (32, 28, 36)        # Wainscot wood face
    WAIN_HIGH = (44, 38, 48)       # Wainscot highlight rail
    FLOOR_DARK = (16, 15, 20)      # Deep floorboard seam
    FLOOR_WOOD = (26, 24, 32)      # Floorboard wood
    FLOOR_HIGH = (36, 32, 42)      # Floorboard light reflection
    
    # 1. Upper Wall Wallpaper: y = 20 to 105
    for y in range(20, 105):
        for x in range(320):
            # Radial distance from ceiling lamp at (160, 24)
            dist = np.hypot((x - 160) * 0.7, y - 24)
            t = np.clip(1.0 - (dist / 140.0), 0.0, 1.0)
            base_r = int(WALL_DARK[0] + (WALL_LIGHT[0] - WALL_DARK[0]) * t)
            base_g = int(WALL_DARK[1] + (WALL_LIGHT[1] - WALL_DARK[1]) * t)
            base_b = int(WALL_DARK[2] + (WALL_LIGHT[2] - WALL_DARK[2]) * t)
            
            # Subtle vertical damask stripe every 12px
            in_stripe = (x % 12) in [0, 1]
            # Diamond motif every 12x12
            in_diamond = ((x + y) % 12 == 0) or ((x - y) % 12 == 0)
            if in_stripe or (in_diamond and y % 3 == 0):
                base_r = int(base_r * 1.15)
                base_g = int(base_g * 1.15)
                base_b = int(base_b * 1.15)
                
            bg.putpixel((x, y), (base_r, base_g, base_b, 255))
            
    # 2. Ceiling and crown molding: y = 0 to 20
    # Crown molding lines:
    for y in range(0, 20):
        col = (10, 11, 15, 255)
        if y in [12, 13]:
            col = (35, 30, 40, 255)
        elif y in [14, 15]:
            col = (25, 22, 30, 255)
        elif y in [16, 17]:
            col = (18, 16, 22, 255)
        elif y in [18, 19]:
            col = (8, 9, 12, 255)
        for x in range(320):
            bg.putpixel((x, y), col)
            
    # Hanging Ceiling Lamp at x = 152..168, y = 0..30
    # Sample actual lamp from concept art: x=475..535, y=30..120 in 1024x571
    lamp_crop = orig.crop((475, 30, 535, 120))
    lamp_small = lamp_crop.resize((19, 29), Image.Resampling.LANCZOS)
    bg.paste(lamp_small, (160 - 9, 2), lamp_small)
    
    # 3. Wainscoting: y = 105 to 138
    # Top rail molding: y = 105..109
    for y in range(105, 109):
        col = WAIN_HIGH if y == 106 else WAIN_MID
        for x in range(320):
            bg.putpixel((x, y), (col[0], col[1], col[2], 255))
            
    # Vertical wainscoting wood slats: y = 109 to 134
    for y in range(109, 134):
        for x in range(320):
            dist = abs(x - 160) / 160.0
            t = np.clip(1.0 - dist * 0.6, 0.4, 1.0)
            # 6px slat pattern with 1px shadow groove
            is_groove = (x % 6 == 0)
            if is_groove:
                r = int(WAIN_DARK[0] * t)
                g = int(WAIN_DARK[1] * t)
                b = int(WAIN_DARK[2] * t)
            elif x % 6 == 1:
                r = int(WAIN_HIGH[0] * t)
                g = int(WAIN_HIGH[1] * t)
                b = int(WAIN_HIGH[2] * t)
            else:
                r = int(WAIN_MID[0] * t)
                g = int(WAIN_MID[1] * t)
                b = int(WAIN_MID[2] * t)
            bg.putpixel((x, y), (r, g, b, 255))
            
    # Baseboard molding: y = 134 to 138
    for y in range(134, 138):
        col = WAIN_DARK if y == 137 else WAIN_MID
        for x in range(320):
            bg.putpixel((x, y), (col[0], col[1], col[2], 255))
            
    # 4. Floorboards: y = 138 to 180
    for y in range(138, 180):
        # Floor plank seams every 7-8px with perspective
        is_seam = (y in [145, 153, 162, 171])
        for x in range(320):
            dist = abs(x - 160) / 160.0
            t = np.clip(1.0 - dist * 0.5, 0.5, 1.0)
            if is_seam:
                r, g, b = FLOOR_DARK
            elif (x + y * 2) % 32 == 0: # subtle wood grain
                r = int(FLOOR_HIGH[0] * t)
                g = int(FLOOR_HIGH[1] * t)
                b = int(FLOOR_HIGH[2] * t)
            else:
                r = int(FLOOR_WOOD[0] * t)
                g = int(FLOOR_WOOD[1] * t)
                b = int(FLOOR_WOOD[2] * t)
            bg.putpixel((x, y), (r, g, b, 255))
            
    # 5. Clean Runner Rug from concept art: x = 70 to 220, y = 146 to 170
    # Sample clean rug from concept: x=280..680, y=462..534
    rug_sample = orig.crop((280, 462, 680, 534))
    # Downscale cleanly to 160x24
    rug_small = rug_sample.resize((150, 24), Image.Resampling.LANCZOS)
    bg.paste(rug_small, (75, 146))
    
    # 6. Rainy Window from concept art: x = 226 to 276, y = 30 to 110 (50x80)
    # The concept window is at x=716..876, y=96..348 in 1024x571
    win_orig = orig.crop((716, 96, 876, 348))
    # Replace bottom pane (green lamp) with top pane (rain streaks)
    top_pane = win_orig.crop((20, 18, 140, 116))
    win_orig.paste(top_pane.transpose(Image.FLIP_LEFT_RIGHT), (20, 134))
    # Central sash bar
    sash_bar = orig.crop((716 + 18, 96 + 116, 716 + 142, 96 + 134))
    win_orig.paste(sash_bar, (18, 116))
    
    win_small = win_orig.resize((50, 78), Image.Resampling.LANCZOS)
    bg.paste(win_small, (226, 30))
    
    # 7. Framed Picture on far right wall: x = 296 to 318, y = 44 to 80 (22x36)
    pic_orig = orig.crop((960, 140, 1024, 256))
    pic_small = pic_orig.resize((20, 36), Image.Resampling.LANCZOS)
    bg.paste(pic_small, (298, 44))
    
    # 8. Left wall corner shadow / crack
    left_orig = orig.crop((0, 90, 50, 340))
    left_small = left_orig.resize((16, 78), Image.Resampling.LANCZOS)
    bg.paste(left_small, (0, 30))
    
    # Save target background
    OUT_BG_PATH.parent.mkdir(parents=True, exist_ok=True)
    bg.convert("RGB").save(OUT_BG_PATH, "PNG")
    print(f"Saved pristine background to {OUT_BG_PATH}")
    
    # Save 4x preview
    preview_4x = bg.resize((1280, 720), Image.Resampling.NEAREST)
    prev_dest = ARTIFACT_DIR / "clean_silas_office_bg_4x.png"
    preview_4x.save(prev_dest, "PNG")
    print(f"Saved 4x preview to {prev_dest}")

if __name__ == "__main__":
    build_pristine_bg()
