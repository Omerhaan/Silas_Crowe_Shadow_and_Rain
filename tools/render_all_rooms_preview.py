#!/usr/bin/env python3
"""
Render Gameplay Previews for all rooms with Silas Crowe and authentic NPCs.
Saves 1x and 4x previews to artifacts directory.
"""

from pathlib import Path
from PIL import Image

BASE_DIR = Path(__file__).resolve().parent.parent
PLATES_DIR = BASE_DIR / "assets" / "plates"
CHARS_DIR = BASE_DIR / "assets" / "sprites" / "characters"
SHADOW_PATH = BASE_DIR / "assets" / "sprites" / "shadow_silas.png"
ARTIFACTS_DIR = Path(r"C:\Users\omerh\.gemini\antigravity\brain\5c6894fa-1020-4a71-85b7-176bca5fdccd")

def paste_char(bg: Image.Image, char_img: Image.Image, shadow_img: Image.Image, x: int, y: int):
    # char canvas is 64x104, feet anchored at y=100, center at x=32
    # Shadow is 40x10, center at x=20, top-left at (x - 20, y - 5)
    # Char top-left at (x - 32, y - 100)
    bg.paste(shadow_img, (x - 20, y - 5), shadow_img)
    bg.paste(char_img, (x - 32, y - 100), char_img)

def main():
    shadow = Image.open(SHADOW_PATH).convert("RGBA")
    silas = Image.open(CHARS_DIR / "silas_idle_right.png").convert("RGBA")
    silas_left = Image.open(CHARS_DIR / "silas_idle_left.png").convert("RGBA")
    
    room_configs = [
        ("bg_main_hall.png", "room_main_hall", [(silas, 240, 245)]),
        ("bg_study.png", "room_study", [(silas, 200, 245)]),
        ("bg_library.png", "room_library", [
            (Image.open(CHARS_DIR / "hale_idle_down.png").convert("RGBA"), 185, 245),
            (silas_left, 320, 245)
        ]),
        ("bg_dining_room.png", "room_dining_room", [
            (Image.open(CHARS_DIR / "pike_idle_down.png").convert("RGBA"), 155, 245),
            (silas_left, 340, 245)
        ]),
        ("bg_kitchen.png", "room_kitchen", [
            (Image.open(CHARS_DIR / "margaret_idle_down.png").convert("RGBA"), 205, 245),
            (silas_left, 320, 245)
        ]),
        ("bg_billiard_room.png", "room_billiard_room", [
            (silas, 180, 245),
            (Image.open(CHARS_DIR / "julian_idle_down.png").convert("RGBA"), 330, 245)
        ]),
        ("bg_upper_floor.png", "room_upper_floor", [(silas, 200, 245)]),
    ]
    
    for plate_name, out_label, chars in room_configs:
        bg = Image.open(PLATES_DIR / plate_name).convert("RGBA")
        comp = bg.copy()
        
        for c_img, cx, cy in chars:
            paste_char(comp, c_img, shadow, cx, cy)
            
        p1 = ARTIFACTS_DIR / f"{out_label}_1x.png"
        comp.save(p1, "PNG")
        
        comp_4x = comp.resize((comp.width * 4, comp.height * 4), Image.Resampling.NEAREST)
        p4 = ARTIFACTS_DIR / f"{out_label}_4x.png"
        comp_4x.save(p4, "PNG")
        print(f"Generated {out_label} 1x & 4x previews.")

if __name__ == "__main__":
    main()
