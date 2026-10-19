from PIL import Image, ImageDraw

for room in ['bg_main_hall', 'bg_library', 'bg_dining_room']:
    im = Image.open(f'assets/plates/{room}.png')
    draw = ImageDraw.Draw(im)
    for x in range(0, 480, 40):
        draw.line([(x, 0), (x, 270)], fill=(255, 0, 0, 128))
        draw.text((x + 2, 250), str(x), fill=(255, 255, 0))
    im.save(f'scratch/{room}_grid.png')
    print(f'Saved scratch/{room}_grid.png')
