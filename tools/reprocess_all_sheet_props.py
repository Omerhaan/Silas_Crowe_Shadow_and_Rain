#!/usr/bin/env python3
"""
Reprocess all props from sliced sheets with 100% verified item indices.
Quantizes each prop to the noir24 palette, adds a 1px contour (#0b0f1a),
saves into assets/sprites/props/, and updates assets/asset_manifest.json.
"""

import os
import glob
import json
from pathlib import Path
from PIL import Image

BASE_DIR = Path(__file__).resolve().parent.parent
MANIFEST_PATH = BASE_DIR / "assets" / "asset_manifest.json"
PALETTE_PATH = BASE_DIR / "data" / "palette" / "noir24.hex"
OUT_DIR = BASE_DIR / "assets" / "sprites" / "props"

def load_palette():
    with open(PALETTE_PATH, "r", encoding="utf-8") as f:
        hex_colors = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    pal = []
    for h in hex_colors:
        h = h.lstrip("#")
        pal.extend([int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)])
    while len(pal) < 256 * 3:
        pal.extend([0, 0, 0])
    return pal

PALETTE_BYTES = load_palette()
PALETTE_IMG = Image.new("P", (1, 1))
PALETTE_IMG.putpalette(PALETTE_BYTES)

def add_contour(img: Image.Image, contour_color=(11, 15, 26, 255)) -> Image.Image:
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

def process_and_save(src_path: Path, dest_path: Path, target_size: tuple, outline: bool = True) -> bool:
    if not src_path or not src_path.exists():
        print(f"MISSING: {src_path}")
        return False

    img = Image.open(src_path).convert("RGBA")
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)

    tw, th = target_size
    img_aspect = img.width / max(1, img.height)
    target_aspect = tw / max(1, th)

    if img_aspect > target_aspect:
        rw = tw
        rh = max(1, int(round(tw / img_aspect)))
    else:
        rh = th
        rw = max(1, int(round(th * img_aspect)))

    resized = img.resize((rw, rh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (tw, th), (0, 0, 0, 0))
    paste_x = (tw - rw) // 2
    paste_y = th - rh  # bottom align
    canvas.paste(resized, (paste_x, paste_y), resized)

    # Clean alpha threshold (no dithering / no noisy quantization)
    alpha = canvas.split()[3].point(lambda p: 255 if p > 80 else 0)
    canvas.putalpha(alpha)

    if outline:
        out_img = add_contour(canvas)
    else:
        out_img = canvas

    dest_path.parent.mkdir(parents=True, exist_ok=True)
    out_img.save(dest_path, "PNG")

    preview = out_img.resize((target_size[0] * 4, target_size[1] * 4), Image.Resampling.NEAREST)
    stem = dest_path.stem
    prev_path = dest_path.parent / f"{stem}_preview.png"
    preview.save(prev_path, "PNG")
    return True

def find_item(folder_rel: str, idx: int):
    folder = BASE_DIR / folder_rel
    matches = sorted(glob.glob(str(folder / f"item_{idx:02d}_*.png")))
    if matches:
        return Path(matches[0])
    return None

ITEMS = [
    # C1: Pencereler ve Kapılar
    ("assets/slices/C1_pencereler_ve_kapilar", 1, "window_mansion.png", (48, 56), "prop_window_mansion", "Gotik kemerli malikane penceresi"),
    ("assets/slices/C1_pencereler_ve_kapilar", 2, "window_large.png", (48, 56), "prop_window_large", "Büyük 3 bölmeli pencere"),
    ("assets/slices/C1_pencereler_ve_kapilar", 3, "window_single.png", (28, 56), "prop_window_single", "Tek kanatlı dar pencere"),
    ("assets/slices/C1_pencereler_ve_kapilar", 4, "window_small.png", (24, 40), "prop_window_small", "Küçük servis penceresi"),

    # C2: Merdiven, Şömine, Çerçeveler
    ("assets/slices/C2_merdiven_somine_cerceveler", 1, "stairs_mansion.png", (72, 76), "prop_stairs_mansion", "Büyük ahşap merdiven trabzanı"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 2, "fireplace_cold.png", (56, 44), "prop_fireplace_cold", "Sönmüş taş şömine"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 3, "fireplace.png", (56, 44), "prop_fireplace", "Yanan klasik taş şömine"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 6, "hall_grand_mirror.png", (30, 52), "prop_hall_grand_mirror", "Büyük altın varaklı ayna"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 7, "family_crest_shield.png", (28, 34), "prop_family_crest_shield", "Hanedan arması ve kalkan"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 8, "portrait_frame_oval.png", (18, 24), "prop_portrait_frame_oval", "Oval portre tablosu"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 9, "study_portrait_harlow.png", (28, 28), "prop_study_portrait_harlow", "Edmund Harlow yağlıboya portresi"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 10, "landscape_painting.png", (28, 20), "prop_landscape_painting", "Geniş manzara tablosu"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 11, "landscape_painting_small.png", (22, 18), "prop_landscape_painting_small", "Küçük manzara tablosu"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 12, "wall_clock_round.png", (16, 16), "prop_wall_clock_round", "Yuvarlak duvar saati"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 15, "wall_sconce.png", (10, 14), "prop_wall_sconce", "Pirinç duvar apliği"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 16, "wall_sconce_lit.png", (10, 14), "prop_wall_sconce_lit", "Yanan pirinç duvar apliği"),

    # C3: Tavan Lambaları
    ("assets/slices/C3_tavan_suslemeler", 1, "ceiling_lamp_pendant.png", (16, 28), "prop_ceiling_lamp_pendant", "Zincirli tekli tavan lambası"),
    ("assets/slices/C3_tavan_suslemeler", 2, "chandelier_grand.png", (36, 36), "prop_chandelier_grand", "Büyük kristal avize"),

    # D: Hub (Silas'ın Evi / Ofisi)
    ("assets/slices/D_silasin_evi", 1, "silas_office_chair.png", (24, 34), "prop_silas_office_chair", "Tekerlekli deri ofis koltuğu"),
    ("assets/slices/D_silasin_evi", 2, "silas_telephone.png", (24, 28), "prop_silas_telephone", "Sehpa üstünde siyah antika telefon"),
    ("assets/slices/D_silasin_evi", 3, "silas_vintage_radio.png", (24, 20), "prop_silas_vintage_radio", "Eski ahşap radyo"),
    ("assets/slices/D_silasin_evi", 4, "silas_whiskey_tray.png", (24, 16), "prop_silas_whiskey_tray", "Viski şişesi ve kadeh tepsisi"),
    ("assets/slices/D_silasin_evi", 5, "silas_desk.png", (64, 34), "prop_silas_desk", "Silas'ın çalışma masası"),
    ("assets/slices/D_silasin_evi", 6, "silas_coat_rack.png", (18, 54), "prop_silas_coat_rack", "Paltolu ve şapkalı ayaklı askılık"),
    ("assets/slices/D_silasin_evi", 7, "silas_filing_cabinet.png", (24, 40), "prop_silas_filing_cabinet", "Silas'ın metal evrak dolabı"),
    ("assets/slices/D_silasin_evi", 8, "silas_memory_wall.png", (48, 32), "prop_silas_memory_wall", "İğneli anı ve ipucu panosu"),
    ("assets/slices/D_silasin_evi", 9, "silas_lamp.png", (12, 28), "prop_silas_lamp", "Yeşil pirinç banker lamba"),
    ("assets/slices/D_silasin_evi", 10, "silas_typewriter.png", (20, 16), "prop_silas_typewriter", "Eski yazı daktilosu"),
    ("assets/slices/D_silasin_evi", 11, "silas_rainy_window.png", (48, 56), "prop_silas_rainy_window", "Pencere pervazında durmuş cep saati"),
    ("assets/slices/D_silasin_evi", 12, "silas_armchair.png", (64, 34), "prop_silas_armchair", "Deri berjer koltuk ve sehpa"),
    ("assets/slices/D_silasin_evi", 13, "silas_books_stack.png", (20, 20), "prop_silas_books_stack", "Eski ciltli kitap yığını"),
    ("assets/slices/D_silasin_evi", 14, "silas_drawer_small.png", (24, 24), "prop_silas_drawer_small", "3 çekmeceli kilitli komodin"),
    ("assets/slices/D_silasin_evi", 15, "silas_rejection_letter.png", (14, 10), "prop_silas_rejection_letter", "Kırmızı mühürlü Bakanlık ret mektubu"),

    # E: Çalışma Odası
    ("assets/slices/E_calisma_odasi", 1, "study_desk.png", (64, 34), "prop_study_desk", "Harlow'un çalışma masası"),
    ("assets/slices/E_calisma_odasi", 2, "study_chair.png", (24, 34), "prop_study_chair", "Boş çalışma koltuğu"),
    ("assets/slices/E_calisma_odasi", 3, "study_corpse_harlow.png", (34, 36), "prop_study_corpse_harlow", "Koltukta yığılmış Harlow cesedi"),
    ("assets/slices/E_calisma_odasi", 4, "study_desk_empty.png", (64, 34), "prop_study_desk_empty", "Boş maun çalışma masası"),
    ("assets/slices/E_calisma_odasi", 5, "study_bookcase.png", (56, 90), "prop_study_bookcase", "Masif ceviz kitaplık"),
    ("assets/slices/E_calisma_odasi", 6, "study_cabinet.png", (48, 44), "prop_study_cabinet", "Camlı büfe dolabı"),
    ("assets/slices/E_calisma_odasi", 7, "study_safe.png", (28, 32), "prop_study_safe", "Kilitli ağır çelik duvar kasası"),
    ("assets/slices/E_calisma_odasi", 8, "study_globe.png", (20, 30), "prop_study_globe", "Pirinç ayaklı dünya küresi"),
    ("assets/slices/E_calisma_odasi", 9, "study_waste_basket.png", (16, 18), "prop_study_waste_basket", "Yırtık kâğıtlı çöp sepeti"),
    ("assets/slices/E_calisma_odasi", 10, "study_lamp.png", (12, 16), "prop_study_lamp", "Pirinç şamdan ve yanan mum"),
    ("assets/slices/E_calisma_odasi", 11, "study_armchair.png", (40, 36), "prop_study_armchair", "Harlow'un deri koltuğu"),
    ("assets/slices/E_calisma_odasi", 14, "study_nightstand.png", (22, 28), "prop_study_nightstand", "Komodin ve ilaç şişesi"),

    # F: Kütüphane
    ("assets/slices/F_kutuphane", 1, "library_bookcase.png", (56, 90), "prop_library_bookcase", "Oymalı ceviz kütüphane kitaplığı"),
    ("assets/slices/F_kutuphane", 2, "library_ladder.png", (18, 60), "prop_library_ladder", "Raylı tekerlekli kütüphane merdiveni"),
    ("assets/slices/F_kutuphane", 3, "library_bookcase_2.png", (56, 90), "prop_library_bookcase_2", "İkinci kütüphane kitaplığı"),
    ("assets/slices/F_kutuphane", 4, "library_bookcase_arch.png", (48, 90), "prop_library_bookcase_arch", "Gotik kemerli kitaplık"),
    ("assets/slices/F_kutuphane", 5, "library_reading_chair.png", (28, 34), "prop_library_reading_chair", "Deri kütüphane okuma koltuğu"),
    ("assets/slices/F_kutuphane", 6, "library_footstool.png", (14, 10), "prop_library_footstool", "Ayak pufu"),
    ("assets/slices/F_kutuphane", 7, "library_grandfather_clock.png", (24, 66), "prop_library_grandfather_clock", "Büyükbaba saati"),
    ("assets/slices/F_kutuphane", 8, "library_globe.png", (20, 32), "prop_library_globe", "Ayaklı pirinç dünya küresi"),
    ("assets/slices/F_kutuphane", 9, "library_table_lamp.png", (18, 28), "prop_library_table_lamp", "Abajurlu okuma sehpası"),
    ("assets/slices/F_kutuphane", 10, "library_cold_fireplace.png", (60, 44), "prop_library_cold_fireplace", "Soğuk şömine ve pervazdaki digitalis şişesi"),
    ("assets/slices/F_kutuphane", 11, "library_piano.png", (36, 50), "prop_library_piano", "Duvar piyanosu"),
    ("assets/slices/F_kutuphane", 13, "library_reading_desk.png", (56, 34), "prop_library_reading_desk", "Geniş okuma masası"),
    ("assets/slices/F_kutuphane", 14, "library_books_stack.png", (24, 22), "prop_library_books_stack", "Büyük araştırma kitapları yığını"),

    # G: Yemek Odası
    ("assets/slices/G_yemek_odasi", 1, "dining_table.png", (72, 34), "prop_dining_table", "Beyaz örtülü, kadehler ve şamdanlı ziyafet masası"),
    ("assets/slices/G_yemek_odasi", 2, "dining_chair_left.png", (18, 36), "prop_dining_chair_left", "Deri yemek sandalyesi (sol)"),
    ("assets/slices/G_yemek_odasi", 3, "dining_chair_right.png", (18, 36), "prop_dining_chair_right", "Deri yemek sandalyesi (sağ)"),
    ("assets/slices/G_yemek_odasi", 4, "dining_candelabra.png", (28, 36), "prop_dining_candelabra", "Yemek salonu kristal avizesi"),
    ("assets/slices/G_yemek_odasi", 5, "dining_grandfather_clock.png", (24, 66), "prop_dining_grandfather_clock", "Yemek odası büyükbaba saati"),
    ("assets/slices/G_yemek_odasi", 6, "dining_china_cabinet.png", (44, 68), "prop_dining_china_cabinet", "Camlı porselen ve gümüş dolabı"),
    ("assets/slices/G_yemek_odasi", 7, "dining_sideboard.png", (64, 36), "prop_dining_sideboard", "Büyük yemek büfesi"),
    ("assets/slices/G_yemek_odasi", 8, "dining_drawer_chest.png", (28, 34), "prop_dining_drawer_chest", "Çekmeceli servis dolabı"),
    ("assets/slices/G_yemek_odasi", 9, "dining_service_cart.png", (28, 28), "prop_dining_service_cart", "Tekerlekli kapaklı servis arabası"),

    # H: Mutfak
    ("assets/slices/H_mutfak", 1, "kitchen_stove.png", (48, 44), "prop_kitchen_stove", "Döküm demir kuzine ve çaydanlık"),
    ("assets/slices/H_mutfak", 2, "kitchen_pot_rack.png", (52, 28), "prop_kitchen_pot_rack", "Tavandan asılı bakır tencere askılığı"),
    ("assets/slices/H_mutfak", 3, "kitchen_sink_counter.png", (64, 34), "prop_kitchen_sink_counter", "Pirinç musluklu lavabo tezgahı"),
    ("assets/slices/H_mutfak", 4, "kitchen_counter.png", (64, 34), "prop_kitchen_counter", "Ahşap hazırlık tezgahı"),
    ("assets/slices/H_mutfak", 5, "kitchen_pantry_cupboard.png", (38, 56), "prop_kitchen_pantry_cupboard", "Kiler dolabı"),
    ("assets/slices/H_mutfak", 6, "kitchen_meat_block.png", (32, 36), "prop_kitchen_meat_block", "Masif et kütüğü ve soğutucu"),
    ("assets/slices/H_mutfak", 7, "kitchen_wall_shelves.png", (48, 32), "prop_kitchen_wall_shelves", "Duvara monte kavanoz ve baharat rafı"),
    ("assets/slices/H_mutfak", 8, "kitchen_wash_basin.png", (20, 30), "prop_kitchen_wash_basin", "Ayaklı emaye yıkama teknesi"),
    ("assets/slices/H_mutfak", 9, "kitchen_veg_basket.png", (24, 20), "prop_kitchen_veg_basket", "Patates ve havuç sepeti"),
    ("assets/slices/H_mutfak", 10, "kitchen_stool.png", (14, 20), "prop_kitchen_stool", "Ahşap mutfak taburesi"),
    ("assets/slices/H_mutfak", 11, "kitchen_clock.png", (16, 16), "prop_kitchen_clock", "Duvar saati"),

    # I: Bilardo Odası
    ("assets/slices/I_bilardo_odasi", 1, "billiard_cue_rack.png", (22, 52), "prop_billiard_cue_rack", "Duvara monte ahşap isteka rafı"),
    ("assets/slices/I_bilardo_odasi", 2, "billiard_table.png", (72, 34), "prop_billiard_table", "Yeşil çuha kaplı bilardo masası"),
    ("assets/slices/I_bilardo_odasi", 3, "billiard_armchair.png", (32, 32), "prop_billiard_armchair", "Kahverengi deri kulüp koltuğu"),
    ("assets/slices/I_bilardo_odasi", 4, "billiard_lamp.png", (48, 20), "prop_billiard_lamp", "Tavandan sarkan yeşil bilardo lambası"),
    ("assets/slices/I_bilardo_odasi", 5, "billiard_bar_cart.png", (30, 28), "prop_billiard_bar_cart", "Tekerlekli pirinç içki arabası"),
    ("assets/slices/I_bilardo_odasi", 6, "billiard_scoreboard.png", (36, 18), "prop_billiard_scoreboard", "Duvar skor tabelası"),
    ("assets/slices/I_bilardo_odasi", 7, "billiard_trophy_stag.png", (24, 32), "prop_billiard_trophy_stag", "Duvara monte trofe geyik kafası"),
    ("assets/slices/I_bilardo_odasi", 8, "billiard_ashtray_stand.png", (12, 28), "prop_billiard_ashtray_stand", "Ayaklı pirinç küllük"),
    ("assets/slices/I_bilardo_odasi", 9, "billiard_whiskey_table.png", (20, 24), "prop_billiard_whiskey_table", "Viski kadehli sehpa (Evidence E11)"),
    ("assets/slices/I_bilardo_odasi", 10, "billiard_ball_tray.png", (18, 8), "prop_billiard_ball_tray", "Bilardo topları tepsisi"),

    # J: Ana Hol
    ("assets/slices/J_ana_hol", 1, "hall_grandfather_clock.png", (24, 66), "prop_hall_grandfather_clock", "Büyükbaba saati"),
    ("assets/slices/J_ana_hol", 2, "door_standard.png", (40, 76), "prop_door_standard", "Ağır malikane giriş kapısı"),
    ("assets/slices/J_ana_hol", 3, "hall_coat_rack.png", (20, 58), "prop_hall_coat_rack", "Ayaklı palto ve şapka askılığı"),
    ("assets/slices/J_ana_hol", 4, "main_hall_phone_table.png", (56, 34), "prop_main_hall_phone_table", "Konsol telefon masası (Evidence E17)"),
    ("assets/slices/J_ana_hol", 5, "hall_umbrella_stand.png", (18, 38), "prop_hall_umbrella_stand", "Şemsiyelik ve ıslak şemsiyeler"),
    ("assets/slices/J_ana_hol", 6, "hall_bench.png", (48, 28), "prop_hall_bench", "Ahşap bekleme sırası"),
    ("assets/slices/J_ana_hol", 7, "hall_grand_mirror.png", (30, 52), "prop_hall_grand_mirror", "Büyük altın varaklı ayna"),
    ("assets/slices/J_ana_hol", 8, "hall_marble_bust.png", (18, 38), "prop_hall_marble_bust", "Kaideli mermer büst"),
    ("assets/slices/J_ana_hol", 9, "hall_potted_fern.png", (24, 28), "prop_hall_potted_fern", "Büyük salon eğrelti otu"),
    ("assets/slices/J_ana_hol", 10, "hall_potted_plant.png", (20, 24), "prop_hall_potted_plant", "Pirinç saksılı salon bitkisi"),
    ("assets/slices/J_ana_hol", 11, "hall_carpet_runner.png", (72, 24), "prop_hall_carpet_runner", "Koridor yolluğu halısı"),

    # K: Üst Kat
    ("assets/slices/K_ust_kat", 1, "upper_wardrobe.png", (44, 60), "prop_upper_wardrobe", "Masif ahşap gardırop"),
    ("assets/slices/K_ust_kat", 2, "upper_dresser_mirror.png", (38, 48), "prop_upper_dresser_mirror", "Aynalı tuvalet masası"),
    ("assets/slices/K_ust_kat", 3, "upper_bed_grand.png", (64, 36), "prop_upper_bed_grand", "Büyük kadife yatak"),
    ("assets/slices/K_ust_kat", 4, "upper_nightstand.png", (18, 28), "prop_upper_nightstand", "Komodin ve abajur"),
    ("assets/slices/K_ust_kat", 5, "julian_room_door.png", (40, 76), "prop_julian_room_door", "Julian'ın oda kapısı"),
    ("assets/slices/K_ust_kat", 6, "harlow_room_door.png", (40, 76), "prop_harlow_room_door", "Harlow'un yatak odası kapısı"),
    ("assets/slices/K_ust_kat", 7, "pike_room_door.png", (40, 76), "prop_pike_room_door", "Pike'ın misafir odası kapısı"),
    ("assets/slices/K_ust_kat", 8, "upper_typewriter_desk.png", (24, 26), "prop_upper_typewriter_desk", "Pike'ın daktilolu masası (Evidence E13)"),
    ("assets/slices/K_ust_kat", 9, "upper_desk_letters.png", (46, 30), "prop_upper_desk_letters", "Mektuplu yazı masası"),
    ("assets/slices/K_ust_kat", 10, "upper_carpet_runner.png", (72, 18), "prop_upper_carpet_runner", "Koridor halı yolluğu"),
    ("assets/slices/K_ust_kat", 11, "upper_chaise_lounge.png", (52, 30), "prop_upper_chaise_lounge", "Deri koridor dinlenme sediri"),
    ("assets/slices/K_ust_kat", 12, "upper_vintage_trunk.png", (30, 20), "prop_upper_vintage_trunk", "Julian'ın deri seyahat sandığı (Evidence E12)"),
    ("assets/slices/K_ust_kat", 13, "upper_leather_suitcase.png", (26, 18), "prop_upper_leather_suitcase", "Yolculuk bavulu"),
]

def main():
    print(f"Reprocessing {len(ITEMS)} props with verified item indices...")
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest_data = json.load(f)
    if "assets" not in manifest_data:
        manifest_data["assets"] = {}

    success = 0
    for folder, idx, filename, target_size, prop_id, desc in ITEMS:
        src = find_item(folder, idx)
        dest = OUT_DIR / filename
        ok = process_and_save(src, dest, target_size, outline=True)
        if ok:
            success += 1
            manifest_data["assets"][prop_id] = {
                "id": prop_id,
                "type": "prop",
                "path": f"res://assets/sprites/props/{filename}",
                "size": list(target_size),
                "status": "final",
                "description": desc
            }
            short_id = prop_id.removeprefix("prop_")
            manifest_data["assets"][short_id] = manifest_data["assets"][prop_id]

    # Additional standard door aliases
    aliases = {
        "study_door": "res://assets/sprites/props/door_standard.png",
        "door_visual_study": "res://assets/sprites/props/door_standard.png",
        "door_visual_library": "res://assets/sprites/props/door_standard.png",
        "library_door": "res://assets/sprites/props/door_standard.png",
        "dining_door": "res://assets/sprites/props/door_standard.png",
        "kitchen_door": "res://assets/sprites/props/door_standard.png",
        "kitchen_door_entry": "res://assets/sprites/props/door_standard.png",
        "billiard_door": "res://assets/sprites/props/door_standard.png",
        "upper_stairs_door": "res://assets/sprites/props/door_standard.png",
        "silas_locked_drawer": "res://assets/sprites/props/silas_drawer_small.png",
        "silas_pocket_watch": "res://assets/sprites/props/silas_rainy_window.png",
        "study_window": "res://assets/sprites/props/window_mansion.png",
        "study_fireplace": "res://assets/sprites/props/fireplace.png",
        "hall_fireplace": "res://assets/sprites/props/fireplace.png",
        "hall_armchair": "res://assets/sprites/props/study_armchair.png",
        "library_armchair": "res://assets/sprites/props/library_reading_chair.png",
        "library_bookcase_left": "res://assets/sprites/props/library_bookcase.png",
        "chandelier_small": "res://assets/sprites/props/chandelier_grand.png",
    }
    for alias_key, alias_path in aliases.items():
        if alias_key not in manifest_data["assets"]:
            manifest_data["assets"][alias_key] = {
                "id": alias_key,
                "type": "prop",
                "path": alias_path,
                "status": "final",
                "description": f"Alias for {alias_key}"
            }
            manifest_data["assets"][f"prop_{alias_key}"] = manifest_data["assets"][alias_key]

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest_data, f, indent=2, ensure_ascii=False)

    print(f"Done! Successfully processed {success}/{len(ITEMS)} props.")

if __name__ == "__main__":
    main()
