import os, re

case3_rooms = 'cases/case03/rooms'

print("=== CHECKING ALL INTERACTABLES & OBSTACLES IN CASE 3 ===")

for f in sorted(os.listdir(case3_rooms)):
    if not f.endswith('.tscn'):
        continue
    rname = f.replace('.tscn', '')
    path = os.path.join(case3_rooms, f)
    with open(path, 'r', encoding='utf-8') as fp:
        content = fp.read()

    # Floor Y
    floor_m = re.findall(r'\[node name=\"FloorShape\"[^\n]*\]\s*position = Vector2\(([^)]+)\)', content)
    floor_y = 260.0
    if floor_m:
        parts = [float(x.strip()) for x in floor_m[0].split(',')]
        floor_y = parts[1]
    
    # LeftWall X and RightWall X
    lw_m = re.findall(r'\[node name=\"LeftWall\"[^\n]*\]\s*position = Vector2\(([^)]+)\)', content)
    rw_m = re.findall(r'\[node name=\"RightWall\"[^\n]*\]\s*position = Vector2\(([^)]+)\)', content)
    lw_x = float(lw_m[0].split(',')[0].strip()) if lw_m else 0.0
    rw_x = float(rw_m[0].split(',')[0].strip()) if rw_m else 480.0
    
    # Silas standing Y is roughly floor_y - 15 (feet touch top of floor shape)
    # FloorShape size is usually height 26 (half 13) -> floor surface is floor_y - 13
    silas_y = floor_y - 13.0

    print(f"\n--- ROOM: {rname} ---")
    print(f"Floor Y surface = {silas_y:.1f} | Walkable X range = [{lw_x:.1f} .. {rw_x:.1f}]")
    
    # Find all interactables and npcs
    items = re.findall(r'(\[node name=\"([^\"]+)\" parent=\"\.\" instance=ExtResource\(\"[^\"]*(?:interact|npc)[^\"]*\"\)[^\]]*\](.*?)(?=\n\[node|\Z))', content, re.DOTALL)
    for full_match, iname, body in items:
        pos_m = re.findall(r'position = Vector2\(([^)]+)\)', full_match)
        if not pos_m:
            continue
        px, py = [float(x.strip()) for x in pos_m[0].split(',')]
        
        oid = re.findall(r'object_id = \"([^\"]+)\"', body)
        oid_s = oid[0] if oid else ""
        dname = re.findall(r'display_name = \"([^\"]+)\"', body)
        dname_s = dname[0] if dname else iname
        evid = re.findall(r'evidence_id = \"([^\"]+)\"', body)
        evid_s = evid[0] if evid else ""
        hsz_m = re.findall(r'hotspot_size = Vector2\(([^)]+)\)', body)
        hsz = [float(x.strip()) for x in hsz_m[0].split(',')] if hsz_m else [26.0, 26.0]
        
        # Check if X is blocked by walls
        is_x_blocked = px < lw_x or px > rw_x
        # Check if vertical distance is within InteractionArea:
        # Player InteractionArea: Y in [silas_y - 210, silas_y + 10]
        # Interactable shape top/bottom: py - hsz[1]/2 to py + hsz[1]/2
        int_top = py - max(hsz[1], 38.0) / 2.0
        int_bot = py + max(hsz[1], 38.0) / 2.0
        player_area_top = silas_y - 210.0
        player_area_bot = silas_y + 10.0
        y_overlaps = not (int_bot < player_area_top or int_top > player_area_bot)
        
        # Check tap-to-move reach:
        # Player stops at abs(player.x - target.x) <= 45 (or 50)
        # But if is_x_blocked, player cannot reach!
        
        status = "OK"
        issues = []
        if is_x_blocked:
            status = "BLOCKED BY WALL"
            issues.append(f"X={px:.1f} is outside [{lw_x:.1f}, {rw_x:.1f}]")
        if not y_overlaps:
            status = "OUT OF VERTICAL REACH"
            issues.append(f"Y={py:.1f} out of reach ({player_area_top:.1f}..{player_area_bot:.1f})")
            
        # Check if click area / area_2d input_pickable works or if prompt label is too high
        print(f"  [{status:18s}] {iname:24s} ({dname_s}): pos=({px:.1f}, {py:.1f}) {' | '.join(issues)}")
