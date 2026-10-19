import sys
from pathlib import Path
from plate_import import import_plate

BASE_DIR = Path(__file__).resolve().parent.parent
PALETTE_PATH = BASE_DIR / "data" / "palette" / "noir40.hex"

PLATES = [
    ("ana_hol.jpg", "bg_main_hall.png"),
    ("calisma_odasi.jpg", "bg_study.png"),
    ("kutuphane.jpg", "bg_library.png"),
    ("yemek_odasi.jpg", "bg_dining_room.png"),
    ("mutfak.jpg", "bg_kitchen.png"),
    ("bilardo_odasi.jpg", "bg_billiard_room.png"),
    ("ust_kat_koridoru.jpg", "bg_upper_floor.png"),
    ("silasin_ofisi.jpg", "bg_hub_office.png"),
    ("harlowun_yatak_odasi.jpg", "bg_harlow_bedroom.png"),
    ("julianın_odasi.jpg", "bg_julian_room.png"),
    ("pikein_odasi.jpg", "bg_pike_room.png"),
]

def main():
    src_dir = BASE_DIR / "assets" / "source" / "plates"
    dst_dir = BASE_DIR / "assets" / "plates"
    for src_name, dst_name in PLATES:
        src_path = src_dir / src_name
        dst_path = dst_dir / dst_name
        if not src_path.exists():
            print(f"Skipping missing: {src_path}")
            continue
        print(f"\nProcessing {src_name} -> {dst_name}...")
        import_plate(src_path, dst_path, PALETTE_PATH, 480, 270)
    print("\nAll plates processed successfully.")

if __name__ == "__main__":
    main()
