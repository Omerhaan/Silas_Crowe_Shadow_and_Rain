import os, re

case3_rooms = 'cases/case03/rooms'
for f in sorted(os.listdir(case3_rooms)):
    if not f.endswith('.tscn'):
        continue
    path = os.path.join(case3_rooms, f)
    with open(path, 'r', encoding='utf-8') as fp:
        lines = fp.readlines()
    print("=" * 60)
    print("ROOM:", f)
    print("=" * 60)
    current_node = ""
    node_props = {}
    for line in lines:
        line_s = line.strip()
        if line_s.startswith("[node name="):
            if current_node:
                pos = node_props.get("position", "NO_POS")
                oid = node_props.get("object_id", "")
                evid = node_props.get("evidence_id", "")
                target_room = node_props.get("target_room_id", "")
                target_spawn = node_props.get("target_spawn", "")
                char_id = node_props.get("character_id", "")
                is_hotspot = node_props.get("is_hotspot", "")
                hotspot_size = node_props.get("hotspot_size", "")
                print(f"  {current_node:28s} pos={pos:18s} obj={oid:18s} ev={evid:6s} char={char_id:12s} door={target_room}:{target_spawn} hotspot={is_hotspot} sz={hotspot_size}")
            m = re.findall(r'name="([^"]+)"', line_s)
            current_node = m[0] if m else "unknown"
            node_props = {}
        elif "=" in line_s and current_node:
            k, v = line_s.split("=", 1)
            node_props[k.strip()] = v.strip().strip('"')
    if current_node:
        pos = node_props.get("position", "NO_POS")
        oid = node_props.get("object_id", "")
        evid = node_props.get("evidence_id", "")
        target_room = node_props.get("target_room_id", "")
        target_spawn = node_props.get("target_spawn", "")
        char_id = node_props.get("character_id", "")
        is_hotspot = node_props.get("is_hotspot", "")
        hotspot_size = node_props.get("hotspot_size", "")
        print(f"  {current_node:28s} pos={pos:18s} obj={oid:18s} ev={evid:6s} char={char_id:12s} door={target_room}:{target_spawn} hotspot={is_hotspot} sz={hotspot_size}")
