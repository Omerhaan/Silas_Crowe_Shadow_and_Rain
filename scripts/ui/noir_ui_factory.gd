class_name NoirUIFactory
extends RefCounted

const NoirPalette = preload("res://scripts/core/noir_palette.gd")

static func create_dialog_panel_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = NoirPalette.SHADOW_DARK # 0d1321
	sb.border_color = NoirPalette.SLATE_MID # 5a5560
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(6)
	return sb

static func create_inner_voice_panel_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = NoirPalette.SHADOW_DEEP # 0b0f1a
	sb.border_color = NoirPalette.NIGHT_NAVY_MID # 2a3a6b
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(6)
	return sb

static func create_notebook_page_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = NoirPalette.PAPER_WARM # e6dccb
	sb.border_color = NoirPalette.WOOD_DARK # 4a2f1d
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(8)
	return sb

static func create_card_style() -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = NoirPalette.SLATE_DARK # 2b2a2f
	sb.border_color = NoirPalette.SLATE_MID # 5a5560
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(4)
	return sb

static func create_button_style(state: String = "normal") -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(1)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3

	match state:
		"hover":
			sb.bg_color = NoirPalette.SLATE_MID # 5a5560
			sb.border_color = NoirPalette.CANDLE_GOLD # e8c872
		"pressed":
			sb.bg_color = NoirPalette.SHADOW_DEEP # 0b0f1a
			sb.border_color = NoirPalette.AMBER_WARM # c9783a
		"disabled":
			sb.bg_color = NoirPalette.SHADOW_DARK # 0d1321
			sb.border_color = NoirPalette.SLATE_DARK # 2b2a2f
		_: # normal
			sb.bg_color = NoirPalette.SLATE_DARK # 2b2a2f
			sb.border_color = NoirPalette.SLATE_MID # 5a5560
	return sb

static func create_icon(icon_name: String, size: int = 16) -> ImageTexture:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0)) # Transparent background

	match icon_name:
		"notebook":
			# 16x16 Leather notebook with bookmark ribbon
			for y in range(2, 14):
				for x in range(3, 13):
					img.set_pixel(x, y, NoirPalette.WOOD_DARK)
			# Page edges
			for y in range(3, 13):
				img.set_pixel(12, y, NoirPalette.PAPER_LIGHT)
			# Spine
			for y in range(2, 14):
				img.set_pixel(3, y, NoirPalette.WOOD_DEEP)
			# Red bookmark ribbon (accent red)
			for y in range(2, 8):
				img.set_pixel(7, y, NoirPalette.ACCENT_RED)
			# 1px Dark Outline
			_draw_box_outline(img, Rect2i(2, 1, 12, 14), NoirPalette.SHADOW_DEEP)

		"accuse":
			# Gavel / warning accent icon
			for y in range(3, 7):
				for x in range(4, 12):
					img.set_pixel(x, y, NoirPalette.WOOD_DARK)
			# Gavel handle
			for y in range(7, 13):
				img.set_pixel(8, y, NoirPalette.WOOD_MEDIUM)
				img.set_pixel(7, y, NoirPalette.WOOD_MEDIUM)
			# Accent highlight
			img.set_pixel(4, 3, NoirPalette.ACCENT_RED)
			img.set_pixel(11, 3, NoirPalette.ACCENT_RED)

		"settings":
			# Minimalist gear icon
			var cx = size / 2
			var cy = size / 2
			for y in range(cy - 4, cy + 5):
				for x in range(cx - 4, cx + 5):
					if abs(x - cx) + abs(y - cy) <= 5:
						img.set_pixel(x, y, NoirPalette.SLATE_LIGHT)
			# Center hole
			for y in range(cy - 1, cy + 2):
				for x in range(cx - 1, cx + 2):
					img.set_pixel(x, y, Color(0, 0, 0, 0))

		"star":
			# 8-point evidence star (gold)
			var cx = size / 2
			var cy = size / 2
			for i in range(-3, 4):
				img.set_pixel(cx + i, cy, NoirPalette.CANDLE_GOLD)
				img.set_pixel(cx, cy + i, NoirPalette.CANDLE_GOLD)
			img.set_pixel(cx - 1, cy - 1, NoirPalette.AMBER_WARM)
			img.set_pixel(cx + 1, cy - 1, NoirPalette.AMBER_WARM)
			img.set_pixel(cx - 1, cy + 1, NoirPalette.AMBER_WARM)
			img.set_pixel(cx + 1, cy + 1, NoirPalette.AMBER_WARM)

		"clock":
			# 16x16 Pocket watch stopped at 03:12
			var cx = size / 2
			var cy = size / 2 + 1
			# Ring
			for a in range(16):
				var angle = a * (TAU / 16.0)
				var px = int(round(cx + cos(angle) * 5.0))
				var py = int(round(cy + sin(angle) * 5.0))
				if px >= 0 and px < size and py >= 0 and py < size:
					img.set_pixel(px, py, NoirPalette.SLATE_LIGHT)
			# Face
			for y in range(cy - 3, cy + 4):
				for x in range(cx - 3, cx + 4):
					if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= 9:
						img.set_pixel(x, y, NoirPalette.PAPER_LIGHT)
			# Center & hands (pointing 03:12)
			img.set_pixel(cx, cy, NoirPalette.SHADOW_DEEP)
			img.set_pixel(cx + 1, cy, NoirPalette.SHADOW_DEEP)
			img.set_pixel(cx + 2, cy, NoirPalette.SHADOW_DEEP)
			img.set_pixel(cx + 1, cy - 2, NoirPalette.SHADOW_DEEP)

		"door":
			for y in range(2, 14):
				for x in range(4, 12):
					img.set_pixel(x, y, NoirPalette.WOOD_DARK)
			img.set_pixel(10, 8, NoirPalette.CANDLE_GOLD) # knob

		_:
			for y in range(2, size - 2):
				for x in range(2, size - 2):
					img.set_pixel(x, y, NoirPalette.SLATE_MID)

	return ImageTexture.create_from_image(img)

static func _draw_box_outline(img: Image, rect: Rect2i, col: Color) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		if x >= 0 and x < img.get_width():
			if rect.position.y >= 0 and rect.position.y < img.get_height():
				img.set_pixel(x, rect.position.y, col)
			var by = rect.position.y + rect.size.y - 1
			if by >= 0 and by < img.get_height():
				img.set_pixel(x, by, col)
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		if y >= 0 and y < img.get_height():
			if rect.position.x >= 0 and rect.position.x < img.get_width():
				img.set_pixel(rect.position.x, y, col)
			var rx = rect.position.x + rect.size.x - 1
			if rx >= 0 and rx < img.get_width():
				img.set_pixel(rx, y, col)
