import json

with open('data/cases/case01/evidence.json', 'r', encoding='utf-8') as f:
    ev = json.load(f)

for item in ev:
    desc = item.get('aciklama', '')
    print(f"{item.get('id')}: len={len(desc)} -> {desc[:50]}...")
