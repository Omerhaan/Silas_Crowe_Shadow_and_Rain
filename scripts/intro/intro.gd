extends Control

## Noir Intro Sequence for Gölge ve Yağmur.
## Displays cards from data/story/intro.json on pure black background with gentle fades,
## rain ambiance, card 7 remote thunder rumble, touch/Space/E advance, and a >=36x36 Skip button.

signal intro_completed
signal card_changed(card_index: int)

enum State {
	IDLE,
	FADING_IN,
	DISPLAYING,
	FADING_OUT,
	TITLE_CARD,
	TRANSITIONING_OUT,
	FINISHED
}

const DATA_PATH = "res://data/story/intro.json"
const DEFAULT_FADE_DURATION = 0.8

@onready var background: ColorRect = $Background
@onready var card_container: Control = $CardContainer
@onready var card_label: Label = $CardContainer/CardLabel
@onready var title_container: Control = $TitleContainer
@onready var title_label: Label = $TitleContainer/TitleVBox/TitleLabel
@onready var prompt_label: Label = $TitleContainer/TitleVBox/PromptLabel
@onready var skip_btn: Button = $TopBar/SkipButton

var intro_data: Dictionary = {}
var cards: Array = []
var current_card_index: int = 0
var current_state: State = State.IDLE
var fade_duration: float = DEFAULT_FADE_DURATION

var active_tween: Tween = null
var pulse_tween: Tween = null
var display_timer: float = 0.0

func _ready() -> void:
	# Setup styles & colors
	_setup_visuals()

	# Connect skip button
	if skip_btn:
		skip_btn.pressed.connect(_on_skip_pressed)

	# Load story data from JSON
	_load_intro_data()

	current_card_index = 0
	if not cards.is_empty():
		var card = cards[0]
		card_label.text = card.get("text", "")

	# If embedded in main game UIOverlays, stay dormant until start_intro() is called.
	# Otherwise (standalone or automated tests), start intro immediately.
	if get_parent() and get_parent().name == "UIOverlays":
		visible = false
		current_state = State.IDLE
		set_process(false)
		set_process_unhandled_input(false)
	else:
		start_intro()

func _setup_visuals() -> void:
	# Pure black background
	if background:
		background.color = Color(0, 0, 0, 1)

	# Safe layout for card label: max width ~380px, 12px safe margins on 480x270 screen
	if card_label:
		card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		card_label.modulate.a = 0.0

	# Title container initial state
	if title_container:
		title_container.modulate.a = 0.0

	# Skip button style (noir minimalist touch-friendly >= 36x36)
	if skip_btn:
		var sb_normal = StyleBoxFlat.new()
		sb_normal.bg_color = Color(0.08, 0.09, 0.12, 0.75)
		sb_normal.border_color = Color(0.35, 0.35, 0.4, 0.8)
		sb_normal.set_border_width_all(1)
		sb_normal.content_margin_left = 8
		sb_normal.content_margin_right = 8
		sb_normal.content_margin_top = 4
		sb_normal.content_margin_bottom = 4

		var sb_hover = sb_normal.duplicate()
		sb_hover.bg_color = Color(0.15, 0.16, 0.22, 0.9)
		sb_hover.border_color = Color(0.91, 0.78, 0.45, 1.0) # Candle gold

		skip_btn.add_theme_stylebox_override("normal", sb_normal)
		skip_btn.add_theme_stylebox_override("hover", sb_hover)
		skip_btn.add_theme_stylebox_override("pressed", sb_normal)
		skip_btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		skip_btn.add_theme_color_override("font_hover_color", Color(0.95, 0.85, 0.55))

func _load_intro_data() -> void:
	if not FileAccess.file_exists(DATA_PATH):
		push_error("[Intro] Story file not found: " + DATA_PATH)
		return

	var file = FileAccess.open(DATA_PATH, FileAccess.READ)
	var json_str = file.get_as_text()
	var json = JSON.new()
	var err = json.parse(json_str)
	if err != OK:
		push_error("[Intro] JSON parse error: " + json.get_error_message())
		return

	intro_data = json.data
	cards = intro_data.get("cards", [])
	fade_duration = intro_data.get("fade_duration", DEFAULT_FADE_DURATION)

	# Set UI texts from JSON (no hardcoded texts)
	var ui_data = intro_data.get("ui", {})
	if skip_btn:
		skip_btn.text = ui_data.get("skip_button", "Atla")

	var title_data = intro_data.get("title_card", {})
	if title_label:
		title_label.text = title_data.get("title", "")
	if prompt_label:
		prompt_label.text = title_data.get("prompt", "")

func start_intro() -> void:
	current_card_index = 0
	current_state = State.IDLE
	title_container.modulate.a = 0.0
	card_label.modulate.a = 0.0
	visible = true
	set_process(true)
	set_process_unhandled_input(true)

	# Start soft rain ambiance
	var ambient = intro_data.get("ambient_audio", "rain")
	if ambient == "rain" and AudioManager:
		AudioManager.start_rain()

	if cards.is_empty():
		_show_title_card()
	else:
		_show_card(current_card_index)

func _process(delta: float) -> void:
	if not visible or current_state == State.IDLE or current_state == State.FINISHED:
		return

	if current_state == State.DISPLAYING:
		display_timer -= delta
		if display_timer <= 0.0:
			_fade_out_current_card()

func _show_card(idx: int) -> void:
	current_card_index = idx
	if idx >= cards.size():
		_show_title_card()
		return

	var card = cards[idx]
	var txt = card.get("text", "")
	var duration = card.get("duration", 4.0)

	card_label.text = txt
	card_label.modulate.a = 0.0
	current_state = State.FADING_IN

	# Audio triggers per card (e.g. 7th card remote thunder rumble)
	var sfx = card.get("sfx", "")
	if sfx == "thunder" or idx == 6: # 7th card (0-indexed 6)
		if AudioManager:
			AudioManager.play_thunder()
	elif not sfx.is_empty() and AudioManager:
		AudioManager.play_sfx(sfx)

	card_changed.emit(idx)

	# Smooth fade-in
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.tween_property(card_label, "modulate:a", 1.0, fade_duration)
	active_tween.finished.connect(func():
		current_state = State.DISPLAYING
		display_timer = duration
	)

func _fade_out_current_card(fast: bool = false) -> void:
	current_state = State.FADING_OUT

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	var duration = fade_duration * 0.5 if fast else fade_duration
	active_tween = create_tween()
	active_tween.tween_property(card_label, "modulate:a", 0.0, duration)
	active_tween.finished.connect(func():
		_advance_to_next_card()
	)

func _advance_to_next_card() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	card_label.modulate.a = 0.0
	current_card_index += 1
	if current_card_index < cards.size():
		_show_card(current_card_index)
	else:
		_show_title_card()

func _show_title_card() -> void:
	current_state = State.TITLE_CARD
	card_label.modulate.a = 0.0

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	title_container.modulate.a = 0.0
	active_tween = create_tween()
	active_tween.tween_property(title_container, "modulate:a", 1.0, fade_duration)

	# Start soft pulsing prompt animation
	if prompt_label:
		if pulse_tween and pulse_tween.is_valid():
			pulse_tween.kill()
		pulse_tween = create_tween().set_loops()
		pulse_tween.tween_property(prompt_label, "modulate:a", 0.35, 0.75)
		pulse_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.75)

func advance() -> void:
	match current_state:
		State.FADING_IN:
			# Snap to fully visible immediately
			if active_tween and active_tween.is_valid():
				active_tween.kill()
			card_label.modulate.a = 1.0
			current_state = State.DISPLAYING
			var card = cards[current_card_index] if current_card_index < cards.size() else {}
			display_timer = card.get("duration", 4.0)

		State.DISPLAYING, State.FADING_OUT:
			# Advance directly to next card
			_advance_to_next_card()

		State.TITLE_CARD:
			_finish_intro()

		_:
			pass

func _on_skip_pressed() -> void:
	if current_state != State.TITLE_CARD and current_state != State.TRANSITIONING_OUT and current_state != State.FINISHED:
		# Jump immediately to the title card
		if active_tween and active_tween.is_valid():
			active_tween.kill()
		card_label.modulate.a = 0.0
		current_card_index = cards.size()
		_show_title_card()
	elif current_state == State.TITLE_CARD:
		_finish_intro()

func _finish_intro() -> void:
	if current_state == State.TRANSITIONING_OUT or current_state == State.FINISHED:
		return

	current_state = State.TRANSITIONING_OUT

	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	if fade_duration <= 0.05:
		current_state = State.FINISHED
		set_process(false)
		set_process_unhandled_input(false)
		visible = false
		intro_completed.emit()
		return

	# Smoothly fade out title card
	active_tween = create_tween()
	active_tween.tween_property(title_container, "modulate:a", 0.0, 0.4)
	active_tween.finished.connect(func():
		current_state = State.FINISHED
		set_process(false)
		set_process_unhandled_input(false)
		visible = false
		intro_completed.emit()
		
		# If running standalone as current scene, load main game scene
		if get_tree() and get_tree().current_scene == self:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	)

func finish_immediately() -> void:
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	current_state = State.FINISHED
	set_process(false)
	set_process_unhandled_input(false)
	visible = false
	intro_completed.emit()
	if get_tree() and get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not visible or current_state == State.IDLE or current_state == State.FINISHED or current_state == State.TRANSITIONING_OUT:
		return

	# Prevent touch/click on the skip button from double-triggering advance
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if skip_btn and skip_btn.get_global_rect().has_point(event.position):
			return
		get_viewport().set_input_as_handled()
		advance()
	elif event is InputEventScreenTouch and event.pressed:
		if skip_btn and skip_btn.get_global_rect().has_point(event.position):
			return
		get_viewport().set_input_as_handled()
		advance()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_E or event.keycode == KEY_ENTER:
			get_viewport().set_input_as_handled()
			advance()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance()
