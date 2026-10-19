#!/usr/bin/env python3
"""
Generate 1x room screenshots and Silas walk cycle GIF for docs/screens/
"""

import os
from pathlib import Path
from PIL import Image

BASE_DIR = Path(__file__).resolve().parent.parent
PLATES_DIR = BASE_DIR / "assets" / "plates"
CHARS_DIR = BASE_DIR / "assets" / "sprites" / "characters"
SHADOW_PATH = BASE_DIR / "assets" / "sprites" / "shadow_silas.png"
OUTPUT_DIR = BASE_DIR / "docs" / "screens"

OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

def paste_char(bg: Image.Image, char_img: Image.Image, shadow_img: Image.Image, x: int, y: int):
    bg.paste(shadow_img, (x - 20, y - 5), shadow_img)
    bg.paste(char_img, (x - 32, y - 100), char_img)

def generate_room_screenshots():
    shadow = Image.open(SHADOW_PATH).convert("RGBA")
    silas_right = Image.open(CHARS_DIR / "silas_idle_right.png").convert("RGBA")
    silas_left = Image.open(CHARS_DIR / "silas_idle_left.png").convert("RGBA")

    room_configs = [
        ("bg_hub_office.png", "room_hub_office_1x.png", [(silas_right, 200, 245)]),
        ("bg_main_hall.png", "room_main_hall_1x.png", [(silas_right, 240, 245)]),
        ("bg_study.png", "room_study_1x.png", [(silas_right, 180, 245)]),
        ("bg_library.png", "room_library_1x.png", [
            (Image.open(CHARS_DIR / "hale_idle_down.png").convert("RGBA"), 185, 245),
            (silas_left, 320, 245)
        ]),
        ("bg_dining_room.png", "room_dining_room_1x.png", [
            (Image.open(CHARS_DIR / "pike_idle_down.png").convert("RGBA"), 155, 245),
            (silas_left, 340, 245)
        ]),
        ("bg_kitchen.png", "room_kitchen_1x.png", [
            (Image.open(CHARS_DIR / "margaret_idle_down.png").convert("RGBA"), 205, 245),
            (silas_left, 320, 245)
        ]),
        ("bg_billiard_room.png", "room_billiard_room_1x.png", [
            (silas_right, 180, 245),
            (Image.open(CHARS_DIR / "julian_idle_down.png").convert("RGBA"), 330, 245)
        ]),
        ("bg_upper_floor.png", "room_upper_floor_1x.png", [(silas_right, 200, 245)]),
    ]

    for plate_name, out_filename, chars in room_configs:
        plate_path = PLATES_DIR / plate_name
        if not plate_path.exists():
            print(f"Warning: {plate_path} does not exist!")
            continue
        bg = Image.open(plate_path).convert("RGBA")
        comp = bg.copy()
        for c_img, cx, cy in chars:
            paste_char(comp, c_img, shadow, cx, cy)
        out_path = OUTPUT_DIR / out_filename
        comp.save(out_path, "PNG")
        print(f"Saved: {out_path.name}")

def generate_silas_walk_animation():
    shadow = Image.open(SHADOW_PATH).convert("RGBA")
    frames = []
    for i in range(1, 7):
        frame_path = CHARS_DIR / f"silas_walk_right_{i}.png"
        img = Image.open(frame_path).convert("RGBA")
        frames.append(img)
        # Also save individual 1x frame
        img.save(OUTPUT_DIR / f"silas_walk_frame_{i}.png", "PNG")

    # 1. Isolated walk cycle GIF (64x104 with shadow)
    cycle_frames = []
    for f in frames:
        c = Image.new("RGBA", (64, 110), (0, 0, 0, 0))
        c.paste(shadow, (12, 95), shadow)
        c.paste(f, (0, 0), f)
        cycle_frames.append(c)

    cycle_gif_path = OUTPUT_DIR / "silas_walk_cycle.gif"
    cycle_frames[0].save(
        cycle_gif_path,
        save_all=True,
        append_images=cycle_frames[1:],
        duration=110,
        loop=0,
        disposal=2
    )
    print(f"Saved: {cycle_gif_path.name}")

    # 2. Main Hall Walk Recording GIF (Silas walking across the 480x270 room)
    hall_bg = Image.open(PLATES_DIR / "bg_main_hall.png").convert("RGBA")
    walk_scene_frames = []
    start_x = 140
    step_dx = 8
    total_steps = 18

    for step in range(total_steps):
        f_idx = step % 6
        cur_x = start_x + (step * step_dx)
        scene_comp = hall_bg.copy()
        paste_char(scene_comp, frames[f_idx], shadow, cur_x, 245)
        walk_scene_frames.append(scene_comp)

    hall_walk_gif = OUTPUT_DIR / "silas_walking_in_hall.gif"
    walk_scene_frames[0].save(
        hall_walk_gif,
        save_all=True,
        append_images=walk_scene_frames[1:],
        duration=100,
        loop=0,
        disposal=2
    )
    print(f"Saved: {hall_walk_gif.name}")

if __name__ == "__main__":
    generate_room_screenshots()
    generate_silas_walk_animation()
