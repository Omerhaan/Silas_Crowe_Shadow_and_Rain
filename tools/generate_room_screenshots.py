#!/usr/bin/env python3
"""
Generate 3x (1440x810) Screenshots for all 9 rooms:
- F1 OFF: Clean gameplay screen with plates, characters, visible props, and HUD
- F1 ON: Debug overlay with color-coded bounding boxes, labels, footline (y=245),
         Silas radius, locked doors, and GEÇİCİ arrow badges.

Rooms:
1. main_hall
2. study
3. library
4. dining_room
5. kitchen
6. billiard_room
7. upper_floor
8. harlow_bedroom
9. pike_room
"""

import os
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = Path(__file__).resolve().parent.parent
PLATES_DIR = BASE_DIR / "assets" / "plates"
CHARS_DIR = BASE_DIR / "assets" / "sprites" / "characters"
PROPS_DIR = BASE_DIR / "assets" / "sprites" / "props"
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
FONT_HUD = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 16)
FONT_HUD_SM = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 12)

def parse_tscn(tscn_path: Path):
    with open(tscn_path, "r", encoding="utf-8") as f:
        content = f.read()

    sections = re.split(r'\n\[node ', content)
    nodes = []
    for s in sections[1:]:
        header_line = s.split("\n")[0]
        name_match = re.search(r'name="([^"]+)"', header_line)
        if not name_match:
            continue
        name = name_match.group(1)
        
        pos = (0.0, 0.0)
        pos_match = re.search(r'position = Vector2\(([^,]+),\s*([^)]+)\)', s)
        if pos_match:
            pos = (float(pos_match.group(1)), float(pos_match.group(2)))

        obj_id = ""
        id_match = re.search(r'object_id = "([^"]+)"', s)
        if id_match:
            obj_id = id_match.group(1)

        char_id = ""
        cid_match = re.search(r'character_id = "([^"]+)"', s)
        if cid_match:
            char_id = cid_match.group(1)

        char_name = ""
        cn_match = re.search(r'character_name = "([^"]+)"', s)
        if cn_match:
            char_name = cn_match.group(1)

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

        is_locked = False
        if "is_locked = true" in s:
            is_locked = True

        lock_msg = ""
        lm_match = re.search(r'locked_message = "([^"]+)"', s)
        if lm_match:
            lock_msg = lm_match.group(1)

        size = (0.0, 0.0)
        size_match = re.search(r'hotspot_size = Vector2\(([^,]+),\s*([^)]+)\)', s)
        if size_match:
            size = (float(size_match.group(1)), float(size_match.group(2)))

        nodes.append({
            "name": name,
            "pos": pos,
            "object_id": obj_id,
            "character_id": char_id,
            "character_name": char_name,
            "evidence_id": ev_id,
            "door_name": d_name,
            "target_room": target_room,
            "target_spawn": target_spawn,
            "is_locked": is_locked,
            "lock_msg": lock_msg,
            "hotspot_size": size
        })
    return nodes

def paste_char(bg: Image.Image, char_img: Image.Image, shadow_img: Image.Image, x: int, y: int):
    # Shadow centered at foot sole
    bg.paste(shadow_img, (x - 20, y - 5), shadow_img)
    # Character sprite: 64x104 with foot sole at y=104 -> offset (-32, -104)
    bg.paste(char_img, (x - 32, y - 104), char_img)

def draw_pill_label(draw: ImageDraw.ImageDraw, x: int, y: int, text: str, font: ImageFont.FreeTypeFont, text_col: tuple, border_col: tuple, bg_col: tuple = (10, 14, 22, 235)):
    bbox = draw.textbbox((x, y), text, font=font)
    pad = 4
    pill_rect = (bbox[0] - pad, bbox[1] - pad + 1, bbox[2] + pad, bbox[3] + pad - 1)
    draw.rectangle(pill_rect, fill=bg_col, outline=border_col, width=1)
    draw.text((x, y), text, font=font, fill=text_col)

def draw_hud(base_img: Image.Image, room_title: str, extra_arrows: list):
    hud_overlay = Image.new("RGBA", (SCREEN_W, SCREEN_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(hud_overlay, "RGBA")

    # Top Bar: height 30*3 = 90
    top_bar = (0, 0, SCREEN_W, 30 * SCALE)
    draw.rectangle(top_bar, fill=(15, 20, 30, 230), outline=(40, 55, 75, 255), width=2)

    # Room title
    draw.text((16 * SCALE, 7 * SCALE), room_title, font=FONT_HUD, fill=(240, 245, 255))

    # Top Right Buttons (Defter, Suçla, Menü)
    btns = ["Defter (TAB)", "Suçla (C)", "Menü (ESC)"]
    bx = SCREEN_W - 350
    for b in btns:
        bw = 100
        draw.rectangle((bx, 5 * SCALE, bx + bw, 25 * SCALE), fill=(25, 35, 50, 230), outline=(70, 95, 130, 255), width=1)
        draw.text((bx + 8, 7 * SCALE), b, font=FONT_HUD_SM, fill=(210, 225, 240))
        bx += bw + 10

    # Draw Navigation Arrows in Bottom Corners (>= 36x36 px)
    for arr in extra_arrows:
        side, text, is_temp = arr
        bw, bh = 76 * SCALE, 36 * SCALE # 228x108 px (>=36x36 at 1x)
        if side == "left":
            ax = 6 * SCALE # 18 px
            ay = SCREEN_H - (42 * SCALE) # 810 - 126 = 684
        elif side == "right":
            ax = SCREEN_W - (6 * SCALE) - bw # 1440 - 18 - 228 = 1194
            ay = SCREEN_H - (42 * SCALE)
        else: # extra
            ax = SCREEN_W - (6 * SCALE) - bw
            ay = SCREEN_H - (82 * SCALE)

        box = (ax, ay, ax + bw, ay + bh)
        border = (240, 160, 40, 255) if is_temp else (80, 150, 220, 255)
        fill = (35, 25, 10, 235) if is_temp else (15, 22, 35, 235)
        draw.rectangle(box, fill=fill, outline=border, width=2)
        txt_col = (255, 215, 90) if is_temp else (230, 240, 255)
        # Center text inside button
        tbbox = draw.textbbox((0, 0), text, font=FONT_BUTTON)
        tw = tbbox[2] - tbbox[0]
        th = tbbox[3] - tbbox[1]
        tx = ax + (bw - tw) // 2
        ty = ay + (bh - th) // 2 - 2
        draw.text((tx, ty), text, font=FONT_BUTTON, fill=txt_col)

    return Image.alpha_composite(base_img, hud_overlay)

def render_room(room_cfg: dict):
    scene_name = room_cfg["scene"]
    plate_name = room_cfg["plate"]
    room_title = room_cfg["title"]
    chars = room_cfg["chars"]
    props = room_cfg.get("props", [])
    arrows = room_cfg.get("arrows", [])
    out_prefix = room_cfg["out_prefix"]

    tscn_path = BASE_DIR / "scenes" / "rooms" / scene_name
    plate_path = PLATES_DIR / plate_name

    # 1. Base 1x composite
    shadow = Image.open(SHADOW_PATH).convert("RGBA")
    bg = Image.open(plate_path).convert("RGBA")
    comp_1x = bg.copy()

    # Paste props (e.g. study corpse & bottle)
    for p_path, px, py in props:
        p_img = Image.open(p_path).convert("RGBA")
        comp_1x.paste(p_img, (px, py), p_img)

    # Paste characters
    for c_img, cx, cy, is_silas, _ in chars:
        paste_char(comp_1x, c_img, shadow, cx, cy)

    # 2. Upscale to 3x Lanczos
    comp_3x = comp_1x.resize((SCREEN_W, SCREEN_H), Image.Resampling.LANCZOS)

    # ----------------------------------------------------
    # GENERATE F1 OFF (Clean Gameplay)
    # ----------------------------------------------------
    clean_3x = draw_hud(comp_3x, room_title, arrows)
    clean_path_1 = OUTPUT_DIR / f"{out_prefix}.png"
    clean_path_2 = OUTPUT_DIR / f"fix2_{room_cfg['room_id']}.png"
    clean_3x.save(clean_path_1, "PNG")
    clean_3x.save(clean_path_2, "PNG")

    # ----------------------------------------------------
    # GENERATE F1 ON (Debug Overlay)
    # ----------------------------------------------------
    debug_overlay = Image.new("RGBA", (SCREEN_W, SCREEN_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(debug_overlay, "RGBA")

    # A) Footline: y = 245 * 3 = 735
    foot_y = 245 * SCALE
    draw.line([(0, foot_y), (SCREEN_W, foot_y)], fill=(255, 60, 60, 240), width=3)
    draw_pill_label(draw, 14, foot_y - 20, "y = 245 [Ayak Çizgisi / Foot Baseline]", FONT_LABEL, (255, 120, 120), (255, 60, 60))

    # B) Silas Marker & Radius
    for c_img, cx, cy, is_silas, c_name in chars:
        if is_silas:
            scx = cx * SCALE
            scy = (cy - 25) * SCALE
            r = 36 * SCALE
            draw.ellipse([(scx - r, scy - r), (scx + r, scy + r)], fill=(30, 220, 80, 45), outline=(50, 255, 110, 220), width=3)
            # Foot crosshair
            sfx, sfy = cx * SCALE, cy * SCALE
            draw.line([(sfx - 14, sfy), (sfx + 14, sfy)], fill=(255, 230, 40, 255), width=3)
            draw.line([(sfx, sfy - 14), (sfx, sfy + 14)], fill=(255, 230, 40, 255), width=3)
            draw_pill_label(draw, sfx - 120, sfy - 180, f"Silas Crowe (Hedef Boy: 100px, Ayak y={cy})", FONT_LABEL, (100, 255, 140), (40, 220, 80))
        else:
            # NPC Box & Measured Label
            nfx, nfy = cx * SCALE, cy * SCALE
            draw.line([(nfx - 14, nfy), (nfx + 14, nfy)], fill=(255, 90, 255, 255), width=3)
            draw.line([(nfx, nfy - 14), (nfx, nfy + 14)], fill=(255, 90, 255, 255), width=3)
            draw_pill_label(draw, nfx - 100, nfy - 180, f"[NPC] {c_name} (Ayak y={cy})", FONT_LABEL, (255, 160, 255), (220, 70, 220))

    # C) Nodes from Scene
    nodes = parse_tscn(tscn_path)
    for n in nodes:
        name = n["name"]
        px, py = n["pos"]
        
        # 1. Doors
        if n["target_room"] or "Door_" in name:
            bw, bh = 44 * SCALE, 80 * SCALE
            bx = int((px - 22) * SCALE)
            by = int((py - 80) * SCALE)
            box = (bx, by, bx + bw, by + bh)

            if n["is_locked"]:
                draw.rectangle(box, fill=(220, 40, 40, 75), outline=(255, 70, 70, 240), width=3)
                lbl = f"[KİLİTLİ KAPI] {n['door_name']}"
                if n["lock_msg"]:
                    lbl += f" : \"{n['lock_msg'][:25]}...\""
                draw_pill_label(draw, bx - 8, by - 22, lbl, FONT_LABEL, (255, 140, 140), (255, 50, 50))
            else:
                draw.rectangle(box, fill=(20, 130, 255, 80), outline=(50, 200, 255, 240), width=3)
                label = f"[KAPI] {n['door_name']} -> {n['target_room']}"
                if n['target_spawn'] and n['target_spawn'] != 'default':
                    label += f" ({n['target_spawn']})"
                draw_pill_label(draw, bx - 8, by - 22, label, FONT_LABEL, (100, 220, 255), (30, 150, 255))

        # 2. Interactables & Evidence
        elif n["object_id"]:
            oid = n["object_id"]
            eid = n["evidence_id"]
            is_npc = oid.startswith("npc_") or n["character_id"] != ""
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

    # D) Temporary Navigation Badges in F1
    for arr in arrows:
        side, text, is_temp = arr
        if is_temp:
            if side == "left":
                ax, ay = 8 * SCALE, 165 * SCALE
            elif side == "right":
                ax, ay = SCREEN_W - 148, 165 * SCALE
            else:
                ax, ay = SCREEN_W - 165, 215 * SCALE
            draw_pill_label(draw, ax, ay, "[GEÇİCİ OK GEÇİŞİ]", FONT_LABEL, (255, 220, 80), (255, 160, 30), bg_col=(40, 25, 5, 245))

    # E) Top-Right Touch "DEBUG" Button
    btn_box = (SCREEN_W - 175, 12, SCREEN_W - 14, 48)
    draw.rectangle(btn_box, fill=(14, 24, 18, 240), outline=(50, 230, 90, 255), width=2)
    draw.text((btn_box[0] + 16, btn_box[1] + 9), "[F1] DEBUG [ON]", font=FONT_BUTTON, fill=(70, 255, 120))

    # F) Top-Left Legend
    legend_box = (12, 12, 750, 48)
    draw.rectangle(legend_box, fill=(10, 14, 22, 235), outline=(70, 100, 140, 200), width=1)
    leg_text = "F1 DEBUG  •  Mavi: Açık Kapı  •  Kırmızı: Kilitli Kapı  •  Sarı: Kanıt  •  Mor: NPC  •  Turuncu: Hotspot"
    draw.text((legend_box[0] + 12, legend_box[1] + 10), leg_text, font=FONT_LABEL, fill=(230, 240, 255))

    debug_final = Image.alpha_composite(clean_3x, debug_overlay)
    debug_path_1 = OUTPUT_DIR / f"debug_{room_cfg['room_id']}.png"
    debug_path_2 = OUTPUT_DIR / f"fix2_{room_cfg['room_id']}_debug.png"
    debug_final.save(debug_path_1, "PNG")
    debug_final.save(debug_path_2, "PNG")

    print(f"Generated {room_cfg['room_id']}: {clean_path_2.name} and {debug_path_2.name}")

def main():
    silas_right = Image.open(CHARS_DIR / "silas_idle_right.png").convert("RGBA")
    silas_left = Image.open(CHARS_DIR / "silas_idle_left.png").convert("RGBA")
    hale_down = Image.open(CHARS_DIR / "hale_idle_down.png").convert("RGBA")
    pike_down = Image.open(CHARS_DIR / "pike_idle_down.png").convert("RGBA")
    margaret_down = Image.open(CHARS_DIR / "margaret_idle_down.png").convert("RGBA")
    julian_down = Image.open(CHARS_DIR / "julian_idle_down.png").convert("RGBA")

    rooms = [
        # 1. Ana Hol (v2)
        {
            "room_id": "main_hall",
            "scene": "main_hall.tscn",
            "plate": "bg_main_hall.png",
            "title": "Ana Hol",
            "out_prefix": "room_main_hall_3x",
            "chars": [
                (silas_right, 240, 245, True, "Silas Crowe")
            ],
            "arrows": [
                ("left", "◀ Kütüphane", False),
                ("right", "Yemek Odası ▶", False)
            ]
        },
        # 2. Çalışma Odası
        {
            "room_id": "study",
            "scene": "study.tscn",
            "plate": "bg_study.png",
            "title": "Çalışma Odası",
            "out_prefix": "room_study_3x",
            "chars": [
                (silas_right, 180, 245, True, "Silas Crowe")
            ],
            "props": [
                (str(PROPS_DIR / "study_corpse_harlow.png"), 225 - 44, 245 - 86),
                (str(PROPS_DIR / "study_cognac_bottle.png"), 385 - 6, 182 - 7)
            ],
            "arrows": []
        },
        # 3. Kütüphane (v2)
        {
            "room_id": "library",
            "scene": "library.tscn",
            "plate": "bg_library.png",
            "title": "Kütüphane",
            "out_prefix": "room_library_3x",
            "chars": [
                (hale_down, 195, 245, False, "Dr. Victor Hale (102px)"),
                (silas_left, 320, 245, True, "Silas Crowe")
            ],
            "arrows": [
                ("left", "◀ Ana Hol", False)
            ]
        },
        # 4. Yemek Odası (v2)
        {
            "room_id": "dining_room",
            "scene": "dining_room.tscn",
            "plate": "bg_dining_room.png",
            "title": "Yemek Odası",
            "out_prefix": "room_dining_room_3x",
            "chars": [
                (pike_down, 135, 245, False, "Raymond Pike (98px)"),
                (silas_left, 360, 245, True, "Silas Crowe")
            ],
            "arrows": []
        },
        # 5. Mutfak
        {
            "room_id": "kitchen",
            "scene": "kitchen.tscn",
            "plate": "bg_kitchen.png",
            "title": "Mutfak",
            "out_prefix": "room_kitchen_3x",
            "chars": [
                (margaret_down, 215, 245, False, "Margaret Doyle (94px)"),
                (silas_left, 320, 245, True, "Silas Crowe")
            ],
            "arrows": [
                ("right", "Yemek Odası [GEÇİCİ] ▶", True)
            ]
        },
        # 6. Bilardo Odası
        {
            "room_id": "billiard_room",
            "scene": "billiard_room.tscn",
            "plate": "bg_billiard_room.png",
            "title": "Bilardo Odası",
            "out_prefix": "room_billiard_room_3x",
            "chars": [
                (silas_right, 180, 245, True, "Silas Crowe"),
                (julian_down, 330, 245, False, "Julian Harlow (98px)")
            ],
            "arrows": [
                ("left", "◀ Kütüphane [GEÇİCİ]", True)
            ]
        },
        # 7. Üst Kat Koridoru
        {
            "room_id": "upper_floor",
            "scene": "upper_floor.tscn",
            "plate": "bg_upper_floor.png",
            "title": "Üst Kat Koridoru",
            "out_prefix": "room_upper_floor_3x",
            "chars": [
                (silas_right, 200, 245, True, "Silas Crowe")
            ],
            "arrows": []
        },
        # 8. Harlow'un Odası
        {
            "room_id": "harlow_bedroom",
            "scene": "harlow_bedroom.tscn",
            "plate": "bg_harlow_bedroom.png",
            "title": "Harlow'un Odası",
            "out_prefix": "room_harlow_bedroom_3x",
            "chars": [
                (silas_right, 200, 245, True, "Silas Crowe")
            ],
            "arrows": [
                ("left", "◀ Koridor", False)
            ]
        },
        # 9. Pike'ın Odası
        {
            "room_id": "pike_room",
            "scene": "pike_room.tscn",
            "plate": "bg_pike_room.png",
            "title": "Pike'ın Odası",
            "out_prefix": "room_pike_room_3x",
            "chars": [
                (silas_right, 200, 245, True, "Silas Crowe")
            ],
            "arrows": [
                ("left", "◀ Koridor", False)
            ]
        }
    ]

    for r_cfg in rooms:
        render_room(r_cfg)

if __name__ == "__main__":
    main()
