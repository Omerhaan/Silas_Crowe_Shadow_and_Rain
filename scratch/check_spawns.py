import glob, re

for f in sorted(glob.glob('cases/case03/rooms/*.tscn')):
    print('=== ' + f + ' ===')
    content = open(f, encoding='utf-8').read()
    spawns = re.findall(r'\[node name="(Spawn_[^"]+)"[^\]]*\]\s*position = Vector2\(([^)]+)\)', content)
    for name, pos in spawns:
        print(f'  {name:<25}: {pos}')
