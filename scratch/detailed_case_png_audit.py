import os
import json
import glob
from PIL import Image

def run_audit():
    print("==================================================")
    print("DETAILED PNG AUDIT: CASE 01 vs CASE 02")
    print("==================================================")

    # 1. Load Evidence JSONs
    c1_ev_path = 'cases/case01/data/evidence.json'
    c2_ev_path = 'cases/case02/data/evidence.json'
    
    with open(c1_ev_path, 'r', encoding='utf-8') as f:
        c1_ev = json.load(f)
    with open(c2_ev_path, 'r', encoding='utf-8') as f:
        c2_ev = json.load(f)

    print(f"Case 1 Evidence Count in JSON: {len(c1_ev)}")
    print(f"Case 2 Evidence Count in JSON: {len(c2_ev)}")

    # 2. Collect PNGs in cases/case01 and cases/case02
    def get_pngs_in(folder):
        res = {}
        for r, d, files in os.walk(folder):
            for f in files:
                if f.lower().endswith('.png'):
                    fp = os.path.join(r, f).replace('\\', '/')
                    sz = os.path.getsize(fp) / 1024
                    try:
                        with Image.open(fp) as im:
                            w, h = im.size
                            mode = im.mode
                    except Exception as e:
                        w, h, mode = 0, 0, str(e)
                    res[fp] = {'w': w, 'h': h, 'mode': mode, 'kb': sz}
        return res

    c1_files = get_pngs_in('cases/case01')
    c2_files = get_pngs_in('cases/case02')
    global_assets = get_pngs_in('assets')

    print(f"\nFiles in cases/case01: {len(c1_files)} PNGs, Total: {sum(x['kb'] for x in c1_files.values()):.1f} KB")
    print(f"Files in cases/case02: {len(c2_files)} PNGs, Total: {sum(x['kb'] for x in c2_files.values()):.1f} KB")

    # Detailed breakdown for Case 1
    print("\n--- CASE 1 SUBDIRECTORIES ---")
    c1_cats = {}
    for p, info in c1_files.items():
        parts = p.split('/')
        sub = parts[3] if len(parts) > 3 else 'root'
        c1_cats.setdefault(sub, []).append((p, info))
    for cat, items in sorted(c1_cats.items()):
        total_kb = sum(x[1]['kb'] for x in items)
        print(f"  [{cat}]: {len(items)} files, {total_kb:.1f} KB")

    # Detailed breakdown for Case 2
    print("\n--- CASE 2 SUBDIRECTORIES ---")
    c2_cats = {}
    for p, info in c2_files.items():
        parts = p.split('/')
        sub = parts[3] if len(parts) > 3 else 'root'
        c2_cats.setdefault(sub, []).append((p, info))
    for cat, items in sorted(c2_cats.items()):
        total_kb = sum(x[1]['kb'] for x in items)
        print(f"  [{cat}]: {len(items)} files, {total_kb:.1f} KB")

    # Inspect Room Plates (Backgrounds)
    print("\n--- CASE 1 ROOM PLATES (BACKGROUNDS) ---")
    for p, info in sorted(c1_files.items()):
        if 'plates' in p:
            print(f"  {os.path.basename(p):<30} | {info['w']}x{info['h']} | {info['mode']:<5} | {info['kb']:.1f} KB")

    print("\n--- CASE 2 ROOM PLATES (BACKGROUNDS) ---")
    for p, info in sorted(c2_files.items()):
        if 'plates' in p:
            print(f"  {os.path.basename(p):<30} | {info['w']}x{info['h']} | {info['mode']:<5} | {info['kb']:.1f} KB")

    # Inspect Characters
    print("\n--- CASE 1 CHARACTERS (in assets/sprites/characters) ---")
    for p, info in sorted(global_assets.items()):
        if 'characters' in p and any(ch in p for ch in ['hale', 'julian', 'margaret', 'pike']):
            print(f"  {os.path.basename(p):<30} | {info['w']}x{info['h']} | {info['mode']:<5} | {info['kb']:.1f} KB")

    print("\n--- CASE 2 CHARACTERS (in cases/case02/assets/characters) ---")
    for p, info in sorted(c2_files.items()):
        if 'characters' in p:
            print(f"  {os.path.basename(p):<30} | {info['w']}x{info['h']} | {info['mode']:<5} | {info['kb']:.1f} KB")

    # Inspect Clues & Inspect View images
    print("\n--- CASE 1 CLUES & INSPECT IMAGES ---")
    c1_ev_items = c1_ev.items() if isinstance(c1_ev, dict) else [(item.get('id', str(i)), item) for i, item in enumerate(c1_ev)]
    for k, v in sorted(c1_ev_items, key=lambda x: x[0]):
        inspect_img = v.get('inspect_image', '')
        icon_img = v.get('icon', '')
        print(f"  [{k}] {v.get('title', v.get('name','')):<25} | icon: {icon_img} | inspect_image: {inspect_img}")

    print("\n--- CASE 2 CLUES & INSPECT IMAGES ---")
    c2_ev_items = c2_ev.items() if isinstance(c2_ev, dict) else [(item.get('id', str(i)), item) for i, item in enumerate(c2_ev)]
    for k, v in sorted(c2_ev_items, key=lambda x: x[0]):
        inspect_img = v.get('inspect_image', '')
        icon_img = v.get('icon', '')
        print(f"  [{k}] {v.get('title', v.get('name','')):<25} | icon: {icon_img} | inspect_image: {inspect_img}")

    with open('scripts/ui/inspect_view.gd', 'r', encoding='utf-8') as f:
        inspect_code = f.read()

    print("\nSample Case 1 Evidence entry:")
    if c1_ev_items:
        print(json.dumps(c1_ev_items[0][1], indent=2))

    print("\nSample Case 2 Evidence entry:")
    if c2_ev_items:
        print(json.dumps(c2_ev_items[0][1], indent=2))

    # InspectView texture map analysis
    print("\n--- INSPECT VIEW TEXTURES FOR CASE 1 & CASE 2 ---")
    import re
    mapping = {}
    for line in inspect_code.splitlines():
        m = re.match(r'^\s*\"([A-Za-z0-9_]+)\"\s*:\s*\"([^\"]+)\"', line)
        if m:
            mapping[m.group(1)] = m.group(2)

    print("Case 1 mappings in inspect_view.gd:")
    for k in sorted([k for k in mapping if k.startswith('E0') or k.startswith('E1')]):
        target = mapping[k].replace('res://', '')
        exists = os.path.exists(target)
        dim = ""
        if exists:
            with Image.open(target) as im:
                dim = f"{im.size[0]}x{im.size[1]} ({os.path.getsize(target)/1024:.1f} KB)"
        print(f"  {k:<10} -> {mapping[k]} | exists: {exists} {dim}")

    print("\nCase 2 mappings in inspect_view.gd:")
    for k in sorted([k for k in mapping if k.startswith('E2') or 'e2' in k.lower() or 'k3' in k.lower()]):
        target = mapping[k].replace('res://', '')
        exists = os.path.exists(target)
        dim = ""
        if exists:
            with Image.open(target) as im:
                dim = f"{im.size[0]}x{im.size[1]} ({os.path.getsize(target)/1024:.1f} KB)"
        print(f"  {k:<25} -> {mapping[k]} | exists: {exists} {dim}")

if __name__ == '__main__':
    run_audit()
