import os
import shutil
from PIL import Image, ImageOps, ImageDraw

BASE_DIR = os.path.abspath(".")
SRC_DOWNLOADS = r"C:\Users\omerh\Downloads"
DEST_RAW = os.path.join(BASE_DIR, "cases", "case01", "assets", "raw")
DEST_CHARS = os.path.join(BASE_DIR, "cases", "case01", "assets", "characters")
GLOBAL_PORTRAITS = os.path.join(BASE_DIR, "assets", "portraits")

os.makedirs(DEST_RAW, exist_ok=True)
os.makedirs(DEST_CHARS, exist_ok=True)
os.makedirs(GLOBAL_PORTRAITS, exist_ok=True)

CHAR_MAP = {
    "julian": "Julian Harlow.jpg",
    "hale": "Dr. Victor Hale.jpg",
    "margaret": "Margaret Doyle.jpg",
    "pike": "Raymond Pike.jpg"
}

print("=== 1. Copying raw files to cases/case01/assets/raw ===")
for char_id, src_filename in CHAR_MAP.items():
    src_path = os.path.join(SRC_DOWNLOADS, src_filename)
    dst_path = os.path.join(DEST_RAW, f"{char_id}.jpg")
    if os.path.exists(src_path):
        shutil.copy2(src_path, dst_path)
        print(f"Copied {src_filename} -> {dst_path}")
    else:
        print(f"ERROR: {src_path} not found!")

# Also copy Edmund Harlow if exists
edmund_src = os.path.join(SRC_DOWNLOADS, "Sir Edmund Harlow.jpg")
if os.path.exists(edmund_src):
    shutil.copy2(edmund_src, os.path.join(DEST_RAW, "edmund.jpg"))
    print("Copied Sir Edmund Harlow.jpg -> edmund.jpg")

print("\n=== 2. Generating optimized portraits (192x192 & 128x128) ===")
for char_id in CHAR_MAP.keys():
    raw_path = os.path.join(DEST_RAW, f"{char_id}.jpg")
    if not os.path.exists(raw_path):
        continue

    with Image.open(raw_path) as img:
        img_rgb = img.convert("RGB")
        w, h = img_rgb.size
        
        # Center square crop (should already be 2048x2048, but ensure exact square)
        min_dim = min(w, h)
        left = (w - min_dim) // 2
        top = (h - min_dim) // 2
        square_crop = img_rgb.crop((left, top, left + min_dim, top + min_dim))
        
        # 1. Preview portrait: 192x192 for notebook
        preview_192 = square_crop.resize((192, 192), Image.Resampling.LANCZOS)
        preview_path = os.path.join(DEST_CHARS, f"{char_id}_preview.png")
        preview_192.save(preview_path, format="PNG", optimize=True)
        print(f"Saved {preview_path} ({os.path.getsize(preview_path)} bytes)")
        
        # 2. Main portrait: 128x128 for dialogue & interrogation
        portrait_128 = square_crop.resize((128, 128), Image.Resampling.LANCZOS)
        portrait_path = os.path.join(DEST_CHARS, f"{char_id}.png")
        portrait_128.save(portrait_path, format="PNG", optimize=True)
        print(f"Saved {portrait_path} ({os.path.getsize(portrait_path)} bytes)")
        
        # Also copy to global portraits for fallback
        global_path = os.path.join(GLOBAL_PORTRAITS, f"{char_id}.png")
        shutil.copy2(portrait_path, global_path)

print("\n=== 3. Cleaning up old .import cache files ===")
for char_id in CHAR_MAP.keys():
    for base in [DEST_CHARS, GLOBAL_PORTRAITS]:
        imp = os.path.join(base, f"{char_id}.png.import")
        if os.path.exists(imp):
            os.remove(imp)
            print(f"Removed {imp}")
        imp_prev = os.path.join(base, f"{char_id}_preview.png.import")
        if os.path.exists(imp_prev):
            os.remove(imp_prev)
            print(f"Removed {imp_prev}")

print("\nDone.")
