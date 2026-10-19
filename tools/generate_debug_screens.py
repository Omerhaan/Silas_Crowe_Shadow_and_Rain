#!/usr/bin/env python3
"""
Generate 3x (1440x810) Debug Screenshots for all 8 rooms.
Overlays:
- Semi-transparent colored boxes for all Doors, NPCs, Evidence, and Props with readable labels
- Red foot baseline at y=245
- Silas position marker and interaction radius (r=36)
- Touch Debug toggle button in top right
- Legend in top left
Saves to docs/screens/debug_<oda>.png
"""

import os
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = Path(__file__).resolve().parent.parent
PLATES_DIR = BASE_DIR / "assets" / "plates"
CHARS_DIR = BASE_DIR / "assets" / "sprites" / "characters"
SHADOW_PATH = BASE_DIR / "assets" / "sprites" / "shadow_silas.png"
OUTPUT_DIR = BASE_DIR / "docs" / "screens"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

SCALE = 3
SCREEN_W = 480 * SCALE # 1440
SCREEN_H = 270 * SCALE # 810

# Load TTF fonts
FONT_LABEL = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 13)
FONT_HEADER = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 15)
FONT_BUTTON = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 14)

def parse_tscn(tscn_path: Path):
    with open(tscn_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Split into sections
    sections = re.split(r'\n\[node ', content)
    nodes = []
    for s in sections[1:]:
        header_line = s.split("\n")[0]
        name_match = re.search(r'name="([^"]+)"', header_line)
        if not name_match:
            continue
        name = name_match.group(1)
        
        # Parse attributes
        pos = (0.0, 0.0)
        pos_match = re.search(r'position = Vector2\(([^,]+),\s*([^)]+)\)', s)
        if pos_match:
            pos = (float(pos_match.group(1)), float(pos_match.group(2)))

        obj_id = ""
        id_match = re.search(r'object_id = "([^"]+)"', s)
        if id_match:
            obj_id = id_match.group(1)

        ev_id = ""
        ev_match = re.search(r'evidence_id = "([^"]+)"', s)
        if ev_match:
            ev_id = ev_match.group(1)

        d_name = ""
        dn_match = re.search(r'door_name = "([^"]+)"', s)
        if dn_match:
            d_name = dn_match.group(1)

        target_room = ""
        tr_match = re.search(r'target_room_id = "([^"]+)"', s)
        if tr_match:
            target_room = tr_match.group(1)

        target_spawn = ""
        ts_match = re.search(r'target_spawn = "([^"]+)"', s)
        if ts_match:
            target_spawn = ts_match.group(1)

        size = (0.0, 0.0)
        size_match = re.search(r'hotspot_size = Vector2\(([^,]+),\s*([^)]+)\)', s)
        if size_match:
            size = (float(size_match.group(1)), float(size_match.group(2)))

        nodes.append({
            "name": name,
            "pos": pos,
            "object_id": obj_id,
            "evidence_id": ev_id,
            "door_name": d_name,
            "target_room": target_room,
            "target_spawn": target_spawn,
            "hotspot_size": size
        })
    return nodes

def paste_char(bg: Image.Image, char_img: Image.Image, shadow_img: Image.Image, x: int, y: int):
    bg.paste(shadow_img, (x - 20, y - 5), shadow_img)
    bg.paste(char_img, (x - 32, y - 100), char_img)

def draw_pill_label(draw: ImageDraw.ImageDraw, x: int, y: int, text: str, font: ImageFont.FreeTypeFont, text_col: tuple, border_col: tuple):
    bbox = draw.textbbox((x, y), text, font=font)
    pad = 4
    pill_rect = (bbox[0] - pad, bbox[1] - pad + 1, bbox[2] + pad, bbox[3] + pad - 1)
    draw.rectangle(pill_rect, fill=(10, 14, 22, 235), outline=border_col, width=1)
    draw.text((x, y), text, font=font, fill=text_col)

def generate_debug_room(scene_name: str, plate_name: str, out_name: str, chars: list):
    tscn_path = BASE_DIR / "scenes" / ("hub" if "office" in scene_name else "rooms") / scene_name
    plate_path = PLATES_DIR / plate_name

    # 1. Base 1x composite
    shadow = Image.open(SHADOW_PATH).convert("RGBA")
    bg = Image.open(plate_path).convert("RGBA")
    comp_1x = bg.copy()
    for c_item in chars:
        c_img, cx, cy = c_item[0], c_item[1], c_item[2]
        paste_char(comp_1x, c_img, shadow, cx, cy)

    # 2. Scale up to 3x (1440x810) using Lanczos for clean background
    comp_3x = comp_1x.resize((SCREEN_W, SCREEN_H), Image.Resampling.LANCZOS)

    # 3. Create transparent overlay for debug boxes and graphics
    overlay = Image.new("RGBA", (SCREEN_W, SCREEN_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")

    # A) Footline: y = 245 * 3 = 735
    foot_y = 245 * SCALE
    draw.line([(0, foot_y), (SCREEN_W, foot_y)], fill=(255, 60, 60, 240), width=3)
    draw_pill_label(draw, 14, foot_y - 20, "y = 245 [Ayak Cizgisi / Foot Baseline]", FONT_LABEL, (255, 120, 120), (255, 60, 60))

    # B) Silas position & interaction circle (radius 36)
    silas_entry = [c for c in chars if len(c) > 3 and c[3]]
    if silas_entry:
        _, sx, sy, _ = silas_entry[0]
        cx = sx * SCALE
        cy = (sy - 25) * SCALE
        r = 36 * SCALE # 108 px

        # Interaction circle
        draw.ellipse([(cx - r, cy - r), (cx + r, cy + r)], fill=(30, 220, 80, 50), outline=(50, 255, 110, 230), width=3)
        # Silas foot crosshair
        sfx = sx * SCALE
        sfy = sy * SCALE
        draw.line([(sfx - 14, sfy), (sfx + 14, sfy)], fill=(255, 230, 40, 255), width=3)
        draw.line([(sfx, sfy - 14), (sfx, sfy + 14)], fill=(255, 230, 40, 255), width=3)
        draw_pill_label(draw, sfx - 110, sfy - 180, f"Silas Crowe (Radius: 36px, Foot: {sx},{sy})", FONT_LABEL, (100, 255, 140), (40, 220, 80))

    # C) Parse room nodes
    nodes = parse_tscn(tscn_path)

    # Walls / Room boundaries
    left_wall = (0, 0, 16 * SCALE, SCREEN_H)
    right_wall = (464 * SCALE, 0, SCREEN_W, SCREEN_H)
    floor_box = (0, 247 * SCALE, SCREEN_W, SCREEN_H)

    draw.rectangle(left_wall, fill=(60, 80, 110, 45), outline=(100, 140, 180, 160), width=2)
    draw_pill_label(draw, 4, 180, "Sol Duvar [x: 0..16]", FONT_LABEL, (160, 190, 220), (80, 120, 160))

    draw.rectangle(right_wall, fill=(60, 80, 110, 45), outline=(100, 140, 180, 160), width=2)
    draw_pill_label(draw, 464 * SCALE - 130, 180, "Sag Duvar [x: 464..480]", FONT_LABEL, (160, 190, 220), (80, 120, 160))

    # Draw Doors, Interactables, Spawns
    for n in nodes:
        name = n["name"]
        px, py = n["pos"]
        
        # 1. Doors
        if n["target_room"]:
            bw, bh = 44 * SCALE, 80 * SCALE
            bx = int((px - 22) * SCALE)
            by = int((py - 80) * SCALE)
            box = (bx, by, bx + bw, by + bh)

            draw.rectangle(box, fill=(20, 130, 255, 80), outline=(50, 200, 255, 240), width=3)
            label = f"[KAPI] {n['door_name']} -> {n['target_room']}"
            if n['target_spawn'] and n['target_spawn'] != 'default':
                label += f" ({n['target_spawn']})"
            draw_pill_label(draw, bx - 8, by - 22, label, FONT_LABEL, (100, 220, 255), (30, 150, 255))

        # 2. Interactables
        elif n["object_id"]:
            oid = n["object_id"]
            eid = n["evidence_id"]
            is_npc = oid.startswith("npc_")
            is_ev = bool(eid)

            hw, hh = n["hotspot_size"]
            if hw == 0 and hh == 0:
                if is_npc:
                    hw, hh = 28, 86
                    py_off = -43
                else:
                    hw, hh = 28, 28
                    py_off = 0
            else:
                py_off = 0

            bw = int(hw * SCALE)
            bh = int(hh * SCALE)
            bx = int((px - hw / 2.0) * SCALE)
            by = int((py + py_off - hh / 2.0) * SCALE)
            box = (bx, by, bx + bw, by + bh)

            if is_ev:
                fill_c = (255, 195, 20, 90)
                out_c = (255, 225, 40, 245)
                lbl_c = (255, 235, 120)
                lbl_text = f"[{eid}] {oid}"
            elif is_npc:
                fill_c = (210, 45, 210, 85)
                out_c = (255, 90, 255, 240)
                lbl_c = (255, 160, 255)
                lbl_text = f"[NPC] {oid}"
            else:
                fill_c = (255, 125, 25, 65)
                out_c = (255, 160, 40, 220)
                lbl_c = (255, 185, 90)
                lbl_text = oid

            draw.rectangle(box, fill=fill_c, outline=out_c, width=2)
            draw_pill_label(draw, bx - 4, by - 18, lbl_text, FONT_LABEL, lbl_c, out_c)

        # 3. Spawns
        elif name.startswith("Spawn_"):
            sx = int(px * SCALE)
            sy = int(py * SCALE)
            d = 7
            draw.polygon([(sx, sy - d), (sx + d, sy), (sx, sy + d), (sx - d, sy)], fill=(50, 240, 210, 230), outline=(20, 100, 90, 255))
            draw_pill_label(draw, sx + 8, sy - 8, name, FONT_LABEL, (80, 255, 220), (50, 220, 190))

    # D) Top-Right Touch "DEBUG" Button
    btn_box = (SCREEN_W - 175, 12, SCREEN_W - 14, 48)
    draw.rectangle(btn_box, fill=(14, 24, 18, 240), outline=(50, 230, 90, 255), width=2)
    draw.text((btn_box[0] + 16, btn_box[1] + 9), "[F1] DEBUG [ON]", font=FONT_BUTTON, fill=(70, 255, 120))

    # E) Top-Left Legend
    legend_box = (12, 12, 730, 48)
    draw.rectangle(legend_box, fill=(10, 14, 22, 235), outline=(70, 100, 140, 200), width=1)
    leg_text = "DEBUG KATMANI (F1)  •  Mavi: Kapi  •  Sari: Kanit  •  Mor: NPC  •  Turuncu: Hotspot  •  Kirmizi: y=245"
    draw.text((legend_box[0] + 12, legend_box[1] + 10), leg_text, font=FONT_LABEL, fill=(230, 240, 255))

    # 4. Composite overlay onto 3x plate
    final_img = Image.alpha_composite(comp_3x, overlay)
    out_path = OUTPUT_DIR / out_name
    final_img.save(out_path, "PNG")
    print(f"Exported: {out_name} (1440x810)")

def main():
    silas_right = Image.open(CHARS_DIR / "silas_idle_right.png").convert("RGBA")
    silas_left = Image.open(CHARS_DIR / "silas_idle_left.png").convert("RGBA")

    rooms = [
        ("silas_office.tscn", "bg_hub_office.png", "debug_hub_office.png", [
            (silas_right, 200, 245, True)
        ]),
        ("main_hall.tscn", "bg_main_hall.png", "debug_main_hall.png", [
            (silas_right, 240, 245, True)
        ]),
        ("study.tscn", "bg_study.png", "debug_study.png", [
            (silas_right, 180, 245, True)
        ]),
        ("library.tscn", "bg_library.png", "debug_library.png", [
            (Image.open(CHARS_DIR / "hale_idle_down.png").convert("RGBA"), 185, 245, False),
            (silas_left, 320, 245, True)
        ]),
        ("dining_room.tscn", "bg_dining_room.png", "debug_dining_room.png", [
            (Image.open(CHARS_DIR / "pike_idle_down.png").convert("RGBA"), 155, 245, False),
            (silas_left, 340, 245, True)
        ]),
        ("kitchen.tscn", "bg_kitchen.png", "debug_kitchen.png", [
            (Image.open(CHARS_DIR / "margaret_idle_down.png").convert("RGBA"), 205, 245, False),
            (silas_left, 320, 245, True)
        ]),
        ("billiard_room.tscn", "bg_billiard_room.png", "debug_billiard_room.png", [
            (silas_right, 180, 245, True),
            (Image.open(CHARS_DIR / "julian_idle_down.png").convert("RGBA"), 330, 245, False)
        ]),
        ("upper_floor.tscn", "bg_upper_floor.png", "debug_upper_floor.png", [
            (silas_right, 200, 245, True)
        ]),
    ]

    for sc_name, pl_name, out_name, chars in rooms:
        generate_debug_room(sc_name, pl_name, out_name, chars)

if __name__ == "__main__":
    main()
