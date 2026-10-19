#!/usr/bin/env python3
"""
Render authentic in-game view of Silas Office at 480x270 (and 1920x1080 4x)
with native 1:1 pixel art Silas Crowe from A1_silas_pozlar, authentic shadow,
HUD top bar, and clean inner voice dialog.
"""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = Path(__file__).resolve().parent.parent
PLATE_PATH = BASE_DIR / "assets" / "plates" / "bg_hub_office.png"
SILAS_PATH = BASE_DIR / "assets" / "sprites" / "characters" / "silas_idle_right.png"
SILAS_PHONE_PATH = BASE_DIR / "assets" / "sprites" / "characters" / "silas_phone.png"
SHADOW_PATH = BASE_DIR / "assets" / "sprites" / "shadow_silas.png"
ARTIFACT_DIR = Path(r"C:\Users\omerh\.gemini\antigravity\brain\5c6894fa-1020-4a71-85b7-176bca5fdccd")

def render_preview():
    plate = Image.open(PLATE_PATH).convert("RGBA")
    w, h = plate.size # 480, 270
    
    silas = Image.open(SILAS_PATH).convert("RGBA")
    silas_phone = Image.open(SILAS_PHONE_PATH).convert("RGBA")
    shadow = Image.open(SHADOW_PATH).convert("RGBA")
    
    foot_y = 245
    
    # 1. Shadow & Silas standing at spawn x=202
    sw, sh = shadow.size
    plate.paste(shadow, (202 - sw // 2, foot_y - sh // 2), shadow)
    
    # Silas canvas is 64x104, feet anchored at y=100
    # So top_y = foot_y - 100
    top_x = 202 - silas.width // 2
    top_y = foot_y - 100
    plate.paste(silas, (top_x, top_y), silas)
    
    # 2. UI Overlay (HUD)
    ui_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d_ui = ImageDraw.Draw(ui_layer)
    
    # Top bar
    d_ui.rectangle([0, 0, w, 14], fill=(11, 15, 26, 200))
    try:
        font_small = ImageFont.load_default()
    except Exception:
        font_small = None

    d_ui.text((6, 2), "Silas'in Ofisi", fill=(245, 227, 161, 255), font=font_small)
    d_ui.line([(70, 2), (70, 11)], fill=(120, 130, 140, 180), width=1)
    d_ui.text((76, 2), "[A/D]: Yuru  *  [E / W]: Incele / Gec", fill=(140, 153, 166, 210), font=font_small)
    d_ui.text((410, 2), "Defter", fill=(220, 225, 230, 240), font=font_small)
    d_ui.text((460, 2), "[*]", fill=(220, 225, 230, 240), font=font_small)
    
    # Inner voice panel at the bottom
    d_ui.rectangle([16, 226, w - 16, 264], fill=(11, 15, 26, 225), outline=(50, 60, 75, 240), width=1)
    d_ui.text((26, 232), '"Yagmur dinmiyor. Masadaki esyalara goz atsam iyi olur..."', fill=(191, 209, 230, 255), font=font_small)
    d_ui.text((w - 145, 248), "[Dokun / E ile Kapat]", fill=(230, 191, 77, 255), font=font_small)
    
    final_img = Image.alpha_composite(plate, ui_layer)
    
    # Save 1x (480x270)
    p1x = ARTIFACT_DIR / "silas_authentic_gameplay_1x.png"
    final_img.save(p1x, "PNG")
    
    # Save 4x (1920x1080)
    final_4x = final_img.resize((1920, 1080), Image.Resampling.NEAREST)
    p4x = ARTIFACT_DIR / "silas_authentic_gameplay_4x.png"
    final_4x.save(p4x, "PNG")
    
    # Also render phone call pose preview at desk (x=280)
    plate_phone = Image.open(PLATE_PATH).convert("RGBA")
    plate_phone.paste(shadow, (280 - sw // 2, foot_y - sh // 2), shadow)
    top_x_phone = 280 - silas_phone.width // 2
    plate_phone.paste(silas_phone, (top_x_phone, top_y), silas_phone)
    phone_4x = plate_phone.resize((1920, 1080), Image.Resampling.NEAREST)
    phone_4x.save(ARTIFACT_DIR / "silas_phone_call_in_office_4x.png", "PNG")
    
    # Also render walk comparison
    walk3 = Image.open(BASE_DIR / "assets" / "sprites" / "characters" / "silas_walk_right_3.png").convert("RGBA")
    plate_walk = Image.open(PLATE_PATH).convert("RGBA")
    plate_walk.paste(shadow, (220 - sw // 2, foot_y - sh // 2), shadow)
    plate_walk.paste(walk3, (220 - walk3.width // 2, top_y), walk3)
    walk_4x = plate_walk.resize((1920, 1080), Image.Resampling.NEAREST)
    walk_4x.save(ARTIFACT_DIR / "silas_walk_in_office_4x.png", "PNG")

    print("All gameplay previews rendered successfully.")

if __name__ == "__main__":
    render_preview()
