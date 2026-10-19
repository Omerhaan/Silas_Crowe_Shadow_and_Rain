#!/usr/bin/env python3
"""
Generate standardized 32x48 character sprites for 'Gölge ve Yağmur'.
Characters fit inside 28x48 bounding box on a 32x48 canvas (2px padding left/right).
Feet align precisely with bottom pixel row (y=47).
Quantized to noir24.hex palette with 1px dark contour (0b0f1a).
"""

import os
from PIL import Image
import numpy as np
from pixelize import load_palette, quantize_to_palette, add_outline

PALETTE_PATH = "data/palette/noir24.hex"
OUT_DIR = "assets/sprites/characters"

def hex_to_rgb(hex_str: str) -> tuple[int, int, int]:
    h = hex_str.strip().lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))

# Key palette colors
COL_OUTLINE = hex_to_rgb("0b0f1a")
COL_SHADOW = hex_to_rgb("0d1321")
COL_NAVY = hex_to_rgb("1d2b53")
COL_SLATE_DARK = hex_to_rgb("2b2a2f")
COL_SLATE_MID = hex_to_rgb("5a5560")
COL_SLATE_LIGHT = hex_to_rgb("8a8691")
COL_HAIR_SILVER = hex_to_rgb("a3b5a8")
COL_HAIR_GREY = hex_to_rgb("8a8691")
COL_SKIN_BASE = hex_to_rgb("e6dccb")
COL_SKIN_SHADOW = hex_to_rgb("c9783a")
COL_SKIN_LIGHT = hex_to_rgb("f2eadc")
COL_SCAR = hex_to_rgb("b0302c")
COL_COAT_GREY = hex_to_rgb("5a5560")
COL_COAT_DARK = hex_to_rgb("2b2a2f")
COL_COAT_HIGH = hex_to_rgb("7f9186")
COL_CRIMSON_DEEP = hex_to_rgb("7e2f3a")
COL_CRIMSON_MID = hex_to_rgb("a24a4f")
COL_WOOD_DARK = hex_to_rgb("4a2f1d")
COL_AMBER = hex_to_rgb("b5803f")

def create_silas_sprite(direction: str = "down", walk_frame: int = 0) -> Image.Image:
    # 32x48 RGBA canvas
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    arr = np.zeros((48, 32, 4), dtype=np.uint8)

    def set_px(x, y, rgb):
        if 0 <= x < 32 and 0 <= y < 48:
            arr[y, x, :3] = rgb
            arr[y, x, 3] = 255

    def fill_rect(x1, y1, x2, y2, rgb):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                set_px(x, y, rgb)

    # 1. Silas Head & Hair: y = 2..15 (Spiky grey/silver hair, scar, stubble)
    if direction in ["down", "left", "right"]:
        # Spiky hair tips: y = 1..5
        for sx in range(11, 21):
            if sx in [11, 13, 16, 18, 20]:
                set_px(sx, 1, COL_HAIR_SILVER)
            if sx in [12, 14, 15, 17, 19]:
                set_px(sx, 2, COL_HAIR_GREY)
        fill_rect(10, 3, 21, 6, COL_HAIR_GREY)
        fill_rect(11, 4, 20, 6, COL_HAIR_SILVER)

        # Face: y = 7..14
        fill_rect(11, 7, 20, 13, COL_SKIN_BASE)
        # Forehead shadow
        fill_rect(11, 7, 20, 7, COL_SLATE_MID)

        # Eyes & stubble
        if direction == "down":
            set_px(13, 9, COL_OUTLINE) # Left eye
            set_px(18, 9, COL_OUTLINE) # Right eye
            # Facial Scar across left eye/cheek: y=8..12, x=14..12
            set_px(14, 8, COL_SCAR)
            set_px(14, 9, COL_SCAR)
            set_px(13, 10, COL_SCAR)
            set_px(13, 11, COL_SCAR)
            # Stubble beard: y=12..14
            fill_rect(12, 12, 19, 13, COL_SLATE_MID)
            set_px(15, 12, COL_SKIN_SHADOW) # Mouth
            set_px(16, 12, COL_SKIN_SHADOW)
        elif direction == "right":
            set_px(18, 9, COL_OUTLINE)
            set_px(17, 10, COL_SCAR)
            set_px(18, 11, COL_SCAR)
            fill_rect(14, 12, 19, 13, COL_SLATE_MID)
        elif direction == "left":
            set_px(13, 9, COL_OUTLINE)
            set_px(14, 9, COL_SCAR)
            set_px(13, 10, COL_SCAR)
            fill_rect(12, 12, 17, 13, COL_SLATE_MID)
    else: # "up"
        # Back of head: full spiky grey hair
        for sx in range(11, 21):
            if sx % 2 == 1:
                set_px(sx, 1, COL_HAIR_SILVER)
        fill_rect(10, 2, 21, 12, COL_HAIR_GREY)
        fill_rect(11, 3, 20, 10, COL_HAIR_SILVER)
        fill_rect(12, 13, 19, 14, COL_COAT_DARK) # Neck

    # 2. High-collared Grey Trench Coat: y = 14..36
    # High upturned lapels/collar
    if direction in ["down", "left", "right"]:
        set_px(9, 13, COL_COAT_GREY)
        set_px(9, 14, COL_COAT_HIGH)
        set_px(10, 14, COL_COAT_GREY)
        set_px(22, 13, COL_COAT_GREY)
        set_px(22, 14, COL_COAT_HIGH)
        set_px(21, 14, COL_COAT_GREY)
        # Trench coat chest & torso: y = 15..28
        fill_rect(9, 15, 22, 28, COL_COAT_GREY)
        # Lapel diagonal creases
        draw_lapel = True if direction == "down" else False
        if draw_lapel:
            fill_rect(14, 15, 17, 18, COL_SLATE_DARK) # Dark tie/shirt beneath
            set_px(15, 16, COL_SKIN_LIGHT)
            set_px(16, 16, COL_SKIN_LIGHT)
            # Buttons
            set_px(17, 20, COL_SLATE_LIGHT)
            set_px(17, 24, COL_SLATE_LIGHT)
            # Belt: y = 26..27
            fill_rect(9, 26, 22, 27, COL_COAT_DARK)
            set_px(15, 26, COL_AMBER)
            set_px(16, 26, COL_AMBER)
        # Coat lower skirt: y = 28..36
        fill_rect(8, 28, 23, 36, COL_COAT_GREY)
        fill_rect(9, 29, 22, 35, COL_COAT_DARK)
        # Highlight along one edge
        for cy in range(16, 36):
            set_px(9, cy, COL_COAT_HIGH)
    else: # "up"
        fill_rect(9, 15, 22, 36, COL_COAT_GREY)
        fill_rect(10, 16, 21, 35, COL_COAT_DARK)
        fill_rect(9, 26, 22, 27, COL_SLATE_DARK) # Belt

    # 3. Legs and Boots: y = 37..47 (Bottom row at y=47!)
    # Walking leg strides
    leg_l_x = 11
    leg_r_x = 18
    stride = 0
    if walk_frame == 1:
        stride = 2
    elif walk_frame == 2:
        stride = -2
    elif walk_frame == 3:
        stride = 3
    elif walk_frame == 4:
        stride = -3

    if direction in ["left", "right"]:
        dir_mult = 1 if direction == "right" else -1
        # Side view legs
        fill_rect(13 - stride * dir_mult, 37, 16 - stride * dir_mult, 43, COL_SLATE_DARK)
        fill_rect(15 + stride * dir_mult, 37, 18 + stride * dir_mult, 43, COL_COAT_DARK)
        # Boots: y = 44..47
        fill_rect(12 - stride * dir_mult, 44, 17 - stride * dir_mult, 47, COL_OUTLINE)
        fill_rect(15 + stride * dir_mult, 44, 20 + stride * dir_mult, 47, COL_SHADOW)
    else:
        # Down / Up legs
        fill_rect(leg_l_x - (1 if stride > 0 else 0), 37, leg_l_x + 3, 43, COL_SLATE_DARK)
        fill_rect(leg_r_x, 37, leg_r_x + 3 + (1 if stride < 0 else 0), 43, COL_SLATE_DARK)
        # Boots: y = 44..47 (exact feet bottom at row 47)
        fill_rect(leg_l_x - 1, 44, leg_l_x + 3, 47, COL_OUTLINE)
        fill_rect(leg_r_x, 44, leg_r_x + 4, 47, COL_OUTLINE)
        # Sole highlight on row 47
        set_px(leg_l_x - 1, 47, COL_SHADOW)
        set_px(leg_r_x + 4, 47, COL_SHADOW)

    img = Image.fromarray(arr, mode="RGBA")
    img = add_outline(img, COL_OUTLINE)
    return img

def create_npc_sprite(npc_id: str, direction: str = "down") -> Image.Image:
    # 32x48 canvas
    arr = np.zeros((48, 32, 4), dtype=np.uint8)

    def set_px(x, y, rgb):
        if 0 <= x < 32 and 0 <= y < 48:
            arr[y, x, :3] = rgb
            arr[y, x, 3] = 255

    def fill_rect(x1, y1, x2, y2, rgb):
        for y in range(y1, y2 + 1):
            for x in range(x1, x2 + 1):
                set_px(x, y, rgb)

    if npc_id == "margaret":
        # Margaret Doyle: Housekeeper, severe bun, black dress, white apron
        # Hair bun: y = 4..7
        fill_rect(13, 3, 18, 6, COL_SLATE_MID)
        # Face: y = 7..14
        fill_rect(12, 7, 19, 13, COL_SKIN_BASE)
        if direction == "down":
            set_px(14, 9, COL_OUTLINE)
            set_px(17, 9, COL_OUTLINE)
            set_px(15, 12, COL_CRIMSON_DEEP) # Tight lips
        # High white collar: y = 14..15
        fill_rect(13, 14, 18, 15, COL_SKIN_LIGHT)
        # Dark Victorian Dress: y = 16..45
        fill_rect(10, 16, 21, 26, COL_COAT_DARK)
        # White Apron bib and skirt: y = 18..38
        fill_rect(12, 18, 19, 36, COL_SKIN_LIGHT)
        fill_rect(13, 19, 18, 35, hex_to_rgb("e6dccb"))
        # Wide skirt: y = 37..45
        fill_rect(8, 37, 23, 45, COL_COAT_DARK)
        # Shoes: y = 46..47
        fill_rect(12, 46, 15, 47, COL_OUTLINE)
        fill_rect(16, 46, 19, 47, COL_OUTLINE)

    elif npc_id == "hale":
        # Dr. Victor Hale: Slicked dark hair, spectacles, dark suit & tie, pocket watch chain
        # Hair: y = 4..8
        fill_rect(11, 4, 20, 7, COL_SLATE_DARK)
        # Face: y = 8..14
        fill_rect(12, 8, 19, 14, COL_SKIN_BASE)
        if direction == "down":
            # Gold spectacles
            fill_rect(13, 9, 15, 10, COL_AMBER)
            set_px(14, 9, COL_SKIN_LIGHT)
            fill_rect(16, 9, 18, 10, COL_AMBER)
            set_px(17, 9, COL_SKIN_LIGHT)
            set_px(15, 9, COL_AMBER) # Bridge
            set_px(15, 13, COL_SKIN_SHADOW) # Thin mustache
            set_px(16, 13, COL_SKIN_SHADOW)
        # Charcoal Frock Coat & Vest: y = 15..34
        fill_rect(10, 15, 21, 33, COL_COAT_DARK)
        fill_rect(13, 15, 18, 26, COL_SLATE_MID) # Vest
        fill_rect(14, 15, 17, 18, COL_SKIN_LIGHT) # White shirt
        set_px(15, 17, hex_to_rgb("b0302c")) # Red cravat
        # Gold watch chain
        draw_chain = [Vector2(14, 23), Vector2(15, 24), Vector2(16, 24), Vector2(17, 23)] if False else None
        set_px(14, 23, COL_AMBER)
        set_px(15, 24, COL_AMBER)
        set_px(16, 23, COL_AMBER)
        # Trousers: y = 34..44
        fill_rect(11, 34, 14, 44, COL_SLATE_DARK)
        fill_rect(17, 34, 20, 44, COL_SLATE_DARK)
        # Polished leather shoes: y = 45..47
        fill_rect(10, 45, 15, 47, COL_OUTLINE)
        fill_rect(17, 45, 22, 47, COL_OUTLINE)

    elif npc_id == "julian":
        # Julian Harlow: Tousled brown hair, unbuttoned collar, velvet smoking jacket
        fill_rect(11, 3, 20, 7, COL_WOOD_DARK)
        set_px(10, 5, COL_WOOD_DARK)
        set_px(21, 5, COL_WOOD_DARK)
        fill_rect(12, 8, 19, 14, COL_SKIN_BASE)
        if direction == "down":
            set_px(14, 10, COL_OUTLINE)
            set_px(17, 10, COL_OUTLINE)
            set_px(15, 13, COL_SKIN_SHADOW)
        # Velvet Burgundy Jacket: y = 15..34
        fill_rect(10, 15, 21, 32, COL_CRIMSON_DEEP)
        fill_rect(13, 15, 18, 22, COL_SKIN_LIGHT) # Open white shirt
        set_px(15, 18, COL_SKIN_BASE) # Bare throat
        # Light trousers: y = 33..44
        fill_rect(11, 33, 14, 44, hex_to_rgb("8a8691"))
        fill_rect(17, 33, 20, 44, hex_to_rgb("8a8691"))
        # Shoes: y = 45..47
        fill_rect(10, 45, 15, 47, COL_WOOD_DARK)
        fill_rect(17, 45, 22, 47, COL_WOOD_DARK)

    elif npc_id == "pike":
        # Raymond Pike: Heavy build, bowler hat, thick mustache, tweed suit
        # Bowler Hat: y = 2..8
        fill_rect(12, 2, 19, 6, COL_OUTLINE)
        fill_rect(9, 7, 22, 8, COL_OUTLINE)
        # Face: y = 9..15
        fill_rect(11, 9, 20, 15, COL_SKIN_BASE)
        if direction == "down":
            set_px(13, 11, COL_OUTLINE)
            set_px(18, 11, COL_OUTLINE)
            # Big bushy mustache
            fill_rect(12, 13, 19, 14, COL_WOOD_DARK)
        # Broad shoulders tweed coat: y = 16..35
        fill_rect(8, 16, 23, 35, hex_to_rgb("3e4a47"))
        fill_rect(9, 17, 22, 34, hex_to_rgb("5c6b63"))
        # Heavy boots: y = 44..47
        fill_rect(9, 44, 15, 47, COL_OUTLINE)
        fill_rect(16, 44, 22, 47, COL_OUTLINE)

    img = Image.fromarray(arr, mode="RGBA")
    img = add_outline(img, COL_OUTLINE)
    return img

def main():
    palette = load_palette(PALETTE_PATH)
    os.makedirs(OUT_DIR, exist_ok=True)

    print("Generating standardized 32x48 character sprites...")

    # 1. Silas sprites
    silas_frames = {
        "silas_idle_down.png": ("down", 0),
        "silas_idle_left.png": ("left", 0),
        "silas_idle_right.png": ("right", 0),
        "silas_idle_up.png": ("up", 0),
        "silas_walk_down_1.png": ("down", 1),
        "silas_walk_down_2.png": ("down", 0),
        "silas_walk_down_3.png": ("down", 2),
        "silas_walk_down_4.png": ("down", 0),
        "silas_walk_left_1.png": ("left", 1),
        "silas_walk_left_2.png": ("left", 2),
        "silas_walk_right_1.png": ("right", 1),
        "silas_walk_right_2.png": ("right", 2),
        "silas_walk_up_1.png": ("up", 1),
        "silas_walk_up_2.png": ("up", 2),
    }

    for fname, (dir_name, frame) in silas_frames.items():
        img = create_silas_sprite(dir_name, frame)
        img = quantize_to_palette(img, palette, dither=False)
        dest = os.path.join(OUT_DIR, fname)
        img.save(dest, "PNG")
        # 4x preview
        prev = img.resize((128, 192), Image.Resampling.NEAREST)
        prev.save(os.path.join(OUT_DIR, fname.replace(".png", "_preview.png")), "PNG")

    # 2. Suspect NPCs
    suspects = ["margaret", "hale", "julian", "pike"]
    directions = ["down", "left", "right", "up"]

    for susp in suspects:
        for d in directions:
            img = create_npc_sprite(susp, d)
            img = quantize_to_palette(img, palette, dither=False)
            fname = f"{susp}_idle_{d}.png"
            dest = os.path.join(OUT_DIR, fname)
            img.save(dest, "PNG")
            prev = img.resize((128, 192), Image.Resampling.NEAREST)
            prev.save(os.path.join(OUT_DIR, fname.replace(".png", "_preview.png")), "PNG")

    print(f"Successfully generated all 32x48 character sprites in {OUT_DIR}!")

if __name__ == "__main__":
    main()
