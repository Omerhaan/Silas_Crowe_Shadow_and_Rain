# AI Generation Log & Style Guide (Gölge ve Yağmur)

## 1. Style Anchor & Specifications
- **Perspective:** Side-view cross section (Revizyon 2)
- **Resolution:** 320x180 base viewport, integer scaling, nearest texture filtering
- **Character Sprite Size:** 32x48 (transparent RGBA8 PNG)
- **Dialogue Portrait Size:** 48x48
- **Inspect View Area:** 192x128
- **Color Palette:** 24 colors (`data/palette/noir24.hex`)
- **Accent Red:** `#b0302c` strictly reserved for accents (badge, blood, flashback focal point)

## 2. Common Style Prefix
```text
pixel art, 1940s film noir, side view, limited dark palette (navy, burgundy, muted yellow candlelight),
chunky visible pixels, no anti-aliasing, no gradients, no text, high contrast lighting, moody
```

## 3. Automation Tooling
- Run `python tools/pixelize.py <input> <output> --size 32x48 --palette data/palette/noir24.hex --key magenta --outline`
- For directory batches: `python tools/pixelize.py --batch <folder> --size 32x48 --palette data/palette/noir24.hex`
