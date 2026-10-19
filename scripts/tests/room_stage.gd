class_name RoomStage
extends Node2D

## Self-contained 320x180 side-view room preview stage.
## Accurately displays the 5 architectural zones (Cornice, Upper Wall, Wainscot, Baseboard, Floor),
## footline y=168, exact prop sizes (Door 40x76, Window 48x56, Desk 64x36, Bookcase 56x90,
## Armchair 64x34, Lamp 12x28, Silas 28x48), 1px contours, 3-tone shading, light cones,
## corner shadows & vignette, screen-edge nav arrows, and compact top bar.

const NoirPalette = preload("res://scripts/core/noir_palette.gd")
const RoomBackgroundScript = preload("res://scripts/core/room_background.gd")
const InteractableScene = preload("res://scenes/entities/interactable.tscn")

@export var room_id: String = "study" # "study" or "main_hall"

var bg: Node2D = null

func _ready() -> void:
	_build_room_stage()

func _build_room_stage() -> void:
	# 1. Background (5 zones)
	bg = RoomBackgroundScript.new()
	bg.room_theme = room_id
	add_child(bg)

	# 2. Props placed along footline y=168
	if room_id == "study":
		_setup_study_props()
	else:
		_setup_main_hall_props()

	# 3. Silas Crowe (28x48, feet at y=168)
	_setup_silas_character()

	# 4. Corner shadows & vignette overlay
	_setup_ambient_lighting()

	# 5. Compact Top Bar & Edge Nav Arrows
	_setup_compact_ui()

func _setup_study_props() -> void:
	# Window: 48x56 at y ≈ 28-84 (center y=56, x=245)
	var win = _create_prop("window", "study_window", Vector2(245, 56))
	add_child(win)

	# Door: 40x76, bottom at y=168 (center x=30, base y=168)
	var door = _create_prop("door", "study_door", Vector2(30, 168))
	add_child(door)

	# Bookcase: 56x90, bottom at y=168 (center x=84, base y=168)
	var bookcase = _create_prop("bookcase", "study_bookcase", Vector2(84, 168))
	add_child(bookcase)

	# Desk: 64x36, bottom at y=168 (center x=165, base y=168)
	var desk = _create_prop("desk", "study_desk", Vector2(165, 168))
	add_child(desk)

	# Lamp: 12x28 sitting on desk (desk top is y=132, so lamp base at y=132)
	var lamp = _create_prop("lamp", "study_lamp", Vector2(188, 132))
	add_child(lamp)

	# Pocket watch & Cognac glass on desk
	var watch = _create_prop("watch", "study_watch", Vector2(148, 129))
	add_child(watch)

	# Armchair: 64x34, bottom at y=168
	var chair = _create_prop("armchair", "study_chair", Vector2(275, 168))
	add_child(chair)

func _setup_main_hall_props() -> void:
	# Grand Door to Study: 40x76, bottom at y=168
	var door_left = _create_prop("door", "hall_door_study", Vector2(35, 168))
	add_child(door_left)

	# Grand Door to Library: 40x76, bottom at y=168
	var door_right = _create_prop("door", "hall_door_library", Vector2(285, 168))
	add_child(door_right)

	# High Mansion Window: 48x56, center at (160, 56) with moonbeam
	var win = _create_prop("window", "hall_window", Vector2(160, 56))
	add_child(win)

	# Fireplace: 64x52, bottom at y=168
	var fireplace = _create_prop("fireplace", "hall_fireplace", Vector2(98, 168))
	add_child(fireplace)

	# Leather Armchair: 64x34, bottom at y=168
	var chair = _create_prop("armchair", "hall_armchair", Vector2(220, 168))
	add_child(chair)

	# Telephone Table / Telephone: bottom at y=168
	var phone = _create_prop("telephone", "hall_phone", Vector2(160, 168))
	add_child(phone)

func _create_prop(type: String, obj_id: String, pos: Vector2) -> Node2D:
	var node = InteractableScene.instantiate()
	node.prop_type = type
	node.object_id = obj_id
	node.position = pos
	return node

func _setup_silas_character() -> void:
	var silas_holder = Node2D.new()
	silas_holder.position = Vector2(132, 168) # Feet touch y=168
	silas_holder.z_index = 5

	# Shadow on floor
	var shadow = ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.4)
	shadow.size = Vector2(16, 4)
	shadow.position = Vector2(-8, -2)
	silas_holder.add_child(shadow)

	# Character sprite (28x48, center at y=-24, bottom at y=0)
	var spr = Sprite2D.new()
	var tex = AssetManager.get_texture("char_silas_idle")
	if not tex and ResourceLoader.exists("res://assets/sprites/characters/silas_idle_right.png"):
		tex = load("res://assets/sprites/characters/silas_idle_right.png")
	if tex:
		spr.texture = tex
	spr.position = Vector2(0, -24)
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	silas_holder.add_child(spr)

	add_child(silas_holder)

func _setup_ambient_lighting() -> void:
	var light_canvas = CanvasGroup.new()
	light_canvas.z_index = 12

	# Vignette & Corner Shadows (using 0b0f1a)
	var vig = ColorRect.new()
	vig.size = Vector2(320, 180)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/film_grain_vignette.gdshader")
	mat.set_shader_parameter("enable_grain", true)
	mat.set_shader_parameter("enable_vignette", true)
	mat.set_shader_parameter("grain_amount", 0.035)
	mat.set_shader_parameter("vignette_intensity", 0.65)
	mat.set_shader_parameter("vignette_color", NoirPalette.SHADOW_DEEP)
	vig.material = mat
	light_canvas.add_child(vig)

	add_child(light_canvas)

func _setup_compact_ui() -> void:
	var ui_root = Control.new()
	ui_root.size = Vector2(320, 180)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.z_index = 20

	# Compact Top Bar (Height 16px)
	var top_bar = PanelContainer.new()
	top_bar.custom_minimum_size = Vector2(320, 16)
	top_bar.position = Vector2(0, 0)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)

	var name_lbl = Label.new()
	name_lbl.text = "Çalışma Odası" if room_id == "study" else "Ana Hol"
	name_lbl.add_theme_font_size_override("font_size", 6)
	name_lbl.add_theme_color_override("font_color", NoirPalette.CANDLE_CREAM)
	hbox.add_child(name_lbl)

	var hint_lbl = Label.new()
	hint_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint_lbl.text = "[A/D]: Yürü • [E/W]: İncele"
	hint_lbl.add_theme_font_size_override("font_size", 5)
	hint_lbl.add_theme_color_override("font_color", NoirPalette.SLATE_LIGHT)
	hbox.add_child(hint_lbl)

	var btn_nb = Button.new()
	btn_nb.text = "Defter"
	btn_nb.custom_minimum_size = Vector2(24, 14)
	btn_nb.add_theme_font_size_override("font_size", 5)
	hbox.add_child(btn_nb)

	var btn_ac = Button.new()
	btn_ac.text = "Suçla"
	btn_ac.custom_minimum_size = Vector2(22, 14)
	btn_ac.add_theme_font_size_override("font_size", 5)
	btn_ac.add_theme_color_override("font_color", NoirPalette.ACCENT_RED)
	hbox.add_child(btn_ac)

	var btn_mn = Button.new()
	btn_mn.text = "⚙"
	btn_mn.custom_minimum_size = Vector2(16, 14)
	btn_mn.add_theme_font_size_override("font_size", 5)
	hbox.add_child(btn_mn)

	top_bar.add_child(hbox)
	ui_root.add_child(top_bar)

	# Screen-edge navigation arrows (≥24x24 px touch targets)
	var btn_left = Button.new()
	btn_left.text = "◀"
	btn_left.custom_minimum_size = Vector2(24, 26)
	btn_left.position = Vector2(2, 138)
	btn_left.add_theme_font_size_override("font_size", 8)
	btn_left.add_theme_color_override("font_color", NoirPalette.CANDLE_CREAM)
	ui_root.add_child(btn_left)

	var btn_right = Button.new()
	btn_right.text = "▶"
	btn_right.custom_minimum_size = Vector2(24, 26)
	btn_right.position = Vector2(294, 138)
	btn_right.add_theme_font_size_override("font_size", 8)
	btn_right.add_theme_color_override("font_color", NoirPalette.CANDLE_CREAM)
	ui_root.add_child(btn_right)

	add_child(ui_root)
