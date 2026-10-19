import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

TARGET_DIR_INSPECT = "assets/sprites/inspect"
TARGET_DIR_CASE = "cases/case02/assets/clues"
os.makedirs(TARGET_DIR_INSPECT, exist_ok=True)
os.makedirs(TARGET_DIR_CASE, exist_ok=True)

# 1. E201: Snapped Crane Cable from cinematic_case02_06_crane_sabotage.jpg
try:
    im_crane = Image.open("cases/case02/assets/cinematics/cinematic_case02_06_crane_sabotage.jpg")
    # Crop the frayed cable and winch gear
    w, h = im_crane.size
    crop_box = (int(w * 0.05), int(h * 0.15), int(w * 0.90), int(h * 0.90))
    cropped = im_crane.crop(crop_box).resize((160, 120), Image.Resampling.LANCZOS)
    cropped.save(f"{TARGET_DIR_INSPECT}/inspect_e201_crane_cable.png")
    cropped.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e201_crane_cable_preview.png")
    cropped.save(f"{TARGET_DIR_CASE}/clue_e201_crane_cable.png")
    print("[OK] E201 created")
except Exception as e:
    print("[ERR] E201 error:", e)

# 2. E207: Typewriter Note from clue_typewriter_letter.png
try:
    im_let = Image.open("cases/case02/assets/clues/clue_typewriter_letter.png")
    w, h = im_let.size
    crop_box = (int(w * 0.12), int(h * 0.08), int(w * 0.88), int(h * 0.92))
    cropped = im_let.crop(crop_box).resize((160, 120), Image.Resampling.LANCZOS)
    cropped.save(f"{TARGET_DIR_INSPECT}/inspect_e207_typewriter_note.png")
    cropped.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e207_typewriter_note_preview.png")
    cropped.save(f"{TARGET_DIR_CASE}/clue_e207_typewriter_note.png")
    print("[OK] E207 created")
except Exception as e:
    print("[ERR] E207 error:", e)

# 3. E208: K-3 Watch (Front) from clue_k3_watch.png
try:
    im_w = Image.open("cases/case02/assets/clues/clue_k3_watch.png")
    w, h = im_w.size
    # Watch dial area
    crop_box = (int(w * 0.20), int(h * 0.15), int(w * 0.65), int(h * 0.85))
    cropped = im_w.crop(crop_box).resize((160, 120), Image.Resampling.LANCZOS)
    cropped.save(f"{TARGET_DIR_INSPECT}/inspect_e208_k3_watch.png")
    cropped.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e208_k3_watch_preview.png")
    cropped.save(f"{TARGET_DIR_CASE}/clue_k3_watch.png")
    print("[OK] E208 front created")
except Exception as e:
    print("[ERR] E208 error:", e)

# 4. E208_back: K-3 Watch (Back Lid) from clue_k3_watch.png
try:
    im_w = Image.open("cases/case02/assets/clues/clue_k3_watch.png")
    w, h = im_w.size
    # Watch open lid with K-3 engraving
    crop_box = (int(w * 0.35), int(h * 0.35), int(w * 0.75), int(h * 0.90))
    cropped = im_w.crop(crop_box).resize((160, 120), Image.Resampling.LANCZOS)
    cropped.save(f"{TARGET_DIR_INSPECT}/inspect_e208_k3_watch_back.png")
    cropped.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e208_k3_watch_back_preview.png")
    print("[OK] E208 back created")
except Exception as e:
    print("[ERR] E208 back error:", e)

# 5. E205: Radio Logbook Page from clue_k3_watch.png
try:
    im_w = Image.open("cases/case02/assets/clues/clue_k3_watch.png")
    w, h = im_w.size
    # Right page of logbook showing frequency columns and notes
    crop_box = (int(w * 0.45), int(h * 0.05), int(w * 0.98), int(h * 0.80))
    cropped = im_w.crop(crop_box).resize((160, 120), Image.Resampling.LANCZOS)
    cropped.save(f"{TARGET_DIR_INSPECT}/inspect_e205_radio_logbook.png")
    cropped.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e205_radio_logbook_preview.png")
    cropped.save(f"{TARGET_DIR_CASE}/clue_e205_radio_logbook.png")
    print("[OK] E205 created")
except Exception as e:
    print("[ERR] E205 error:", e)

# 6. E202: Military Crate (Pixel Art)
im_crate = Image.new("RGB", (160, 120), (13, 19, 33))
d = ImageDraw.Draw(im_crate)
# Wooden floor
d.rectangle([0, 95, 160, 120], fill=(46, 29, 20))
# Wooden crate
d.rectangle([25, 25, 135, 95], fill=(74, 47, 29), outline=(46, 29, 20), width=2)
# Slats
for y in range(40, 95, 15):
    d.line([25, y, 135, y], fill=(46, 29, 20), width=1)
# Cross brace
d.line([25, 25, 135, 95], fill=(138, 90, 43), width=2)
d.line([25, 95, 135, 25], fill=(138, 90, 43), width=2)
# Metal corner braces
for cx, cy in [(25, 25), (135, 25), (25, 95), (135, 95)]:
    d.rectangle([cx-4, cy-4, cx+4, cy+4], fill=(90, 85, 96), outline=(43, 42, 47))
# Stencil text on crate: "1944 - KUZEY"
d.rectangle([45, 45, 115, 62], fill=(46, 29, 20))
d.text((48, 48), "KUZEY - 1944", fill=(190, 180, 150))
# Broken wax seal
d.ellipse([110, 68, 126, 84], fill=(176, 48, 44), outline=(126, 47, 58))
im_crate.save(f"{TARGET_DIR_INSPECT}/inspect_e202_military_crate.png")
im_crate.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e202_military_crate_preview.png")
im_crate.save(f"{TARGET_DIR_CASE}/clue_e202_military_crate.png")
print("[OK] E202 created")

# 7. E203: Bloody Brass Lantern (Pixel Art)
im_lan = Image.new("RGB", (160, 120), (11, 15, 26))
d = ImageDraw.Draw(im_lan)
# Stone floor
d.rectangle([0, 90, 160, 120], fill=(43, 42, 47))
# Blood pool on stone
d.ellipse([45, 92, 115, 108], fill=(126, 47, 58))
d.ellipse([55, 95, 95, 105], fill=(176, 48, 44))
# Brass lantern body
d.rectangle([55, 35, 105, 95], fill=(181, 128, 63), outline=(74, 47, 29), width=2)
# Glass chamber
d.rectangle([65, 45, 95, 85], fill=(230, 220, 203), outline=(138, 90, 43))
# Cracked glass line
d.line([65, 55, 80, 70], fill=(43, 42, 47), width=1)
d.line([80, 70, 75, 85], fill=(43, 42, 47), width=1)
d.line([80, 70, 95, 65], fill=(43, 42, 47), width=1)
# Extinguished candle / wick inside
d.rectangle([77, 65, 83, 85], fill=(90, 85, 96))
# Top brass dome and loop
d.ellipse([65, 20, 95, 38], fill=(201, 120, 58), outline=(74, 47, 29), width=2)
d.ellipse([72, 8, 88, 24], outline=(181, 128, 63), width=2)
# Blood smear on brass base
d.polygon([(90, 85), (105, 85), (105, 98), (85, 98)], fill=(176, 48, 44))
# Hair strand
d.line([98, 88, 108, 96], fill=(11, 15, 26), width=1)
im_lan.save(f"{TARGET_DIR_INSPECT}/inspect_e203_bloody_lantern.png")
im_lan.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e203_bloody_lantern_preview.png")
im_lan.save(f"{TARGET_DIR_CASE}/clue_e203_bloody_lantern.png")
print("[OK] E203 created")

# 8. E204: Acid-Stained Captain's Coat (Pixel Art)
im_coat = Image.new("RGB", (160, 120), (13, 19, 33))
d = ImageDraw.Draw(im_coat)
# Wall planks
for y in range(0, 120, 16):
    d.line([0, y, 160, y], fill=(46, 29, 20), width=1)
# Coat body hanging
d.polygon([(80, 15), (50, 45), (40, 115), (120, 115), (110, 45)], fill=(29, 43, 83), outline=(13, 19, 33), width=2)
# Lapels and collar
d.polygon([(80, 15), (65, 45), (80, 65), (95, 45)], fill=(42, 58, 107))
# Brass buttons
for by in [45, 65, 85]:
    d.ellipse([77, by, 83, by+6], fill=(232, 200, 114))
# Right sleeve with acid burn
d.polygon([(110, 45), (135, 75), (130, 95), (105, 65)], fill=(29, 43, 83), outline=(13, 19, 33))
# Acid burn holes and discoloration on cuff
d.ellipse([120, 80, 134, 94], fill=(62, 74, 71), outline=(92, 107, 99))
d.ellipse([123, 83, 130, 90], fill=(47, 90, 110))
d.ellipse([125, 85, 128, 88], fill=(11, 15, 26)) # Burn-through hole
# Metal shavings / iron dust specks
for spx, spy in [(118, 78), (126, 76), (132, 85), (120, 92), (128, 95)]:
    d.point((spx, spy), fill=(169, 196, 212))
im_coat.save(f"{TARGET_DIR_INSPECT}/inspect_e204_acid_coat.png")
im_coat.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e204_acid_coat_preview.png")
im_coat.save(f"{TARGET_DIR_CASE}/clue_e204_acid_coat.png")
print("[OK] E204 created")

# 9. E206: Tide & Duty Chart (Pixel Art)
im_tide = Image.new("RGB", (160, 120), (13, 19, 33))
d = ImageDraw.Draw(im_tide)
# Paper parchment
d.rectangle([20, 12, 140, 108], fill=(230, 220, 203), outline=(74, 47, 29), width=2)
# Header
d.rectangle([25, 16, 135, 26], fill=(42, 58, 107))
d.text((32, 17), "PORT TIDE & DUTY ROSTER", fill=(242, 234, 220))
# Table grid
for y in range(32, 95, 12):
    d.line([25, y, 135, y], fill=(138, 134, 145), width=1)
d.line([65, 26, 65, 95], fill=(138, 134, 145), width=1)
d.line([100, 26, 100, 95], fill=(138, 134, 145), width=1)
# Red highlight box around 02:15 - 02:45
d.rectangle([26, 56, 134, 69], outline=(176, 48, 44), width=2)
d.text((30, 58), "02:30", fill=(176, 48, 44))
d.text((70, 58), "HIGH TIDE", fill=(176, 48, 44))
d.text((105, 58), "UNGUARDED", fill=(176, 48, 44))
# Official stamps
d.ellipse([105, 75, 130, 100], outline=(162, 74, 79), width=2)
d.text((109, 82), "PORT", fill=(162, 74, 79))
im_tide.save(f"{TARGET_DIR_INSPECT}/inspect_e206_tide_chart.png")
im_tide.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e206_tide_chart_preview.png")
im_tide.save(f"{TARGET_DIR_CASE}/clue_e206_tide_chart.png")
print("[OK] E206 created")

# 10. E209: Stamped Night Pass Permit (Pixel Art)
im_pass = Image.new("RGB", (160, 120), (13, 19, 33))
d = ImageDraw.Draw(im_pass)
# Parchment certificate
d.rectangle([25, 15, 135, 105], fill=(242, 234, 220), outline=(90, 85, 96), width=2)
# Ornate border
d.rectangle([28, 18, 132, 102], outline=(181, 128, 63), width=1)
# Header
d.rectangle([35, 24, 125, 34], fill=(42, 58, 107))
d.text((40, 25), "NIGHT HARBOR PASS", fill=(246, 227, 161))
# Text lines
for y in range(42, 75, 8):
    d.line([36, y, 124, y], fill=(138, 134, 145), width=1)
# Official Red Wax Seal
d.ellipse([95, 72, 125, 98], fill=(176, 48, 44), outline=(126, 47, 58), width=2)
d.text((102, 80), "SEAL", fill=(242, 234, 220))
# Handwritten signature
d.line([38, 85, 80, 85], fill=(11, 15, 26), width=1)
d.text((40, 75), "A. Morris", fill=(13, 19, 33))
im_pass.save(f"{TARGET_DIR_INSPECT}/inspect_e209_night_pass.png")
im_pass.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e209_night_pass_preview.png")
im_pass.save(f"{TARGET_DIR_CASE}/clue_e209_night_pass.png")
print("[OK] E209 created")

# 11. E210: Bribe Ledger (Pixel Art)
im_bribe = Image.new("RGB", (160, 120), (13, 19, 33))
d = ImageDraw.Draw(im_bribe)
# Green leather book cover
d.rectangle([15, 10, 145, 110], fill=(62, 74, 71), outline=(43, 42, 47), width=3)
# Open pages
d.rectangle([25, 18, 135, 102], fill=(230, 220, 203), outline=(90, 85, 96), width=1)
d.line([80, 18, 80, 102], fill=(90, 85, 96), width=2) # Center spine
# Column lines on pages
d.line([48, 22, 48, 98], fill=(162, 74, 79), width=1)
d.line([105, 22, 105, 98], fill=(162, 74, 79), width=1)
# Handwritten entries
d.text((30, 25), "PAYEE", fill=(43, 42, 47))
d.text((52, 25), "AMOUNT", fill=(43, 42, 47))
d.text((30, 40), "Vance", fill=(11, 15, 26))
d.text((52, 40), "£ 250", fill=(176, 48, 44))
d.text((30, 55), "Corley", fill=(11, 15, 26))
d.text((52, 55), "£ 400", fill=(176, 48, 44))
d.text((30, 70), "Morris", fill=(11, 15, 26))
d.text((52, 70), "£ 150", fill=(176, 48, 44))
# Right page entries
d.text((85, 25), "DATE", fill=(43, 42, 47))
d.text((110, 25), "STATUS", fill=(43, 42, 47))
d.text((85, 40), "12 Oct", fill=(11, 15, 26))
d.text((110, 40), "PAID", fill=(63, 107, 79))
d.text((85, 55), "13 Oct", fill=(11, 15, 26))
d.text((110, 55), "PAID", fill=(63, 107, 79))
d.text((85, 70), "14 Oct", fill=(11, 15, 26))
d.text((110, 70), "DUE", fill=(176, 48, 44))
im_bribe.save(f"{TARGET_DIR_INSPECT}/inspect_e201_bribe_ledger.png") # duplicate safeguard
im_bribe.save(f"{TARGET_DIR_INSPECT}/inspect_e210_bribe_ledger.png")
im_bribe.resize((640, 480), Image.Resampling.NEAREST).save(f"{TARGET_DIR_INSPECT}/inspect_e210_bribe_ledger_preview.png")
im_bribe.save(f"{TARGET_DIR_CASE}/clue_e210_bribe_ledger.png")
print("[OK] E210 created")

print("ALL CASE 2 INSPECT ASSETS SUCCESSFULLY GENERATED!")
