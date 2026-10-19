#!/usr/bin/env python3
"""
Generate Silas Height Test Screenshots (70px, 84px, 100px)
at 480x270 resolution with Silas foot line at y=245.
Generates 1x (480x270) and 4x (1920x1080) screenshots.
"""

from pathlib import Path
from PIL import Image

BASE_DIR = Path(__file__).resolve().parent.parent
PLATE_PATH = BASE_DIR / "assets" / "plates" / "bg_hub_office.png"
SILAS_PATH = BASE_DIR / "assets" / "sprites" / "characters" / "silas_idle_right.png"
ARTIFACT_DIR = Path(r"C:\Users\omerh\.gemini\antigravity\brain\5c6894fa-1020-4a71-85b7-176bca5fdccd")

def render_silas_test(height_px: int, out_prefix: str) -> None:
    plate = Image.open(PLATE_PATH).convert("RGBA")
    silas_orig = Image.open(SILAS_PATH).convert("RGBA")
    
    # Calculate scaled width keeping exact aspect ratio
    orig_w, orig_h = silas_orig.size # 32, 48
    scale = height_px / float(orig_h)
    new_w = int(round(orig_w * scale))
    new_h = height_px
    
    # Clean nearest neighbor scale for pixel art
    silas_scaled = silas_orig.resize((new_w, new_h), Image.Resampling.NEAREST)
    
    # Foot line at y = 245
    # Silas standing on the rug at X = 205 (in front of radio/coat rack)
    foot_y = 245
    top_y = foot_y - new_h
    center_x = 205
    top_x = center_x - new_w // 2
    
    canvas_1x = plate.copy()
    
    # Simple shadow ellipse under feet
    shadow = Image.new("RGBA", (new_w + 8, 8), (0, 0, 0, 0))
    from PIL import ImageDraw
    d = ImageDraw.Draw(shadow)
    d.ellipse([0, 0, new_w + 7, 7], fill=(11, 15, 26, 120))
    canvas_1x.paste(shadow, (center_x - (new_w + 8) // 2, foot_y - 4), shadow)
    
    # Paste Silas
    canvas_1x.paste(silas_scaled, (top_x, top_y), silas_scaled)
    
    # Also add a second Silas pose near the phone (x = 275) to show scale relative to phone table & desk
    top_x2 = 275 - new_w // 2
    canvas_1x.paste(shadow, (275 - (new_w + 8) // 2, foot_y - 4), shadow)
    canvas_1x.paste(silas_scaled, (top_x2, top_y), silas_scaled)
    
    # Save 1x (480x270)
    path_1x = ARTIFACT_DIR / f"{out_prefix}_1x.png"
    canvas_1x.save(path_1x, "PNG")
    
    # Save 4x (1920x1080)
    canvas_4x = canvas_1x.resize((1920, 1080), Image.Resampling.NEAREST)
    path_4x = ARTIFACT_DIR / f"{out_prefix}_4x.png"
    canvas_4x.save(path_4x, "PNG")
    
    print(f"Generated {out_prefix}: Silas {new_w}x{new_h}px, feet at y={foot_y} (1x: {path_1x.name}, 4x: {path_4x.name})")

def main():
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    
    # 3 Heights: 70px, 84px, 100px
    render_silas_test(70, "silas_scale_70px")
    render_silas_test(84, "silas_scale_84px")
    render_silas_test(100, "silas_scale_100px")
    
    # Also extract detail crops (Pano, Daktilo, Radyo) to inspect legibility
    plate = Image.open(PLATE_PATH).convert("RGBA")
    
    # Pano (clue board): x=280..375, y=75..135
    pano_crop = plate.crop((280, 75, 375, 135))
    pano_4x = pano_crop.resize((pano_crop.width * 4, pano_crop.height * 4), Image.Resampling.NEAREST)
    pano_4x.save(ARTIFACT_DIR / "detail_pano_4x.png")
    
    # Daktilo & Banker Lambası: x=345..400, y=130..185
    daktilo_crop = plate.crop((345, 130, 400, 185))
    daktilo_4x = daktilo_crop.resize((daktilo_crop.width * 4, daktilo_crop.height * 4), Image.Resampling.NEAREST)
    daktilo_4x.save(ARTIFACT_DIR / "detail_daktilo_4x.png")
    
    # Radyo & Komodin: x=175..230, y=135..215
    radyo_crop = plate.crop((175, 135, 230, 215))
    radyo_4x = radyo_crop.resize((radyo_crop.width * 4, radyo_crop.height * 4), Image.Resampling.NEAREST)
    radyo_4x.save(ARTIFACT_DIR / "detail_radyo_4x.png")
    
    print("Detail crops saved successfully.")

if __name__ == "__main__":
    main()
