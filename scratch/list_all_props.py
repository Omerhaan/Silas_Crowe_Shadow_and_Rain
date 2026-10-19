import glob, re

for f in sorted(glob.glob('cases/case03/rooms/*.tscn')):
    print('=== ' + f + ' ===')
    content = open(f, encoding='utf-8').read()
    nodes = re.findall(r'\[node name="([^"]+)"[^\]]*\]', content)
    for n in nodes:
        if any(k in n for k in ['Prop', 'Evidence', 'NPC', 'Door', 'Walls', 'Spawn', 'Left', 'Right', 'Floor']):
            pattern = r'\[node name="' + re.escape(n) + r'"[^\]]*\](.*?)(?=\n\[|\Z)'
            m = re.search(pattern, content, re.DOTALL)
            sec = m.group(1) if m else ''
            pos = re.search(r'position = Vector2\(([^)]+)\)', sec)
            oid = re.search(r'object_id = "([^"]+)"', sec)
            eid = re.search(r'evidence_id = "([^"]+)"', sec)
            dname = re.search(r'(?:display_name|door_name) = "([^"]+)"', sec)
            ptype = re.search(r'prop_type = "([^"]+)"', sec)
            hot = re.search(r'is_hotspot = (\w+)', sec)
            size = re.search(r'hotspot_size = Vector2\(([^)]+)\)', sec)
            pos_str = pos.group(1) if pos else 'NONE'
            oid_str = oid.group(1) if oid else ''
            eid_str = eid.group(1) if eid else ''
            dn_str = dname.group(1) if dname else ''
            pt_str = ptype.group(1) if ptype else ''
            print(f'  {n:<25} pos=({pos_str:<12}) id={oid_str:<20} ev={eid_str:<6} pt={pt_str:<10} name={dn_str}')
