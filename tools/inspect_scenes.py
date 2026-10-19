import glob, re

for tscn in sorted(glob.glob('scenes/rooms/*.tscn')):
    print('=== ' + tscn + ' ===')
    with open(tscn, 'r', encoding='utf-8') as f:
        content = f.read()
    # Find all node definitions
    matches = re.finditer(r'\[node name="([^"]+)"(?: type="([^"]+)")?(?: parent="([^"]*)")?(?: instance=ExtResource\("([^"]+)"\))?\]', content)
    for m in matches:
        name = m.group(1)
        ntype = m.group(2) or "Instance"
        parent = m.group(3) or "."
        if any(k in name for k in ['Door', 'Arrow', 'Evidence', 'NPC', 'Stairs', 'Silas']) or 'Interactable' in name:
            print(f'  {name} ({ntype}) parent={parent}')
