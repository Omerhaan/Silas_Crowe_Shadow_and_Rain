import os
import glob
from PIL import Image

TARGETS = {
    "silas": 100,
    "hale": 102,
    "julian": 98,
    "pike": 98,
    "margaret": 94,
    "edmund": 98
}

CANVAS_W = 64
CANVAS_H = 104
CHARS_DIR = os.path.join("assets", "sprites", "characters")

def main():
    results = []
    for prefix, target_h in TARGETS.items():
        pattern = os.path.join(CHARS_DIR, f"{prefix}_*.png")
        for path in sorted(glob.glob(pattern)):
            if "preview" in path:
                continue
            fname = os.path.basename(path)
            img = Image.open(path).convert("RGBA")
            bbox = img.getbbox()
            if not bbox:
                continue
            cur_w = bbox[2] - bbox[0]
            cur_h = bbox[3] - bbox[1]

            # Crop to visible pixels
            cropped = img.crop(bbox)

            # If height differs from target_h, scale with NEAREST
            if cur_h != target_h:
                scale_ratio = target_h / float(cur_h)
                new_w = max(1, round(cur_w * scale_ratio))
                new_cropped = cropped.resize((new_w, target_h), Image.Resampling.NEAREST)
            else:
                new_cropped = cropped
                new_w = cur_w

            # Canvas 64x104 with feet bottom-aligned to y = CANVAS_H
            new_img = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
            paste_x = (CANVAS_W - new_w) // 2
            paste_y = CANVAS_H - target_h  # Soles at bottom edge (y=104)
            new_img.paste(new_cropped, (paste_x, paste_y), new_cropped)

            new_bbox = new_img.getbbox()
            final_h = new_bbox[3] - new_bbox[1]
            final_bot_offset = CANVAS_H - new_bbox[3]

            new_img.save(path)
            if "idle_down" in fname:
                results.append((prefix.capitalize(), fname, cur_h, target_h, final_h, final_bot_offset))

    header = f"{'Karakter':12} | {'Sprite':22} | {'Önceki Boy':10} | {'Hedef':6} | {'Son Boy':8} | {'Taban Boşluğu'}"
    print(header)
    print("-" * len(header))
    for r in results:
        print(f"{r[0]:12} | {r[1]:22} | {r[2]} px     | {r[3]} px | {r[4]} px   | {r[5]} px")

if __name__ == "__main__":
    main()
