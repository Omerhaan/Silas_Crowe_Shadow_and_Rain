extends CanvasLayer

## In-game HUD: Controls hint, mobile buttons, safe area, floating prompt, inner voice box, and clue toasts.

@onready var prompt_panel: PanelContainer = $SafeArea/PromptPanel
@onready var prompt_btn: Button = $SafeArea/PromptPanel/PromptButton

@onready var dialogue_box: Control = $SafeArea/DialogueBox
@onready var inner_voice_panel: PanelContainer = $SafeArea/InnerVoicePanel
@onready var inner_voice_label: Label = $SafeArea/InnerVoicePanel/MarginContainer/VBoxContainer/VoiceLabel
@onready var inner_voice_hint: Label = $SafeArea/InnerVoicePanel/MarginContainer/VBoxContainer/AdvanceHint

@onready var toast_panel: PanelContainer = get_node_or_null("ToastPanel") if has_node("ToastPanel") else get_node_or_null("SafeArea/ToastPanel")
@onready var toast_label: Label = get_node_or_null("ToastPanel/MarginContainer/ToastLabel") if has_node("ToastPanel") else get_node_or_null("SafeArea/ToastPanel/MarginContainer/ToastLabel")

@onready var achievement_banner: PanelContainer = get_node_or_null("AchievementBanner")
@onready var ach_title_label: Label = get_node_or_null("AchievementBanner/MarginContainer/HBoxContainer/VBoxContainer/TitleLabel")
@onready var ach_desc_label: Label = get_node_or_null("AchievementBanner/MarginContainer/HBoxContainer/VBoxContainer/DescLabel")

var achievement_timer: float = 0.0

@onready var room_name_label: Label = $SafeArea/TopBar/MarginContainer/HBoxContainer/RoomNameLabel
@onready var hint_label: Label = get_node_or_null("SafeArea/TopBar/MarginContainer/HBoxContainer/HintLabel")
@onready var focus_btn: Button = get_node_or_null("SafeArea/TopBar/MarginContainer/HBoxContainer/FocusButton")
@onready var bag_btn: Button = get_node_or_null("SafeArea/TopBar/MarginContainer/HBoxContainer/BagButton")
@onready var notebook_btn: Button = $SafeArea/TopBar/MarginContainer/HBoxContainer/NotebookButton
@onready var accuse_btn: Button = $SafeArea/TopBar/MarginContainer/HBoxContainer/AccuseButton
@onready var menu_btn: Button = $SafeArea/TopBar/MarginContainer/HBoxContainer/MenuButton
@onready var inventory_modal: Control = get_node_or_null("InventoryModal")
@onready var nav_left_btn: Button = get_node_or_null("NavLeftButton")
@onready var nav_right_btn: Button = get_node_or_null("NavRightButton")
@onready var nav_extra_btn: Button = get_node_or_null("NavExtraButton")

var room_names_tr = {
	"silas_office": "Silas'ın Ofisi",
	"main_hall": "Ana Hol",
	"study": "Çalışma Odası",
	"library": "Kütüphane",
	"dining_room": "Yemek Odası",
	"kitchen": "Mutfak",
	"billiard_room": "Bilardo Odası",
	"upper_floor": "Üst Kat Koridoru",
	"harlow_bedroom": "Harlow'un Odası",
	"julian_room": "Julian'ın Odası",
	"pike_room": "Pike'ın Odası",
	"dock_pier": "Sisli Rıhtım",
	"dock_warehouse": "Liman Ambarı",
	"dock_office": "Gümrük İdaresi",
	"dock_saloon": "Tuzlu Çapa",
	"captain_cabin": "Kargo Gemisi",
	"opera_foyer": "Kraliyet Operası Fuayesi",
	"opera_auditorium": "Tiyatro Salonu",
	"royal_box": "Kraliyet Locası",
	"backstage": "Sahne Arkası (Kulis)",
	"prop_room": "Aksesuar Atölyesi",
	"light_bridge": "Işık Köprüsü",
	"opera_roof": "Opera Çatısı"
}

var room_names_en = {
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
	"opera_foyer": "Royal Opera Foyer",
	"opera_auditorium": "Auditorium Hall",
	"royal_box": "Royal Box",
	"backstage": "Backstage",
	"prop_room": "Prop Room",
	"light_bridge": "Light Bridge",
	"opera_roof": "Opera Roof"
}

var room_names = room_names_tr

var room_connections = {
	"dining_room": {
		"left": {"room": "kitchen", "spawn": "from_dining_room"},
		"right": {"room": "main_hall", "spawn": "from_dining_room"}
	},
	"kitchen": {
		"right": {"room": "dining_room", "spawn": "from_kitchen"}
	},
	"main_hall": {
		"left": {"room": "dining_room", "spawn": "from_main_hall"},
		"right": {"room": "library", "spawn": "from_main_hall"},
		"extra": {"room": "upper_floor", "spawn": "from_main_hall"}
	},
	"study": {
		"left": {"room": "main_hall", "spawn": "from_study"}
	},
	"upper_floor": {
		"left": {"room": "main_hall", "spawn": "from_upper_floor"},
		"right": {"room": "pike_room", "spawn": "from_upper_floor"},
		"extra": {"room": "harlow_bedroom", "spawn": "from_upper_floor"}
	},
	"library": {
		"left": {"room": "main_hall", "spawn": "from_library"},
		"right": {"room": "billiard_room", "spawn": "from_library"}
	},
	"billiard_room": {
		"left": {"room": "library", "spawn": "from_billiard_room"}
	},
	"harlow_bedroom": {
		"left": {"room": "upper_floor", "spawn": "from_harlow_bedroom"}
	},
	"pike_room": {
		"left": {"room": "upper_floor", "spawn": "from_pike_room"}
	},
	"julian_room": {
		"left": {"room": "upper_floor", "spawn": "from_julian_room"}
	},
	"captain_cabin": {
		"left": {"room": "dock_pier", "spawn": "from_cabin"}
	},
	"dock_office": {
		"right": {"room": "dock_pier", "spawn": "from_office"}
	},
	"dock_pier": {
		"left": {"room": "dock_office", "spawn": "from_pier"},
		"right": {"room": "dock_warehouse", "spawn": "from_pier"},
		"extra": {"room": "captain_cabin", "spawn": "from_pier"}
	},
	"dock_warehouse": {
		"left": {"room": "dock_pier", "spawn": "from_warehouse"},
		"right": {"room": "dock_saloon", "spawn": "from_warehouse"}
	},
	"dock_saloon": {
		"left": {"room": "dock_warehouse", "spawn": "from_saloon"}
	},
	"opera_foyer": {
		"left": {"room": "backstage", "spawn": "from_foyer"},
		"right": {"room": "opera_auditorium", "spawn": "from_foyer"},
		"extra": {"room": "royal_box", "spawn": "from_foyer"}
	},
	"opera_auditorium": {
		"left": {"room": "opera_foyer", "spawn": "from_auditorium"}
	},
	"royal_box": {
		"left": {"room": "opera_foyer", "spawn": "from_royal_box"}
	},
	"backstage": {
		"left": {"room": "opera_foyer", "spawn": "from_backstage2"},
		"right": {"room": "prop_room", "spawn": "from_backstage"},
		"extra": {"room": "light_bridge", "spawn": "from_backstage"}
	},
	"prop_room": {
		"left": {"room": "backstage", "spawn": "from_prop_room"}
	},
	"light_bridge": {
		"left": {"room": "opera_roof", "spawn": "from_light_bridge"},
		"right": {"room": "backstage", "spawn": "from_light_bridge"}
	},
	"opera_roof": {
		"right": {"room": "light_bridge", "spawn": "from_roof"}
	}
}

var active_interactable: Node2D = null
var is_showing_inner_voice: bool = false
var inner_voice_cooldown: float = 0.0
var toast_timer: float = 0.0

func _ready() -> void:
	prompt_panel.visible = false
	inner_voice_panel.visible = false
	toast_panel.visible = false

	EventBus.interaction_available.connect(_on_interaction_available)
	EventBus.interaction_unavailable.connect(_on_interaction_unavailable)
	EventBus.inner_voice_requested.connect(_on_inner_voice_requested)
	EventBus.evidence_collected.connect(_on_evidence_collected)
	EventBus.toast_requested.connect(_on_toast_requested)
	if EventBus.has_signal("achievement_unlocked"):
		EventBus.achievement_unlocked.connect(_on_achievement_unlocked)
	EventBus.room_changed.connect(_on_room_changed)
	_on_room_changed(GameState.current_room_id)

	if prompt_btn:
		prompt_btn.pressed.connect(_on_prompt_btn_pressed)
	if focus_btn:
		focus_btn.pressed.connect(_trigger_focus_pulse)
	if bag_btn:
		bag_btn.pressed.connect(_on_bag_btn_pressed)
	if notebook_btn:
		notebook_btn.pressed.connect(_on_notebook_btn_pressed)
	if accuse_btn:
		accuse_btn.pressed.connect(func(): EventBus.accusation_requested.emit())
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_btn_pressed)
	if inner_voice_panel:
		inner_voice_panel.gui_input.connect(_on_inner_voice_gui_input)
	if dialogue_box:
		dialogue_box.advance_requested.connect(close_inner_voice)

	if nav_left_btn:
		nav_left_btn.pressed.connect(_on_nav_left_pressed)
	if nav_right_btn:
		nav_right_btn.pressed.connect(_on_nav_right_pressed)
	if nav_extra_btn:
		nav_extra_btn.pressed.connect(_on_nav_extra_pressed)

	for b in [focus_btn, bag_btn, notebook_btn, accuse_btn, menu_btn, nav_left_btn, nav_right_btn, nav_extra_btn, prompt_btn]:
		if b:
			b.focus_mode = Control.FOCUS_NONE

	_setup_nav_button_styles()
	_setup_achievement_banner_styles()
	_apply_safe_area()
	var vp = get_viewport()
	if vp:
		vp.size_changed.connect(_apply_safe_area)

	if EventBus.has_signal("language_changed"):
		EventBus.language_changed.connect(func(_loc): _update_localization())
	if EventBus.has_signal("font_scale_changed"):
		EventBus.font_scale_changed.connect(apply_font_scale)
	if EventBus.has_signal("evidence_collected"):
		EventBus.evidence_collected.connect(func(_ev): _update_nav_buttons.call_deferred(GameState.current_room_id))
	if EventBus.has_signal("toast_requested"):
		EventBus.toast_requested.connect(func(_msg): _update_nav_buttons.call_deferred(GameState.current_room_id))
	apply_font_scale(GameState.get_font_scale())
	_update_localization()

func apply_font_scale(scale: String) -> void:
	var toast_sz = 8
	var voice_sz = 8
	var hint_sz = 6
	if scale == "small":
		toast_sz = 6
		voice_sz = 6
		hint_sz = 5
	elif scale == "large":
		toast_sz = 10
		voice_sz = 10
		hint_sz = 7
	else:
		toast_sz = 8
		voice_sz = 8
		hint_sz = 6

	if toast_label:
		toast_label.add_theme_font_size_override("font_size", toast_sz)
	if inner_voice_label:
		inner_voice_label.add_theme_font_size_override("font_size", voice_sz)
	if inner_voice_hint:
		inner_voice_hint.add_theme_font_size_override("font_size", max(5, voice_sz - 2))
	if hint_label:
		hint_label.add_theme_font_size_override("font_size", hint_sz)
	if prompt_btn:
		prompt_btn.add_theme_font_size_override("font_size", hint_sz + 1)
	if room_name_label:
		room_name_label.add_theme_font_size_override("font_size", toast_sz)

func _update_localization() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	room_names = room_names_en if is_en else room_names_tr
	_on_room_changed(GameState.current_room_id)

	if hint_label:
		hint_label.text = "[A/D]: Walk  •  [E]: Inspect  •  [X]: Focus" if is_en else "[A/D]: Yürü  •  [E]: İncele  •  [X]: Odak"
	if notebook_btn:
		notebook_btn.text = "Notebook" if is_en else "Defter"
	if accuse_btn:
		accuse_btn.text = "Accuse" if is_en else "Suçla"
	if bag_btn:
		bag_btn.text = "🎒 Bag" if is_en else "🎒 Çanta"
	if focus_btn:
		focus_btn.text = "🔍 Focus" if is_en else "🔍 Odak"
	if menu_btn:
		menu_btn.text = "Menu" if is_en else "Menü"
	if inner_voice_hint:
		inner_voice_hint.text = "[Close: Tap / E]" if is_en else "[Dokun / E ile Kapat]"

	if active_interactable and not is_showing_inner_voice:
		var name_str = ""
		if active_interactable.has_method("get_localized_name"):
			name_str = active_interactable.get_localized_name()
		else:
			name_str = active_interactable.get("display_name")
		if name_str == null or name_str == "":
			name_str = "Inspect" if is_en else "İncele"
		prompt_btn.text = "[E] " + str(name_str)

func _apply_safe_area() -> void:
	var safe_area_node = get_node_or_null("SafeArea")
	if not safe_area_node or not (safe_area_node is MarginContainer):
		return
	if DisplayServer.has_method("get_display_safe_area"):
		var safe = DisplayServer.get_display_safe_area()
		var screen_size = DisplayServer.screen_get_size()
		if screen_size.x > 0 and screen_size.y > 0 and (safe.position != Vector2i.ZERO or safe.size != screen_size):
			var vp = get_viewport()
			if vp:
				var vp_size = vp.get_visible_rect().size
				var scale_x = vp_size.x / float(screen_size.x)
				var scale_y = vp_size.y / float(screen_size.y)
				safe_area_node.add_theme_constant_override("margin_left", int(safe.position.x * scale_x) + 2)
				safe_area_node.add_theme_constant_override("margin_top", int(safe.position.y * scale_y) + 1)
				safe_area_node.add_theme_constant_override("margin_right", int((screen_size.x - safe.end.x) * scale_x) + 2)
				safe_area_node.add_theme_constant_override("margin_bottom", int((screen_size.y - safe.end.y) * scale_y) + 1)

func _setup_achievement_banner_styles() -> void:
	if achievement_banner:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.08, 0.13, 0.96)
		sb.border_width_left = 1
		sb.border_width_right = 1
		sb.border_width_top = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.96, 0.82, 0.35, 1.0)
		sb.corner_radius_top_left = 3
		sb.corner_radius_top_right = 3
		sb.corner_radius_bottom_left = 3
		sb.corner_radius_bottom_right = 3
		achievement_banner.add_theme_stylebox_override("panel", sb)

	if toast_panel:
		var tsb = StyleBoxFlat.new()
		tsb.bg_color = Color(0.08, 0.11, 0.16, 0.94)
		tsb.border_width_left = 1
		tsb.border_width_right = 1
		tsb.border_width_top = 1
		tsb.border_width_bottom = 1
		tsb.border_color = Color(0.35, 0.48, 0.65, 0.9)
		tsb.corner_radius_top_left = 3
		tsb.corner_radius_top_right = 3
		tsb.corner_radius_bottom_left = 3
		tsb.corner_radius_bottom_right = 3
		toast_panel.add_theme_stylebox_override("panel", tsb)

func _setup_nav_button_styles() -> void:
	for btn in [nav_left_btn, nav_right_btn, nav_extra_btn]:
		if not btn:
			continue
		var normal_sb = StyleBoxFlat.new()
		normal_sb.bg_color = Color(0.06, 0.09, 0.14, 0.85)
		normal_sb.border_width_left = 1
		normal_sb.border_width_right = 1
		normal_sb.border_width_top = 1
		normal_sb.border_width_bottom = 1
		normal_sb.border_color = Color(0.25, 0.35, 0.48, 0.9)
		normal_sb.corner_radius_top_left = 3
		normal_sb.corner_radius_top_right = 3
		normal_sb.corner_radius_bottom_left = 3
		normal_sb.corner_radius_bottom_right = 3
		btn.add_theme_stylebox_override("normal", normal_sb)
		
		var hover_sb = normal_sb.duplicate()
		hover_sb.bg_color = Color(0.12, 0.18, 0.28, 0.95)
		hover_sb.border_color = Color(0.96, 0.89, 0.63, 0.9)
		btn.add_theme_stylebox_override("hover", hover_sb)
		btn.add_theme_stylebox_override("pressed", hover_sb)

		var focus_sb = hover_sb.duplicate()
		btn.add_theme_stylebox_override("focus", focus_sb)

func _on_nav_left_pressed() -> void:
	var curr = GameState.current_room_id
	if room_connections.has(curr) and room_connections[curr].has("left"):
		var target = room_connections[curr]["left"]
		_navigate_to_room(target["room"], target.get("spawn", "default"))

func _on_nav_right_pressed() -> void:
	var curr = GameState.current_room_id
	if room_connections.has(curr) and room_connections[curr].has("right"):
		var target = room_connections[curr]["right"]
		_navigate_to_room(target["room"], target.get("spawn", "default"))

func _process(delta: float) -> void:
	if toast_timer > 0.0:
		toast_timer -= delta
		if toast_timer <= 0.0:
			if toast_panel:
				toast_panel.visible = false

	if achievement_timer > 0.0:
		achievement_timer -= delta
		if achievement_timer <= 0.0:
			if achievement_banner:
				achievement_banner.visible = false

	if is_showing_inner_voice:
		if inner_voice_cooldown > 0.0:
			inner_voice_cooldown -= delta
		elif Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
			if dialogue_box and dialogue_box.visible:
				dialogue_box.advance()
			else:
				close_inner_voice()

func _on_interaction_available(interactable: Node2D) -> void:
	active_interactable = interactable
	if not is_showing_inner_voice:
		var name_str = ""
		if interactable.has_method("get_localized_name"):
			name_str = interactable.get_localized_name()
		else:
			name_str = interactable.get("display_name")
		var is_en = (LocalizationManager and LocalizationManager.get_locale() == "en")
		if name_str == null or name_str == "":
			name_str = "Inspect" if is_en else "İncele"
		prompt_btn.text = "[E] " + str(name_str)
		var has_overhead = (interactable.get_node_or_null("PromptLabel") != null and interactable.get_node_or_null("PromptLabel").visible)
		prompt_panel.visible = not has_overhead

func _on_interaction_unavailable(interactable: Node2D) -> void:
	if active_interactable == interactable:
		active_interactable = null
		prompt_panel.visible = false

func _on_prompt_btn_pressed() -> void:
	if prompt_btn:
		prompt_btn.release_focus()
	if active_interactable and active_interactable.has_method("interact"):
		active_interactable.interact()

func _on_notebook_btn_pressed() -> void:
	InputManager.trigger_notebook()

func _on_bag_btn_pressed() -> void:
	if inventory_modal and inventory_modal.has_method("toggle_inventory"):
		inventory_modal.toggle_inventory()
	else:
		EventBus.inventory_toggled.emit(true)

func _on_menu_btn_pressed() -> void:
	InputManager.trigger_menu()

func _on_inner_voice_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_inner_voice()
	elif event is InputEventScreenTouch and event.pressed:
		close_inner_voice()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("detective_focus") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_X):
		_trigger_focus_pulse()
		get_viewport().set_input_as_handled()
		return

	if is_showing_inner_voice:
		if (not dialogue_box or not dialogue_box.visible) and (not inner_voice_panel or not inner_voice_panel.visible):
			close_inner_voice()
			return

	if is_showing_inner_voice and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_inner_voice()
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_E or event.keycode == KEY_SPACE) and inner_voice_cooldown <= 0.0:
			if dialogue_box and dialogue_box.visible:
				dialogue_box.advance()
			else:
				close_inner_voice()
			get_viewport().set_input_as_handled()

func _trigger_focus_pulse() -> void:
	var inspect_view = get_tree().root.find_child("InspectView", true, false)
	if inspect_view and inspect_view.visible:
		return
	var eb = get_node_or_null("/root/EventBus")
	if eb and eb.has_signal("focus_pulse_requested"):
		eb.focus_pulse_requested.emit()
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("menu_select")

func _on_inner_voice_requested(text: String) -> void:
	# Avoid showing inner voice if an inspect modal or cutscene is active
	var inspect_view = get_tree().root.find_child("InspectView", true, false)
	if inspect_view and inspect_view.visible:
		return
	if CutsceneManager.is_cutscene_active:
		return

	if dialogue_box:
		dialogue_box.set_dialogue("INNER_VOICE", text)
		dialogue_box.visible = true
	if inner_voice_panel:
		inner_voice_label.text = text
		inner_voice_panel.visible = false
	prompt_panel.visible = false
	is_showing_inner_voice = true
	inner_voice_cooldown = 0.25
	GameState.can_player_move = false

func close_inner_voice() -> void:
	if dialogue_box:
		dialogue_box.visible = false
	if inner_voice_panel:
		inner_voice_panel.visible = false
	is_showing_inner_voice = false
	inner_voice_cooldown = 0.0
	GameState.can_player_move = true
	if active_interactable:
		prompt_panel.visible = true

func _on_achievement_unlocked(ach_id: String, title: String, desc: String) -> void:
	if not achievement_banner:
		return
	var gs = get_node_or_null("/root/GameState")
	var final_desc = desc
	if final_desc.is_empty() and gs:
		if ach_id != "" and gs.achievements_db.has(ach_id):
			final_desc = gs.achievements_db[ach_id].get("aciklama", "")
		else:
			for a in gs.achievements_db.values():
				if a.get("ad", "") == title:
					final_desc = a.get("aciklama", "")
					break

	if ach_title_label and title != "":
		ach_title_label.text = title
	if ach_desc_label:
		if not final_desc.is_empty():
			ach_desc_label.text = final_desc
		elif ach_desc_label.text.is_empty():
			ach_desc_label.text = "Tebrikler! Yeni bir başarıma ulaştın."

	achievement_banner.visible = true
	achievement_timer = 5.0
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("chime")

func _on_evidence_collected(ev_id: String) -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var ev_data = GameState.get_evidence_data(ev_id)
	var title = ev_data.get("ad", ev_id)
	if toast_label:
		var prefix = "★ New Clue: " if is_en else "★ Yeni Kanıt: "
		toast_label.text = prefix + str(title)
	if toast_panel:
		toast_panel.visible = true
	toast_timer = 4.5

func _on_toast_requested(message: String) -> void:
	if message.is_empty():
		if toast_panel:
			toast_panel.visible = false
		toast_timer = 0.0
		return

	if message.contains("BAŞARIM") or message.contains("🏆"):
		var title = message.replace("🏆 BAŞARIM: ", "").replace("🏆", "").replace("BAŞARIM:", "").strip_edges()
		_on_achievement_unlocked("", title, "")
		return

	if toast_label:
		toast_label.text = message
	if toast_panel:
		toast_panel.visible = true
	toast_timer = 4.5

func _on_room_changed(room_id: String) -> void:
	if is_showing_inner_voice:
		close_inner_voice()
	active_interactable = null
	if prompt_panel:
		prompt_panel.visible = false
	if room_name_label:
		room_name_label.text = room_names.get(room_id, room_id.capitalize())
	if accuse_btn:
		accuse_btn.visible = (room_id != "silas_office")
	_update_nav_buttons(room_id)
	_update_nav_buttons.call_deferred(room_id)

func _find_door_for_target(target_room: String) -> Area2D:
	var doors = get_tree().get_nodes_in_group("doors")
	for d in doors:
		if is_instance_valid(d) and d.is_inside_tree() and not d.is_queued_for_deletion():
			if "target_room_id" in d and d.target_room_id == target_room:
				return d
	return null

func _is_passage_locked(target_room: String) -> bool:
	var door = _find_door_for_target(target_room)
	if not door:
		return false
	if not door.is_locked:
		return false
	if door.required_key_id != "" and GameState.has_item(door.required_key_id):
		return false
	return true

func _navigate_to_room(target_room: String, target_spawn: String) -> void:
	var door = _find_door_for_target(target_room)
	if door:
		if "target_spawn" in door and (door.target_spawn == null or door.target_spawn.is_empty()):
			door.target_spawn = target_spawn
		door.interact()
		_update_nav_buttons.call_deferred(GameState.current_room_id)
		return
	EventBus.room_change_requested.emit(target_room, target_spawn)

func _update_nav_buttons(room_id: String) -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var locked_tag = " [Locked]" if is_en else " [Kilitli]"
	var locked_tip = " (Locked)" if is_en else " (Kilitli)"

	if nav_left_btn:
		var has_left = room_connections.has(room_id) and room_connections[room_id].has("left")
		nav_left_btn.visible = has_left
		if has_left:
			var target_data = room_connections[room_id]["left"]
			var target_room = target_data["room"]
			var target_name = room_names.get(target_room, target_room.capitalize())
			if target_data.get("is_temporary", false):
				target_name += " [GEÇİCİ]"
			var is_locked = _is_passage_locked(target_room)
			if is_locked:
				nav_left_btn.tooltip_text = target_name + locked_tip
				nav_left_btn.text = "◀ 🔒 " + target_name + locked_tag
			else:
				nav_left_btn.tooltip_text = target_name
				nav_left_btn.text = "◀ " + target_name

	if nav_right_btn:
		var has_right = room_connections.has(room_id) and room_connections[room_id].has("right")
		nav_right_btn.visible = has_right
		if has_right:
			var target_data = room_connections[room_id]["right"]
			var target_room = target_data["room"]
			var target_name = room_names.get(target_room, target_room.capitalize())
			if target_data.get("is_temporary", false):
				target_name += " [GEÇİCİ]"
			var is_locked = _is_passage_locked(target_room)
			if is_locked:
				nav_right_btn.tooltip_text = target_name + locked_tip
				nav_right_btn.text = "🔒 " + target_name + locked_tag + " ▶"
			else:
				nav_right_btn.tooltip_text = target_name
				nav_right_btn.text = target_name + " ▶"

	if nav_extra_btn:
		var has_extra = room_connections.has(room_id) and room_connections[room_id].has("extra")
		nav_extra_btn.visible = has_extra
		if has_extra:
			var target_data = room_connections[room_id]["extra"]
			var target_room = target_data["room"]
			var target_name = room_names.get(target_room, target_room.capitalize())
			if target_data.get("is_temporary", false):
				target_name += " [GEÇİCİ]"
			var is_locked = _is_passage_locked(target_room)
			if is_locked:
				nav_extra_btn.tooltip_text = target_name + locked_tip
				nav_extra_btn.text = "🔒 " + target_name + locked_tag + " ▶"
			else:
				nav_extra_btn.tooltip_text = target_name
				nav_extra_btn.text = target_name + " ▶"

func _on_nav_extra_pressed() -> void:
	var cur_room = GameState.current_room_id
	if room_connections.has(cur_room) and room_connections[cur_room].has("extra"):
		var target_info = room_connections[cur_room]["extra"]
		_navigate_to_room(target_info["room"], target_info.get("spawn", "default"))

