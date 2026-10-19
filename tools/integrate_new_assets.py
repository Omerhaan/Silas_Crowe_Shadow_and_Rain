#!/usr/bin/env python3
"""
Integrate all sliced assets from 'new_assets' into the game using robust index finding.
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
) -> None:
    if not src_path or not os.path.exists(src_path):
        print(f"Warning: Source not found for {dest_path}: {src_path}")
        return

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

def main():
    print("Integrating assets from new_assets...")

    # 1. Silas Sprites
    a1 = "assets/slices/A1_silas_pozlar"
    process_and_save(find_item(a1, 1), "assets/sprites/characters/silas_idle_right.png", (32, 48))
    process_and_save(find_item(a1, 1), "assets/sprites/characters/silas_idle_left.png", (32, 48), flip_h=True)
    process_and_save(find_item(a1, 2), "assets/sprites/characters/silas_idle_down.png", (32, 48))
    process_and_save(find_item(a1, 2), "assets/sprites/characters/silas_idle_up.png", (32, 48))

    process_and_save(find_item(a1, 3), "assets/sprites/characters/silas_walk_right_1.png", (32, 48))
    process_and_save(find_item(a1, 4), "assets/sprites/characters/silas_walk_right_2.png", (32, 48))
    process_and_save(find_item(a1, 3), "assets/sprites/characters/silas_walk_left_1.png", (32, 48), flip_h=True)
    process_and_save(find_item(a1, 4), "assets/sprites/characters/silas_walk_left_2.png", (32, 48), flip_h=True)

    process_and_save(find_item(a1, 5), "assets/sprites/characters/silas_walk_down_1.png", (32, 48))
    process_and_save(find_item(a1, 6), "assets/sprites/characters/silas_walk_down_2.png", (32, 48))
    process_and_save(find_item(a1, 7), "assets/sprites/characters/silas_walk_down_3.png", (32, 48))
    process_and_save(find_item(a1, 8), "assets/sprites/characters/silas_walk_down_4.png", (32, 48))
    process_and_save(find_item(a1, 5), "assets/sprites/characters/silas_walk_up_1.png", (32, 48))
    process_and_save(find_item(a1, 6), "assets/sprites/characters/silas_walk_up_2.png", (32, 48))

    process_and_save(find_item(a1, 11), "assets/sprites/characters/silas_notebook.png", (32, 48))
    process_and_save(find_item(a1, 12), "assets/sprites/characters/silas_phone.png", (32, 48))
    process_and_save(find_item(a1, 13), "assets/sprites/characters/silas_shudder.png", (32, 48))
    process_and_save(find_item(a1, 9), "assets/sprites/characters/silas_inspect.png", (32, 48))

    # 2. Silas Portraits
    a2 = "assets/slices/A2_silas_portreler"
    for i, name in enumerate(["silas.png", "silas_neutral.png", "silas_thoughtful.png", "silas_shocked.png", "silas_angry.png", "silas_sad.png", "silas_suspicious.png", "silas_relieved.png"]):
        process_and_save(find_item(a2, i + 1), f"assets/portraits/{name}", (48, 48))

    # 3. Suspect NPCs
    b1 = "assets/slices/B1_Margaret_Doyle"
    process_and_save(find_item(b1, 11), "assets/sprites/characters/margaret_idle_right.png", (32, 48))
    process_and_save(find_item(b1, 11), "assets/sprites/characters/margaret_idle_left.png", (32, 48), flip_h=True)
    process_and_save(find_item(b1, 11), "assets/sprites/characters/margaret_idle_down.png", (32, 48))
    # portrait
    m_p = find_item(b1, 40) or find_item(b1, 11)
    process_and_save(m_p, "assets/portraits/margaret.png", (48, 48))

    b2 = "assets/slices/B2_Julian_Harlow"
    process_and_save(find_item(b2, 1), "assets/sprites/characters/julian_idle_right.png", (32, 48))
    process_and_save(find_item(b2, 1), "assets/sprites/characters/julian_idle_left.png", (32, 48), flip_h=True)
    process_and_save(find_item(b2, 1), "assets/sprites/characters/julian_idle_down.png", (32, 48))
    j_p = find_item(b2, 7) or find_item(b2, 1)
    process_and_save(j_p, "assets/portraits/julian.png", (48, 48))

    b3 = "assets/slices/B3_Raymond_Pike"
    process_and_save(find_item(b3, 1), "assets/sprites/characters/pike_idle_right.png", (32, 48))
    process_and_save(find_item(b3, 1), "assets/sprites/characters/pike_idle_left.png", (32, 48), flip_h=True)
    process_and_save(find_item(b3, 1), "assets/sprites/characters/pike_idle_down.png", (32, 48))
    pi_p = find_item(b3, 7) or find_item(b3, 1)
    process_and_save(pi_p, "assets/portraits/pike.png", (48, 48))

    b4 = "assets/slices/B4_Dr_Victor_Hale"
    process_and_save(find_item(b4, 1), "assets/sprites/characters/hale_idle_right.png", (32, 48))
    process_and_save(find_item(b4, 1), "assets/sprites/characters/hale_idle_left.png", (32, 48), flip_h=True)
    process_and_save(find_item(b4, 1), "assets/sprites/characters/hale_idle_down.png", (32, 48))
    h_p = find_item(b4, 7) or find_item(b4, 1)
    process_and_save(h_p, "assets/portraits/hale.png", (48, 48))

    # B5 Edmund Harlow (Corpse)
    b5 = "assets/slices/B5_Edmund_Harlow"
    process_and_save(find_item(b5, 1), "assets/sprites/props/harlow_corpse.png", (48, 34))

    # 4. Doors & Windows (C1, C2)
    c1 = "assets/slices/C1_pencereler_ve_kapilar"
    process_and_save(find_item(c1, 1), "assets/sprites/props/door_standard.png", (40, 76))
    process_and_save(find_item(c1, 2), "assets/sprites/props/window_mansion.png", (48, 56))

    c2 = "assets/slices/C2_merdiven_somine_cerceveler"
    process_and_save(find_item(c2, 2), "assets/sprites/props/fireplace.png", (56, 44))
    process_and_save(find_item(c2, 5), "assets/sprites/props/wall_clock.png", (8, 8))

    # 5. Room Props
    # D: Hub
    d = "assets/slices/D_silasin_evi"
    process_and_save(find_item(d, 5), "assets/sprites/props/silas_desk.png", (64, 34))
    process_and_save(find_item(d, 3), "assets/sprites/props/silas_telephone.png", (24, 18))
    process_and_save(find_item(d, 8), "assets/sprites/props/silas_memory_wall.png", (48, 32))
    process_and_save(find_item(d, 9), "assets/sprites/props/silas_lamp.png", (12, 28))
    process_and_save(find_item(d, 10), "assets/sprites/props/silas_typewriter.png", (20, 16))
    process_and_save(find_item(d, 11), "assets/sprites/props/silas_armchair.png", (64, 34))
    process_and_save(find_item(d, 13), "assets/sprites/props/silas_pocket_watch.png", (8, 8))
    process_and_save(find_item(d, 14), "assets/sprites/props/silas_rejection_letter.png", (10, 8))
    process_and_save(find_item(d, 15), "assets/sprites/props/silas_drawer.png", (18, 12))

    # E: Study
    e = "assets/slices/E_calisma_odasi"
    process_and_save(find_item(e, 1), "assets/sprites/props/study_desk.png", (64, 34))
    process_and_save(find_item(e, 11), "assets/sprites/props/study_armchair.png", (64, 34))
    process_and_save(find_item(e, 13), "assets/sprites/props/study_bookcase.png", (56, 90))
    process_and_save(find_item(e, 8), "assets/sprites/props/study_waste_basket.png", (14, 16))
    process_and_save(find_item(e, 9), "assets/sprites/props/study_lamp.png", (12, 28))

    # F: Library
    f = "assets/slices/F_kutuphane"
    process_and_save(find_item(f, 1), "assets/sprites/props/library_bookcase.png", (56, 90))

    # G: Dining
    g = "assets/slices/G_yemek_odasi"
    process_and_save(find_item(g, 1), "assets/sprites/props/dining_table.png", (64, 34))

    # H: Kitchen
    h = "assets/slices/H_mutfak"
    process_and_save(find_item(h, 1), "assets/sprites/props/kitchen_stove.png", (64, 34))
    process_and_save(find_item(h, 3), "assets/sprites/props/kitchen_counter.png", (64, 34))

    # I: Billiard
    i = "assets/slices/I_bilardo_odasi"
    process_and_save(find_item(i, 2), "assets/sprites/props/billiard_table.png", (64, 34))

    # J: Main Hall
    j = "assets/slices/J_ana_hol"
    process_and_save(find_item(j, 4), "assets/sprites/props/main_hall_phone_table.png", (64, 34))

    update_manifest()
    print("Integration complete!")

def update_manifest():
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)

    prop_updates = {
        "prop_silas_desk": ("res://assets/sprites/props/silas_desk.png", [64, 34]),
        "prop_silas_telephone": ("res://assets/sprites/props/silas_telephone.png", [24, 18]),
        "prop_silas_lamp": ("res://assets/sprites/props/silas_lamp.png", [12, 28]),
        "prop_silas_memory_wall": ("res://assets/sprites/props/silas_memory_wall.png", [48, 32]),
        "prop_silas_typewriter": ("res://assets/sprites/props/silas_typewriter.png", [20, 16]),
        "prop_silas_pocket_watch": ("res://assets/sprites/props/silas_pocket_watch.png", [8, 8]),
        "prop_silas_rejection_letter": ("res://assets/sprites/props/silas_rejection_letter.png", [10, 8]),
        "prop_silas_drawer": ("res://assets/sprites/props/silas_drawer.png", [18, 12]),
        "prop_silas_armchair": ("res://assets/sprites/props/silas_armchair.png", [64, 34]),

        "prop_study_desk": ("res://assets/sprites/props/study_desk.png", [64, 34]),
        "prop_study_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
        "prop_study_armchair": ("res://assets/sprites/props/study_armchair.png", [64, 34]),
        "prop_study_bookcase": ("res://assets/sprites/props/study_bookcase.png", [56, 90]),
        "prop_study_lamp": ("res://assets/sprites/props/study_lamp.png", [12, 28]),
        "prop_study_trash": ("res://assets/sprites/props/study_waste_basket.png", [14, 16]),

        "prop_library_bookcase": ("res://assets/sprites/props/library_bookcase.png", [56, 90]),
        "prop_dining_table": ("res://assets/sprites/props/dining_table.png", [64, 34]),
        "prop_kitchen_stove": ("res://assets/sprites/props/kitchen_stove.png", [64, 34]),
        "prop_kitchen_counter": ("res://assets/sprites/props/kitchen_counter.png", [64, 34]),
        "prop_billiard_table": ("res://assets/sprites/props/billiard_table.png", [64, 34]),
        "prop_fireplace": ("res://assets/sprites/props/fireplace.png", [56, 44]),
        "prop_armchair": ("res://assets/sprites/props/study_armchair.png", [64, 34]),
        "prop_bookcase": ("res://assets/sprites/props/study_bookcase.png", [56, 90]),
        "prop_lamp": ("res://assets/sprites/props/study_lamp.png", [12, 28]),
        "prop_window": ("res://assets/sprites/props/window_mansion.png", [48, 56]),
        "prop_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    }

    if "assets" not in data:
        data["assets"] = {}

    for prop_id, (path, size) in prop_updates.items():
        data["assets"][prop_id] = {
            "id": prop_id,
            "type": "prop",
            "path": path,
            "size": size,
            "status": "final",
            "description": f"Real asset from new_assets for {prop_id}"
        }

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print("Updated asset_manifest.json with new final prop assets.")

if __name__ == "__main__":
    main()
