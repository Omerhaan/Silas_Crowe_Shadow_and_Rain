import glob, re

for tscn in sorted(glob.glob('cases/case03/rooms/*.tscn')):
    with open(tscn, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    print('=== ' + tscn + ' ===')
    curr_node = None
    curr_lines = []
    for line in lines:
        if line.startswith('[node '):
            if curr_node and ('Evidence' in curr_node or any('evidence_id' in l for l in curr_lines)):
                print(curr_node)
                for l in curr_lines:
                    if any(k in l for k in ['evidence_id', 'is_hotspot', 'position', 'collision', 'object_id', 'display_name', 'interactable']):
                        print('  ', l.strip())
            curr_node = line.strip()
            curr_lines = []
        else:
            curr_lines.append(line)
    if curr_node and ('Evidence' in curr_node or any('evidence_id' in l for l in curr_lines)):
        print(curr_node)
        for l in curr_lines:
            if any(k in l for k in ['evidence_id', 'is_hotspot', 'position', 'collision', 'object_id', 'display_name', 'interactable']):
                print('  ', l.strip())
