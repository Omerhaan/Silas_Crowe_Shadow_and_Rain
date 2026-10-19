import os, re

case3_rooms = 'cases/case03/rooms'
room_data = {}

for f in sorted(os.listdir(case3_rooms)):
    if not f.endswith('.tscn'):
        continue
    rname = f.replace('.tscn', '')
    path = os.path.join(case3_rooms, f)
    with open(path, 'r', encoding='utf-8') as fp:
        content = fp.read()
    
    # find doors
    doors = []
    door_blocks = re.findall(r'(\[node name=\"([^\"]+)\" parent=\"\.\" instance=ExtResource\(\"[^\"]*door[^\"]*\"\)[^\]]*\](.*?)(?=\n\[node|\Z))', content, re.DOTALL)
    for full_match, dname, body in door_blocks:
        t_room = re.findall(r'target_room_id = \"([^\"]+)\"', body)
        t_spawn = re.findall(r'target_spawn = \"([^\"]+)\"', body)
        pos = re.findall(r'position = Vector2\(([^)]+)\)', full_match)
        doors.append({
            'name': dname,
            'pos': pos[0] if pos else 'NONE',
            'target_room': t_room[0] if t_room else '',
            'target_spawn': t_spawn[0] if t_spawn else ''
        })
    
    # find spawns
    spawns = re.findall(r'\[node name=\"(Spawn_[^\"]+)\"[^\]]*\]\s*position = Vector2\(([^)]+)\)', content)
    spawn_dict = {sname: spos for sname, spos in spawns}
    
    # find interactables
    interacts = []
    int_blocks = re.findall(r'(\[node name=\"([^\"]+)\" parent=\"\.\" instance=ExtResource\(\"[^\"]*interact[^\"]*\"\)[^\]]*\](.*?)(?=\n\[node|\Z))', content, re.DOTALL)
    for full_match, iname, body in int_blocks:
        oid = re.findall(r'object_id = \"([^\"]+)\"', body)
        evid = re.findall(r'evidence_id = \"([^\"]+)\"', body)
        pos = re.findall(r'position = Vector2\(([^)]+)\)', full_match)
        ptype = re.findall(r'prop_type = \"([^\"]+)\"', body)
        is_hot = re.findall(r'is_hotspot = ([^\n]+)', body)
        hsz = re.findall(r'hotspot_size = Vector2\(([^)]+)\)', body)
        interacts.append({
            'name': iname,
            'pos': pos[0] if pos else 'NONE',
            'oid': oid[0] if oid else '',
            'evid': evid[0] if evid else '',
            'ptype': ptype[0] if ptype else '',
            'is_hotspot': is_hot[0] if is_hot else '',
            'hotspot_size': hsz[0] if hsz else ''
        })
        
    # find walls & floor
    floor_pos = re.findall(r'\[node name=\"FloorShape\"[^\n]*\]\s*position = Vector2\(([^)]+)\)', content)
    left_wall = re.findall(r'\[node name=\"LeftWall\"[^\n]*\]\s*position = Vector2\(([^)]+)\)', content)
    right_wall = re.findall(r'\[node name=\"RightWall\"[^\n]*\]\s*position = Vector2\(([^)]+)\)', content)
    
    room_data[rname] = {
        'doors': doors,
        'spawns': spawn_dict,
        'interacts': interacts,
        'floor': floor_pos[0] if floor_pos else 'NONE',
        'left_wall': left_wall[0] if left_wall else 'NONE',
        'right_wall': right_wall[0] if right_wall else 'NONE'
    }

print("=== 1. VERIFYING ALL DOOR CONNECTIONS & SPAWN TARGETS ===")
for rname, data in room_data.items():
    print(f"\nROOM: {rname}")
    print(f"  Floor: {data['floor']} | LeftWall: {data['left_wall']} | RightWall: {data['right_wall']}")
    print(f"  Spawns defined: {list(data['spawns'].keys())}")
    for d in data['doors']:
        t_room = d['target_room']
        t_spawn = d['target_spawn']
        expected_spawn_node = f"Spawn_{t_spawn}"
        if t_room not in room_data:
            print(f"  [ERROR] DOOR {d['name']}: target room '{t_room}' DOES NOT EXIST!")
        else:
            target_spawns = room_data[t_room]['spawns']
            if expected_spawn_node not in target_spawns:
                print(f"  [MISMATCH] DOOR {d['name']}: targets '{t_room}' with spawn '{t_spawn}' (looks for '{expected_spawn_node}'), but '{t_room}' only has: {list(target_spawns.keys())}")
            else:
                print(f"  [OK] DOOR {d['name']} -> {t_room}:{expected_spawn_node} at {target_spawns[expected_spawn_node]}")
