import os
import re
import json

base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
manifest_path = os.path.join(base_dir, "assets", "asset_manifest.json")

with open(manifest_path, "r", encoding="utf-8") as f:
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

report = {}

for sc in rooms:
    sc_path = os.path.join(base_dir, sc)
    with open(sc_path, "r", encoding="utf-8") as f:
        text = f.read()
    
    room_nodes = []
    chunks = text.split("[node ")
    for ch in chunks[1:]:
        header_line = ch.split("\n")[0]
        name_m = re.search(r'name="([^"]+)"', header_line)
        name = name_m.group(1) if name_m else "unknown"
        
        parent_m = re.search(r'parent="([^"]+)"', header_line)
        parent = parent_m.group(1) if parent_m else "root"

        if "ExtResource" not in header_line:
            continue
            
        oid_m = re.search(r'object_id = "([^"]+)"', ch)
        disp_m = re.search(r'display_name = "([^"]+)"', ch)
        ev_m = re.search(r'evidence_id = "([^"]+)"', ch)
        pt_m = re.search(r'prop_type = "([^"]+)"', ch)
        pos_m = re.search(r'position = Vector2\(([^)]+)\)', ch)
        
        oid = oid_m.group(1) if oid_m else ""
        disp = disp_m.group(1) if disp_m else ""
        ev = ev_m.group(1) if ev_m else ""
        pt = pt_m.group(1) if pt_m else ""
        pos = pos_m.group(1) if pos_m else ""
        
        entry = manifest.get(oid) or manifest.get(f"prop_{oid}")
        path = entry.get("path", entry.get("texture", "")) if entry else ""
        file_exists = False
        if path:
            real_path = os.path.join(base_dir, path.replace("res://", ""))
            file_exists = os.path.exists(real_path)
            
        room_nodes.append({
            "name": name,
            "parent": parent,
            "object_id": oid,
            "display_name": disp,
            "evidence_id": ev,
            "prop_type": pt,
            "position": pos,
            "manifest_path": path,
            "file_exists": file_exists
        })
    report[sc] = room_nodes

report_path = os.path.join(base_dir, "tools", "audit_report.json")
with open(report_path, "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2, ensure_ascii=False)

print(f"Report written to {report_path}")
