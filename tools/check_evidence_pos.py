import glob, re

for tscn in sorted(glob.glob('scenes/rooms/*.tscn')):
    with open(tscn, 'r', encoding='utf-8') as f:
        c = f.read()
    
    # Split by node
    sections = re.split(r'\[node ', c)
    evs = []
    for s in sections:
        if not s.startswith('name="'):
            continue
        name_match = re.search(r'name="([^"]+)"', s)
        pos_match = re.search(r'position = Vector2\(([^,]+),\s*([^)]+)\)', s)
        ev_match = re.search(r'evidence_id = "([^"]+)"', s)
        hotspot_match = re.search(r'hotspot_size = Vector2\(([^,]+),\s*([^)]+)\)', s)
        
        name = name_match.group(1) if name_match else ""
        if 'Evidence' in name or ev_match:
            pos = (pos_match.group(1), pos_match.group(2)) if pos_match else ("?", "?")
            ev_id = ev_match.group(1) if ev_match else ""
            hs = (hotspot_match.group(1), hotspot_match.group(2)) if hotspot_match else ("-", "-")
            evs.append((name, ev_id, pos, hs))
    if evs:
        print(f"=== {tscn} ===")
        for name, ev_id, pos, hs in evs:
            print(f"  {name} (ev={ev_id}): pos={pos}, hotspot={hs}")
