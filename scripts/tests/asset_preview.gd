extends Control

## Visual Asset Inspection & Style Anchor Preview Tool (Brief Section 8 & 9 + Revision 2 Room Rebuild)
## Displays 320x180 side-view rooms (Study & Main Hall) in 1x and 4x scale,
## 32-color noir palette, 32x48 character sprites, procedural props with 1px contour and 3-tone shading,
## UI styleboxes, and atmospheric controls.

const NoirPalette = preload("res://scripts/core/noir_palette.gd")
const NoirUIFactory = preload("res://scripts/ui/noir_ui_factory.gd")
const InteractableScene = preload("res://scenes/entities/interactable.tscn")

@onready var palette_grid: GridContainer = $ScrollContainer/VBox/PaletteSection/PaletteGrid
@onready var character_row: HBoxContainer = $ScrollContainer/VBox/CharacterSection/CharacterRow
@onready var props_container: HBoxContainer = $ScrollContainer/VBox/PropsSection/Scroll/PropsContainer
@onready var ui_preview_box: VBoxContainer = $ScrollContainer/VBox/UISection/UIBox
@onready var inspect_rect: ColorRect = $ScrollContainer/VBox/InspectSection/InspectRect
@onready var ambient_vfx = $AmbientVFX

# Room Preview Section Nodes
@onready var viewport_study: SubViewport = $Viewports/ViewportStudy
@onready var viewport_hall: SubViewport = $Viewports/ViewportHall
@onready var room_preview_texture: TextureRect = $ScrollContainer/VBox/RoomSection/PreviewScroll/PreviewTexture
@onready var room_scale_label: Label = $ScrollContainer/VBox/RoomSection/ScaleLabel
@onready var btn_study_1x: Button = $ScrollContainer/VBox/RoomSection/RoomButtons/BtnStudy1x
@onready var btn_study_4x: Button = $ScrollContainer/VBox/RoomSection/RoomButtons/BtnStudy4x
@onready var btn_hall_1x: Button = $ScrollContainer/VBox/RoomSection/RoomButtons/BtnHall1x
@onready var btn_hall_4x: Button = $ScrollContainer/VBox/RoomSection/RoomButtons/BtnHall4x

# Silas demo sprite
@onready var silas_demo_sprite: AnimatedSprite2D = $ScrollContainer/VBox/CharacterSection/SilasDemo/SpriteContainer/AnimatedSprite2D

var demo_time: float = 0.0
var demo_mode: String = "idle" # "idle", "walk", "shudder"
var shudder_timer: float = 0.0

func _ready() -> void:
	_build_room_selector()
	_build_palette_swatches()
	_build_character_previews()
	_build_prop_silhouettes()
	_build_ui_showcase()
	_setup_ambient_controls()

	if silas_demo_sprite:
		silas_demo_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		silas_demo_sprite.play("idle_right")

func _process(delta: float) -> void:
	if not silas_demo_sprite:
		return

	demo_time += delta

	match demo_mode:
		"idle":
			var breath = round(sin(demo_time * 2.5) * 1.0)
			silas_demo_sprite.position.y = breath
			silas_demo_sprite.rotation = 0.0
			silas_demo_sprite.position.x = 0.0
		"walk":
			var bounce = round(abs(sin(demo_time * 12.0)) * 1.0)
			silas_demo_sprite.position.y = -bounce
			silas_demo_sprite.rotation = 0.04
			silas_demo_sprite.position.x = 0.0
		"shudder":
			shudder_timer -= delta
			silas_demo_sprite.position.x = randf_range(-1.0, 1.0)
			if shudder_timer <= 0.0:
				demo_mode = "idle"

func _build_room_selector() -> void:
	if btn_study_1x:
		btn_study_1x.pressed.connect(func(): _set_room_view(viewport_study, 1, "Çalışma Odası (1x: 320x180 - Gerçek Oyun Çözünürlüğü)"))
	if btn_study_4x:
		btn_study_4x.pressed.connect(func(): _set_room_view(viewport_study, 4, "Çalışma Odası (4x: 1280x720 - Yakın Detay İnceleme)"))
	if btn_hall_1x:
		btn_hall_1x.pressed.connect(func(): _set_room_view(viewport_hall, 1, "Ana Hol (1x: 320x180 - Gerçek Oyun Çözünürlüğü)"))
	if btn_hall_4x:
		btn_hall_4x.pressed.connect(func(): _set_room_view(viewport_hall, 4, "Ana Hol (4x: 1280x720 - Yakın Detay İnceleme)"))

	# Default view: Study 1x
	_set_room_view(viewport_study, 1, "Çalışma Odası (1x: 320x180 - Gerçek Oyun Çözünürlüğü)")

func _set_room_view(vp: SubViewport, scale_factor: int, title: String) -> void:
	if not vp or not room_preview_texture:
		return
	room_preview_texture.texture = vp.get_texture()
	room_preview_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	room_preview_texture.custom_minimum_size = Vector2(320 * scale_factor, 180 * scale_factor)
	if room_scale_label:
		room_scale_label.text = title

func _build_palette_swatches() -> void:
	for c in palette_grid.get_children():
		c.queue_free()

	for hex in NoirPalette.HEX_CODES:
		var col = Color(hex)
		var box = VBoxContainer.new()
		box.custom_minimum_size = Vector2(34, 28)

		var swatch = ColorRect.new()
		swatch.color = col
		swatch.custom_minimum_size = Vector2(32, 14)

		var label = Label.new()
		label.text = "#" + hex
		label.add_theme_font_size_override("font_size", 5)
		label.add_theme_color_override("font_color", NoirPalette.PAPER_LIGHT)

		box.add_child(swatch)
		box.add_child(label)
		palette_grid.add_child(box)

func _build_character_previews() -> void:
	var chars = [
		{"id": "char_silas_idle", "name": "Silas Crowe"},
		{"id": "char_hale", "name": "Dr. Hale"},
		{"id": "char_margaret", "name": "Margaret"},
		{"id": "char_julian", "name": "Julian"},
		{"id": "char_pike", "name": "Raymond Pike"}
	]

	for char_info in chars:
		var col_box = VBoxContainer.new()
		col_box.custom_minimum_size = Vector2(48, 64)

		var name_lbl = Label.new()
		name_lbl.text = char_info["name"]
		name_lbl.add_theme_font_size_override("font_size", 6)
		name_lbl.add_theme_color_override("font_color", NoirPalette.CANDLE_CREAM)
		col_box.add_child(name_lbl)

		var tex = AssetManager.get_texture(char_info["id"])
		var tex_rect = TextureRect.new()
		tex_rect.custom_minimum_size = Vector2(32, 48)
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if tex:
			tex_rect.texture = tex
		col_box.add_child(tex_rect)

		character_row.add_child(col_box)

func _build_prop_silhouettes() -> void:
	var prop_types = [
		"door", "window", "desk", "bookcase", "armchair",
		"lamp", "telephone", "fireplace", "watch", "typewriter"
	]

	for p in prop_types:
		var prop_node = InteractableScene.instantiate()
		prop_node.prop_type = p
		prop_node.object_id = "demo_" + p

		var sub_control = Control.new()
		sub_control.custom_minimum_size = Vector2(40, 50)
		sub_control.add_child(prop_node)
		prop_node.position = Vector2(20, 40)

		var v = VBoxContainer.new()
		v.add_child(sub_control)
		var l = Label.new()
		l.text = p.capitalize()
		l.add_theme_font_size_override("font_size", 5)
		l.add_theme_color_override("font_color", NoirPalette.PAPER_WARM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)

		props_container.add_child(v)

func _build_ui_showcase() -> void:
	# Dialog Box Sample
	var dlg_panel = PanelContainer.new()
	dlg_panel.add_theme_stylebox_override("panel", NoirUIFactory.create_dialog_panel_style())
	var dlg_lbl = Label.new()
	dlg_lbl.text = "\"Gölge ve Yağmur: 9-slice stil kutusu noir24 paletine tam bağlıdır.\""
	dlg_lbl.add_theme_font_size_override("font_size", 6)
	dlg_lbl.add_theme_color_override("font_color", NoirPalette.PAPER_LIGHT)
	dlg_panel.add_child(dlg_lbl)
	ui_preview_box.add_child(dlg_panel)

	# Inner Voice Sample
	var iv_panel = PanelContainer.new()
	iv_panel.add_theme_stylebox_override("panel", NoirUIFactory.create_inner_voice_panel_style())
	var iv_lbl = Label.new()
	iv_lbl.text = "\"Bu acı badem kokusu... bir şeyler ters gidiyor.\""
	iv_lbl.add_theme_font_size_override("font_size", 6)
	iv_lbl.add_theme_color_override("font_color", NoirPalette.SKY_MIST)
	iv_panel.add_child(iv_lbl)
	ui_preview_box.add_child(iv_panel)

	# Buttons & Icons
	var row = HBoxContainer.new()
	var icons = ["notebook", "accuse", "settings", "star", "clock", "door"]
	for ic in icons:
		var tex = NoirUIFactory.create_icon(ic, 16)
		var tr = TextureRect.new()
		tr.texture = tex
		tr.custom_minimum_size = Vector2(16, 16)
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(tr)

	ui_preview_box.add_child(row)

func _setup_ambient_controls() -> void:
	var btn_idle = $ScrollContainer/VBox/CharacterSection/SilasDemo/Buttons/BtnIdle
	var btn_walk = $ScrollContainer/VBox/CharacterSection/SilasDemo/Buttons/BtnWalk
	var btn_lean = $ScrollContainer/VBox/CharacterSection/SilasDemo/Buttons/BtnLean
	var btn_shudder = $ScrollContainer/VBox/CharacterSection/SilasDemo/Buttons/BtnShudder

	if btn_idle:
		btn_idle.pressed.connect(func(): demo_mode = "idle")
	if btn_walk:
		btn_walk.pressed.connect(func(): demo_mode = "walk")
	if btn_lean:
		btn_lean.pressed.connect(_test_inspect_lean)
	if btn_shudder:
		btn_shudder.pressed.connect(func():
			demo_mode = "shudder"
			shudder_timer = 0.6
		)

	var btn_lightning = $ScrollContainer/VBox/AmbientSection/AmbientControls/BtnLightning
	var btn_rain = $ScrollContainer/VBox/AmbientSection/AmbientControls/BtnRain
	var btn_grain = $ScrollContainer/VBox/AmbientSection/AmbientControls/BtnGrain
	var btn_vignette = $ScrollContainer/VBox/AmbientSection/AmbientControls/BtnVignette

	if btn_lightning and ambient_vfx:
		btn_lightning.pressed.connect(func():
			ambient_vfx.trigger_lightning()
			demo_mode = "shudder"
			shudder_timer = 0.6
		)
	if btn_rain and ambient_vfx:
		var rain_state = [true]
		btn_rain.pressed.connect(func():
			rain_state[0] = !rain_state[0]
			ambient_vfx.set_rain_enabled(rain_state[0])
		)
	if btn_grain and ambient_vfx:
		var grain_state = [true]
		btn_grain.pressed.connect(func():
			grain_state[0] = !grain_state[0]
			ambient_vfx.set_film_grain_enabled(grain_state[0])
		)
	if btn_vignette and ambient_vfx:
		var vig_state = [true]
		btn_vignette.pressed.connect(func():
			vig_state[0] = !vig_state[0]
			ambient_vfx.set_vignette_enabled(vig_state[0])
		)

func _test_inspect_lean() -> void:
	if not silas_demo_sprite:
		return
	var tween = create_tween()
	tween.tween_property(silas_demo_sprite, "position:y", 2.0, 0.15)
	tween.parallel().tween_property(silas_demo_sprite, "rotation", 0.08, 0.15)
	tween.tween_interval(0.3)
	tween.tween_property(silas_demo_sprite, "position:y", 0.0, 0.2)
	tween.parallel().tween_property(silas_demo_sprite, "rotation", 0.0, 0.2)
