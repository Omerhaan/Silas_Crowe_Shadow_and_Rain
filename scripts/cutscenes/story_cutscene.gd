extends CanvasLayer

## Atmospheric narrative cutscene viewer.
## Displays noir letterboxing, sleek subtitle bar, slide progression, and skip controls.

@onready var chapter_title: Label = $TopLetterbox/TopMargin/HBox/ChapterTitle
@onready var speaker_badge: Label = $SubtitleCard/Margin/HBox/SpeakerBadge
@onready var dialogue_label: Label = $SubtitleCard/Margin/HBox/DialogueLabel
@onready var advance_btn: Button = $SubtitleCard/Margin/HBox/AdvanceButton
@onready var skip_btn: Button = $TopLetterbox/TopMargin/HBox/SkipButton
@onready var cinematic_texture: TextureRect = $CinematicTexture
@onready var subtitle_card: Control = $SubtitleCard

var cutscene_data: Dictionary = {}
var current_slide_index: int = 0
var slides: Array = []
var slide_timer: float = 0.0
var auto_advance: bool = false
var active_tween: Tween = null
var text_tween: Tween = null

func _ready() -> void:
	visible = false
	skip_btn.pressed.connect(_on_skip_pressed)
	advance_btn.pressed.connect(advance)
	set_process_input(true)
	if EventBus.has_signal("font_scale_changed"):
		EventBus.font_scale_changed.connect(apply_font_scale)
	apply_font_scale(GameState.get_font_scale())

func apply_font_scale(scale: String) -> void:
	var font_dialogue = 8
	var font_badge = 7
	var font_btn = 7
	if scale == "small":
		font_dialogue = 7
		font_badge = 6
		font_btn = 6
	elif scale == "large":
		font_dialogue = 10
		font_badge = 8
		font_btn = 8

	if dialogue_label:
		dialogue_label.add_theme_font_size_override("font_size", font_dialogue)
	if speaker_badge:
		speaker_badge.add_theme_font_size_override("font_size", font_badge)
	if advance_btn:
		advance_btn.add_theme_font_size_override("font_size", font_btn)
	if skip_btn:
		skip_btn.add_theme_font_size_override("font_size", font_btn)

func load_and_play(json_path: String) -> void:
	var data = GameState._load_json_file(json_path)
	if data is Dictionary:
		cutscene_data = data
		slides = data.get("slides", [])
		current_slide_index = 0
		auto_advance = data.get("auto_advance", false)
		visible = true
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
		var title_str = data.get("title_en", data.get("title", "Gölge ve Yağmur")) if is_en else data.get("title", "Gölge ve Yağmur")
		var brand = "✦ SHADOW & RAIN ✦  |  " if is_en else "✦ GÖLGE VE YAĞMUR ✦  |  "
		chapter_title.text = brand + title_str.to_upper()
		CutsceneManager.start_cutscene(data.get("cutscene_id", "cutscene"))
		show_current_slide()

func show_current_slide() -> void:
	if current_slide_index >= slides.size():
		finish()
		return

	if active_tween and active_tween.is_valid():
		active_tween.kill()
	if text_tween and text_tween.is_valid():
		text_tween.kill()

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	var slide = slides[current_slide_index]
	var txt = slide.get("en", slide.get("text_en", slide.get("text", ""))) if is_en else slide.get("text", "")
	var spk = slide.get("speaker", "SILAS")
	if is_en and (spk == "İÇ SES" or spk == "IC SES"):
		spk = "INNER VOICE"
	elif is_en and (spk == "DIŞ SES" or spk == "DIS SES"):
		spk = "NARRATOR"

	speaker_badge.text = (spk + ":").to_upper()
	dialogue_label.text = txt
	slide_timer = slide.get("duration", 8.0)

	# Atmospheric SFX trigger
	var sfx = slide.get("sfx", "")
	if sfx == "thunder" or sfx == "thunder_soft":
		AudioManager.play_thunder()
	elif sfx == "rain_loop":
		AudioManager.start_rain()

	# Load and display cinematic image if present
	if slide.has("image") and slide["image"] != "":
		var img_path = slide["image"]
		var tex: Texture2D = _load_texture_resilient(img_path)
		if tex and cinematic_texture:
			cinematic_texture.texture = tex
			cinematic_texture.visible = true
			# Strict 1:1 scale - no zoom distortion or crop
			cinematic_texture.scale = Vector2.ONE
			cinematic_texture.modulate = Color(1, 1, 1, 0.4)

			active_tween = create_tween()
			active_tween.tween_property(cinematic_texture, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
		elif cinematic_texture:
			cinematic_texture.visible = false
			cinematic_texture.texture = null
	elif cinematic_texture:
		cinematic_texture.visible = false
		cinematic_texture.texture = null

	# Text smooth fade-in
	subtitle_card.modulate.a = 0.3
	text_tween = create_tween()
	text_tween.tween_property(subtitle_card, "modulate:a", 1.0, 0.25)

	# Update button text for last slide vs intermediate slide
	skip_btn.text = "Skip [ESC] ▶▶" if is_en else "Atla [ESC] ▶▶"
	if current_slide_index == slides.size() - 1:
		advance_btn.text = "▶ Begin" if is_en else "▶ Başla"
	else:
		advance_btn.text = "▶ Next" if is_en else "▶ İlerle"

func _process(delta: float) -> void:
	if not visible:
		return
	if auto_advance and slide_timer > 0.0:
		slide_timer -= delta
		if slide_timer <= 0.0:
			advance()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		advance()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		advance()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E:
			advance()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			finish()
			get_viewport().set_input_as_handled()

func advance() -> void:
	current_slide_index += 1
	if current_slide_index < slides.size():
		show_current_slide()
	else:
		finish()

func _on_skip_pressed() -> void:
	finish()

func finish() -> void:
	visible = false
	var cid = cutscene_data.get("cutscene_id", "cutscene")
	CutsceneManager.finish_cutscene(cid)

func _load_texture_resilient(base_path: String) -> Texture2D:
	if base_path == "":
		return null

	var candidates = [base_path]
	if base_path.ends_with(".png"):
		candidates.append(base_path.trim_suffix(".png") + ".jpg")
		candidates.append(base_path.trim_suffix(".png") + ".jpeg")
	elif base_path.ends_with(".jpg"):
		candidates.append(base_path.trim_suffix(".jpg") + ".png")
	elif base_path.ends_with(".jpeg"):
		candidates.append(base_path.trim_suffix(".jpeg") + ".png")

	# Check modular case paths as fallback
	var b_name = base_path.get_file()
	var case_id = GameState.current_case_id
	candidates.append("res://cases/%s/assets/cinematics/%s" % [case_id, b_name])
	candidates.append("res://cases/%s/assets/cinematics/%s.jpg" % [case_id, b_name.get_basename()])
	candidates.append("res://cases/%s/assets/cinematics/%s.png" % [case_id, b_name.get_basename()])
	candidates.append("res://assets/cases/%s/cinematics/%s" % [case_id, b_name])
	candidates.append("res://assets/cases/%s/cinematics/%s.jpg" % [case_id, b_name.get_basename()])
	candidates.append("res://assets/cases/%s/cinematics/%s.png" % [case_id, b_name.get_basename()])
	candidates.append("res://assets/sprites/cinematics/%s" % b_name)
	candidates.append("res://assets/sprites/cinematics/%s.jpg" % b_name.get_basename())
	candidates.append("res://assets/sprites/cinematics/%s.png" % b_name.get_basename())

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
