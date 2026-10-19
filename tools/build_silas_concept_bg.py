#!/usr/bin/env python3
"""
Build clean empty Silas Office background plate at 320x180 from the concept art.
Removes baked furniture (Silas sitting at desk, desk, armchair, cabinet) so that
our sharp pixel-art asset sprites (silas_desk, silas_armchair, etc.) can be placed
as independent physics/interactable objects without blur or collision issues.
"""

from pathlib import Path
from PIL import Image, ImageFilter
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent
CONCEPT_PATH = Path(r"C:\Users\omerh\.gemini\antigravity\brain\5c6894fa-1020-4a71-85b7-176bca5fdccd\.user_uploaded\media_1791553833755_9957dd0b.png")
OUT_BG_PATH = BASE_DIR / "assets" / "sprites" / "backgrounds" / "bg_silas_office.png"
ARTIFACT_DIR = Path(r"C:\Users\omerh\.gemini\antigravity\brain\5c6894fa-1020-4a71-85b7-176bca5fdccd")

def main():
    im = Image.open(CONCEPT_PATH).convert("RGBA")
    w, h = im.size # 1024, 571
    
    # We will build a clean 1024x571 room shell, then downsample cleanly to 320x180.
    plate = Image.new("RGBA", (w, h), (18, 16, 22, 255))
    
    # 1. Clean Wallpaper Sample
    # Clean section between coat rack and Silas head: x=530..640, y=140..310 (110x170)
    wall_sample = im.crop((530, 140, 640, 310))
    # Tile wallpaper horizontally across the entire upper wall (y=90 to 330)
    for px in range(0, w, wall_sample.width):
        plate.paste(wall_sample, (px, 140))
        # Top extension if needed
        plate.paste(wall_sample.crop((0, 0, wall_sample.width, 60)), (px, 90))
        
    # 2. Wainscoting Sample (lower wall paneling)
    # Clean section: x=530..640, y=340..420 (110x80)
    wain_sample = im.crop((530, 340, 640, 420))
    for px in range(0, w, wain_sample.width):
        plate.paste(wain_sample, (px, 330))
        plate.paste(wain_sample.crop((0, 0, wain_sample.width, 40)), (px, 410))
        
    # 3. Floor Sample & Perspective
    # Floor: y=430 to 571
    # Clean section in the middle: x=340..580, y=430..570
    floor_sample = im.crop((340, 430, 580, 570))
    for px in range(0, w, floor_sample.width):
        plate.paste(floor_sample, (px, 430))
        
    # 4. Center Rug Runner
    # Rug is at x=215..740, y=460..535 in original
    rug = im.crop((215, 460, 740, 535))
    # Inpaint/clean feet from rug: Silas's feet are around x=670..710, y=470..530
    # Clean rug patch from x=320..360:
    rug_patch = rug.crop((105, 0, 155, rug.height))
    rug.paste(rug_patch, (455, 0)) # replace feet area on rug with clean rug pattern
    plate.paste(rug, (215, 460))
    
    # 5. Rainy Window (x=716..876, y=96..348)
    window = im.crop((716, 96, 876, 348))
    plate.paste(window, (716, 96))
    
    # 6. Framed Picture on right wall (x=960..1024, y=140..256)
    pic = im.crop((960, 140, 1024, 256))
    plate.paste(pic, (960, 140))
    
    # 7. Ceiling & Crown Molding & Hanging Lamp (y=0..130)
    ceiling = im.crop((0, 0, w, 130))
    # Replace top part of plate with original dark ceiling, beams, molding, and pendant lamp!
    plate.paste(ceiling, (0, 0))
    
    # 8. Left wall corner shading & Right wall corner shading
    # Let's check left corner of original (x=0..60, y=90..340)
    left_corner = im.crop((0, 90, 60, 340))
    plate.paste(left_corner, (0, 90))
    
    # 9. Clean downscale to 320x180 using high quality Lanczos (crisp, no dither, 16:9)
    bg_320 = plate.resize((320, 180), Image.Resampling.LANCZOS)
    
    # Save target background
    OUT_BG_PATH.parent.mkdir(parents=True, exist_ok=True)
    bg_320.convert("RGB").save(OUT_BG_PATH, "PNG")
    print(f"Saved clean background to {OUT_BG_PATH}")
    
    # Save 4x preview for inspection
    preview_4x = bg_320.resize((1280, 720), Image.Resampling.NEAREST)
    prev_dest = ARTIFACT_DIR / "clean_silas_office_bg_4x.png"
    preview_4x.save(prev_dest, "PNG")
    print(f"Saved 4x preview to {prev_dest}")

if __name__ == "__main__":
    main()
