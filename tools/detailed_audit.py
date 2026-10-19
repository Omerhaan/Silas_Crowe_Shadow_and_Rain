#!/usr/bin/env python3
import os
import re
import json

with open("assets/asset_manifest.json", "r", encoding="utf-8") as f:
    manifest = json.load(f).get("assets", {})

rooms = [
    "scenes/hub/silas_office.tscn",
    "scenes/rooms/study.tscn",
    "scenes/rooms/main_hall.tscn",
    "scenes/rooms/library.tscn",
    "scenes/rooms/dining_room.tscn",
    "scenes/rooms/kitchen.tscn",
    "scenes/rooms/billiard_room.tscn",
    "scenes/rooms/upper_floor.tscn",
]

for sc in rooms:
    print(f"\n=======================================================\n{sc}\n=======================================================")
    with open(sc, "r", encoding="utf-8") as f:
        text = f.read()
    
    # Split by [node
    chunks = text.split("[node ")
    for ch in chunks[1:]:
        header_line = ch.split("\n")[0]
        name_m = re.search(r'name="([^"]+)"', header_line)
        name = name_m.group(1) if name_m else "unknown"
        
        # We only care about interactables and doors
        if "ExtResource" not in header_line:
            continue
            
        oid_m = re.search(r'object_id = "([^"]+)"', ch)
        disp_m = re.search(r'display_name = "([^"]+)"', ch)
        ev_m = re.search(r'evidence_id = "([^"]+)"', ch)
        pt_m = re.search(r'prop_type = "([^"]+)"', ch)
        pos_m = re.search(r'position = Vector2\(([^)]+)\)', ch)
        
        oid = oid_m.group(1) if oid_m else "(none)"
        disp = disp_m.group(1) if disp_m else "(none)"
        ev = ev_m.group(1) if ev_m else ""
        pt = pt_m.group(1) if pt_m else ""
        pos = pos_m.group(1) if pos_m else ""
        
        entry = manifest.get(oid) or manifest.get(f"prop_{oid}")
        path = entry.get("path", entry.get("texture", "")) if entry else "NO_MANIFEST"
        exists = os.path.exists(path.replace("res://", "")) if path != "NO_MANIFEST" else False
        
        print(f"Node: {name:<26} | OID: {oid:<25} | Name: {disp:<30} | Ev: {ev:<4} | Path: {path} (exists={exists})")
