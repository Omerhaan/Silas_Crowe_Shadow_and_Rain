import os
import shutil
from collections import deque
from PIL import Image, ImageOps, ImageDraw
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(BASE_DIR, 'cases', 'case03', 'assets')
RAW_DIR = os.path.join(SRC_DIR, 'raw')
PLATES_DIR = os.path.join(SRC_DIR, 'plates')
CHARS_DIR = os.path.join(SRC_DIR, 'characters')
CLUES_DIR = os.path.join(SRC_DIR, 'clues')
CINES_DIR = os.path.join(SRC_DIR, 'cinematics')
GLOBAL_PORTRAITS = os.path.join(BASE_DIR, 'assets', 'portraits')
GLOBAL_CLUES = os.path.join(BASE_DIR, 'assets', 'sprites', 'clues')
GLOBAL_CINES = os.path.join(BASE_DIR, 'assets', 'sprites', 'cinematics')

for d in [RAW_DIR, PLATES_DIR, CHARS_DIR, CLUES_DIR, CINES_DIR, GLOBAL_PORTRAITS, GLOBAL_CLUES, GLOBAL_CINES]:
    os.makedirs(d, exist_ok=True)

# 1. Backup original raw files
print("--- 1. Backing up original raw files ---")
for f in os.listdir(SRC_DIR):
    fp = os.path.join(SRC_DIR, f)
    if os.path.isfile(fp) and f.endswith(('.jpg', '.png')) and not f.startswith('test_'):
        dst = os.path.join(RAW_DIR, f)
        if not os.path.exists(dst):
            shutil.copy2(fp, dst)
print("Backup complete.")

# 2. Background Plates
print("\n--- 2. Processing Background Plates (480x270) ---")
plates = [
    'bg_opera_foyer.jpg',
    'bg_opera_auditorium.jpg',
    'bg_royal_box.jpg',
    'bg_backstage.jpg',
    'bg_prop_room.jpg',
    'bg_light_bridge.jpg',
    'bg_opera_roof.jpg'
]

for p in plates:
    raw_path = os.path.join(RAW_DIR, p)
    if not os.path.exists(raw_path):
        raw_path = os.path.join(SRC_DIR, p)
    if not os.path.exists(raw_path):
        print(f"Warning: {p} not found!")
        continue
    with Image.open(raw_path) as img:
        w, h = img.size
        # Crop letterbox (approx 80px top, 79px bottom)
        cropped = img.crop((0, 80, w, h - 79))
        resized = cropped.resize((480, 270), Image.Resampling.LANCZOS)
        out_name = p.replace('.jpg', '.png')
        out_path = os.path.join(PLATES_DIR, out_name)
        resized.save(out_path, format='PNG', optimize=True)
        # Also copy to global plates for fallback
        global_plates = os.path.join(BASE_DIR, 'assets', 'plates')
        os.makedirs(global_plates, exist_ok=True)
        shutil.copy2(out_path, os.path.join(global_plates, out_name))
        print(f"Saved plate: {out_name} (480x270, {os.path.getsize(out_path)//1024} KB)")

# 3. Transparent Characters
print("\n--- 3. Processing Characters (Transparency & Sprites) ---")
chars = ['finch', 'elena', 'sterling', 'patch', 'henderson', 'unknown_sniper']

def remove_checkerboard(img_path):
    img = Image.open(img_path).convert('RGB')
    w, h = img.size
    arr = np.array(img, dtype=int)
    r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]
    diff = np.maximum(np.maximum(np.abs(r-g), np.abs(g-b)), np.abs(r-b))
    mean_val = (r + g + b) / 3.0
    is_checker = (diff <= 18) & (mean_val >= 90) & (mean_val <= 185)

    visited = np.zeros((h, w), dtype=bool)
    q = deque()
    for x in range(w):
        if is_checker[0, x]: q.append((0, x)); visited[0, x] = True
        if is_checker[h-1, x]: q.append((h-1, x)); visited[h-1, x] = True
    for y in range(h):
        if is_checker[y, 0]: q.append((y, 0)); visited[y, 0] = True
        if is_checker[y, w-1]: q.append((y, w-1)); visited[y, w-1] = True

    while q:
        y, x = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx]:
                if is_checker[ny, nx]:
                    visited[ny, nx] = True
                    q.append((ny, nx))

    # Pockets inside
    unvisited_checker = is_checker & (~visited)
    pocket_visited = np.zeros((h, w), dtype=bool)
    for y in range(h):
        for x in range(w):
            if unvisited_checker[y, x] and not pocket_visited[y, x]:
                comp = []
                cq = deque([(y, x)])
                pocket_visited[y, x] = True
                while cq:
                    cy, cx = cq.popleft()
                    comp.append((cy, cx))
                    for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
                        ny, nx = cy + dy, cx + dx
                        if 0 <= ny < h and 0 <= nx < w and unvisited_checker[ny, nx] and not pocket_visited[ny, nx]:
                            pocket_visited[ny, nx] = True
                            cq.append((ny, nx))
                m_vals = [mean_val[cy, cx] for cy, cx in comp]
                if len(comp) > 50 and any(m < 130 for m in m_vals) and any(m > 145 for m in m_vals):
                    for cy, cx in comp:
                        visited[cy, cx] = True

    alpha = np.where(visited, 0, 255).astype(np.uint8)
    rgba = np.dstack([arr.astype(np.uint8), alpha])
    return Image.fromarray(rgba)

for c in chars:
    raw_path = os.path.join(RAW_DIR, f"{c}.jpg")
    if not os.path.exists(raw_path):
        raw_path = os.path.join(SRC_DIR, f"{c}.jpg")
    if not os.path.exists(raw_path):
        print(f"Warning: {c}.jpg not found!")
        continue

    print(f"Extracting transparent alpha for {c}...")
    clean_rgba = remove_checkerboard(raw_path)
    
    # Bounding box of content
    alpha_arr = np.array(clean_rgba)[:, :, 3]
    rows = np.where(alpha_arr > 10)[0]
    cols = np.where(alpha_arr > 10)[1]
    ymin, ymax = rows.min(), rows.max()
    xmin, xmax = cols.min(), cols.max()
    
    # Save full transparent cropped
    full_crop = clean_rgba.crop((xmin, ymin, xmax + 1, ymax + 1))
    full_crop.save(os.path.join(CHARS_DIR, f"{c}_full.png"))
    
    # Standing sprite 64x104 (height ~96px, foot at y=103)
    char_h = ymax - ymin + 1
    char_w = xmax - xmin + 1
    target_h = 96
    target_w = max(1, int(char_w * (target_h / char_h)))
    scaled_body = full_crop.resize((target_w, target_h), Image.Resampling.LANCZOS)
    
    # Canvas 64x104
    sprite_canvas = Image.new('RGBA', (64, 104), (0, 0, 0, 0))
    paste_x = (64 - target_w) // 2
    paste_y = 104 - target_h  # places feet at y=103
    sprite_canvas.paste(scaled_body, (paste_x, paste_y), scaled_body)
    
    sprite_canvas.save(os.path.join(CHARS_DIR, f"{c}_idle_down.png"))
    sprite_canvas.save(os.path.join(CHARS_DIR, f"{c}_idle_up.png"))
    sprite_canvas.save(os.path.join(CHARS_DIR, f"{c}_idle_right.png"))
    ImageOps.mirror(sprite_canvas).save(os.path.join(CHARS_DIR, f"{c}_idle_left.png"))
    
    # Portrait close-up (head & shoulders: top 32% of height)
    bust_h = int(char_h * 0.35)
    bust_ymin = ymin
    bust_ymax = ymin + bust_h
    bust_center_x = (xmin + xmax) // 2
    bust_half_size = bust_h // 2
    bust_xmin = max(0, bust_center_x - bust_half_size)
    bust_xmax = min(clean_rgba.size[0], bust_center_x + bust_half_size)
    
    bust_crop = clean_rgba.crop((bust_xmin, bust_ymin, bust_xmax, bust_ymax))
    
    # Create nice dark noir circular / square portrait (192x192)
    preview_bg = Image.new('RGB', (192, 192), (24, 28, 36)) # dark noir navy
    # draw subtle vignette
    d_ctx = ImageDraw.Draw(preview_bg)
    d_ctx.rectangle([4, 4, 187, 187], outline=(45, 52, 65), width=2)
    
    # scale bust to fit ~170x170
    bw, bh = bust_crop.size
    scale_factor = 160.0 / max(bw, bh)
    scaled_bust = bust_crop.resize((int(bw * scale_factor), int(bh * scale_factor)), Image.Resampling.LANCZOS)
    bx = (192 - scaled_bust.size[0]) // 2
    by = (192 - scaled_bust.size[1]) // 2 + 8
    preview_bg.paste(scaled_bust, (bx, by), scaled_bust)
    
    preview_path = os.path.join(CHARS_DIR, f"{c}_preview.png")
    preview_bg.save(preview_path)
    
    # 48x48 icon
    icon_48 = preview_bg.resize((48, 48), Image.Resampling.LANCZOS)
    icon_path = os.path.join(CHARS_DIR, f"{c}.png")
    icon_48.save(icon_path)
    shutil.copy2(icon_path, os.path.join(GLOBAL_PORTRAITS, f"{c}.png"))
    print(f"Character {c} ready: idle (64x104), preview (192x192), portrait (48x48)")

# 4. Evidence Clues
print("\n--- 4. Processing Clues ---")
clues = {
    'clue_e301_k4_rifle.jpg': 'clue_e301_k4_rifle.png',
    'clue_e302_spent_casing.jpg': 'clue_e302_spent_casing.png',
    'clue_e306_marked_score.jpg': 'clue_e306_marked_score.png',
    'clue_e308_typewriter_note.jpg': 'clue_e308_typewriter_note.png',
    'clue_e309_k4_watch.jpg': 'clue_e309_k4_watch.png'
}

for src_name, dst_name in clues.items():
    raw_path = os.path.join(RAW_DIR, src_name)
    if not os.path.exists(raw_path):
        raw_path = os.path.join(SRC_DIR, src_name)
    if not os.path.exists(raw_path):
        print(f"Warning: {src_name} not found!")
        continue
    with Image.open(raw_path) as img:
        # 160x120 inspect preview
        preview_160 = img.resize((160, 120), Image.Resampling.LANCZOS)
        out_preview = os.path.join(CLUES_DIR, dst_name.replace('.png', '_preview.png'))
        preview_160.save(out_preview)
        
        # 32x32 inventory icon (center crop to square then scale)
        min_dim = min(img.size)
        cx, cy = img.size[0] // 2, img.size[1] // 2
        sq_crop = img.crop((cx - min_dim//2, cy - min_dim//2, cx + min_dim//2, cy + min_dim//2))
        icon_32 = sq_crop.resize((32, 32), Image.Resampling.LANCZOS)
        out_icon = os.path.join(CLUES_DIR, dst_name)
        icon_32.save(out_icon)
        shutil.copy2(out_icon, os.path.join(GLOBAL_CLUES, dst_name))
        print(f"Clue {dst_name}: preview (160x120) and icon (32x32)")

# 5. Cinematics
print("\n--- 5. Processing Cinematics (480x270) ---")
cinematics = [
    'cinematic_case03_travel.jpg',
    'cinematic_case03_01_office_call.jpg',
    'cinematic_case03_02_soprano_aria.jpg',
    'cinematic_case03_body_k4.jpg',
    'flashback_fb03_snow_sniper.jpg'
]

for cine in cinematics:
    raw_path = os.path.join(RAW_DIR, cine)
    if not os.path.exists(raw_path):
        raw_path = os.path.join(SRC_DIR, cine)
    if not os.path.exists(raw_path):
        print(f"Warning: {cine} not found!")
        continue
    with Image.open(raw_path) as img:
        w, h = img.size
        # If letterboxed, crop
        top_crop = 80 if h == 1536 else 0
        bot_crop = (h - 79) if h == 1536 else h
        cropped = img.crop((0, top_crop, w, bot_crop))
        c_480 = cropped.resize((480, 270), Image.Resampling.LANCZOS)
        
        out_cine = os.path.join(CINES_DIR, cine)
        c_480.save(out_cine, quality=90, optimize=True)
        shutil.copy2(out_cine, os.path.join(GLOBAL_CINES, cine))
        print(f"Cinematic {cine}: 480x270 ({os.path.getsize(out_cine)//1024} KB)")

# Remove top-level loose raw files from cases/case03/assets to keep folder pristine
print("\n--- Cleaning up loose files in root assets dir ---")
for f in os.listdir(SRC_DIR):
    fp = os.path.join(SRC_DIR, f)
    if os.path.isfile(fp):
        os.remove(fp)

print("\n=== ALL CASE 03 ASSETS OPTIMIZED & ORGANIZED SUCCESSFULLY! ===")
