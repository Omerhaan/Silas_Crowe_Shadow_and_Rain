extends Control

## Anı Duvarı (Memory Wall) Screen.
## Displays the 9 pocket watch slots (K-1 to K-9) and the assembled unit photo pieces.
## Rule: K-2 slot remains conspicuously empty.

@onready var close_btn: Button = $Panel/CloseBtn
@onready var photo_label: Label = $Panel/PhotoBoard/PhotoLabel
@onready var photo_rect: ColorRect = $Panel/PhotoBoard/PhotoRect
@onready var photo_texture: TextureRect = $Panel/PhotoBoard/PhotoTexture
@onready var slots_container: GridContainer = $Panel/WatchSlots/SlotsGrid

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(func():
		visible = false
		GameState.can_player_move = true
	)
	EventBus.memory_wall_requested.connect(open_memory_wall)

func open_memory_wall() -> void:
	visible = true
	GameState.can_player_move = false
	_refresh_display()

func _refresh_display() -> void:
	# Update Photo Board with actual soldier photo sprite
	if "photo_piece_harlow_silas" in GameState.memory_wall_items or GameState.has_evidence("E16"):
		var p_tex = _load_texture("res://assets/sprites/story/story_torn_photo_soldiers_2.png")
		if p_tex:
			photo_texture.texture = p_tex
			photo_texture.visible = true
			photo_label.visible = false
		else:
			photo_rect.color = Color(0.25, 0.28, 0.35, 1.0)
			photo_label.text = "1944 KUZEY BİRLİĞİ\n[Silas Crowe & Edmund Harlow Köşesi]\n(Diğer yüzler eksik ve yırtık)"
			photo_label.visible = true
			photo_texture.visible = false
	else:
		photo_rect.color = Color(0.15, 0.15, 0.18, 1.0)
		photo_label.text = "Boş Pano — Henüz fotoğraf parçası bulunamadı."
		photo_label.visible = true
		photo_texture.visible = false

	# Update 9 Watch Slots
	for c in slots_container.get_children():
		c.queue_free()

	for k in range(1, 10):
		var slot_panel = Panel.new()
		slot_panel.custom_minimum_size = Vector2(26, 26)

		var lbl = Label.new()
		lbl.layout_mode = 1
		lbl.anchors_preset = Control.PRESET_FULL_RECT
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 6)

		match k:
			1:
				# Silas's own watch (03:12)
				slot_panel.self_modulate = Color(0.8, 0.9, 1.0, 1.0)
				lbl.text = "K-1\n03:12"
				lbl.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0, 1.0))
			2:
				# Conspicuously empty!
				slot_panel.self_modulate = Color(0.4, 0.2, 0.2, 1.0)
				lbl.text = "K-2\n[ ? ]"
				lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
			3:
				if "watch_k3_drawing" in GameState.memory_wall_items or GameState.has_evidence("E208"):
					slot_panel.self_modulate = Color(0.9, 0.8, 0.4, 1.0)
					lbl.text = "K-3\n02:40"
					lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3, 1.0))
				else:
					slot_panel.self_modulate = Color(0.2, 0.2, 0.2, 1.0)
					lbl.text = "K-3\n—"
			4:
				if "watch_k4_drawing" in GameState.memory_wall_items or GameState.has_evidence("E309"):
					slot_panel.self_modulate = Color(0.9, 0.8, 0.4, 1.0)
					lbl.text = "K-4\n20:52"
					lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3, 1.0))
				else:
					slot_panel.self_modulate = Color(0.2, 0.2, 0.2, 1.0)
					lbl.text = "K-4\n—"
			5:
				if "watch_k5_drawing" in GameState.memory_wall_items or GameState.has_evidence("E01"):
					slot_panel.self_modulate = Color(0.9, 0.8, 0.4, 1.0)
					lbl.text = "K-5\n22:10"
					lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.3, 1.0))
				else:
					slot_panel.self_modulate = Color(0.2, 0.2, 0.2, 1.0)
					lbl.text = "K-5\n—"
			_:
				slot_panel.self_modulate = Color(0.18, 0.18, 0.22, 1.0)
				lbl.text = "K-%d\n—" % k
				lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1.0))

		slot_panel.add_child(lbl)
		slots_container.add_child(slot_panel)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var real_path = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(real_path):
		var img = Image.load_from_file(real_path)
		if img:
			return ImageTexture.create_from_image(img)
	return null
