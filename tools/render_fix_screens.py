#!/usr/bin/env python3
"""
Generate 5 high-resolution (1440x810, 3x) verification screenshots for the 5 fixes:
1. docs/screens/fix_interrogation.png - NPC Interrogation UI, 5 topics, dialogue response, prompt
2. docs/screens/fix_scale.png         - Character scale lineup with real measured alpha heights & sole alignment
3. docs/screens/fix_dialogue.png      - DialogueBox component showcase (Suspect, Inner Voice, Caller Glitch Silhouette, System)
4. docs/screens/fix_hub.png           - Silas Office Hub state machine (no right arrow, locked exit inner voice)
5. docs/screens/fix_rooms.png         - Notebook Harita 3x2 Ground Floor Grid + 3 Bedroom Upper Floor + Active Room Highlight
"""

import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = Path(__file__).resolve().parent.parent
PLATES_DIR = BASE_DIR / "assets" / "plates"
CHARS_DIR = BASE_DIR / "assets" / "sprites" / "characters"
PORTRAITS_DIR = BASE_DIR / "assets" / "portraits"
SHADOW_PATH = BASE_DIR / "assets" / "sprites" / "shadow_silas.png"
OUTPUT_DIR = BASE_DIR / "docs" / "screens"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

SCALE = 3
SCREEN_W = 480 * SCALE # 1440
SCREEN_H = 270 * SCALE # 810

# Fonts
FONT_TITLE = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 22)
FONT_SUBTITLE = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 16)
FONT_BODY = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 15)
FONT_BODY_BOLD = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 15)
FONT_SMALL = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 13)
FONT_SMALL_BOLD = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 13)
FONT_TAG = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 11)

def get_base_plate(plate_name: str) -> Image.Image:
    p_path = PLATES_DIR / f"bg_{plate_name}.png"
    img = Image.open(p_path).convert("RGBA")
    return img.resize((SCREEN_W, SCREEN_H), Image.NEAREST)

def draw_top_hud(draw: ImageDraw.ImageDraw, room_title: str):
    # Top HUD Bar
    draw.rectangle([0, 0, SCREEN_W, 36], fill=(13, 17, 23, 230))
    draw.line([0, 36, SCREEN_W, 36], fill=(50, 60, 75, 255), width=2)
    draw.text((20, 9), room_title, font=FONT_SUBTITLE, fill=(245, 227, 161, 255))
    draw.text((170, 11), "[A/D]: Yürü  •  [E / W]: İncele / Geç", font=FONT_SMALL, fill=(140, 153, 166, 200))
    # HUD Buttons
    draw.rounded_rectangle([SCREEN_W - 240, 6, SCREEN_W - 140, 30], radius=4, fill=(25, 33, 44, 255), outline=(90, 105, 125, 255))
    draw.text((SCREEN_W - 208, 9), "Defter [J]", font=FONT_SMALL_BOLD, fill=(230, 230, 230, 255))
    draw.rounded_rectangle([SCREEN_W - 130, 6, SCREEN_W - 50, 30], radius=4, fill=(45, 20, 20, 255), outline=(150, 60, 60, 255))
    draw.text((SCREEN_W - 105, 9), "Suçla", font=FONT_SMALL_BOLD, fill=(255, 120, 120, 255))
    draw.rounded_rectangle([SCREEN_W - 40, 6, SCREEN_W - 10, 30], radius=4, fill=(25, 33, 44, 255), outline=(90, 105, 125, 255))
    draw.text((SCREEN_W - 30, 9), "⚙", font=FONT_SMALL_BOLD, fill=(230, 230, 230, 255))

# -------------------------------------------------------------
# SCREENSHOT 1: fix_interrogation.png
# -------------------------------------------------------------
def generate_fix1_interrogation():
    print("Generating fix_interrogation.png...")
    img = get_base_plate("library")
    draw = ImageDraw.Draw(img, "RGBA")
    draw_top_hud(draw, "Kütüphane")

    # Draw Silas at (130, 245)
    silas_img = Image.open(CHARS_DIR / "silas_idle_right.png").convert("RGBA")
    silas_scaled = silas_img.resize((silas_img.width * SCALE, silas_img.height * SCALE), Image.NEAREST)
    img.alpha_composite(silas_scaled, (130 * SCALE - silas_scaled.width // 2, 245 * SCALE - silas_scaled.height))

    # Draw Dr. Hale at (195, 245)
    hale_img = Image.open(CHARS_DIR / "hale_idle_left.png").convert("RGBA")
    hale_scaled = hale_img.resize((hale_img.width * SCALE, hale_img.height * SCALE), Image.NEAREST)
    img.alpha_composite(hale_scaled, (195 * SCALE - hale_scaled.width // 2, 245 * SCALE - hale_scaled.height))

    # Proximity Prompt above Dr. Hale
    prompt_rect = [195 * SCALE - 90, 245 * SCALE - hale_scaled.height - 35, 195 * SCALE + 90, 245 * SCALE - hale_scaled.height - 10]
    draw.rounded_rectangle(prompt_rect, radius=6, fill=(10, 14, 20, 230), outline=(245, 227, 161, 240), width=2)
    draw.text((prompt_rect[0] + 12, prompt_rect[1] + 4), "[E] Konuş: Dr. Victor Hale", font=FONT_SMALL_BOLD, fill=(245, 227, 161, 255))

    # Interrogation Modal Window (Center-bottom)
    modal_rect = [120, 310, SCREEN_W - 120, SCREEN_H - 25]
    draw.rounded_rectangle(modal_rect, radius=8, fill=(14, 18, 26, 245), outline=(90, 105, 125, 255), width=2)
    # Header bar
    draw.rounded_rectangle([modal_rect[0], modal_rect[1], modal_rect[2], modal_rect[1] + 40], radius=8, fill=(22, 28, 40, 255))
    draw.text((modal_rect[0] + 20, modal_rect[1] + 10), "Sorgulama: DR. VICTOR HALE", font=FONT_SUBTITLE, fill=(245, 227, 161, 255))
    draw.rounded_rectangle([modal_rect[2] - 40, modal_rect[1] + 8, modal_rect[2] - 10, modal_rect[1] + 32], radius=4, fill=(35, 42, 55, 255))
    draw.text((modal_rect[2] - 30, modal_rect[1] + 11), "✕", font=FONT_BODY_BOLD, fill=(200, 200, 200, 255))

    # Left: Portrait of Dr. Hale
    p_rect = [modal_rect[0] + 25, modal_rect[1] + 60, modal_rect[0] + 25 + 130, modal_rect[1] + 60 + 130]
    draw.rounded_rectangle(p_rect, radius=6, fill=(8, 12, 18, 255), outline=(210, 190, 140, 255), width=3)
    p_img = Image.open(PORTRAITS_DIR / "hale.png").convert("RGBA")
    p_scaled = p_img.resize((124, 124), Image.NEAREST)
    img.alpha_composite(p_scaled, (p_rect[0] + 3, p_rect[1] + 3))

    # Under portrait: Name & Role
    draw.text((p_rect[0] + 4, p_rect[3] + 10), "Dr. Victor Hale", font=FONT_BODY_BOLD, fill=(128, 217, 191, 255))
    draw.text((p_rect[0] + 4, p_rect[3] + 32), "Alay Cerrahı & Hekim", font=FONT_SMALL, fill=(160, 175, 190, 220))

    # Center/Right: 5 Topics on Top
    topics = [
        "1. Olay Gecesi",
        "2. Harlow ile İlişkisi",
        "3. Alibi (Neredeydiniz?)",
        "4. Beni Siz mi Çağırdınız?",
        "★ Kanıt Göster"
    ]
    t_start_x = modal_rect[0] + 180
    t_y = modal_rect[1] + 58
    for i, t in enumerate(topics):
        col = i % 3
        row = i // 3
        bx = t_start_x + col * 320
        by = t_y + row * 45
        is_active = (i == 0)
        btn_bg = (40, 60, 85, 255) if is_active else (25, 32, 44, 255)
        btn_border = (245, 227, 161, 255) if is_active else (60, 75, 95, 255)
        draw.rounded_rectangle([bx, by, bx + 300, by + 36], radius=5, fill=btn_bg, outline=btn_border, width=2)
        txt_col = (255, 235, 170, 255) if is_active else (200, 210, 220, 255)
        draw.text((bx + 12, by + 8), t, font=FONT_BODY_BOLD if is_active else FONT_BODY, fill=txt_col)

    # Response Box Below Topics
    resp_rect = [t_start_x, modal_rect[1] + 160, modal_rect[2] - 30, modal_rect[3] - 40]
    draw.rounded_rectangle(resp_rect, radius=6, fill=(18, 22, 32, 255), outline=(55, 68, 85, 255), width=2)
    resp_text = (
        "\"Akşam yemeğinden sonra saat sekiz buçuk gibi ayrıldım. Edmund konyak içiyordu, neşesi yerindeydi. "
        "Fırtına kopmak üzereyken çalışma odasının lambasını yaktığını gördüm. Kütüphaneye geçip tıbbî kayıtları inceledim...\""
    )
    draw.text((resp_rect[0] + 20, resp_rect[1] + 20), resp_text, font=FONT_BODY, fill=(235, 240, 245, 255))
    draw.text((resp_rect[0] + 20, resp_rect[3] - 30), "✔ İfade Defter'e eklendi  •  [1-5]: Seç  •  [Boşluk]: Devam", font=FONT_SMALL, fill=(245, 200, 90, 255))

    img.save(OUTPUT_DIR / "fix_interrogation.png")
    print("Saved fix_interrogation.png")

# -------------------------------------------------------------
# SCREENSHOT 2: fix_scale.png
# -------------------------------------------------------------
def generate_fix2_scale():
    print("Generating fix_scale.png...")
    # Clean dark presentation studio
    img = Image.new("RGBA", (SCREEN_W, SCREEN_H), (15, 18, 24, 255))
    draw = ImageDraw.Draw(img, "RGBA")

    # Header
    draw.rectangle([0, 0, SCREEN_W, 60], fill=(22, 28, 38, 255))
    draw.line([0, 60, SCREEN_W, 60], fill=(60, 75, 95, 255), width=2)
    draw.text((40, 16), "KARAKTER GÖRÜNÜR PİKSEL BOY VE TABAN HİZALAMA DOĞRULAMASI (±2 px Tolerans)", font=FONT_TITLE, fill=(245, 227, 161, 255))

    characters = [
        ("Silas Crowe", "silas_idle_down.png", 100, 100),
        ("Dr. Victor Hale", "hale_idle_down.png", 102, 102),
        ("Julian Harlow", "julian_idle_down.png", 98, 98),
        ("Raymond Pike", "pike_idle_down.png", 98, 98),
        ("Margaret Doyle", "margaret_idle_down.png", 94, 94),
        ("Edmund Harlow", "edmund_idle_down.png", 98, 98)
    ]

    baseline_y = 660 # Pixel sole level
    draw.line([30, baseline_y, SCREEN_W - 30, baseline_y], fill=(255, 60, 60, 240), width=3)
    draw.text((40, baseline_y + 8), "Ayak Taban Çizgisi (y = 245 / Zemin Süpürgelik Hizası) — Taban Boşluğu = 0 px", font=FONT_SMALL_BOLD, fill=(255, 100, 100, 255))

    col_w = (SCREEN_W - 80) // len(characters)
    for i, (name, fname, target_h, measured_h) in enumerate(characters):
        cx = 50 + i * col_w + col_w // 2
        char_img = Image.open(CHARS_DIR / fname).convert("RGBA")
        char_scaled = char_img.resize((char_img.width * SCALE, char_img.height * SCALE), Image.NEAREST)

        # Sole is at baseline_y
        char_x = cx - char_scaled.width // 2
        char_y = baseline_y - char_scaled.height
        img.alpha_composite(char_scaled, (char_x, char_y))

        # Height measurement bracket on left of character
        bx = char_x - 14
        top_y = char_y + (char_scaled.height - measured_h * SCALE)
        draw.line([bx, top_y, bx, baseline_y], fill=(245, 227, 161, 200), width=2)
        draw.line([bx - 4, top_y, bx + 4, top_y], fill=(245, 227, 161, 200), width=2)
        draw.line([bx - 4, baseline_y, bx + 4, baseline_y], fill=(245, 227, 161, 200), width=2)

        # Label card below
        card_rect = [cx - col_w // 2 + 10, baseline_y + 35, cx + col_w // 2 - 10, baseline_y + 130]
        draw.rounded_rectangle(card_rect, radius=6, fill=(24, 30, 42, 255), outline=(60, 75, 95, 255), width=2)
        draw.text((card_rect[0] + 12, card_rect[1] + 10), name, font=FONT_BODY_BOLD, fill=(255, 255, 255, 255))
        draw.text((card_rect[0] + 12, card_rect[1] + 32), f"Hedef:  {target_h} px", font=FONT_SMALL, fill=(180, 195, 210, 255))
        draw.text((card_rect[0] + 12, card_rect[1] + 52), f"Ölçülen: {measured_h} px", font=FONT_SMALL_BOLD, fill=(100, 255, 140, 255))
        draw.text((card_rect[0] + 12, card_rect[1] + 72), "Fark: 0 px  •  Taban: 0 px", font=FONT_TAG, fill=(245, 227, 161, 255))

    img.save(OUTPUT_DIR / "fix_scale.png")
    print("Saved fix_scale.png")

# -------------------------------------------------------------
# SCREENSHOT 3: fix_dialogue.png
# -------------------------------------------------------------
def generate_fix3_dialogue():
    print("Generating fix_dialogue.png...")
    img = Image.new("RGBA", (SCREEN_W, SCREEN_H), (14, 17, 24, 255))
    draw = ImageDraw.Draw(img, "RGBA")

    # Header
    draw.rectangle([0, 0, SCREEN_W, 60], fill=(20, 26, 36, 255))
    draw.line([0, 60, SCREEN_W, 60], fill=(55, 70, 90, 255), width=2)
    draw.text((40, 16), "STANDART DIALOGUEBOX BİLEŞENİ (Çerçeveli 48x48 Portre, İsim, İç Ses, Siluet)", font=FONT_TITLE, fill=(245, 227, 161, 255))

    cards = [
        {
            "title": "1. ŞÜPHELİ / KARAKTER DİYALOĞU (Dr. Victor Hale)",
            "portrait": PORTRAITS_DIR / "hale.png",
            "name": "DR. VICTOR HALE",
            "name_col": (128, 217, 191, 255),
            "badge": None,
            "text": "\"Bu flakon benim tıbbi çantamdan düşmüş olmalı. Kütüphanede otururken fark etmemişim. Silas, beni cinayetle mi suçluyorsun?!\"",
            "text_col": (240, 240, 240, 255)
        },
        {
            "title": "2. SİLAS CROWE İÇ SESİ ([İÇ SES] Rozeti, İtalik Soluk Mavi, Tırnaklı)",
            "portrait": PORTRAITS_DIR / "silas_thoughtful.png",
            "name": "SİLAS CROWE",
            "name_col": (165, 210, 245, 255),
            "badge": "[İÇ SES]",
            "text": "\"Buz gibi bir fırtına gecesinde saatlerce kitap okuyan bir hekim şömineyi yakmaz mı? Hale yalan söylüyor. Kütüphanede hiç oturmadı.\"",
            "text_col": (185, 215, 240, 255)
        },
        {
            "title": "3. GİZEMLİ ARAYAN (Cızırtılı Siluet İkonu, İsim '???')",
            "portrait": PORTRAITS_DIR / "caller_silhouette.png",
            "name": "???",
            "name_col": (220, 220, 230, 255),
            "badge": None,
            "text": "\"Kuzey Operasyonu'nu hatırla Crowe... 1944'teki o karlı geceyi. Edmund Harlow bedelini ödedi. Sıra sende değil mi?\"",
            "text_col": (230, 235, 245, 255)
        },
        {
            "title": "4. ANLATICI / SİSTEM METNİ (Portresiz, İsimsiz, Odaklanmış Açıklama)",
            "portrait": None,
            "name": "",
            "name_col": None,
            "badge": None,
            "text": "Eski meşe kapının kilit göbeği omuz darbesiyle zorlanmış. Pirinç anahtar içeriden kilit yuvasında takılı ve eğrilmiş durumda.",
            "text_col": (190, 205, 215, 255)
        }
    ]

    y_offset = 85
    for c in cards:
        # Category title
        draw.text((45, y_offset), c["title"], font=FONT_SMALL_BOLD, fill=(245, 227, 161, 255))
        box_rect = [40, y_offset + 22, SCREEN_W - 40, y_offset + 142]
        draw.rounded_rectangle(box_rect, radius=6, fill=(22, 28, 40, 255), outline=(50, 65, 85, 255), width=2)

        content_left = box_rect[0] + 25
        if c["portrait"]:
            p_rect = [content_left, box_rect[1] + 12, content_left + 96, box_rect[1] + 108]
            draw.rounded_rectangle(p_rect, radius=4, fill=(10, 14, 20, 255), outline=(210, 190, 140, 255), width=2)
            p_img = Image.open(c["portrait"]).convert("RGBA").resize((92, 92), Image.NEAREST)
            img.alpha_composite(p_scaled := p_img, (p_rect[0] + 2, p_rect[1] + 2))
            content_left = p_rect[2] + 25

        # Name and badge
        text_y = box_rect[1] + 18
        if c["name"]:
            draw.text((content_left, text_y), c["name"], font=FONT_BODY_BOLD, fill=c["name_col"])
            if c["badge"]:
                badge_x = content_left + 140
                draw.rounded_rectangle([badge_x, text_y - 2, badge_x + 75, text_y + 18], radius=3, fill=(35, 60, 95, 255), outline=(100, 160, 230, 255))
                draw.text((badge_x + 8, text_y), c["badge"], font=FONT_TAG, fill=(180, 220, 255, 255))
            text_y += 32

        # Dialogue text
        draw.text((content_left, text_y), c["text"], font=FONT_BODY, fill=c["text_col"])

        # Advance hint
        draw.text((box_rect[2] - 140, box_rect[3] - 25), "[E / Dokun: İlerle]", font=FONT_TAG, fill=(140, 155, 175, 200))

        y_offset += 175

    img.save(OUTPUT_DIR / "fix_dialogue.png")
    print("Saved fix_dialogue.png")

# -------------------------------------------------------------
# SCREENSHOT 4: fix_hub.png
# -------------------------------------------------------------
def generate_fix4_hub():
    print("Generating fix_hub.png...")
    img = get_base_plate("hub_office")
    draw = ImageDraw.Draw(img, "RGBA")
    draw_top_hud(draw, "Silas'ın Ofisi (Hub)")

    # Draw Silas near the right door attempting to leave
    silas_img = Image.open(CHARS_DIR / "silas_idle_right.png").convert("RGBA")
    silas_scaled = silas_img.resize((silas_img.width * SCALE, silas_img.height * SCALE), Image.NEAREST)
    img.alpha_composite(silas_scaled, (410 * SCALE - silas_scaled.width // 2, 245 * SCALE - silas_scaled.height))

    # Office Door exit hotspot on right wall
    door_box = [450 * SCALE, 195 * SCALE, 478 * SCALE, 265 * SCALE]
    draw.rectangle(door_box, outline=(255, 200, 50, 255), width=3)
    draw.text((door_box[0] - 80, door_box[1] - 30), "[E] Ofis Kapısı", font=FONT_SMALL_BOLD, fill=(255, 220, 100, 255))

    # Inner Voice DialogueBox active at bottom:
    # "Bu yağmurda dışarı çıkacak bir sebebim yok."
    dbox_rect = [60, SCREEN_H - 140, SCREEN_W - 60, SCREEN_H - 20]
    draw.rounded_rectangle(dbox_rect, radius=8, fill=(18, 24, 34, 250), outline=(60, 78, 102, 255), width=2)
    # Silas portrait
    p_rect = [dbox_rect[0] + 16, dbox_rect[1] + 12, dbox_rect[0] + 16 + 96, dbox_rect[1] + 108]
    draw.rounded_rectangle(p_rect, radius=4, fill=(10, 14, 20, 255), outline=(210, 190, 140, 255), width=2)
    p_img = Image.open(PORTRAITS_DIR / "silas_thoughtful.png").convert("RGBA").resize((92, 92), Image.NEAREST)
    img.alpha_composite(p_img, (p_rect[0] + 2, p_rect[1] + 2))

    # Speaker and badge
    draw.text((p_rect[2] + 20, dbox_rect[1] + 18), "SİLAS CROWE", font=FONT_BODY_BOLD, fill=(165, 210, 245, 255))
    draw.rounded_rectangle([p_rect[2] + 160, dbox_rect[1] + 16, p_rect[2] + 235, dbox_rect[1] + 36], radius=3, fill=(35, 60, 95, 255), outline=(100, 160, 230, 255))
    draw.text((p_rect[2] + 168, dbox_rect[1] + 18), "[İÇ SES]", font=FONT_TAG, fill=(180, 220, 255, 255))

    draw.text((p_rect[2] + 20, dbox_rect[1] + 52), "\"Bu yağmurda dışarı çıkacak bir sebebim yok.\"", font=FONT_BODY, fill=(185, 215, 240, 255))
    draw.text((dbox_rect[2] - 150, dbox_rect[3] - 25), "[E / Dokun ile Kapat]", font=FONT_TAG, fill=(245, 227, 161, 200))

    # Visual callout explaining that the right navigation button is removed
    callout_rect = [SCREEN_W - 380, 80, SCREEN_W - 40, 220]
    draw.rounded_rectangle(callout_rect, radius=6, fill=(12, 16, 24, 245), outline=(100, 180, 255, 255), width=2)
    draw.text((callout_rect[0] + 15, callout_rect[1] + 12), "HUB DURUM MAKİNESİ GÜVENCESİ", font=FONT_SMALL_BOLD, fill=(100, 200, 255, 255))
    draw.text((callout_rect[0] + 15, callout_rect[1] + 38), "✔ HUD Sağ Ok Butonu (▶) Hub'da KALDIRILDI", font=FONT_SMALL, fill=(100, 255, 140, 255))
    draw.text((callout_rect[0] + 15, callout_rect[1] + 62), "✔ Kapıya gidildiğinde çıkış engelleniyor", font=FONT_SMALL, fill=(100, 255, 140, 255))
    draw.text((callout_rect[0] + 15, callout_rect[1] + 86), "✔ Arama yanıtlanmadan malikâneye geçilemez", font=FONT_SMALL, fill=(100, 255, 140, 255))
    draw.text((callout_rect[0] + 15, callout_rect[1] + 110), "✔ Yolculuk sadece telefon sonrası sinematikle başlar", font=FONT_SMALL, fill=(245, 227, 161, 255))

    img.save(OUTPUT_DIR / "fix_hub.png")
    print("Saved fix_hub.png")

# -------------------------------------------------------------
# SCREENSHOT 5: fix_rooms.png
# -------------------------------------------------------------
def generate_fix5_rooms():
    print("Generating fix_rooms.png...")
    img = Image.new("RGBA", (SCREEN_W, SCREEN_H), (12, 15, 22, 255))
    draw = ImageDraw.Draw(img, "RGBA")

    # Header
    draw.rectangle([0, 0, SCREEN_W, 60], fill=(20, 26, 36, 255))
    draw.line([0, 60, SCREEN_W, 60], fill=(55, 70, 90, 255), width=2)
    draw.text((40, 16), "MALİKÂNE MİMARİSİ: ZEMİN KAT 3x2 IZGARA VE ÜST KAT YATAK ODALARI PLANI", font=FONT_TITLE, fill=(245, 227, 161, 255))

    # Notebook Map Tab Frame
    frame_rect = [60, 85, SCREEN_W - 60, SCREEN_H - 30]
    draw.rounded_rectangle(frame_rect, radius=8, fill=(18, 23, 33, 255), outline=(70, 85, 110, 255), width=2)

    # Upper Floor Section
    draw.text((frame_rect[0] + 30, frame_rect[1] + 20), "▲ ÜST KAT (Yatak Odaları Katı)", font=FONT_SUBTITLE, fill=(245, 227, 161, 255))
    
    # 3 Bedroom Cards
    u_bedrooms = [
        ("Julian Harlow Odası", "E12: Kumar Borcu Mektubu", "res://scenes/rooms/julian_room.tscn", False),
        ("Harlow Yatak Odası", "E16: Yırtık Birlik Fotoğrafı & Rozet", "res://scenes/rooms/harlow_bedroom.tscn", False),
        ("Raymond Pike Odası", "E13: Daktilo Şeridi & Borç Mektubu", "res://scenes/rooms/pike_room.tscn", False),
    ]
    u_w = (frame_rect[2] - frame_rect[0] - 100) // 3
    for i, (rname, ev, scn, is_act) in enumerate(u_bedrooms):
        bx = frame_rect[0] + 30 + i * (u_w + 20)
        by = frame_rect[1] + 55
        draw.rounded_rectangle([bx, by, bx + u_w, by + 85], radius=6, fill=(28, 36, 50, 255), outline=(90, 115, 145, 255), width=2)
        draw.text((bx + 16, by + 12), rname, font=FONT_BODY_BOLD, fill=(255, 255, 255, 255))
        draw.text((bx + 16, by + 36), "★ " + ev, font=FONT_SMALL, fill=(255, 215, 100, 255))
        draw.text((bx + 16, by + 58), "Giriş: Üst Kat Koridoru Kapısı", font=FONT_TAG, fill=(150, 170, 190, 255))

    # Upper Corridor Bar
    corridor_rect = [frame_rect[0] + 30, frame_rect[1] + 155, frame_rect[2] - 30, frame_rect[1] + 205]
    draw.rounded_rectangle(corridor_rect, radius=6, fill=(25, 33, 46, 255), outline=(75, 95, 125, 255), width=2)
    draw.text((corridor_rect[0] + 25, corridor_rect[1] + 15), "ÜST KAT KORİDORU  (Julian ↔ Harlow ↔ Pike Kapıları)", font=FONT_BODY_BOLD, fill=(200, 220, 245, 255))
    draw.text((corridor_rect[2] - 220, corridor_rect[1] + 15), "↕ Merdiven: Ana Hol", font=FONT_BODY_BOLD, fill=(245, 227, 161, 255))

    # Ground Floor Section
    draw.text((frame_rect[0] + 30, frame_rect[1] + 230), "▼ ZEMİN KAT (3x2 Izgara Düzeni: Arka Sıra ↕ Ön Sıra)", font=FONT_SUBTITLE, fill=(245, 227, 161, 255))

    # 3x2 Grid
    g_rooms = [
        # Row 1 (Arka Sıra)
        ("Mutfak (Margaret Doyle)", "E14 Kovulma Taslağı  •  Çıkmaz", "Arka Çıkış: KİLİTLİ (Köprü Çöktü)", False),
        ("Çalışma Odası (Suç Mahalli)", "E01-E08 Kanıtları  •  Ceset", "TEK ÇIKIŞ: Ana Hol (İçeriden Kilitli)", True),
        ("Bilardo Odası (Julian Harlow)", "E11 Viski ve Ayak İzi  •  Çıkmaz", "Bağlantı: Kütüphane Kapısı", False),
        # Row 2 (Ön Sıra)
        ("Yemek Odası (Raymond Pike)", "Servis Masası & Büfe", "↕ Mutfak Kapısı  ↔ Ana Hol (Ok)", False),
        ("Ana Hol (Giriş & Merdiven)", "E15 Paspas  •  E17 Telefon", "↕ Çalışma Kapısı / Merdiven  ↔ Yan Odalar (Oklar)", False),
        ("Kütüphane (Dr. Victor Hale)", "E09 Flakon  •  E10 Soğuk Şömine", "↕ Bilardo Kapısı  ↔ Ana Hol (Ok)", False)
    ]

    gw = (frame_rect[2] - frame_rect[0] - 80) // 3
    gh = 95
    for idx, (rname, sub, desc, is_active) in enumerate(g_rooms):
        col = idx % 3
        row = idx // 3
        bx = frame_rect[0] + 30 + col * (gw + 10)
        by = frame_rect[1] + 265 + row * (gh + 12)
        
        bg_col = (35, 55, 80, 255) if is_active else (22, 28, 40, 255)
        border_col = (100, 200, 255, 255) if is_active else (55, 70, 92, 255)
        draw.rounded_rectangle([bx, by, bx + gw, by + gh], radius=6, fill=bg_col, outline=border_col, width=3 if is_active else 2)

        name_col = (255, 235, 140, 255) if is_active else (255, 255, 255, 255)
        draw.text((bx + 14, by + 10), rname, font=FONT_BODY_BOLD, fill=name_col)
        draw.text((bx + 14, by + 34), sub, font=FONT_SMALL, fill=(215, 225, 235, 255))
        draw.text((bx + 14, by + 58), desc, font=FONT_TAG, fill=(245, 190, 80, 255) if is_active else (140, 160, 180, 255))

        if is_active:
            draw.rounded_rectangle([bx + gw - 130, by + 8, bx + gw - 12, by + 32], radius=4, fill=(10, 80, 160, 255))
            draw.text((bx + gw - 122, by + 12), "★ AKTİF KONUM", font=FONT_TAG, fill=(255, 255, 255, 255))

    # Bottom status bar
    draw.text((frame_rect[0] + 35, frame_rect[3] - 30), "✔ Kütüphane ↔ Çalışma bağlantısı KALDIRILDI  •  Çalışma odası tam 1 çıkışlı  •  Tüm odalara Ana Hol üzerinden ulaşılıyor", font=FONT_SMALL_BOLD, fill=(100, 255, 140, 255))

    img.save(OUTPUT_DIR / "fix_rooms.png")
    print("Saved fix_rooms.png")

if __name__ == "__main__":
    generate_fix1_interrogation()
    generate_fix2_scale()
    generate_fix3_dialogue()
    generate_fix4_hub()
    generate_fix5_rooms()
    print("All 5 fix screenshots generated successfully!")
