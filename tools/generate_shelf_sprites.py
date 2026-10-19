import os
from PIL import Image

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def hex_to_rgba(h, a=255):
    return (*hex_to_rgb(h), a)

# Palette
TRANSPARENT = (0, 0, 0, 0)
SHADOW_DEEP = hex_to_rgba("0b0f1a", 255)
SHADOW_DARK = hex_to_rgba("0d1321", 255)
SHADOW_ALPHA = hex_to_rgba("0b0f1a", 100)
SHADOW_ALPHA_SOFT = hex_to_rgba("0b0f1a", 50)

WOOD_DEEP = hex_to_rgba("2e1d14", 255)
WOOD_DARK = hex_to_rgba("4a2f1d", 255)
WOOD_MEDIUM = hex_to_rgba("8a5a2b", 255)
WOOD_LIGHT = hex_to_rgba("b5803f", 255)
AMBER_WARM = hex_to_rgba("c9783a", 255)
CANDLE_GOLD = hex_to_rgba("e8c872", 255)

IRON_DARK = hex_to_rgba("2b2a2f", 255)
IRON_MID = hex_to_rgba("5a5560", 255)
IRON_LIGHT = hex_to_rgba("8a8691", 255)

# Item colors
GLASS_CYAN = hex_to_rgba("a9c4d4", 230)
GLASS_HIGHLIGHT = hex_to_rgba("f2eadc", 255)
GOLD_BRIGHT = hex_to_rgba("f6e3a1", 255)
INK_BLACK = hex_to_rgba("0d1321", 255)
CHALK_BLUE = hex_to_rgba("2a3a6b", 255)
CHALK_LIGHT = hex_to_rgba("6b8fa3", 255)
CHALK_WHITE = hex_to_rgba("e6dccb", 220)

W = 48
H = 20

def create_base_shelf():
    img = Image.new("RGBA", (W, H), TRANSPARENT)
    pixels = img.load()

    # Drop shadow on wall (y = 8 to 14)
    for x in range(3, W - 3):
        pixels[x, 8] = SHADOW_ALPHA
        pixels[x, 9] = SHADOW_ALPHA_SOFT

    # Wrought iron brackets (Left: x=8..10, Right: x=37..39)
    brackets_x = [8, 37]
    for bx in brackets_x:
        # Vertical wall mount
        for y in range(8, 16):
            pixels[bx, y] = IRON_DARK
            pixels[bx + 1, y] = IRON_MID
            pixels[bx + 2, y] = IRON_DARK
        # Diagonal strut
        pixels[bx + 3, 8] = IRON_MID
        pixels[bx + 3, 9] = IRON_DARK
        pixels[bx + 4, 8] = IRON_LIGHT
        # Little decorative iron curl/rivet
        pixels[bx + 1, 10] = IRON_LIGHT
        pixels[bx + 1, 15] = IRON_DARK

    # Wooden Shelf Plank (x = 2 to W - 3, y = 3 to 7)
    for x in range(2, W - 2):
        # Row 3: Top surface rim highlight
        if x in [2, W - 3]:
            pixels[x, 3] = WOOD_DARK
        elif (x % 7 == 2 or x % 11 == 5):
            pixels[x, 3] = AMBER_WARM
        else:
            pixels[x, 3] = CANDLE_GOLD if (x % 3 == 0) else WOOD_LIGHT

        # Row 4: Top surface wood plank
        if (x % 5 == 1 or x % 9 == 4):
            pixels[x, 4] = WOOD_DARK # wood grain
        else:
            pixels[x, 4] = WOOD_MEDIUM

        # Row 5: Front face upper
        if (x % 8 == 3):
            pixels[x, 5] = WOOD_DEEP
        else:
            pixels[x, 5] = WOOD_DARK

        # Row 6: Front face lower
        pixels[x, 6] = WOOD_DEEP

        # Row 7: Under plank shadow line
        pixels[x, 7] = SHADOW_DEEP

    # Left & Right plank end caps
    pixels[1, 4] = WOOD_DARK
    pixels[1, 5] = WOOD_DEEP
    pixels[W - 2, 4] = WOOD_DARK
    pixels[W - 2, 5] = WOOD_DEEP

    return img

def create_shelf_with_pen():
    img = create_base_shelf()
    pixels = img.load()
    cx = 24 # center of shelf

    # Crystal base (octagonal glass holder at x=21..27, y=0..3)
    # Glass block
    for x in range(cx - 3, cx + 4):
        for y in range(0, 3):
            pixels[x, y] = GLASS_CYAN
    pixels[cx - 3, 0] = TRANSPARENT
    pixels[cx + 3, 0] = TRANSPARENT
    # Highlights
    pixels[cx - 2, 0] = GLASS_HIGHLIGHT
    pixels[cx - 1, 1] = GLASS_HIGHLIGHT
    pixels[cx, 2] = GOLD_BRIGHT # brass ring

    # Tilted fountain pen (stem tilted up-right)
    # Pen body
    pen_coords = [(cx, 1), (cx + 1, 0), (cx + 2, -1), (cx + 3, -2), (cx + 4, -3), (cx + 5, -4)]
    for px, py in pen_coords:
        if 0 <= py < H and 0 <= px < W:
            pixels[px, py] = INK_BLACK
    # Gold nib
    if 0 <= cx - 1 < W:
        pixels[cx - 1, 2] = GOLD_BRIGHT
    # Gold pen clip
    if 0 <= cx + 4 < W:
        pixels[cx + 4, 0] = GOLD_BRIGHT
        pixels[cx + 3, -1] = GOLD_BRIGHT

    return img

def create_shelf_with_key():
    img = create_base_shelf()
    pixels = img.load()
    cx = 22

    # Vintage Manor Skeleton Key lying flat on shelf (x = 18 to 30, y = 1..2)
    # Bow (handle ring)
    pixels[cx - 4, 1] = GOLD_BRIGHT
    pixels[cx - 4, 2] = AMBER_WARM
    pixels[cx - 3, 0] = GOLD_BRIGHT
    pixels[cx - 3, 3] = AMBER_WARM
    pixels[cx - 2, 1] = GOLD_BRIGHT
    pixels[cx - 2, 2] = AMBER_WARM
    # Key shaft
    for x in range(cx - 1, cx + 7):
        pixels[x, 1] = GOLD_BRIGHT
        pixels[x, 2] = AMBER_WARM
    # Bit / teeth
    pixels[cx + 5, 0] = GOLD_BRIGHT
    pixels[cx + 6, 0] = AMBER_WARM
    pixels[cx + 6, -1] = GOLD_BRIGHT

    return img

def create_shelf_with_chalk():
    img = create_base_shelf()
    pixels = img.load()
    cx = 24

    # Cube of billiard chalk (x = 21..27, y = 0..3)
    for x in range(cx - 3, cx + 4):
        for y in range(0, 3):
            pixels[x, y] = CHALK_BLUE
    # Top surface (light blue with chalk indentation)
    for x in range(cx - 3, cx + 4):
        pixels[x, 0] = CHALK_LIGHT
    # Dimple / chalk hole in center
    pixels[cx, 0] = INK_BLACK
    pixels[cx - 1, 0] = CHALK_BLUE
    # Chalk paper wrapping
    for x in range(cx - 3, cx + 4):
        pixels[x, 2] = CHALK_WHITE

    # A few stray blue chalk dust specks on wood
    pixels[cx - 4, 3] = CHALK_LIGHT
    pixels[cx + 4, 3] = CHALK_LIGHT
    pixels[cx + 5, 3] = CHALK_BLUE

    return img

def main():
    out_dir = "assets/sprites/props"
    os.makedirs(out_dir, exist_ok=True)

    base = create_base_shelf()
    base.save(os.path.join(out_dir, "silas_souvenir_shelf.png"))

    pen = create_shelf_with_pen()
    pen.save(os.path.join(out_dir, "silas_souvenir_shelf_pen.png"))

    key = create_shelf_with_key()
    key.save(os.path.join(out_dir, "silas_souvenir_shelf_key.png"))

    chalk = create_shelf_with_chalk()
    chalk.save(os.path.join(out_dir, "silas_souvenir_shelf_chalk.png"))

    print("Successfully generated shelf sprites in", out_dir)

if __name__ == "__main__":
    main()
