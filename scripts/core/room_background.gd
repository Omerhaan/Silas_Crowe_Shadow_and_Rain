class_name RoomBackground
extends Node2D

## Procedural Noir Room Cross-Section Background (320x180)
## Strict zone layout:
##   y: 0..10   - Korniş (Ceiling crown molding)
##   y: 10..100 - Üst Duvar (Upper wall wallpaper + age/stain details)
##   y: 100..132- Lambri (3-tone wainscoting wood panels)
##   y: 132..137- Süpürgelik (Baseboard / skirting board)
##   y: 137..180- Zemin (Floor wood planks)
## Baseline foot level: y = 168

const NoirPalette = preload("res://scripts/core/noir_palette.gd")

@export var room_theme: String = "study" # "study", "main_hall", "library", "dining_room", "silas_office"
@export var show_window: bool = true
@export var window_pos_x: float = 160.0

var _bg_texture: Texture2D = null

func _ready() -> void:
	z_index = -10
	generate_background_texture()
	queue_redraw()

func generate_background_texture() -> void:
	var case_id = ""
	var ml = Engine.get_main_loop()
	if ml and ml.root:
		var gs = ml.root.get_node_or_null("GameState")
		if gs:
			case_id = gs.current_case_id

	var candidate_paths = []
	if case_id != "":
		candidate_paths.append("res://cases/%s/assets/plates/bg_%s.png" % [case_id, room_theme])
		candidate_paths.append("res://cases/%s/assets/plates/bg_%s.jpg" % [case_id, room_theme])
	candidate_paths.append("res://assets/plates/bg_%s.png" % room_theme)
	candidate_paths.append("res://assets/plates/bg_%s.jpg" % room_theme)
	candidate_paths.append("res://assets/sprites/backgrounds/bg_%s.png" % room_theme)
	candidate_paths.append("res://assets/sprites/backgrounds/bg_%s.jpg" % room_theme)

	for p in candidate_paths:
		var gp = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(gp):
			var img_loaded = Image.load_from_file(gp)
			if img_loaded:
				_bg_texture = ImageTexture.create_from_image(img_loaded)
				return
		if ResourceLoader.exists(p):
			_bg_texture = load(p)
			if _bg_texture:
				return

	var img = Image.create(320, 180, false, Image.FORMAT_RGBA8)

	var wall_base = NoirPalette.PETROL_DARK
	var wall_pattern = NoirPalette.PETROL_MID
	var wood_base = NoirPalette.WOOD_DARK
	var wood_shadow = NoirPalette.WOOD_DEEP
	var wood_high = NoirPalette.WOOD_MEDIUM

	match room_theme:
		"main_hall":
			wall_base = NoirPalette.PLUM_DARK
			wall_pattern = NoirPalette.PLUM_LIGHT
		"library":
			wall_base = NoirPalette.GREEN_DARK
			wall_pattern = NoirPalette.SAGE_MID
		"dining_room":
			wall_base = NoirPalette.CRIMSON_DEEP
			wall_pattern = NoirPalette.CRIMSON_MID
		"kitchen":
			wall_base = NoirPalette.SLATE_DARK
			wall_pattern = NoirPalette.SAGE_MID
		"billiard_room":
			wall_base = NoirPalette.GREEN_DARK
			wall_pattern = NoirPalette.GREEN_MOSS
		"upper_floor":
			wall_base = NoirPalette.DUSK_PURPLE_DARK
			wall_pattern = NoirPalette.DUSK_PURPLE_MID
		"silas_office", "hub_office":
			wall_base = NoirPalette.SLATE_DARK
			wall_pattern = NoirPalette.SLATE_MID
		"dock_warehouse":
			wall_base = NoirPalette.PETROL_DARK
			wall_pattern = NoirPalette.RAIN_BLUE
		"dock_pier":
			wall_base = NoirPalette.NIGHT_NAVY_DEEP
			wall_pattern = NoirPalette.RAIN_BLUE
		"dock_office":
			wall_base = NoirPalette.SLATE_DARK
			wall_pattern = NoirPalette.SLATE_MID
		"dock_saloon":
			wall_base = NoirPalette.CRIMSON_DEEP
			wall_pattern = NoirPalette.AMBER_MID
		"captain_cabin":
			wall_base = NoirPalette.WOOD_DEEP
			wall_pattern = NoirPalette.WOOD_DARK
		"opera_foyer":
			wall_base = NoirPalette.PLUM_DARK
			wall_pattern = NoirPalette.AMBER_MID
		"opera_auditorium", "royal_box":
			wall_base = NoirPalette.CRIMSON_DEEP
			wall_pattern = NoirPalette.AMBER_MID
		"backstage":
			wall_base = NoirPalette.WOOD_DEEP
			wall_pattern = NoirPalette.SLATE_DARK
		"prop_room":
			wall_base = NoirPalette.WOOD_DARK
			wall_pattern = NoirPalette.AMBER_MID
		"light_bridge":
			wall_base = NoirPalette.SLATE_DARK
			wall_pattern = NoirPalette.RAIN_BLUE
		"opera_roof":
			wall_base = NoirPalette.NIGHT_NAVY_DEEP
			wall_pattern = NoirPalette.RAIN_BLUE
		_: # study
			wall_base = NoirPalette.PETROL_DARK
			wall_pattern = NoirPalette.PETROL_MID

	# 1. Korniş: y = 0..10
	for y in range(0, 10):
		var col = wood_shadow
		if y in [2, 3]:
			col = wood_high
		elif y in [4, 5, 6]:
			col = wood_base
		elif y in [7, 8]:
			col = wood_shadow
		elif y == 9:
			col = NoirPalette.SHADOW_DEEP
		for x in range(320):
			img.set_pixel(x, y, col)

	# 2. Üst Duvar: y = 10..100 (Tam yükseklikte dolu)
	for y in range(10, 100):
		for x in range(320):
			var col = wall_base
			# Elegant 8px stripe & subtle damask motif
			var in_stripe = (x % 16) in [0, 1, 2]
			var in_diamond = ((x + y) % 12 == 0) or ((x - y) % 12 == 0)
			if in_stripe or (in_diamond and y % 4 == 0):
				col = wall_pattern
			img.set_pixel(x, y, col)

	# Age stains and hairline cracks on upper wall
	_apply_wall_weathering(img, 10, 100)

	# 3. Lambri (Wainscoting): y = 100..132 (3-tone wood panels)
	# Top chair rail molding: y=100..104
	for y in range(100, 104):
		var rail_col = wood_high if y == 101 else (wood_base if y in [102, 103] else wood_shadow)
		for x in range(320):
			img.set_pixel(x, y, rail_col)

	# Wainscoting panels (32px wide repeat with 3-tone bevel)
	for y in range(104, 129):
		for x in range(320):
			var px = x % 40
			var is_panel = px >= 4 and px <= 36 and y >= 107 and y <= 126
			if not is_panel:
				img.set_pixel(x, y, wood_base)
			else:
				# 3-tone shading inside recessed panel
				if px == 4 or y == 107:
					img.set_pixel(x, y, wood_shadow) # Inner top-left shadow
				elif px == 36 or y == 126:
					img.set_pixel(x, y, wood_high) # Inner bottom-right highlight
				else:
					img.set_pixel(x, y, wood_base)

	# Bottom rail of wainscot: y=129..132
	for y in range(129, 132):
		for x in range(320):
			img.set_pixel(x, y, wood_shadow if y == 131 else wood_base)

	# 4. Süpürgelik: y = 132..137
	for y in range(132, 137):
		var base_col = wood_high if y == 132 else (wood_shadow if y in [133, 134, 135] else NoirPalette.SHADOW_DEEP)
		for x in range(320):
			img.set_pixel(x, y, base_col)

	# 5. Zemin (Tahta Döşeme): y = 137..180
	for y in range(137, 180):
		var plank_idx = (y - 137) / 7
		var plank_line = (y - 137) % 7
		var plank_base = wood_base if plank_idx % 2 == 0 else wood_shadow

		for x in range(320):
			var col = plank_base
			if plank_line == 0:
				col = wood_high # Plank top edge highlight
			elif plank_line == 6:
				col = NoirPalette.SHADOW_DEEP # Seam groove
			else:
				# Staggered vertical plank joints every 64px
				var x_offset = (plank_idx % 3) * 22
				if (x + x_offset) % 64 == 0:
					col = NoirPalette.SHADOW_DEEP
				# Occasional wood grain grain streaks
				elif (x + y * 2) % 37 == 0:
					col = wood_high
				# Nail marks near seams
				elif ((x + x_offset) % 64 == 2 or (x + x_offset) % 64 == 62) and plank_line == 3:
					col = NoirPalette.SHADOW_DEEP

			img.set_pixel(x, y, col)

	_bg_texture = ImageTexture.create_from_image(img)

static func _apply_wall_weathering(img: Image, y_min: int, y_max: int) -> void:
	# Subtle deterministic cracks and water stain gradients
	var stain_seeds = [Vector2i(54, 30), Vector2i(210, 45), Vector2i(275, 25)]
	for s in stain_seeds:
		for dy in range(-12, 13):
			for dx in range(-16, 17):
				var px = s.x + dx
				var py = s.y + dy
				if px >= 0 and px < 320 and py >= y_min and py < y_max:
					if dx * dx + dy * dy * 1.8 < 140:
						var orig = img.get_pixel(px, py)
						img.set_pixel(px, py, orig.darkened(0.12))

	# Faint hairline crack
	var cx = 110
	for cy in range(25, 65):
		if cy % 3 == 0:
			cx += (1 if cy % 2 == 0 else -1)
		if cx >= 0 and cx < 320 and cy >= y_min and cy < y_max:
			img.set_pixel(cx, cy, NoirPalette.SHADOW_DARK)

func _draw() -> void:
	if _bg_texture:
		draw_texture(_bg_texture, Vector2.ZERO)

	# Footline guide (invisible during gameplay, but sets accurate floor baseline y=168)
	# draw_line(Vector2(0, 168), Vector2(320, 168), Color(1, 0, 0, 0.3), 1.0)
