extends Control

## Confrontation dialogue sequence between Silas Crowe and Dr. Victor Hale.
## Uses the shared DialogueBox component.

@onready var dialogue_box: Control = $CenterBox/DialogueBox
@onready var next_btn: Button = $CenterBox/Controls/NextBtn
@onready var backdrop_image: TextureRect = get_node_or_null("BackdropImage")

var lines: Array = []
var current_line_index: int = 0

var current_culprit: String = "hale"

func _load_dialogue_lines() -> void:
	var path = "res://cases/case01/data/cutscenes/confrontation_hale.json"
	if current_culprit == "vance":
		path = "res://cases/case02/data/cutscenes/confrontation_vance.json"
	elif current_culprit == "unknown_sniper":
		path = "res://cases/case03/data/cutscenes/confrontation_sniper.json"
	var loaded = GameState._load_json_file(path)
	if loaded is Array:
		lines = loaded

func _ready() -> void:
	visible = false
	next_btn.pressed.connect(_on_next_pressed)
	if dialogue_box:
		dialogue_box.advance_requested.connect(_on_next_pressed)
	EventBus.accusation_resolved.connect(_on_accusation_resolved)

func _on_accusation_resolved(success: bool, culprit_id: String) -> void:
	if success:
		if culprit_id in ["hale", "vance", "unknown_sniper"]:
			current_culprit = culprit_id
			start_confrontation()

func start_confrontation() -> void:
	_load_dialogue_lines()
	visible = true
	current_line_index = 0
	GameState.can_player_move = false
	GameState.case_solved = true

	if backdrop_image:
		backdrop_image.visible = false
		backdrop_image.texture = null

	# Play dramatic objection stinger and shake camera
	AudioManager.play_sfx("objection")
	if current_culprit == "hale":
		EventBus.deduction_made.emit("D7")
		# Automatically award Chapter 1 Kuzey Parçası
		if not "photo_piece_harlow_silas" in GameState.memory_wall_items:
			GameState.memory_wall_items.append("photo_piece_harlow_silas")
		if not "watch_k5_drawing" in GameState.memory_wall_items:
			GameState.memory_wall_items.append("watch_k5_drawing")
	elif current_culprit == "vance":
		EventBus.deduction_made.emit("D203")
		if not "watch_k3_drawing" in GameState.memory_wall_items:
			GameState.memory_wall_items.append("watch_k3_drawing")
	elif current_culprit == "unknown_sniper":
		EventBus.deduction_made.emit("D306")
		if not "watch_k4_drawing" in GameState.memory_wall_items:
			GameState.memory_wall_items.append("watch_k4_drawing")
		if not "photo_piece_sniper_elias" in GameState.memory_wall_items:
			GameState.memory_wall_items.append("photo_piece_sniper_elias")

	_display_current_line()

func _display_current_line() -> void:
	if current_line_index >= lines.size():
		_finish_confrontation()
		return

	var cur = lines[current_line_index]
	var spk = cur.get("speaker", "Silas Crowe")
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var txt = cur.get("en", cur.get("text_en", cur.get("text", ""))) if is_en else cur.get("text", "")

	# Extra dramatic impact when suspect confesses
	if (spk.contains("Hale") or spk.contains("Vance") or spk.contains("Tetikçi") or spk.contains("Sniper")) and current_line_index == 3:
		AudioManager.play_sfx("chime")
		if current_culprit == "hale":
			EventBus.deduction_made.emit("D7")
		elif current_culprit == "vance":
			EventBus.deduction_made.emit("D203")
		elif current_culprit == "unknown_sniper":
			EventBus.deduction_made.emit("D306")

	if backdrop_image:
		var img_path = cur.get("image", "")
		if img_path != "":
			var tex = _load_texture_resilient(img_path)
			if tex:
				backdrop_image.texture = tex
				backdrop_image.visible = true

	dialogue_box.set_dialogue(spk, txt)

func _on_next_pressed() -> void:
	current_line_index += 1
	_display_current_line()

func _finish_confrontation() -> void:
	visible = false
	if backdrop_image:
		backdrop_image.visible = false
		backdrop_image.texture = null
	GameState.can_player_move = false
	GameState.complete_current_case()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	if current_culprit == "vance":
		var toast = "⚖ Case 2 Solved: Captain Vance Arrested." if is_en else "⚖ Vaka 2 Çözüldü: Kaptan Vance Tutuklandı."
		EventBus.toast_requested.emit(toast)
	elif current_culprit == "unknown_sniper":
		var toast = "⚖ Case 3 Solved: The Blind Spot Exposed." if is_en else "⚖ Vaka 3 Çözüldü: Kör Nokta Suikastı Aydınlatıldı."
		EventBus.toast_requested.emit(toast)
	else:
		var toast = "⚖ Case 1 Solved: Dr. Victor Hale Arrested." if is_en else "⚖ Vaka 1 Çözüldü: Dr. Victor Hale Tutuklandı."
		EventBus.toast_requested.emit(toast)
	# Launch Newspaper, Detective Rating, and Credits ending sequence
	EventBus.case_ending_requested.emit()

func _load_texture_resilient(base_path: String) -> Texture2D:
	if base_path == "":
		return null
	var candidates = [
		base_path,
		"res://assets/sprites/cinematics/" + base_path.get_file(),
		"res://cases/case03/assets/cinematics/" + base_path.get_file()
	]
	for p in candidates:
		if ResourceLoader.exists(p):
			var res = load(p)
			if res is Texture2D:
				return res
		var gp = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(gp):
			var img = Image.load_from_file(gp)
			if img:
				return ImageTexture.create_from_image(img)
	return null
