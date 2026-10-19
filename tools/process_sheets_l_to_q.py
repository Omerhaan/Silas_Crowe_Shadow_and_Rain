#!/usr/bin/env python3
"""
Comprehensive Slicing, Naming, and Processing Script for Gölge ve Yağmur
Covers Sheets L through Q:
  - Grup L: Kanıt İkonları (Clue Icons -> assets/sprites/clues/)
  - Grup M: Yakın Plan İnceleme Sahneleri (InspectView Vignettes -> assets/sprites/inspect/)
  - Grup N: UI İkonları (UI Icons -> assets/sprites/ui/)
  - Grup O: Dekaller (Duvar ve Zemin Detayları -> assets/sprites/decals/)
  - Grup P: Prolog Sinematikleri (16:9 Scenes -> assets/sprites/cinematics/)
  - Grup Q: Flashback Kareleri & Hikâye Nesneleri (-> assets/sprites/flashback/ & assets/sprites/story/)

Strictly avoids Floyd-Steinberg dithering: uses clean downscaling, sharp alpha, and 1px dark contours.
"""

import os
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
import numpy as np

BASE_DIR = Path(__file__).resolve().parent.parent
NEW_ASSETS_DIR = BASE_DIR / "assets" / "new_assets"
SLICES_DIR = BASE_DIR / "assets" / "slices"
SPRITES_DIR = BASE_DIR / "assets" / "sprites"
MANIFEST_PATH = BASE_DIR / "assets" / "asset_manifest.json"

CONTOUR_COLOR = (11, 15, 26, 255)

def add_contour(img: Image.Image, contour_color=CONTOUR_COLOR) -> Image.Image:
    w, h = img.size
    alpha = img.split()[3]
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            if dx == 0 and dy == 0:
                continue
            shifted = Image.new("L", (w, h), 0)
            shifted.paste(alpha, (dx, dy))
            contour_part = Image.new("RGBA", (w, h), contour_color)
            contour_part.putalpha(shifted)
            out = Image.alpha_composite(out, contour_part)
    out = Image.alpha_composite(out, img)
    return out

def key_magenta(img: Image.Image, tolerance: int = 50) -> Image.Image:
    rgb = img.convert("RGB")
    arr = np.array(rgb, dtype=np.int32)
    # Distance to magenta (255, 0, 255)
    dist = np.sqrt((arr[:, :, 0] - 255)**2 + (arr[:, :, 1] - 0)**2 + (arr[:, :, 2] - 255)**2)
    rgba = img.convert("RGBA")
    rgba_arr = np.array(rgba)
    rgba_arr[dist <= tolerance, 3] = 0
    return Image.fromarray(rgba_arr, mode="RGBA")

def fit_and_pad(img: Image.Image, tw: int, th: int, pad_align: str = "center", outline: bool = True) -> Image.Image:
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    
    cw, ch = img.size
    scale = min(tw / max(1, cw), th / max(1, ch))
    rw = max(1, int(round(cw * scale)))
    rh = max(1, int(round(ch * scale)))
    
    resized = img.resize((rw, rh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    
    paste_x = (tw - rw) // 2
    if pad_align == "bottom":
        paste_y = th - rh
    elif pad_align == "top":
        paste_y = 0
    else: # center
        paste_y = (th - rh) // 2
        
    canvas.paste(resized, (paste_x, paste_y), resized)
    
    # Sharp alpha threshold
    alpha = canvas.split()[3].point(lambda p: 255 if p > 80 else 0)
    canvas.putalpha(alpha)
    
    if outline:
        return add_contour(canvas)
    return canvas

def save_sprite_with_preview(img: Image.Image, dest_path: Path):
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    img.save(dest_path, "PNG")
    preview = img.resize((img.width * 4, img.height * 4), Image.Resampling.NEAREST)
    prev_path = dest_path.parent / f"{dest_path.stem}_preview.png"
    preview.save(prev_path, "PNG")

def create_contact_sheet(orig_img: Image.Image, boxes: list[dict], out_path: Path):
    contact = orig_img.convert("RGB").copy()
    draw = ImageDraw.Draw(contact)
    for b in boxes:
        idx = b["idx"]
        x1, y1, x2, y2 = b["x1"], b["y1"], b["x2"], b["y2"]
        draw.rectangle([x1, y1, x2, y2], outline=(255, 0, 0), width=3)
        draw.rectangle([x1, y1, x1 + 36, y1 + 22], fill=(0, 0, 0))
        draw.text((x1 + 4, y1 + 3), str(idx), fill=(255, 255, 255))
    out_path.parent.mkdir(parents=True, exist_ok=True)
    contact.save(out_path, "PNG")

# -------------------------------------------------------------
# 1. PROCESS GRUP L: KANIT İKONLARI
# -------------------------------------------------------------
def process_group_l():
    print(">>> Processing Grup L: Kanıt İkonları...")
    sheet_path = NEW_ASSETS_DIR / "L_kanit_ikonlari.jpg"
    im = Image.open(sheet_path)
    keyed = key_magenta(im, tolerance=60)
    
    # We already have slices in assets/slices/L_kanit_ikonlari
    # Let's map verified item indices to game clue IDs
    clue_mappings = [
        (2,  "clue_e01_pocket_watch",        "E01 Kırık Cep Saati",           (32, 32)),
        (8,  "clue_e02_half_written_letter", "E02 Yarım Kalmış Mektup",       (32, 32)),
        (10, "clue_e03_burned_candle",       "E03 Sönmüş Şamdan Mumu",        (32, 32)),
        (1,  "clue_e04_brandy_glass",        "E04 Zehirli Kadeh",             (32, 32)),
        (3,  "clue_e05_dropper_bottle",      "E05 Kalp İlacı Damlalığı",      (32, 32)),
        (6,  "clue_e06_prescription",        "E06 Dr. Hale'in Reçetesi",      (32, 32)),
        (5,  "clue_e07_threat_letters",      "E07 Mühürlü Tehdit Mektupları", (32, 32)),
        (14, "clue_e08_dismissal_notice",    "E08 Kovulma Bildirimi",         (32, 32)),
        (7,  "clue_e09_digitalis_vial",      "E09 Boş Dijitalis Flakonu",     (32, 32)),
        (20, "clue_e10_fireplace_ash",       "E10 Şömine Külü",               (32, 32)),
        (13, "clue_e11_billiard_chalk",      "E11 Mavi Tebeşir Küpü",         (32, 32)),
        (12, "clue_e13_debt_letter",         "E13 Borç Senedi",               (32, 32)),
        (11, "clue_e14_typewriter_ribbon",   "E14 Daktilo Şeridi",            (32, 32)),
        (9,  "clue_e15_brass_key",           "E15 Pirinç Kapı Anahtarı",      (32, 32)),
        (4,  "clue_e16_torn_photo",          "E16 Yırtık Fotoğraf",           (32, 32)),
        (18, "clue_e17_rotary_phone",        "E17 Açık Bırakılmış Telefon",   (32, 32)),
        (15, "icon_medical_bag",             "Doktor Çantası",                (32, 32)),
        (16, "icon_medic_registry",          "Sıhhiye Kayıt Defteri",         (32, 32)),
        (17, "icon_matchbook",               "Kibrit Kutusu",                 (32, 32)),
        (19, "icon_cigar_ashtray",           "Küllük ve Puro",                (32, 32)),
        (22, "icon_muddy_bootprint",         "Çamurlu Ayak İzi",              (32, 32)),
        (23, "icon_wet_umbrella",            "Islak Şemsiye",                 (32, 32)),
        (26, "icon_reading_glasses",         "Okuma Gözlüğü",                 (32, 32)),
        (25, "icon_door_lock",               "Pirinç Kapı Kilidi",            (32, 32)),
    ]
    
    slices_dir = SLICES_DIR / "L_kanit_ikonlari"
    out_dir = SPRITES_DIR / "clues"
    manifest_entries = {}
    
    for item_idx, name, desc, size in clue_mappings:
        # Find slice
        prefix = f"item_{item_idx:02d}_"
        match = None
        for sf in slices_dir.iterdir():
            if sf.name.startswith(prefix) and sf.name.endswith(".png"):
                match = sf
                break
        if not match:
            print(f"Warning: Slice not found for {prefix}")
            continue
        
        raw_slice = Image.open(match)
        sprite = fit_and_pad(raw_slice, size[0], size[1], pad_align="center", outline=True)
        dest_path = out_dir / f"{name}.png"
        save_sprite_with_preview(sprite, dest_path)
        
        manifest_entries[name] = {
            "path": f"res://assets/sprites/clues/{name}.png",
            "size": list(size),
            "display_name": desc,
            "category": "clue_icon",
            "sheet": "L"
        }
    print(f"Processed {len(manifest_entries)} clue icons.")
    return manifest_entries

# -------------------------------------------------------------
# 2. PROCESS GRUP M: YAKIN PLAN İNCELEME SAHNELERİ (Vignettes)
# -------------------------------------------------------------
def process_group_m():
    print(">>> Processing Grup M: Yakın Plan İnceleme Sahneleri...")
    # Target size: 160x120 (4:3 aspect ratio modal viewport)
    vignettes_def = [
        # Sheet 1:
        ("M_yakin_plan_sahnesi_1.jpg", "M1", [
            ("inspect_e04_brandy_poison",  "Zehirli Kadeh ve Şişe Yakın Planı",             (0, 0, 896, 1200)),
            ("inspect_e01_pocket_watch",   "Kırık Cep Saati ve Çatlak Cam Yakın Planı",     (896, 0, 1791, 1200)),
            ("inspect_e07_threat_letters", "Mühürlü Tehdit Mektupları Yakın Planı",         (0, 1200, 896, 2399)),
            ("inspect_e05_desk_drawer",    "Açık Çekmece, Damlalık ve Evrak Yakın Planı",    (896, 1200, 1791, 2399)),
        ]),
        # Sheet 2:
        ("M_yakin_plan_sahnesi_2.jpg", "M2", [
            ("inspect_e16_torn_photo",         "İki Askerin Yırtık Fotoğrafı Yakın Planı",  (0, 0, 1370, 762)),
            ("inspect_e17_phone_off_hook",     "Açık Bırakılmış Telefon Yakın Planı",       (1381, 0, 2751, 762)),
            ("inspect_silas_ministry_desk",    "Silas'ın Masası ve Mühürlü Mektup",         (0, 773, 1370, 1535)),
            ("inspect_e11_billiard_corner",    "Bilardo Masası Köşesi ve Tebeşir",          (1381, 773, 2751, 1535)),
        ]),
        # Sheet 3:
        ("M_yakin_plan_sahnesi_3.jpg", "M3", [
            ("inspect_e08_wastebasket",    "Çöp Kovası ve Kovulma Bildirimi",               (0, 0, 1200, 896)),
            ("inspect_e09_cold_fireplace", "Küllü Şömine ve Boş Flakon",                    (1200, 0, 2399, 896)),
            ("inspect_e15_keyhole_key",    "Kilit Deliğindeki Pirinç Anahtar",              (0, 896, 1200, 1791)),
            ("inspect_e03_burned_candle",  "Erimiş Şamdan Mumu Yakın Planı",                (1200, 896, 2399, 1791)),
        ])
    ]
    
    out_dir = SPRITES_DIR / "inspect"
    manifest_entries = {}
    
    for filename, group_code, panels in vignettes_def:
        sheet_path = NEW_ASSETS_DIR / filename
        im = Image.open(sheet_path).convert("RGBA")
        slice_dir = SLICES_DIR / filename.replace(".jpg", "")
        slice_dir.mkdir(parents=True, exist_ok=True)
        
        boxes = []
        for i, (name, desc, box) in enumerate(panels, 1):
            x1, y1, x2, y2 = box
            cropped = im.crop((x1, y1, x2, y2))
            # Save raw slice
            cropped.save(slice_dir / f"panel_{i:02d}_{name}.png", "PNG")
            boxes.append({"idx": i, "x1": x1, "y1": y1, "x2": x2, "y2": y2})
            
            # Scale cleanly to 160x120 for in-game InspectView modal
            tw, th = 160, 120
            scaled = cropped.resize((tw, th), Image.Resampling.LANCZOS)
            dest_path = out_dir / f"{name}.png"
            save_sprite_with_preview(scaled, dest_path)
            
            manifest_entries[name] = {
                "path": f"res://assets/sprites/inspect/{name}.png",
                "size": [tw, th],
                "display_name": desc,
                "category": "inspect_vignette",
                "sheet": group_code
            }
        create_contact_sheet(im, boxes, slice_dir / "contact_sheet.png")
    
    print(f"Processed {len(manifest_entries)} inspect vignettes.")
    return manifest_entries

# -------------------------------------------------------------
# 3. PROCESS GRUP N: UI İKONLARI
# -------------------------------------------------------------
def process_group_n():
    print(">>> Processing Grup N: UI İkonları...")
    sheet_path = NEW_ASSETS_DIR / "N_ui_ikonlari.jpg"
    im = Image.open(sheet_path)
    keyed = key_magenta(im, tolerance=60)
    
    # 24 UI Icons mapping
    # Item pairs to combine: (17, 19) for question mark, (22, 23) for pause, (26, 27) for quotes
    slices_dir = SLICES_DIR / "N_ui_ikonlari"
    
    def get_slice(item_idx):
        prefix = f"item_{item_idx:02d}_"
        for sf in slices_dir.iterdir():
            if sf.name.startswith(prefix) and sf.name.endswith(".png"):
                return Image.open(sf).convert("RGBA")
        raise FileNotFoundError(f"Missing slice: {prefix}")

    ui_items = [
        ("ui_icon_notebook",        "Defter İkonu",               get_slice(1)),
        ("ui_icon_folder",          "Kanıt Klasörü İkonu",         get_slice(2)),
        ("ui_icon_magnifier",       "Büyüteç İncele İkonu",        get_slice(3)),
        ("ui_icon_gear",            "Ayarlar Çarkı İkonu",         get_slice(4)),
        ("ui_icon_arrow_left",      "Sol Ok İkonu",               get_slice(5)),
        ("ui_icon_arrow_right",     "Sağ Ok İkonu",               get_slice(6)),
        ("ui_icon_phone",           "Telefon İkonu",              get_slice(7)),
        ("ui_icon_accuse",          "Suçlama / İşaret Parmağı",    get_slice(10)),
        ("ui_icon_tab_evidence",    "Kanıt Sekmesi (İğneli Kâğıt)",get_slice(8)),
        ("ui_icon_tab_statements",  "İfadeler Sekmesi (Balon)",    get_slice(11)),
        ("ui_icon_tab_timeline",    "Zaman Çizelgesi Sekmesi",     get_slice(9)),
        ("ui_icon_tab_deductions",  "Dedüksiyon Sekmesi (Halkalar)",get_slice(12)),
        ("ui_icon_tab_suspects",    "Şüpheliler Sekmesi (Profil)", get_slice(13)),
        ("ui_icon_tab_map",         "Harita Sekmesi (Kroki)",      get_slice(14)),
        ("ui_icon_lock_closed",     "Kilitli Asma Kilit",          get_slice(15)),
        ("ui_icon_lock_open",       "Açık Asma Kilit",             get_slice(16)),
        ("ui_icon_check",           "Onay İşareti",               get_slice(18)),
        ("ui_icon_cross",           "Çarpı / İptal İşareti",       get_slice(20)),
        ("ui_icon_lightbulb",       "İpucu Ampulü",               get_slice(21)),
        ("ui_icon_floppy",          "Kayıt Disketi",              get_slice(24)),
        ("ui_icon_close",           "Kapat Çarpı Butonu",         get_slice(25)),
    ]
    
    # Combined items
    # Question mark (17 + 19)
    q_top = get_slice(17)
    q_dot = get_slice(19)
    qw = max(q_top.width, q_dot.width)
    qh = q_top.height + q_dot.height + 4
    q_img = Image.new("RGBA", (qw, qh), (0, 0, 0, 0))
    q_img.paste(q_top, ((qw - q_top.width)//2, 0), q_top)
    q_img.paste(q_dot, ((qw - q_dot.width)//2, q_top.height + 4), q_dot)
    ui_items.append(("ui_icon_question", "Soru İşareti", q_img))
    
    # Pause bars (22 + 23)
    p1 = get_slice(22)
    p2 = get_slice(23)
    pw = p1.width + p2.width + 4
    ph = max(p1.height, p2.height)
    p_img = Image.new("RGBA", (pw, ph), (0, 0, 0, 0))
    p_img.paste(p1, (0, 0), p1)
    p_img.paste(p2, (p1.width + 4, 0), p2)
    ui_items.append(("ui_icon_pause", "Duraklat İkonu", p_img))
    
    # Quotes (26 + 27)
    q1 = get_slice(26)
    q2 = get_slice(27)
    quw = q1.width + q2.width + 4
    quh = max(q1.height, q2.height)
    qu_img = Image.new("RGBA", (quw, quh), (0, 0, 0, 0))
    qu_img.paste(q1, (0, 0), q1)
    qu_img.paste(q2, (q1.width + 4, 0), q2)
    ui_items.append(("ui_icon_quotes", "Tırnak / İç Ses İkonu", qu_img))
    
    out_dir = SPRITES_DIR / "ui"
    manifest_entries = {}
    
    for name, desc, raw_img in ui_items:
        sprite = fit_and_pad(raw_img, 24, 24, pad_align="center", outline=False)
        dest_path = out_dir / f"{name}.png"
        save_sprite_with_preview(sprite, dest_path)
        manifest_entries[name] = {
            "path": f"res://assets/sprites/ui/{name}.png",
            "size": [24, 24],
            "display_name": desc,
            "category": "ui_icon",
            "sheet": "N"
        }
    print(f"Processed {len(manifest_entries)} UI icons.")
    return manifest_entries

# -------------------------------------------------------------
# 4. PROCESS GRUP O: DEKALLER (Duvar ve Zemin Detayları)
# -------------------------------------------------------------
def process_group_o():
    print(">>> Processing Grup O: Dekaller...")
    sheet_path = NEW_ASSETS_DIR / "O_duvar_zemin_detaylari.jpg"
    im = Image.open(sheet_path)
    keyed = key_magenta(im, tolerance=60)
    
    cols = [0, 458, 917, 1376, 1834, 2293, 2752]
    rows = [0, 512, 1024, 1536]
    
    decal_names = [
        # Row 1
        ("decal_crack_wall_round",    "Yuvarlak Duvar Çatlağı",       (32, 32)),
        ("decal_crack_wall_spider",   "Örümcek Ağı Duvar Çatlağı",     (36, 30)),
        ("decal_crack_wall_vertical", "Dikey Duvar Çatlağı",           (20, 38)),
        ("decal_wallpaper_peel",      "Soyulmuş Duvar Kâğıdı",         (36, 38)),
        ("decal_water_stain",         "Duvar Su Lekesi ve Damlaları",  (28, 38)),
        ("decal_mold_patch",          "Küf Lekesi Kümesi",             (40, 48)),
        # Row 2
        ("decal_cobweb_corner",       "Köşe Örümcek Ağı",              (38, 42)),
        ("decal_paint_burgundy",      "Bordo Boya Sıçraması",          (34, 34)),
        ("decal_paint_gray",          "Gri Boya Sıçraması",            (34, 34)),
        ("decal_paint_cream",         "Krem Boya Sıçraması",           (34, 34)),
        ("decal_footprints_mud",      "Çamurlu Ayak İzi Patikası",     (38, 40)),
        ("decal_footprints_wet",      "Islak Ayak İzi Patikası",       (36, 48)),
        # Row 3
        ("decal_scratches_floor",     "Zemin Tahta Çizikleri",         (42, 40)),
        ("decal_glass_shards",        "Kırık Cam Parçaları",           (40, 36)),
        ("decal_water_puddle",        "Su Birikintisi",                (38, 32)),
        ("decal_newspaper_crumpled",  "Buruşuk Gazete Parçası",        (38, 36)),
        ("decal_dust_debris",         "Dağılmış Toz ve Döküntü",       (38, 38)),
        ("decal_frame_sunbleached",   "Duvarda Solmuş Tablo İzi",      (42, 48)),
    ]
    
    slices_dir = SLICES_DIR / "O_duvar_zemin_detaylari"
    slices_dir.mkdir(parents=True, exist_ok=True)
    out_dir = SPRITES_DIR / "decals"
    
    contact_boxes = []
    manifest_entries = {}
    
    idx = 0
    for r in range(3):
        for c in range(6):
            name, desc, target_size = decal_names[idx]
            x1, x2 = cols[c], cols[c+1]
            y1, y2 = rows[r], rows[r+1]
            
            cell_img = keyed.crop((x1, y1, x2, y2))
            bbox = cell_img.getbbox()
            if bbox:
                cropped = cell_img.crop(bbox)
                bx1 = x1 + bbox[0]
                by1 = y1 + bbox[1]
                bx2 = x1 + bbox[2]
                by2 = y1 + bbox[3]
            else:
                cropped = cell_img
                bx1, by1, bx2, by2 = x1, y1, x2, y2
                
            contact_boxes.append({"idx": idx + 1, "x1": bx1, "y1": by1, "x2": bx2, "y2": by2})
            cropped.save(slices_dir / f"decal_{idx+1:02d}_{name}.png", "PNG")
            
            # Scale to game decal size (no outline, smooth alpha)
            sprite = fit_and_pad(cropped, target_size[0], target_size[1], pad_align="center", outline=False)
            dest_path = out_dir / f"{name}.png"
            save_sprite_with_preview(sprite, dest_path)
            
            manifest_entries[name] = {
                "path": f"res://assets/sprites/decals/{name}.png",
                "size": list(target_size),
                "display_name": desc,
                "category": "decal",
                "sheet": "O"
            }
            idx += 1
            
    create_contact_sheet(im, contact_boxes, slices_dir / "contact_sheet.png")
    print(f"Processed {len(manifest_entries)} decals.")
    return manifest_entries

# -------------------------------------------------------------
# 5. PROCESS GRUP P: PROLOG SİNEMATİKLERİ
# -------------------------------------------------------------
def process_group_p():
    print(">>> Processing Grup P: Prolog Sinematikleri...")
    slices_dir = SLICES_DIR / "P_sinematik"
    slices_dir.mkdir(parents=True, exist_ok=True)
    out_dir = SPRITES_DIR / "cinematics"
    manifest_entries = {}
    
    # Target resolution: 320x180 (Full native 16:9 game resolution)
    cinematics = [
        ("P_sinematik_1.jpg", 1, "cinematic_prologue_01", "Prolog 1: Silas Masasında Gece",           None),
        ("P_sinematik_2.jpg", 2, "cinematic_prologue_02", "Prolog 2: Titreyen Siyah Telefon Yakın Planı", None),
        ("P_sinematik_3_4.jpg", 3, "cinematic_prologue_03", "Prolog 3: Yağmurda İlerleyen Sedan Araba",   (0, 0, 825, 501)),
        ("P_sinematik_3_4.jpg", 4, "cinematic_prologue_04", "Prolog 4: Taş Köprüden Geçiş ve Şimşek",    (0, 502, 825, 1024)),
        ("P_sinematik_5_6_7.jpg", 5, "cinematic_prologue_05", "Prolog 5: Yıkılan Taş Köprü",             (0, 0, 1536, 919)),
        ("P_sinematik_5_6_7.jpg", 6, "cinematic_prologue_06", "Prolog 6: Malikane Dış Cephesi Gece",     (0, 920, 1536, 1835)),
        ("P_sinematik_5_6_7.jpg", 7, "cinematic_prologue_07", "Prolog 7: 7 Odalı Malikane Kesit Maketi",  (0, 1836, 1536, 2752)),
    ]
    
    for filename, scene_num, name, desc, box in cinematics:
        im = Image.open(NEW_ASSETS_DIR / filename).convert("RGBA")
        if box:
            cropped = im.crop(box)
        else:
            cropped = im
            
        cropped.save(slices_dir / f"scene_{scene_num:02d}_{name}.png", "PNG")
        
        # Clean scale to 320x180 (16:9)
        scaled = cropped.resize((320, 180), Image.Resampling.LANCZOS)
        dest_path = out_dir / f"{name}.png"
        save_sprite_with_preview(scaled, dest_path)
        
        manifest_entries[name] = {
            "path": f"res://assets/sprites/cinematics/{name}.png",
            "size": [320, 180],
            "display_name": desc,
            "category": "cinematic",
            "sheet": "P"
        }
        
    print(f"Processed {len(manifest_entries)} cinematics.")
    return manifest_entries

# -------------------------------------------------------------
# 6. PROCESS GRUP Q: FLASHBACK & HİKÂYE NESNELERİ
# -------------------------------------------------------------
def process_group_q():
    print(">>> Processing Grup Q: Flashback & Hikâye Nesneleri...")
    # Flashback Scenes (2x2 grid from Q_flashback_kareleri.jpg)
    q_sheet = NEW_ASSETS_DIR / "Q_flashback_kareleri.jpg"
    im_fb = Image.open(q_sheet).convert("RGBA")
    fb_slices_dir = SLICES_DIR / "Q_flashback_kareleri"
    fb_slices_dir.mkdir(parents=True, exist_ok=True)
    fb_out_dir = SPRITES_DIR / "flashback"
    
    fb_panels = [
        ("flashback_fb01_01_battlefield", "FB01 Kare 1: Gece Karlı Savaş Alanı",              (5, 0, 1370, 762)),
        ("flashback_fb01_02_medic_bag",   "FB01 Kare 2: Karda Kırmızı Haçlı Sıhhiye Çantası", (1381, 0, 2746, 762)),
        ("flashback_fb01_03_clutched_hand", "FB01 Kare 3: Kıvranan El ve Kırmızı İplik",      (5, 773, 1370, 1535)),
        ("flashback_fb01_04_explosion_flare", "FB01 Kare 4: Ufuktaki Patlama ve Kırmızı Fişek",(1381, 773, 2746, 1535)),
    ]
    
    manifest_entries = {}
    boxes = []
    for i, (name, desc, box) in enumerate(fb_panels, 1):
        cropped = im_fb.crop(box)
        cropped.save(fb_slices_dir / f"frame_{i:02d}_{name}.png", "PNG")
        boxes.append({"idx": i, "x1": box[0], "y1": box[1], "x2": box[2], "y2": box[3]})
        
        # Scale to 320x180
        scaled = cropped.resize((320, 180), Image.Resampling.LANCZOS)
        dest_path = fb_out_dir / f"{name}.png"
        save_sprite_with_preview(scaled, dest_path)
        manifest_entries[name] = {
            "path": f"res://assets/sprites/flashback/{name}.png",
            "size": [320, 180],
            "display_name": desc,
            "category": "flashback",
            "sheet": "Q"
        }
    create_contact_sheet(im_fb, boxes, fb_slices_dir / "contact_sheet.png")
    
    # Story Objects (from Q_hikaye_nesneleri.jpg, keyed magenta)
    story_slices_dir = SLICES_DIR / "Q_hikaye_nesneleri"
    story_out_dir = SPRITES_DIR / "story"
    
    def get_story_slice(item_idx):
        prefix = f"item_{item_idx:02d}_"
        for sf in story_slices_dir.iterdir():
            if sf.name.startswith(prefix) and sf.name.endswith(".png"):
                return Image.open(sf).convert("RGBA")
        raise FileNotFoundError(f"Missing story slice: {prefix}")
        
    story_items = [
        (1,  "story_pocket_watch_front",   "Kuzey Birimi Cep Saati (Ön Yüz 3:12)",      (48, 48),  "center", True),
        (2,  "story_pocket_watch_back",    "Kuzey Birimi Cep Saati (Arka Amblem)",      (48, 48),  "center", True),
        (5,  "story_unit_board_slots",     "Gizli Kuzey Birimi 9 Madalya Yuvası",       (128, 32), "center", True),
        (3,  "story_torn_photo_soldiers_2","Yırtık Fotoğraf: 2 Asker",                 (48, 56),  "center", True),
        (4,  "story_torn_photo_soldiers_3","Yırtık Fotoğraf: 3 Asker",                 (56, 56),  "center", True),
        (9,  "story_handwritten_note",     "Gizli Not (Sarı Kâğıt)",                    (40, 48),  "center", True),
        (6,  "story_ministry_letter",      "Savaş Bakanlığı Ret Mektubu",              (44, 56),  "center", True),
        (10, "story_medic_badge",          "Kırmızı Haç Sıhhiye Rozeti",               (32, 32),  "center", True),
        (7,  "story_military_dog_tag",     "Paslanmış Askeri Künye",                   (32, 48),  "center", True),
        (8,  "story_coat_hat_hook",        "Askıda Palto ve Şapka",                    (32, 56),  "bottom", True),
    ]
    
    for item_idx, name, desc, size, align, outline in story_items:
        raw_slice = get_story_slice(item_idx)
        sprite = fit_and_pad(raw_slice, size[0], size[1], pad_align=align, outline=outline)
        dest_path = story_out_dir / f"{name}.png"
        save_sprite_with_preview(sprite, dest_path)
        manifest_entries[name] = {
            "path": f"res://assets/sprites/story/{name}.png",
            "size": list(size),
            "display_name": desc,
            "category": "story_object",
            "sheet": "Q"
        }
        
    print(f"Processed {len(manifest_entries)} flashback and story objects.")
    return manifest_entries

def main():
    print("=" * 60)
    print("  GÖLGE VE YAĞMUR — BATCH ASSET PROCESSOR (SHEETS L to Q)")
    print("=" * 60)
    
    all_manifest_entries = {}
    all_manifest_entries.update(process_group_l())
    all_manifest_entries.update(process_group_m())
    all_manifest_entries.update(process_group_n())
    all_manifest_entries.update(process_group_o())
    all_manifest_entries.update(process_group_p())
    all_manifest_entries.update(process_group_q())
    
    # Update asset_manifest.json
    if MANIFEST_PATH.exists():
        with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    else:
        manifest = {}
        
    manifest.setdefault("assets", {})
    manifest["assets"].update(all_manifest_entries)
    
    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2, ensure_ascii=False)
        
    print(f"Total {len(all_manifest_entries)} new assets integrated into manifest!")
    print("=" * 60)

if __name__ == "__main__":
    main()
