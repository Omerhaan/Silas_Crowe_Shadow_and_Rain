import json, glob

for f in sorted(glob.glob('data/cases/case01/dialogues/*.json')):
    with open(f, 'r', encoding='utf-8') as jf:
        d = json.load(jf)
    topics = d.get('topics', [])
    print(f"=== {f} ===")
    if isinstance(topics, list):
        for t in topics:
            print("  id:", t.get('id'), "title:", t.get('title'))
    elif isinstance(topics, dict):
        for k, v in topics.items():
            print("  id:", k, "title:", v.get('title'))
