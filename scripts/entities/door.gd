extends Area2D

## Door / passage trigger connecting rooms.
## Displays prompt [E] <door_name> on player approach, transitions room on [E] or tap.

@export var target_room_id: String = "main_hall"
@export var target_spawn: String = "default"
@export var door_name: String = "Kapı"
@export var requires_interaction: bool = true

@export var is_locked: bool = false
@export var locked_message: String = ""
@export var required_key_id: String = ""
@export var is_temporary: bool = false

var display_name: String:
	get:
		return get_localized_name()

func _get_loc_mgr() -> Node:
	if is_inside_tree():
		return get_node_or_null("/root/LocalizationManager")
	var ml = Engine.get_main_loop()
	if ml and "root" in ml and ml.root:
		return ml.root.get_node_or_null("LocalizationManager")
	return null

func get_localized_name() -> String:
	var loc_mgr = _get_loc_mgr()
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	if not is_en:
		return door_name

	var door_names_en = {
		"silas_office": "Silas's Office",
		"main_hall": "Main Hall",
		"study": "Study",
		"library": "Library",
		"dining_room": "Dining Room",
		"kitchen": "Kitchen",
		"billiard_room": "Billiard Room",
		"upper_floor": "Upper Floor Corridor",
		"harlow_bedroom": "Harlow's Bedroom",
		"julian_room": "Julian's Bedroom",
		"pike_room": "Pike's Bedroom",
		"dock_pier": "Foggy Pier",
		"dock_warehouse": "Port Warehouse",
		"dock_office": "Customs Office",
		"dock_saloon": "Salty Anchor",
		"captain_cabin": "Cargo Ship",
		"opera_foyer": "Opera Foyer",
		"opera_auditorium": "Auditorium",
		"royal_box": "Royal Box",
		"backstage": "Backstage",
		"prop_room": "Prop Room",
		"light_bridge": "Light Bridge",
		"opera_roof": "Opera Roof"
	}
	if door_names_en.has(target_room_id):
		if "Merdiven" in door_name:
			if "Aşağı" in door_name:
				return "Stairs Down to Main Hall"
			return "Stairs to Upper Floor"
		return door_names_en[target_room_id]

	var special_names = {
		"Ana Hol": "Main Hall",
		"Çalışma Odası": "Study",
		"Kütüphane": "Library",
		"Yemek Odası": "Dining Room",
		"Mutfak": "Kitchen",
		"Bilardo Odası": "Billiard Room",
		"Koridor": "Corridor",
		"Üst Kat Merdiveni": "Stairs to Upper Floor",
		"Aşağı İnen Merdiven": "Stairs Down to Main Hall",
		"Harlow'un Odası": "Harlow's Bedroom",
		"Julian'ın Odası": "Julian's Bedroom",
		"Pike'ın Odası": "Pike's Bedroom",
		"Malikâne Giriş Kapısı": "Manor Entrance",
		"Mutfak Arka Çıkışı": "Kitchen Back Exit",
		"Ofis Kapısı": "Office Door",
		"Kapı": "Door",
		"Sisli Rıhtım": "Foggy Pier",
		"Liman Ambarı": "Port Warehouse",
		"Gümrük İdaresi": "Customs Office",
		"Kargo Gemisi": "Cargo Ship",
		"Kargo Gemisi Kamarası": "Cargo Ship Cabin",
		"Tuzlu Çapa": "Salty Anchor",
		"Tuzlu Çapa Barı": "Salty Anchor Saloon",
		"Sahne Arkası (Kulis)": "Backstage",
		"Kraliyet Fuayesi": "Royal Foyer",
		"Aksesuar Atölyesi": "Prop Workshop",
		"Işık Köprüsü Merdiveni": "Light Bridge Stairs",
		"Kulise İniş Merdiveni": "Stairs Down to Backstage",
		"Çatı Kapağı": "Roof Hatch",
		"Kulise Dön": "Return to Backstage",
		"Kraliyet Locası Merdiveni": "Stairs to Royal Box",
		"Tiyatro Salonu": "Auditorium"
	}
	return special_names.get(door_name, door_name)

var prompt_label: Label = null
var highlight: ReferenceRect = null
var pulse_tween: Tween = null

func _ready() -> void:
	add_to_group("doors")
	body_entered.connect(_on_body_entered)
	input_event.connect(_on_input_event)

	prompt_label = Label.new()
	prompt_label.text = "[E] " + get_localized_name()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-60, -90)
	prompt_label.custom_minimum_size = Vector2(120, 16)
	prompt_label.add_theme_font_size_override("font_size", 7)
	prompt_label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.63, 1))
	prompt_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("shadow_offset_x", 1)
	prompt_label.add_theme_constant_override("shadow_offset_y", 1)
	prompt_label.visible = false
	prompt_label.z_index = 25
	add_child(prompt_label)

	highlight = ReferenceRect.new()
	highlight.editor_only = false
	highlight.border_color = Color(0.96, 0.89, 0.63, 0.0)
	highlight.border_width = 1.5
	highlight.position = Vector2(-22, -80)
	highlight.size = Vector2(44, 80)
	highlight.visible = false
	highlight.z_index = 20
	add_child(highlight)

	var eb = get_node_or_null("/root/EventBus")
	if eb and eb.has_signal("focus_pulse_requested"):
		eb.focus_pulse_requested.connect(pulse_highlight)
	if eb and eb.has_signal("language_changed"):
		eb.language_changed.connect(func(_loc):
			if prompt_label and prompt_label.visible:
				prompt_label.text = "[E] " + get_localized_name()
		)

	if required_key_id != "" and is_locked:
		var gs = get_node_or_null("/root/GameState")
		if gs and gs.has_item(required_key_id):
			is_locked = false

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not requires_interaction:
		interact()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		var im = get_node_or_null("/root/InputManager")
		if im and im.has_method("request_interact_with"):
			im.request_interact_with(self)

func set_highlight(active: bool) -> void:
	if prompt_label:
		prompt_label.text = "[E] " + get_localized_name()
		prompt_label.visible = active
	if highlight:
		highlight.visible = false

func pulse_highlight(duration: float = 1.6) -> void:
	if not visible or not is_inside_tree():
		return

	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()

	if highlight:
		highlight.visible = true
		highlight.border_color = Color(0.96, 0.89, 0.63, 0.95)
		highlight.modulate.a = 1.0

	if prompt_label:
		prompt_label.text = "🚪 " + get_localized_name()
		prompt_label.visible = true
		prompt_label.modulate.a = 1.0

	pulse_tween = create_tween()
	if highlight:
		pulse_tween.parallel().tween_property(highlight, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if prompt_label:
		pulse_tween.parallel().tween_property(prompt_label, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pulse_tween.tween_callback(func():
		if not is_instance_valid(self): return
		if highlight:
			highlight.visible = false
		if prompt_label:
			prompt_label.visible = false
	)

func interact() -> void:
	var am = get_node_or_null("/root/AudioManager")
	var eb = get_node_or_null("/root/EventBus")
	var gs = get_node_or_null("/root/GameState")
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	if required_key_id != "" and is_locked:
		if gs and gs.has_item(required_key_id):
			is_locked = false
			if eb and eb.has_signal("toast_requested"):
				var toast_msg = "🔑 Unlocked: " if is_en else "🔑 Kilit Açıldı: "
				eb.toast_requested.emit(toast_msg + get_localized_name())
		else:
			if am and am.has_method("play_sfx"):
				am.play_sfx("door_locked")
			var msg = locked_message
			if msg.is_empty():
				msg = "This door is locked. A proper key is needed to open it." if is_en else "Bu kapı kilitli. Açmak için uygun bir anahtar gerekiyor."
			if eb and eb.has_signal("inner_voice_requested"):
				eb.inner_voice_requested.emit("\"" + msg + "\"")
			return

	if is_locked or target_room_id == "":
		if am and am.has_method("play_sfx"):
			am.play_sfx("door_locked")
		var msg = locked_message
		if msg.is_empty():
			msg = "This door is locked." if is_en else "Bu kapı kilitli."
		if eb and eb.has_signal("inner_voice_requested"):
			eb.inner_voice_requested.emit("\"" + msg + "\"")
		return

	if am and am.has_method("play_sfx"):
		am.play_sfx("door_open")
	if eb and eb.has_signal("room_change_requested"):
		eb.room_change_requested.emit(target_room_id, target_spawn)
