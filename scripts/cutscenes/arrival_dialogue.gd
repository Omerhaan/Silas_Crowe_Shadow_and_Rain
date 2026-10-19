extends CanvasLayer

## Arrival doorstep cinematic dialogue scene between Silas, Margaret Doyle, and Dr. Hale.
## Uses the shared DialogueBox component.

signal arrival_finished

@onready var dialogue_box: Control = $CenterBox/DialogueBox
@onready var skip_btn: Button = $CenterBox/ControlsBox/SkipButton

var lines: Array = []
var current_index: int = 0

func _ready() -> void:
	visible = false
	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)
	if dialogue_box:
		dialogue_box.advance_requested.connect(advance)

func start_arrival(json_path: String = "") -> void:
	if json_path == "":
		json_path = "res://cases/%s/data/cutscenes/arrival.json" % GameState.current_case_id
	var data = GameState._load_json_file(json_path)
	lines = data.get("lines", [])
	current_index = 0
	visible = true
	GameState.can_player_move = false
	show_current_line()

func show_current_line() -> void:
	if current_index >= lines.size():
		finish()
		return

	var line = lines[current_index]
	var spk = line.get("speaker", "")
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var txt = line.get("en", line.get("text_en", line.get("text", ""))) if is_en else line.get("text", "")
	dialogue_box.set_dialogue(spk, txt)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
	elif event is InputEventScreenTouch and event.pressed:
		advance()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		advance()

func advance() -> void:
	current_index += 1
	show_current_line()

func _on_skip_pressed() -> void:
	finish()

func finish() -> void:
	visible = false
	GameState.can_player_move = true
	arrival_finished.emit()
