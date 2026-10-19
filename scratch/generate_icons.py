import os
from PIL import Image

def generate_icons():
    src_path = r'C:/Users/omerh/.gemini/antigravity/brain/4575aca9-af2c-40a2-832e-408a15fcebaa/.user_uploaded/media_1792158223675_c2091a16.jpg'
    os.makedirs('assets/icons', exist_ok=True)

    img = Image.open(src_path).convert('RGBA')
    print('Source image loaded:', img.size)

    # 1. Master 1024x1024 PNG
    img.save('assets/icons/game_icon_1024.png', 'PNG')

    # 2. Project root icon.png (512x512)
    icon_512 = img.resize((512, 512), Image.Resampling.LANCZOS)
    icon_512.save('icon.png', 'PNG')
    icon_512.save('assets/icons/game_icon_512.png', 'PNG')

    # 3. Android launcher icons
    icon_192 = img.resize((192, 192), Image.Resampling.LANCZOS)
    icon_192.save('assets/icons/game_icon_192.png', 'PNG')

    icon_128 = img.resize((128, 128), Image.Resampling.LANCZOS)
    icon_128.save('assets/icons/game_icon_128.png', 'PNG')

    icon_48 = img.resize((48, 48), Image.Resampling.LANCZOS)
    icon_48.save('assets/icons/game_icon_48.png', 'PNG')

    # 4. Adaptive icons for Android (432x432 foreground with safe zone padding + background)
    fg_canvas = Image.new('RGBA', (432, 432), (0, 0, 0, 0))
    fg_content = img.resize((320, 320), Image.Resampling.LANCZOS)
    fg_canvas.paste(fg_content, ((432 - 320) // 2, (432 - 320) // 2))
    fg_canvas.save('assets/icons/adaptive_foreground_432.png', 'PNG')

    # Dark noir background for adaptive icon
    bg_canvas = Image.new('RGBA', (432, 432), (8, 10, 18, 255))
    bg_canvas.save('assets/icons/adaptive_background_432.png', 'PNG')

    # 5. Windows multi-size .ico file
    ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
    img.save('icon.ico', format='ICO', sizes=ico_sizes)
    img.save('assets/icons/icon.ico', format='ICO', sizes=ico_sizes)

    print('All icons generated successfully!')
    for f in sorted(os.listdir('assets/icons')):
        fp = os.path.join('assets/icons', f)
        print(f"  assets/icons/{f}: {os.path.getsize(fp)/1024:.1f} KB")
    print(f"  icon.png: {os.path.getsize('icon.png')/1024:.1f} KB")
    print(f"  icon.ico: {os.path.getsize('icon.ico')/1024:.1f} KB")

if __name__ == '__main__':
    generate_icons()
