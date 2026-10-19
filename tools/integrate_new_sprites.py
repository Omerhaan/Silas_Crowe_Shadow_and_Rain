"""
integrate_new_sprites.py
Processes the new user-uploaded high-quality character sprite sheets and crime scene artwork.
- Silas Crowe (idle, walk cycles, inspect, shudder)
- Dr. Victor Hale (4-way idle, portraits)
- Julian Harlow (4-way idle, portraits)
- Margaret Doyle (4-way idle, portraits)
- Raymond Pike (4-way idle, portraits)
- Sir Edmund Harlow crime scene illustration & study corpse prop
"""

import os
from PIL import Image
import numpy as np
from collections import deque

IMAGE_PATHS = {
    'silas': r'C:/Users/omerh/.gemini/antigravity/brain/4575aca9-af2c-40a2-832e-408a15fcebaa/.user_uploaded/media_1791790216852_76da125b.jpg',
    'julian': r'C:/Users/omerh/.gemini/antigravity/brain/4575aca9-af2c-40a2-832e-408a15fcebaa/.user_uploaded/media_1791790553562_181d6612.jpg',
    'hale': r'C:/Users/omerh/.gemini/antigravity/brain/4575aca9-af2c-40a2-832e-408a15fcebaa/.user_uploaded/media_1791790553578_8f5d9f37.jpg',
    'margaret': r'C:/Users/omerh/.gemini/antigravity/brain/4575aca9-af2c-40a2-832e-408a15fcebaa/.user_uploaded/media_1791790553590_2412ebed.jpg',
    'pike': r'C:/Users/omerh/.gemini/antigravity/brain/4575aca9-af2c-40a2-832e-408a15fcebaa/.user_uploaded/media_1791790553665_c800d776.jpg',
    'edmund_crime_scene': r'C:/Users/omerh/.gemini/antigravity/brain/4575aca9-af2c-40a2-832e-408a15fcebaa/.user_uploaded/media_1791790553768_c2a21920.jpg'
}

TARGET_HEIGHTS = {
    'silas': 100,
    'hale': 102,
    'julian': 98,
    'pike': 98,
    'margaret': 94
}

CHAR_DIR = 'assets/sprites/characters'
PORTRAIT_DIR = 'assets/portraits'
INSPECT_DIR = 'assets/sprites/inspect'
CINEMATIC_DIR = 'assets/sprites/cinematics'
PROP_DIR = 'assets/sprites/props'

os.makedirs(CHAR_DIR, exist_ok=True)
os.makedirs(PORTRAIT_DIR, exist_ok=True)
os.makedirs(INSPECT_DIR, exist_ok=True)
os.makedirs(CINEMATIC_DIR, exist_ok=True)
os.makedirs(PROP_DIR, exist_ok=True)

def extract_cell(im, col, row, target_h, target_w=64):
    W_img, H_img = im.size
    cw = W_img / 6.0
    ch = H_img / 3.0
    box = (int(col * cw), int(row * ch), int((col + 1) * cw), int((row + 1) * ch))
    cell = im.crop(box)
    
    arr = np.array(cell.convert('RGBA'))
    H, W = arr.shape[:2]
    # White background threshold
    is_white = (arr[:, :, 0] > 230) & (arr[:, :, 1] > 230) & (arr[:, :, 2] > 230)
    bg = np.zeros((H, W), dtype=bool)
    q = deque()
    for y in range(H):
        if is_white[y, 0]: q.append((y, 0)); bg[y, 0] = True
        if is_white[y, W-1]: q.append((y, W-1)); bg[y, W-1] = True
    for x in range(W):
        if is_white[0, x]: q.append((0, x)); bg[0, x] = True
        if is_white[H-1, x]: q.append((H-1, x)); bg[H-1, x] = True

    while q:
        y, x = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < H and 0 <= nx < W and not bg[ny, nx] and is_white[ny, nx]:
                bg[ny, nx] = True
                q.append((ny, nx))

    arr[bg, 3] = 0
    clean = Image.fromarray(arr)
    bbox = clean.getbbox()
    if not bbox:
        return Image.new('RGBA', (target_w, 104), (0,0,0,0))
    
    char_crop = clean.crop(bbox)
    cw_crop, ch_crop = char_crop.size
    
    scale = target_h / float(ch_crop)
    new_w = max(1, int(round(cw_crop * scale)))
    new_h = target_h
    scaled = char_crop.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    canvas = Image.new('RGBA', (target_w, 104), (0,0,0,0))
    paste_x = (target_w - new_w) // 2
    paste_y = 104 - new_h
    canvas.paste(scaled, (paste_x, paste_y), scaled)
    return canvas

def extract_portrait(im, col, row, size=48):
    W_img, H_img = im.size
    cw = W_img / 6.0
    ch = H_img / 3.0
    box = (int(col * cw), int(row * ch), int((col + 1) * cw), int((row + 1) * ch))
    cell = im.crop(box)
    
    # Head and shoulders are in upper 40% of cell
    arr = np.array(cell.convert('RGBA'))
    H, W = arr.shape[:2]
    is_white = (arr[:, :, 0] > 230) & (arr[:, :, 1] > 230) & (arr[:, :, 2] > 230)
    bg = np.zeros((H, W), dtype=bool)
    q = deque()
    for y in range(H):
        if is_white[y, 0]: q.append((y, 0)); bg[y, 0] = True
        if is_white[y, W-1]: q.append((y, W-1)); bg[y, W-1] = True
    for x in range(W):
        if is_white[0, x]: q.append((0, x)); bg[0, x] = True
        if is_white[H-1, x]: q.append((H-1, x)); bg[H-1, x] = True
    while q:
        y, x = q.popleft()
        for dy, dx in [(-1,0), (1,0), (0,-1), (0,1)]:
            ny, nx = y + dy, x + dx
            if 0 <= ny < H and 0 <= nx < W and not bg[ny, nx] and is_white[ny, nx]:
                bg[ny, nx] = True
                q.append((ny, nx))
    arr[bg, 3] = 0
    clean = Image.fromarray(arr)
    bbox = clean.getbbox()
    if bbox:
        # Take upper 45% of character height for bust portrait
        char_h = bbox[3] - bbox[1]
        bust_box = (bbox[0], bbox[1], bbox[2], int(bbox[1] + char_h * 0.45))
        bust = clean.crop(bust_box)
        # Pad to square
        bw, bh = bust.size
        side = max(bw, bh)
        sq = Image.new('RGBA', (side, side), (0,0,0,0))
        sq.paste(bust, ((side - bw) // 2, (side - bh) // 2), bust)
        return sq.resize((size, size), Image.Resampling.LANCZOS)
    return Image.new('RGBA', (size, size), (0,0,0,0))

def main():
    print("=== 1. Processing Silas Crowe ===")
    im_silas = Image.open(IMAGE_PATHS['silas'])
    th_silas = TARGET_HEIGHTS['silas']
    
    # Idle postures
    silas_idle_down = extract_cell(im_silas, 0, 0, th_silas)
    silas_idle_down.save(os.path.join(CHAR_DIR, 'silas_idle_down.png'))
    
    silas_inspect = extract_cell(im_silas, 2, 0, th_silas)
    silas_inspect.save(os.path.join(CHAR_DIR, 'silas_inspect.png'))
    
    silas_notebook = extract_cell(im_silas, 3, 0, th_silas)
    silas_notebook.save(os.path.join(CHAR_DIR, 'silas_notebook.png'))
    
    silas_shudder = extract_cell(im_silas, 0, 2, th_silas)
    silas_shudder.save(os.path.join(CHAR_DIR, 'silas_shudder.png'))
    
    # Walk cycle right (row 1, cols 0..5)
    for col in range(6):
        w_frame = extract_cell(im_silas, col, 1, th_silas)
        w_frame.save(os.path.join(CHAR_DIR, f'silas_walk_right_{col+1}.png'))
        # Flip for walk left
        w_flip = w_frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        w_flip.save(os.path.join(CHAR_DIR, f'silas_walk_left_{col+1}.png'))
        
    # Idle right & left from first walk frame with legs together
    silas_idle_right = extract_cell(im_silas, 0, 1, th_silas)
    silas_idle_right.save(os.path.join(CHAR_DIR, 'silas_idle_right.png'))
    silas_idle_left = silas_idle_right.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    silas_idle_left.save(os.path.join(CHAR_DIR, 'silas_idle_left.png'))
    
    # Walk down & up frames
    for idx in range(1, 5):
        # Pick alternating idle / walk frames for down
        f_down = extract_cell(im_silas, idx % 6, 0, th_silas)
        f_down.save(os.path.join(CHAR_DIR, f'silas_walk_down_{idx}.png'))
    
    # Silas portrait
    silas_portrait = extract_portrait(im_silas, 0, 0, 48)
    silas_portrait.save(os.path.join(PORTRAIT_DIR, 'silas.png'))
    
    # 2. Process Suspects: Hale, Julian, Margaret, Pike
    for susp_key in ['hale', 'julian', 'margaret', 'pike']:
        print(f"=== Processing {susp_key.capitalize()} ===")
        im_susp = Image.open(IMAGE_PATHS[susp_key])
        th_susp = TARGET_HEIGHTS[susp_key]
        
        # Idle down (front)
        idle_down = extract_cell(im_susp, 0, 0, th_susp)
        idle_down.save(os.path.join(CHAR_DIR, f'{susp_key}_idle_down.png'))
        
        # Idle right (side view)
        idle_right = extract_cell(im_susp, 0, 1, th_susp)
        idle_right.save(os.path.join(CHAR_DIR, f'{susp_key}_idle_right.png'))
        
        # Idle left (flipped side view)
        idle_left = idle_right.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        idle_left.save(os.path.join(CHAR_DIR, f'{susp_key}_idle_left.png'))
        
        # Portrait
        portrait = extract_portrait(im_susp, 0, 0, 48)
        portrait.save(os.path.join(PORTRAIT_DIR, f'{susp_key}.png'))
        
    print("=== 3. Processing Edmund Harlow Crime Scene Illustration ===")
    im_scene = Image.open(IMAGE_PATHS['edmund_crime_scene'])
    # Resample to native 480x270 viewport
    scene_480 = im_scene.resize((480, 270), Image.Resampling.LANCZOS)
    scene_480.save(os.path.join(CINEMATIC_DIR, 'cinematic_crime_scene_harlow.png'))
    
    # Inspect views (160x120 for modal box)
    inspect_160 = im_scene.resize((160, 120), Image.Resampling.LANCZOS)
    inspect_160.save(os.path.join(INSPECT_DIR, 'inspect_e01_pocket_watch.png'))
    inspect_160.save(os.path.join(INSPECT_DIR, 'inspect_e04_brandy_poison.png'))
    
    # Extract Edmund in armchair as study corpse prop
    # Corpse is located in left half: x=80..480, y=100..571
    corpse_crop = im_scene.crop((80, 120, 520, 570))
    # Rescale to match armchair in study room (~100x105)
    corpse_prop = corpse_crop.resize((100, 105), Image.Resampling.LANCZOS)
    corpse_prop.save(os.path.join(PROP_DIR, 'study_corpse_harlow.png'))
    
    print("All sprites, portraits, and inspect views integrated successfully!")

if __name__ == '__main__':
    main()
