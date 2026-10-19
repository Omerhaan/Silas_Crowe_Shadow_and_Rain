#!/usr/bin/env python3
"""
Comprehensive batch integration of ALL props from sheets C1, C2, C3, D, E, F, G, H, I, J, K
into assets/sprites/props/, quantized to noir24 palette and registered in asset_manifest.json.
"""

import os
import json
from pathlib import Path
from PIL import Image
import numpy as np
from pixelize import load_palette, quantize_to_palette, add_outline, crop_and_fit

PALETTE_PATH = "data/palette/noir24.hex"
MANIFEST_PATH = "assets/asset_manifest.json"

palette = load_palette(PALETTE_PATH)

def find_item(folder: str, item_num: int) -> str | None:
    if not os.path.exists(folder):
        return None
    prefix = f"item_{item_num:02d}_"
    for f in os.listdir(folder):
        if f.startswith(prefix) and f.endswith(".png"):
            return os.path.join(folder, f)
    return None

def process_and_save(
    src_path: str | None,
    dest_path: str,
    target_size: tuple[int, int],
    outline: bool = True,
    dither: bool = False,
    flip_h: bool = False
) -> bool:
    if not src_path or not os.path.exists(src_path):
        print(f"Warning: Source not found for {dest_path}: {src_path}")
        return False

    im = Image.open(src_path).convert("RGBA")
    if flip_h:
        im = im.transpose(Image.Transpose.FLIP_LEFT_RIGHT)

    fitted = crop_and_fit(im, target_size[0], target_size[1])

    # Hard alpha threshold
    arr = np.array(fitted)
    arr[:, :, 3] = np.where(arr[:, :, 3] >= 110, 255, 0)
    fitted = Image.fromarray(arr, mode="RGBA")

    if outline:
        fitted = add_outline(fitted, (11, 15, 26))

    out_img = quantize_to_palette(fitted, palette, dither=dither)

    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
    out_img.save(dest_path, "PNG")

    # 4x preview
    preview = out_img.resize((target_size[0] * 4, target_size[1] * 4), Image.Resampling.NEAREST)
    stem = Path(dest_path).stem
    prev_dir = Path(dest_path).parent
    preview.save(str(prev_dir / f"{stem}_preview.png"), "PNG")
    print(f"Saved: {dest_path} ({target_size[0]}x{target_size[1]})")
    return True

# Item definitions: (folder, item_index, dest_filename, (width, height), prop_id, description)
ALL_ITEMS = [
    # C1: Pencereler ve Kapılar
    ("assets/slices/C1_pencereler_ve_kapilar", 1, "door_standard.png", (40, 76), "prop_door_standard", "Standart ahşap panel kapı"),
    ("assets/slices/C1_pencereler_ve_kapilar", 2, "window_mansion.png", (48, 56), "prop_window_mansion", "Büyük malikane penceresi"),
    ("assets/slices/C1_pencereler_ve_kapilar", 3, "window_single.png", (28, 56), "prop_window_single", "Tek kanatlı dar pencere"),
    ("assets/slices/C1_pencereler_ve_kapilar", 4, "window_small.png", (24, 40), "prop_window_small", "Küçük servis penceresi"),

    # C2: Merdiven, Şömine, Çerçeveler
    ("assets/slices/C2_merdiven_somine_cerceveler", 1, "stairs_mansion.png", (72, 76), "prop_stairs_mansion", "Büyük ahşap merdiven"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 2, "fireplace.png", (56, 44), "prop_fireplace", "Klasik taş şömine"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 3, "fireplace_marble.png", (56, 44), "prop_fireplace_marble", "Mermer şömine"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 6, "wall_clock_pendulum.png", (14, 28), "prop_wall_clock_pendulum", "Sarkaçlı duvar saati"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 7, "portrait_frame_oval.png", (18, 24), "prop_portrait_frame_oval", "Oval portre çerçevesi"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 8, "portrait_frame_rect.png", (18, 22), "prop_portrait_frame_rect", "Dikdörtgen tablo çerçevesi"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 9, "wall_sconce.png", (10, 14), "prop_wall_sconce", "Pirinç duvar apliği"),
    ("assets/slices/C2_merdiven_somine_cerceveler", 10, "landscape_painting.png", (28, 20), "prop_landscape_painting", "Geniş manzara tablosu"),

    # C3: Tavan Süslemeleri
    ("assets/slices/C3_tavan_suslemeler", 1, "ceiling_lamp_pendant.png", (16, 28), "prop_ceiling_lamp_pendant", "Zincirli tekli tavan lambası"),
    ("assets/slices/C3_tavan_suslemeler", 2, "chandelier_small.png", (28, 28), "prop_chandelier_small", "Oda avizesi"),
    ("assets/slices/C3_tavan_suslemeler", 3, "chandelier_grand.png", (36, 36), "prop_chandelier_grand", "Büyük kristal avize"),

    # D: Hub (Silas'ın Evi / Ofisi)
    ("assets/slices/D_silasin_evi", 1, "silas_filing_cabinet.png", (24, 34), "prop_silas_filing_cabinet", "Silas'ın metal evrak dolabı"),
    ("assets/slices/D_silasin_evi", 2, "silas_coat_rack.png", (18, 54), "prop_silas_coat_rack", "Silas'ın ayaklı palto askılığı"),
    ("assets/slices/D_silasin_evi", 3, "silas_telephone.png", (24, 18), "prop_silas_telephone", "Siyah çevirmeli telefon"),
    ("assets/slices/D_silasin_evi", 4, "silas_drawer_small.png", (18, 14), "prop_silas_drawer_small", "Masa üstü küçük çekmece"),
    ("assets/slices/D_silasin_evi", 5, "silas_desk.png", (64, 34), "prop_silas_desk", "Silas'ın çalışma masası"),
    ("assets/slices/D_silasin_evi", 6, "silas_bookcase_tall.png", (26, 60), "prop_silas_bookcase_tall", "Ofis kitaplığı"),
    ("assets/slices/D_silasin_evi", 8, "silas_memory_wall.png", (48, 32), "prop_silas_memory_wall", "İğneli anı ve ipucu panosu"),
    ("assets/slices/D_silasin_evi", 9, "silas_lamp.png", (12, 28), "prop_silas_lamp", "Yeşil banker lamba"),
    ("assets/slices/D_silasin_evi", 10, "silas_typewriter.png", (20, 16), "prop_silas_typewriter", "Eski yazı daktilosu"),
    ("assets/slices/D_silasin_evi", 11, "silas_armchair.png", (64, 34), "prop_silas_armchair", "Yıpranmış kahverengi deri koltuk"),
    ("assets/slices/D_silasin_evi", 13, "silas_pocket_watch.png", (8, 8), "prop_silas_pocket_watch", "03:12'de durmuş cep saati"),
    ("assets/slices/D_silasin_evi", 14, "silas_souvenir_shelf.png", (36, 18), "prop_silas_souvenir_shelf", "Hatıra ve madalya rafı"),
    ("assets/slices/D_silasin_evi", 15, "silas_rejection_letter.png", (10, 8), "prop_silas_rejection_letter", "Savaş Bakanlığı ret mektubu"),

    # E: Çalışma Odası
    ("assets/slices/E_calisma_odasi", 1, "study_desk.png", (64, 34), "prop_study_desk", "Harlow'un maun çalışma masası"),
    ("assets/slices/E_calisma_odasi", 2, "study_safe.png", (24, 32), "prop_study_safe", "Kilitli gizli duvar kasası"),
    ("assets/slices/E_calisma_odasi", 3, "study_portrait_harlow.png", (28, 28), "prop_study_portrait_harlow", "Edmund Harlow yağlıboya portresi"),
    ("assets/slices/E_calisma_odasi", 7, "study_armchair.png", (64, 34), "prop_study_armchair", "Harlow'un deri koltuğu"),
    ("assets/slices/E_calisma_odasi", 8, "study_waste_basket.png", (14, 16), "prop_study_waste_basket", "Yırtık kâğıtlı çöp sepeti"),
    ("assets/slices/E_calisma_odasi", 9, "study_lamp.png", (12, 28), "prop_study_lamp", "Masa lambası"),
    ("assets/slices/E_calisma_odasi", 10, "study_cognac_bottle.png", (12, 14), "prop_study_cognac_bottle", "Konyak şişesi ve kadeh"),
    ("assets/slices/E_calisma_odasi", 12, "study_bookcase.png", (56, 90), "prop_study_bookcase", "Masif ceviz kitaplık"),
    ("assets/slices/E_calisma_odasi", 13, "study_cabinet.png", (48, 34), "prop_study_cabinet", "Arka konsol evrak dolabı"),

    # F: Kütüphane
    ("assets/slices/F_kutuphane", 1, "library_bookcase.png", (56, 90), "prop_library_bookcase", "Devasa ceviz kütüphane kitaplığı"),
    ("assets/slices/F_kutuphane", 2, "library_ladder.png", (18, 54), "prop_library_ladder", "Raylı pirinç tekerlekli kitaplık merdiveni"),
    ("assets/slices/F_kutuphane", 3, "library_bookcase_2.png", (56, 90), "prop_library_bookcase_2", "İkinci kütüphane kitaplığı"),
    ("assets/slices/F_kutuphane", 5, "library_globe.png", (20, 26), "prop_library_globe", "Ayaklı pirinç dünya küresi"),
    ("assets/slices/F_kutuphane", 6, "library_books_stack.png", (14, 12), "prop_library_books_stack", "Açık araştırma kitapları yığını"),
    ("assets/slices/F_kutuphane", 8, "library_reading_chair.png", (26, 34), "prop_library_reading_chair", "Deri kütüphane okuma koltuğu"),
    ("assets/slices/F_kutuphane", 10, "library_reading_desk.png", (56, 34), "prop_library_reading_desk", "Geniş okuma masası"),
    ("assets/slices/F_kutuphane", 11, "library_bust_pedestal.png", (18, 38), "prop_library_bust_pedestal", "Mermer büst kaidesi"),

    # G: Yemek Odası
    ("assets/slices/G_yemek_odasi", 1, "dining_table.png", (72, 34), "prop_dining_table", "Beyaz keten örtülü ziyafet masası"),
    ("assets/slices/G_yemek_odasi", 2, "dining_chair_left.png", (18, 36), "prop_dining_chair_left", "Deri yemek sandalyesi (sol)"),
    ("assets/slices/G_yemek_odasi", 3, "dining_chair_right.png", (18, 36), "prop_dining_chair_right", "Deri yemek sandalyesi (sağ)"),
    ("assets/slices/G_yemek_odasi", 4, "dining_candelabra.png", (16, 22), "prop_dining_candelabra", "Gümüş çok kollu şamdan"),
    ("assets/slices/G_yemek_odasi", 6, "dining_china_cabinet.png", (44, 68), "prop_dining_china_cabinet", "Camlı porselen ve gümüş dolabı"),
    ("assets/slices/G_yemek_odasi", 7, "dining_sideboard.png", (56, 36), "prop_dining_sideboard", "Büyük yemek büfesi"),
    ("assets/slices/G_yemek_odasi", 8, "dining_service_cart.png", (26, 26), "prop_dining_service_cart", "Tekerlekli gümüş servis arabası"),

    # H: Mutfak
    ("assets/slices/H_mutfak", 1, "kitchen_stove.png", (48, 44), "prop_kitchen_stove", "Döküm demir kuzine soba"),
    ("assets/slices/H_mutfak", 2, "kitchen_sink_counter.png", (52, 34), "prop_kitchen_sink_counter", "Pirinç armatürlü lavabo tezgahı"),
    ("assets/slices/H_mutfak", 3, "kitchen_counter.png", (64, 34), "prop_kitchen_counter", "Ahşap hazırlık tezgahı"),
    ("assets/slices/H_mutfak", 4, "kitchen_wall_shelves.png", (42, 22), "prop_kitchen_wall_shelves", "Duvara monte tencere rafı"),
    ("assets/slices/H_mutfak", 5, "kitchen_pantry_cupboard.png", (38, 56), "prop_kitchen_pantry_cupboard", "Kiler erzak dolabı"),
    ("assets/slices/H_mutfak", 6, "kitchen_meat_block.png", (24, 34), "prop_kitchen_meat_block", "Masif et kütüğü"),
    ("assets/slices/H_mutfak", 13, "kitchen_pot_rack.png", (56, 14), "prop_kitchen_pot_rack", "Tavandan asılı bakır tava askısı"),

    # I: Bilardo Odası
    ("assets/slices/I_bilardo_odasi", 1, "billiard_cue_rack.png", (22, 52), "prop_billiard_cue_rack", "Duvara monte ahşap isteka rafı"),
    ("assets/slices/I_bilardo_odasi", 2, "billiard_table.png", (72, 34), "prop_billiard_table", "Yeşil çuha kaplı bilardo masası"),
    ("assets/slices/I_bilardo_odasi", 3, "billiard_bar_cart.png", (30, 28), "prop_billiard_bar_cart", "Tekerlekli pirinç içki arabası"),
    ("assets/slices/I_bilardo_odasi", 4, "billiard_trophy_stag.png", (32, 28), "prop_billiard_trophy_stag", "Duvara monte trofe geyik kafası"),
    ("assets/slices/I_bilardo_odasi", 5, "billiard_armchair.png", (32, 32), "prop_billiard_armchair", "Alçak deri kulüp koltuğu"),
    ("assets/slices/I_bilardo_odasi", 6, "billiard_lamp.png", (48, 20), "prop_billiard_lamp", "Tavandan sarkan yeşil bilardo lambası"),

    # J: Ana Hol
    ("assets/slices/J_ana_hol", 1, "hall_coat_rack.png", (20, 58), "prop_hall_coat_rack", "Uzun ayaklı palto ve şapka askılığı"),
    ("assets/slices/J_ana_hol", 2, "hall_grandfather_clock.png", (24, 66), "prop_hall_grandfather_clock", "Büyükbaba saati (sarkaçlı)"),
    ("assets/slices/J_ana_hol", 3, "hall_umbrella_stand.png", (18, 38), "prop_hall_umbrella_stand", "Şemsiyelik ve ıslak şemsiyeler"),
    ("assets/slices/J_ana_hol", 4, "main_hall_phone_table.png", (56, 34), "prop_main_hall_phone_table", "Konsol telefon masası"),
    ("assets/slices/J_ana_hol", 5, "hall_marble_bust.png", (18, 38), "prop_hall_marble_bust", "Kaideli mermer büst"),
    ("assets/slices/J_ana_hol", 6, "hall_bench.png", (48, 28), "prop_hall_bench", "Ahşap bekleme sırası"),
    ("assets/slices/J_ana_hol", 7, "hall_grand_mirror.png", (30, 52), "prop_hall_grand_mirror", "Büyük altın varaklı ayna"),
    ("assets/slices/J_ana_hol", 9, "hall_potted_fern.png", (22, 28), "prop_hall_potted_fern", "Pirinç saksıda salon eğrelti otu"),

    # K: Üst Kat
    ("assets/slices/K_ust_kat", 1, "upper_wardrobe.png", (44, 60), "prop_upper_wardrobe", "Masif ahşap gardırop"),
    ("assets/slices/K_ust_kat", 2, "upper_dresser_mirror.png", (38, 48), "prop_upper_dresser_mirror", "Aynalı tuvalet masası"),
    ("assets/slices/K_ust_kat", 3, "upper_bed_grand.png", (64, 36), "prop_upper_bed_grand", "Büyük kadife yatak"),
    ("assets/slices/K_ust_kat", 4, "upper_nightstand.png", (18, 28), "prop_upper_nightstand", "Komodin ve abajur"),
    ("assets/slices/K_ust_kat", 8, "upper_window_seat.png", (34, 24), "prop_upper_window_seat", "Minderli pencere önü sediri"),
    ("assets/slices/K_ust_kat", 9, "upper_desk_letters.png", (46, 30), "prop_upper_desk_letters", "Mektuplu yazı masası"),
    ("assets/slices/K_ust_kat", 11, "upper_chaise_lounge.png", (52, 30), "prop_upper_chaise_lounge", "Deri uzanma koltuğu"),
    ("assets/slices/K_ust_kat", 12, "upper_vintage_trunk.png", (30, 20), "prop_upper_vintage_trunk", "Deri köşeli eski sandık"),
    ("assets/slices/K_ust_kat", 13, "upper_leather_suitcase.png", (26, 18), "prop_upper_leather_suitcase", "Yolculuk bavulu"),
]

def main():
    print(f"Starting batch integration of {len(ALL_ITEMS)} props from sheets C1..K...")
    
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest_data = json.load(f)
    if "assets" not in manifest_data:
        manifest_data["assets"] = {}

    success_count = 0
    for folder, idx, filename, target_size, prop_id, desc in ALL_ITEMS:
        src = find_item(folder, idx)
        dest = f"assets/sprites/props/{filename}"
        res = process_and_save(src, dest, target_size, outline=True)
        if res:
            success_count += 1
            manifest_data["assets"][prop_id] = {
                "id": prop_id,
                "type": "prop",
                "path": f"res://assets/sprites/props/{filename}",
                "size": list(target_size),
                "status": "final",
                "description": desc
            }
            # Also register without 'prop_' prefix so both lookups work seamlessly
            short_id = prop_id.removeprefix("prop_")
            manifest_data["assets"][short_id] = manifest_data["assets"][prop_id]

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest_data, f, indent=2, ensure_ascii=False)

    print(f"\nSuccessfully processed {success_count}/{len(ALL_ITEMS)} items and updated {MANIFEST_PATH}!")

if __name__ == "__main__":
    main()
