extends Node2D

## Main scene controller: manages room instancing, player positioning, tap-to-move, cutscenes, and transitions.

@onready var room_container: Node2D = $RoomContainer
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var fade_transition: CanvasLayer = $FadeTransition

@onready var story_cutscene: CanvasLayer = $StoryCutscene
@onready var phone_call_dialogue: CanvasLayer = $PhoneCallDialogue
@onready var arrival_dialogue: CanvasLayer = $ArrivalDialogue

@onready var ui_overlays: CanvasLayer = $UIOverlays
@onready var souvenir_modal: Control = $UIOverlays/SouvenirModal
@onready var second_call: Control = $UIOverlays/SecondCall
@onready var main_menu: Control = $UIOverlays/MainMenu
@onready var intro_sequence: Control = $UIOverlays/Intro if $UIOverlays.has_node("Intro") else null
@onready var light_range_modal: Control = $UIOverlays/LightRangeModal if $UIOverlays.has_node("LightRangeModal") else null
@onready var tumbler_lock_modal: Control = $UIOverlays/TumblerLockModal if $UIOverlays.has_node("TumblerLockModal") else null
@onready var safe_dial_modal: Control = $UIOverlays/SafeDialModal if $UIOverlays.has_node("SafeDialModal") else null
@onready var crane_winch_modal: Control = $UIOverlays/CraneWinchModal if $UIOverlays.has_node("CraneWinchModal") else null
@onready var camera: Camera2D = $Camera2D

var _is_replaying_intro: bool = false
var _previous_state_before_intro: Dictionary = {}
var _shake_tween: Tween = null

var current_room_node: Node2D = null

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)

	EventBus.room_change_requested.connect(_on_room_change_requested)
	CutsceneManager.cutscene_finished.connect(_on_cutscene_finished)
	phone_call_dialogue.phone_call_completed.connect(_on_phone_call_completed)
	arrival_dialogue.arrival_finished.connect(_on_arrival_finished)
	EventBus.souvenir_shelf_requested.connect(func(): souvenir_modal.open_shelf())
	EventBus.light_range_requested.connect(func(): if light_range_modal: light_range_modal.open_board())
	EventBus.tumbler_lock_requested.connect(func(): if tumbler_lock_modal: tumbler_lock_modal.open_modal())
	EventBus.safe_dial_requested.connect(func(): if safe_dial_modal: safe_dial_modal.open_modal())
	EventBus.crane_winch_requested.connect(func(): if crane_winch_modal: crane_winch_modal.open_modal())
	EventBus.intro_replay_requested.connect(_on_intro_replay_requested)
	EventBus.lightning_occurred.connect(func(): shake_camera(2.5, 0.30))
	EventBus.deduction_made.connect(func(_id): shake_camera(1.8, 0.22))
	EventBus.statement_collected.connect(func(_s, _t): shake_camera(1.4, 0.18))

	if intro_sequence:
		intro_sequence.intro_completed.connect(_on_intro_completed)

	main_menu.game_started.connect(_on_new_game_started)
	main_menu.game_continued.connect(_on_continue_game)
	if main_menu.has_signal("case_selected"):
		main_menu.case_selected.connect(_on_case_selected)
	EventBus.case_continue_requested.connect(_on_case_continue_requested)
	EventBus.main_menu_requested.connect(_return_to_main_menu)

	# Start on Main Menu
	hud.visible = false
	GameState.can_player_move = false
	main_menu.open_menu()

var _is_intro_active: bool = false

func _start_case_sequence(case_id: String) -> void:
	hud.visible = true
	var switched = GameState.switch_case(case_id)
	if switched:
		var title = GameState.case_data.get("title", case_id)
		EventBus.toast_requested.emit("📂 %s Başlatıldı" % title)

		# Reset in-case state for a fresh chapter playthrough
		GameState.discovered_evidence.clear()
		GameState.collected_statements.clear()
		GameState.unlocked_deductions.clear()
		GameState.inspected_objects.clear()
		GameState.accusation_chances_left = 3
		GameState.case_solved = false
		GameState.flags.clear()
		GameState.inventory_items.clear()
		GameState.selected_souvenir = ""
		GameState.current_room_id = "silas_office"
		GameState.store_current_case_state()

		# 1. Silas starts in his office, movement temporarily locked
		load_room("silas_office", "default")
		GameState.can_player_move = false

		# 2. Masadaki telefon net şekilde çalar (zil sesi + titreşim), ardından konuşma açılır
		if current_room_node and current_room_node.has_method("start_incoming_call"):
			current_room_node.start_incoming_call(0.5, 1.6)
		elif current_room_node and current_room_node.has_method("start_phone_timer"):
			current_room_node.start_phone_timer(0.5)

		if case_id == "case01":
			EventBus.inner_voice_requested.emit("\"Fırtına gittikçe şiddetleniyor... Ofiste bu saatte kim arar?\"")
		elif case_id == "case02":
			EventBus.inner_voice_requested.emit("\"Fırtına rıhtıma doğru sürükleniyor... Ofisteki telefon çalıyor.\"")
		elif case_id == "case03":
			EventBus.inner_voice_requested.emit("\"Kraliyet Operası gecesi... Ofisteki telefon ısrarla çalıyor.\"")

func _on_case_selected(case_id: String) -> void:
	_start_case_sequence(case_id)

func _on_case_continue_requested(next_case_id: String) -> void:
	_start_case_sequence(next_case_id)

func _return_to_main_menu() -> void:
	# Close pause menu if open
	var pause_menu = $UIOverlays.get_node_or_null("PauseMenu")
	if pause_menu and pause_menu.has_method("close_menu"):
		pause_menu.close_menu()
	elif pause_menu:
		pause_menu.visible = false

	# Close any cutscenes / dialogues / modals
	if story_cutscene:
		story_cutscene.visible = false
	if phone_call_dialogue:
		phone_call_dialogue.visible = false
	if arrival_dialogue:
		arrival_dialogue.visible = false
	CutsceneManager.is_cutscene_active = false

	# Close UI overlays
	for overlay in [souvenir_modal, second_call, light_range_modal, tumbler_lock_modal, safe_dial_modal, crane_winch_modal]:
		if overlay and is_instance_valid(overlay):
			overlay.visible = false

	var inspect = $UIOverlays.get_node_or_null("InspectView")
	if inspect and is_instance_valid(inspect):
		inspect.visible = false

	# Hide HUD and disable movement
	hud.visible = false
	GameState.can_player_move = false

	# Unload active room
	if current_room_node and is_instance_valid(current_room_node):
		current_room_node.queue_free()
		current_room_node = null

	# Play main menu music
	AudioManager.play_music("res://assets/audio/bgm_noir_piano.mp3")

	# Show main menu
	if main_menu and is_instance_valid(main_menu):
		main_menu.open_menu()

func _on_new_game_started() -> void:
	_is_replaying_intro = false
	_is_intro_active = true
	_previous_state_before_intro.clear()

	# Start intro sequence for New Game
	hud.visible = false
	GameState.can_player_move = false
	if intro_sequence:
		intro_sequence.visible = true
		intro_sequence.start_intro()
	else:
		_start_hub_opening()

func _on_intro_completed() -> void:
	if intro_sequence:
		intro_sequence.visible = false

	GameState.intro_seen = true
	SaveSystem.save_game()

	if _is_replaying_intro:
		_is_replaying_intro = false
		_is_intro_active = false
		if _previous_state_before_intro.get("main_menu_visible", false):
			main_menu.open_menu()
		elif _previous_state_before_intro.get("pause_menu_visible", false):
			var pause_menu = $UIOverlays.get_node_or_null("PauseMenu")
			if pause_menu:
				pause_menu.open_menu()
		else:
			hud.visible = _previous_state_before_intro.get("hud_visible", true)
			GameState.can_player_move = _previous_state_before_intro.get("can_move", true)
		_previous_state_before_intro.clear()
		return

	if not _is_intro_active:
		# If intro was not actively initiated, do not reset gameplay
		return

	_is_intro_active = false
	_start_hub_opening()

func _start_hub_opening() -> void:
	_start_case_sequence("case01")

func _on_intro_replay_requested() -> void:
	_is_replaying_intro = true
	_is_intro_active = true
	var pause_menu = $UIOverlays.get_node_or_null("PauseMenu")
	_previous_state_before_intro = {
		"hud_visible": hud.visible,
		"main_menu_visible": main_menu.visible,
		"pause_menu_visible": (pause_menu.visible if pause_menu else false),
		"can_move": GameState.can_player_move
	}

	hud.visible = false
	main_menu.visible = false
	if pause_menu:
		pause_menu.visible = false
	GameState.can_player_move = false

	if intro_sequence:
		intro_sequence.visible = true
		intro_sequence.start_intro()

func _on_continue_game() -> void:
	hud.visible = true
	GameState.can_player_move = true
	load_room(GameState.current_room_id, "default")

func _unhandled_input(event: InputEvent) -> void:
	if not GameState.can_player_move:
		return

	var target_pos = Vector2.ZERO
	var is_click_or_touch = false

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		target_pos = get_global_mouse_position()
		is_click_or_touch = true
	elif event is InputEventScreenTouch and event.pressed:
		target_pos = get_canvas_transform().affine_inverse() * event.position
		is_click_or_touch = true

	if is_click_or_touch:
		var best_interactable: Node2D = null
		var min_tap_dist = 30.0
		if current_room_node:
			for child in current_room_node.get_children():
				if child.has_method("interact") and child.visible:
					var d = child.global_position.distance_to(target_pos)
					if d < min_tap_dist:
						min_tap_dist = d
						best_interactable = child
		if best_interactable:
			InputManager.request_interact_with(best_interactable)
		else:
			InputManager.request_move_to(target_pos)

func get_room_scene_path(room_id: String) -> String:
	if room_id == "silas_office":
		return "res://scenes/hub/silas_office.tscn"
	var case_rooms = GameState.case_data.get("rooms", {})
	if case_rooms.has(room_id):
		var p = case_rooms[room_id]
		if ResourceLoader.exists(p):
			return p
	var case_room_path = "res://cases/%s/rooms/%s.tscn" % [GameState.current_case_id, room_id]
	if ResourceLoader.exists(case_room_path):
		return case_room_path
	var hub_room = "res://scenes/hub/%s.tscn" % room_id
	if ResourceLoader.exists(hub_room):
		return hub_room
	return ""

func load_room(room_id: String, spawn_point_name: String) -> void:
	var scene_path = get_room_scene_path(room_id)
	if scene_path.is_empty():
		push_error("[Main] Unknown room ID: " + room_id)
		return

	GameState.can_player_move = false
	GameState.current_room_id = room_id

	# Remove previous room
	if current_room_node:
		current_room_node.queue_free()
		current_room_node = null

	# Instance new room
	var scene_res = load(scene_path)
	current_room_node = scene_res.instantiate()
	room_container.add_child(current_room_node)

	# Hook office telephone if in silas_office
	if room_id == "silas_office":
		var office = current_room_node
		if office.has_signal("phone_picked_up") and not office.phone_picked_up.is_connected(_on_office_phone_answered):
			office.phone_picked_up.connect(_on_office_phone_answered)
		if office.has_signal("second_call_triggered") and not office.second_call_triggered.is_connected(_on_second_call_triggered):
			office.second_call_triggered.connect(_on_second_call_triggered)
		# Connect telephone interactable directly
		var phone_node = current_room_node.find_child("TelephoneInteract", true, false)
		if phone_node and not phone_node.area_2d.input_event.is_connected(_on_phone_area_clicked):
			phone_node.area_2d.input_event.connect(_on_phone_area_clicked)

	# Position player at spawn marker
	if player and player.has_method("reset_interaction_state"):
		player.reset_interaction_state()

	var spawn_pos = Vector2(240, 245)
	var spawn_node = current_room_node.find_child("Spawn_" + spawn_point_name, true, false)
	if spawn_node:
		spawn_pos = spawn_node.global_position
	else:
		var default_spawn = current_room_node.find_child("Spawn_default", true, false)
		if default_spawn:
			spawn_pos = default_spawn.global_position

	player.global_position = spawn_pos
	if player.has_method("reset_interaction_state"):
		player.reset_interaction_state()
	EventBus.room_changed.emit(room_id)

	if not CutsceneManager.is_cutscene_active and not phone_call_dialogue.visible and not arrival_dialogue.visible:
		GameState.can_player_move = true

func _on_phone_area_clicked(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		if current_room_node and current_room_node.has_method("answer_phone"):
			current_room_node.answer_phone()

func _on_office_phone_answered() -> void:
	if not GameState.case_solved:
		_trigger_phone_call()

func _on_second_call_triggered() -> void:
	if player and player.has_method("set_on_phone"):
		player.set_on_phone(true)
	if second_call:
		second_call.start_second_call()

func get_cutscene_json_path(cutscene_name: String) -> String:
	var modular_path = "res://cases/%s/data/cutscenes/%s.json" % [GameState.current_case_id, cutscene_name]
	if ResourceLoader.exists(modular_path) or FileAccess.file_exists(ProjectSettings.globalize_path(modular_path)):
		return modular_path
	var case_legacy = "res://data/cases/%s/cutscenes/%s.json" % [GameState.current_case_id, cutscene_name]
	if ResourceLoader.exists(case_legacy) or FileAccess.file_exists(ProjectSettings.globalize_path(case_legacy)):
		return case_legacy
	return "res://data/cutscenes/%s.json" % cutscene_name

func _trigger_phone_call() -> void:
	if GameState.case_solved:
		return
	if not phone_call_dialogue.visible:
		EventBus.toast_requested.emit("")
		if player and player.has_method("set_on_phone"):
			player.set_on_phone(true)
		var call_json = get_cutscene_json_path("phone_call")
		phone_call_dialogue.start_phone_call(call_json)

func _on_phone_call_completed(_attitude: String) -> void:
	if player and player.has_method("set_on_phone"):
		player.set_on_phone(false)
	# Transition from phone call to travel cutscene
	await fade_transition.fade_out(0.2)
	var travel_json = get_cutscene_json_path("travel")
	story_cutscene.load_and_play(travel_json)
	await fade_transition.fade_in(0.2)

func _on_cutscene_finished(cutscene_id: String) -> void:
	if cutscene_id == "prologue_intro":
		if current_room_node and current_room_node.has_method("start_phone_timer"):
			current_room_node.start_phone_timer(3.5)
		EventBus.inner_voice_requested.emit("\"Yağmur dinmiyor. Masadaki eşyalara göz atsam iyi olur...\"")
	elif cutscene_id == "travel":
		# When travel ends, show arrival at manor door
		arrival_dialogue.start_arrival(get_cutscene_json_path("arrival"))
	elif cutscene_id == "travel_case02":
		await fade_transition.fade_out(0.2)
		story_cutscene.load_and_play(get_cutscene_json_path("arrival"))
		await fade_transition.fade_in(0.2)
	elif cutscene_id == "arrival_case02":
		# Step into Greywater Docks Pier (Crime Scene)
		await fade_transition.fade_out(0.25)
		load_room("dock_pier", "default")
		await fade_transition.fade_in(0.25)
	elif cutscene_id == "travel_case03":
		await fade_transition.fade_out(0.2)
		story_cutscene.load_and_play(get_cutscene_json_path("arrival"))
		await fade_transition.fade_in(0.2)
	elif cutscene_id == "arrival_case03":
		# Step into Greywater Royal Opera Foyer (Crime Scene)
		await fade_transition.fade_out(0.25)
		load_room("opera_foyer", "default")
		await fade_transition.fade_in(0.25)

func _on_arrival_finished() -> void:
	# Seamlessly step into Harlow Manor Main Hall!
	await fade_transition.fade_out(0.25)
	load_room("main_hall", "default")
	await fade_transition.fade_in(0.25)

func _on_room_change_requested(target_room_id: String, target_spawn: String) -> void:
	GameState.can_player_move = false
	await fade_transition.fade_out(0.2)
	load_room(target_room_id, target_spawn)
	SaveSystem.save_game()
	await fade_transition.fade_in(0.2)

func shake_camera(intensity: float = 2.0, duration: float = 0.25) -> void:
	if not camera:
		return
	if _shake_tween and _shake_tween.is_valid():
		_shake_tween.kill()

	_shake_tween = create_tween()
	var steps = int(duration / 0.04)
	for i in range(steps):
		var damp = 1.0 - float(i) / float(steps)
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)) * damp
		_shake_tween.tween_property(camera, "offset", offset, 0.04)
	_shake_tween.tween_property(camera, "offset", Vector2.ZERO, 0.04)

