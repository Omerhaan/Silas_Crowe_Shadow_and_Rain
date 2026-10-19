import os
import re
from PIL import Image

def main():
    print("=" * 60)
    print("COMPREHENSIVE PNG ASSET AUDIT FOR CASE 1 & CASE 2")
    print("=" * 60)

    # 1. Collect all PNG files in project
    all_pngs = {}
    for root, dirs, files in os.walk('.'):
        if any(ex in root for ex in ['.git', '.godot', 'build', '__pycache__', '.system_generated']):
            continue
        for f in files:
            if f.lower().endswith('.png'):
                full_path = os.path.join(root, f)
                norm_path = full_path.replace('\\', '/')
                if norm_path.startswith('./'):
                    norm_path = norm_path[2:]
                size_kb = os.path.getsize(full_path) / 1024
                try:
                    with Image.open(full_path) as im:
                        w, h = im.size
                        mode = im.mode
                except Exception as e:
                    w, h, mode = 0, 0, str(e)
                all_pngs[norm_path] = {
                    'width': w,
                    'height': h,
                    'mode': mode,
                    'size_kb': size_kb
                }

    print(f"Total PNG files on disk (excluding .godot/build): {len(all_pngs)}")

    # 2. Categorize by Case 1 and Case 2
    c1_pngs = {}
    c2_pngs = {}
    shared_pngs = {}

    for path, info in all_pngs.items():
        low = path.lower()
        if 'case01' in low or 'case1' in low:
            c1_pngs[path] = info
        elif 'case02' in low or 'case2' in low:
            c2_pngs[path] = info
        elif any(c1_term in low for c1_term in ['harlow', 'hale', 'julian', 'margaret', 'pike', 'billiard', 'study', 'dining_room', 'kitchen', 'library', 'main_hall', 'upper_floor']):
            c1_pngs[path] = info
        elif any(c2_term in low for c2_term in ['vance', 'morris', 'boris', 'corley', 'brandt', 'dock', 'pier', 'saloon', 'crane_cable', 'military_crate', 'bloody_lantern', 'acid_coat', 'radio_logbook', 'tide_chart', 'k3_watch', 'night_pass', 'bribe_ledger']):
            c2_pngs[path] = info
        else:
            shared_pngs[path] = info

    # 3. Check code references
    code_files = []
    for root, dirs, files in os.walk('.'):
        if any(ex in root for ex in ['.git', '.godot', 'build', '__pycache__', '.system_generated']):
            continue
        for f in files:
            if f.endswith(('.gd', '.tscn', '.json', '.cfg', '.csv')):
                code_files.append(os.path.join(root, f))

    all_text = ""
    for cf in code_files:
        try:
            with open(cf, 'r', encoding='utf-8', errors='ignore') as f:
                all_text += "\n" + f.read()
        except:
            pass

    print("\n--- CASE 1 PNG ASSETS ---")
    c1_size_total = sum(i['size_kb'] for i in c1_pngs.values())
    print(f"Count: {len(c1_pngs)}, Total Size: {c1_size_total:.1f} KB ({c1_size_total/1024:.2f} MB)")
    
    # Subgroup Case 1
    c1_plates = {p: i for p, i in c1_pngs.items() if 'plate' in p or 'bg_' in p or 'background' in p}
    c1_clues = {p: i for p, i in c1_pngs.items() if 'clue' in p or 'inspect' in p}
    c1_chars = {p: i for p, i in c1_pngs.items() if 'character' in p or any(ch in p for ch in ['hale', 'julian', 'margaret', 'pike'])}
    c1_other = {p: i for p, i in c1_pngs.items() if p not in c1_plates and p not in c1_clues and p not in c1_chars}

    print(f"  Backgrounds/Plates: {len(c1_plates)} files, {sum(i['size_kb'] for i in c1_plates.values()):.1f} KB")
    print(f"  Clues & Inspect: {len(c1_clues)} files, {sum(i['size_kb'] for i in c1_clues.values()):.1f} KB")
    print(f"  Characters: {len(c1_chars)} files, {sum(i['size_kb'] for i in c1_chars.values()):.1f} KB")
    print(f"  Other/Props: {len(c1_other)} files, {sum(i['size_kb'] for i in c1_other.values()):.1f} KB")

    print("\n--- CASE 2 PNG ASSETS ---")
    c2_size_total = sum(i['size_kb'] for i in c2_pngs.values())
    print(f"Count: {len(c2_pngs)}, Total Size: {c2_size_total:.1f} KB ({c2_size_total/1024:.2f} MB)")
    
    # Subgroup Case 2
    c2_plates = {p: i for p, i in c2_pngs.items() if 'plate' in p or 'bg_' in p or 'background' in p}
    c2_clues = {p: i for p, i in c2_pngs.items() if 'clue' in p or 'inspect' in p}
    c2_chars = {p: i for p, i in c2_pngs.items() if 'character' in p or any(ch in p for ch in ['vance', 'morris', 'boris', 'corley', 'brandt'])}
    c2_other = {p: i for p, i in c2_pngs.items() if p not in c2_plates and p not in c2_clues and p not in c2_chars}

    print(f"  Backgrounds/Plates: {len(c2_plates)} files, {sum(i['size_kb'] for i in c2_plates.values()):.1f} KB")
    print(f"  Clues & Inspect: {len(c2_clues)} files, {sum(i['size_kb'] for i in c2_clues.values()):.1f} KB")
    print(f"  Characters: {len(c2_chars)} files, {sum(i['size_kb'] for i in c2_chars.values()):.1f} KB")
    print(f"  Other/Props: {len(c2_other)} files, {sum(i['size_kb'] for i in c2_other.values()):.1f} KB")

    # 4. Check for anomalies, duplicates, huge files, missing files
    print("\n--- DETAILED AUDIT / FINDINGS ---")
    
    # 4a. Files over 200 KB
    large_files = {p: i for p, i in all_pngs.items() if i['size_kb'] > 200}
    print(f"\n[1] Large PNG Files (> 200 KB) - Total: {len(large_files)}")
    for p, i in sorted(large_files.items(), key=lambda x: -x[1]['size_kb']):
        print(f"    {i['size_kb']:.1f} KB | {i['width']}x{i['height']} | {p}")

    # 4b. Duplicates or redundant versions (_v1, _v2, etc.)
    version_files = [p for p in all_pngs if '_v1' in p or '_v2' in p]
    print(f"\n[2] Versioned/Duplicate Plate Files (_v1, _v2) - Total: {len(version_files)}")
    for p in sorted(version_files):
        print(f"    {p}")

    # 4c. Preview files (_preview.png)
    preview_files = [p for p in all_pngs if '_preview' in p]
    print(f"\n[3] Preview Files (_preview.png) - Total: {len(preview_files)}")
    print(f"    Total size of _preview.png files: {sum(all_pngs[p]['size_kb'] for p in preview_files):.1f} KB")

    # 4d. Duplicate paths across cases/ and assets/
    print("\n[4] Duplicate Clue / Inspect Assets across directories:")
    cases_clue_basenames = {os.path.basename(p): p for p in all_pngs if 'cases/' in p and 'clues' in p}
    assets_clue_basenames = {os.path.basename(p): p for p in all_pngs if 'assets/' in p and ('clues' in p or 'inspect' in p)}
    
    common = set(cases_clue_basenames.keys()).intersection(set(assets_clue_basenames.keys()))
    for c in sorted(common):
        p1 = cases_clue_basenames[c]
        p2 = assets_clue_basenames[c]
        print(f"    {c}:")
        print(f"       Cases:  {p1} ({all_pngs[p1]['width']}x{all_pngs[p1]['height']}, {all_pngs[p1]['size_kb']:.1f} KB)")
        print(f"       Assets: {p2} ({all_pngs[p2]['width']}x{all_pngs[p2]['height']}, {all_pngs[p2]['size_kb']:.1f} KB)")

if __name__ == '__main__':
    main()
