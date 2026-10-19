extends CanvasLayer

## Interactive phone call dialogue system with audio crackle, tick-tock cues, and choices.
## Uses the shared DialogueBox component with framed portraits and speaker badges.

signal phone_call_completed(attitude: String)

@onready var dialogue_box: Control = $Container/DialogueBox
@onready var choice_container: VBoxContainer = $Container/ChoiceContainer
@onready var backdrop_texture: TextureRect = get_node_or_null("BackdropTexture")

var phone_cinematic_tex: Texture2D = null
var call_data: Dictionary = {}
var phase: String = "opening" # "opening", "choice", "reply", "closing", "done"
var current_line_index: int = 0
var opening_lines: Array = []
var closing_lines: Array = []
var choices: Array = []
var selected_choice_data: Dictionary = {}

func _ready() -> void:
	visible = false
	choice_container.visible = false
	if dialogue_box:
		dialogue_box.advance_requested.connect(advance)

	var p_path = "res://assets/sprites/cinematics/cinematic_prologue_02.png"
	if ResourceLoader.exists(p_path):
		phone_cinematic_tex = load(p_path)
	else:
		var gp = ProjectSettings.globalize_path(p_path)
		if FileAccess.file_exists(gp):
			var img = Image.load_from_file(gp)
			if img:
				phone_cinematic_tex = ImageTexture.create_from_image(img)

	if backdrop_texture and phone_cinematic_tex:
		backdrop_texture.texture = phone_cinematic_tex

func _process(_delta: float) -> void:
	if visible and backdrop_texture:
		var jitter = sin(Time.get_ticks_msec() * 0.003) * 0.015
		backdrop_texture.scale = Vector2(1.0 + jitter, 1.0 + jitter)

func start_phone_call(json_path: String = "") -> void:
	if json_path == "":
		json_path = "res://cases/%s/data/cutscenes/phone_call.json" % GameState.current_case_id
	call_data = GameState._load_json_file(json_path)
	opening_lines = call_data.get("opening_lines", [])
	closing_lines = call_data.get("closing_lines", [])
	choices = call_data.get("choices", [])

	phase = "opening"
	current_line_index = 0
	visible = true
	GameState.can_player_move = false

	AudioManager.play_sfx("phone_ring")
	show_current_step()

func show_current_step() -> void:
	choice_container.visible = false

	if phase == "opening":
		if current_line_index < opening_lines.size():
			var line = opening_lines[current_line_index]
			_render_line(line)
		else:
			phase = "choice"
			_show_choices()

	elif phase == "reply":
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
		if current_line_index == 0:
			var rep_txt = selected_choice_data.get("caller_reply_en", selected_choice_data.get("caller_reply", "")) if is_en else selected_choice_data.get("caller_reply", "")
			_render_line({
				"speaker": "???",
				"text": rep_txt
			})
		elif current_line_index == 1:
			var iv_txt = selected_choice_data.get("inner_voice_en", selected_choice_data.get("inner_voice", "")) if is_en else selected_choice_data.get("inner_voice", "")
			_render_line({
				"speaker": "INNER_VOICE",
				"text": iv_txt
			})
		else:
			phase = "closing"
			current_line_index = 0
			show_current_step()

	elif phase == "closing":
		if current_line_index < closing_lines.size():
			var line = closing_lines[current_line_index]
			_render_line(line)
		else:
			finish_call()

func _render_line(line: Dictionary) -> void:
	var spk = line.get("speaker", "???")
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var txt = line.get("en", line.get("text_en", line.get("text", ""))) if is_en else line.get("text", "")
	dialogue_box.set_dialogue(spk, txt)

func _show_choices() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var prompt_txt = "The raspy voice on the receiver awaits an answer..." if is_en else "Telefondaki hırıltılı ses bir yanıt bekliyor..."
	dialogue_box.set_dialogue("???", prompt_txt)
	for c in choice_container.get_children():
		c.queue_free()
	choice_container.visible = true

	for i in range(choices.size()):
		var choice = choices[i]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 20)
		btn.add_theme_font_size_override("font_size", 6)
		btn.text = choice.get("en", choice.get("text_en", choice.get("text", ""))) if is_en else choice.get("text", "")
		btn.pressed.connect(func(): _on_choice_selected(choice))
		choice_container.add_child(btn)

func _on_choice_selected(choice: Dictionary) -> void:
	choice_container.visible = false
	selected_choice_data = choice
	phase = "reply"
	current_line_index = 0
	GameState.flags["phone_attitude"] = choice.get("attitude", "neutral")
	show_current_step()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if phase == "choice":
		var is_choice_1 = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_1 or event.keycode == KEY_KP_1)) or (InputMap.has_action("choice_1") and event.is_action_pressed("choice_1"))
		var is_choice_2 = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_2 or event.keycode == KEY_KP_2)) or (InputMap.has_action("choice_2") and event.is_action_pressed("choice_2"))
		var is_choice_3 = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_3 or event.keycode == KEY_KP_3)) or (InputMap.has_action("choice_3") and event.is_action_pressed("choice_3"))

		if is_choice_1:
			if choices.size() > 0: _on_choice_selected(choices[0])
		elif is_choice_2:
			if choices.size() > 1: _on_choice_selected(choices[1])
		elif is_choice_3:
			if choices.size() > 2: _on_choice_selected(choices[2])
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
	elif event is InputEventScreenTouch and event.pressed:
		advance()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		advance()

func advance() -> void:
	if phase == "choice":
		return
	current_line_index += 1
	show_current_step()

func finish_call() -> void:
	visible = false
	GameState.can_player_move = false
	var attitude = selected_choice_data.get("attitude", "neutral")
	phone_call_completed.emit(attitude)
