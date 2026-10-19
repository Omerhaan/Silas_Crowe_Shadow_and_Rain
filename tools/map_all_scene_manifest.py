#!/usr/bin/env python3
"""
Map all scene-specific object IDs directly to their authentic new_assets sprite files in asset_manifest.json.
"""

import json

MANIFEST_PATH = "assets/asset_manifest.json"

with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
    data = json.load(f)

if "assets" not in data:
    data["assets"] = {}

mappings = {
    # Doors (C1 item 1)
    "door_visual_study": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "door_visual_library": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "study_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "library_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "dining_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "kitchen_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "kitchen_door_entry": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "billiard_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "harlow_room_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "julian_room_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "pike_room_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),
    "upper_stairs_door": ("res://assets/sprites/props/door_standard.png", [40, 76]),

    # Windows (C1 item 2)
    "hall_window": ("res://assets/sprites/props/window_mansion.png", [48, 56]),
    "silas_rainy_window": ("res://assets/sprites/props/window_mansion.png", [48, 56]),
    "study_window": ("res://assets/sprites/props/window_mansion.png", [48, 56]),

    # Fireplaces (C2 items 2, 3)
    "study_fireplace": ("res://assets/sprites/props/fireplace.png", [56, 44]),
    "hall_fireplace": ("res://assets/sprites/props/fireplace.png", [56, 44]),
    "library_cold_fireplace": ("res://assets/sprites/props/fireplace_marble.png", [56, 44]),

    # Bookcases (E item 12, F item 1)
    "library_bookcase_left": ("res://assets/sprites/props/library_bookcase.png", [56, 90]),

    # Armchairs (D item 11, E item 7, I item 5)
    "hall_armchair": ("res://assets/sprites/props/study_armchair.png", [64, 34]),
    "library_armchair": ("res://assets/sprites/props/library_reading_chair.png", [26, 34]),
    
    # Silas items
    "silas_telephone": ("res://assets/sprites/props/silas_telephone.png", [24, 18]),
    "silas_pocket_watch": ("res://assets/sprites/props/silas_pocket_watch.png", [8, 8]),
    "silas_rejection_letter": ("res://assets/sprites/props/silas_rejection_letter.png", [10, 8]),
    "silas_typewriter": ("res://assets/sprites/props/silas_typewriter.png", [20, 16]),
    "silas_lamp": ("res://assets/sprites/props/silas_lamp.png", [12, 28]),
}

for k, (path, size) in mappings.items():
    data["assets"][k] = {
        "id": k,
        "type": "prop",
        "path": path,
        "size": size,
        "status": "final",
        "description": f"Real asset from new_assets for {k}"
    }
    prop_k = f"prop_{k}"
    data["assets"][prop_k] = data["assets"][k]

with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"Updated {MANIFEST_PATH} with {len(mappings)} scene-specific object mappings.")
