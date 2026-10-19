extends Control

## Chapter / Case Selection Modal (Vaka Dosyaları ve Bölüm Seçimi).
## Displays available case dossiers with unlock progression, completion status, and direct launch buttons.

signal case_selected(case_id: String)
signal closed

@onready var backdrop: ColorRect = $Backdrop
@onready var modal_panel: Panel = $Panel
@onready var title_label: Label = $Panel/Title
@onready var subtitle_label: Label = $Panel/Subtitle
@onready var close_btn: Button = $Panel/CloseBtn
@onready var back_btn: Button = $Panel/FooterBox/BackBtn
@onready var info_label: Label = $Panel/FooterBox/InfoLabel

# Cards
@onready var card1: PanelContainer = $Panel/CardsContainer/CardCase01
@onready var card2: PanelContainer = $Panel/CardsContainer/CardCase02
@onready var card3: PanelContainer = $Panel/CardsContainer/CardCase03

@onready var card1_title: Label = $Panel/CardsContainer/CardCase01/Margin/VBox/TitleLabel
@onready var card1_sub: Label = $Panel/CardsContainer/CardCase01/Margin/VBox/SubLabel
@onready var card1_desc: Label = $Panel/CardsContainer/CardCase01/Margin/VBox/DescLabel
@onready var card1_status: Label = $Panel/CardsContainer/CardCase01/Margin/VBox/StatusLabel
@onready var card1_btn: Button = $Panel/CardsContainer/CardCase01/Margin/VBox/PlayBtn

@onready var card2_title: Label = $Panel/CardsContainer/CardCase02/Margin/VBox/TitleLabel
@onready var card2_sub: Label = $Panel/CardsContainer/CardCase02/Margin/VBox/SubLabel
@onready var card2_desc: Label = $Panel/CardsContainer/CardCase02/Margin/VBox/DescLabel
@onready var card2_status: Label = $Panel/CardsContainer/CardCase02/Margin/VBox/StatusLabel
@onready var card2_btn: Button = $Panel/CardsContainer/CardCase02/Margin/VBox/PlayBtn

@onready var card3_title: Label = $Panel/CardsContainer/CardCase03/Margin/VBox/TitleLabel
@onready var card3_sub: Label = $Panel/CardsContainer/CardCase03/Margin/VBox/SubLabel
@onready var card3_desc: Label = $Panel/CardsContainer/CardCase03/Margin/VBox/DescLabel
@onready var card3_status: Label = $Panel/CardsContainer/CardCase03/Margin/VBox/StatusLabel
@onready var card3_btn: Button = $Panel/CardsContainer/CardCase03/Margin/VBox/PlayBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_modal)
	back_btn.pressed.connect(close_modal)
	card1_btn.pressed.connect(func(): _on_case_btn_pressed("case01"))
	card2_btn.pressed.connect(func(): _on_case_btn_pressed("case02"))
	card3_btn.pressed.connect(func(): _on_case_btn_pressed("case03"))

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_modal()
		get_viewport().set_input_as_handled()

func open_modal() -> void:
	visible = true
	SaveSystem.sync_case_progress()
	_refresh_cards()
	card1_btn.grab_focus()

func close_modal() -> void:
	visible = false
	closed.emit()

func _refresh_cards() -> void:
	# Synchronize state from registry and completed_cases
	var reg = GameState.case_registry
	var completed = GameState.completed_cases

	var case1_data = _find_case_entry("case01", reg)
	var case2_data = _find_case_entry("case02", reg)
	var case3_data = _find_case_entry("case03", reg)

	title_label.text = tr("UI_CASE_DOSSIERS")
	subtitle_label.text = tr("UI_SELECT_CHAPTER_HINT")
	info_label.text = tr("UI_CHAPTER_UNLOCK_INFO")
	back_btn.text = tr("UI_BACK")

	# ---- Case 1 (Karanlık Malikâne) ----
	var c1_completed = ("case01" in completed) or (case1_data and case1_data.get("completed", false))
	card1_title.text = tr("UI_CHAPTER_1_TITLE")
	card1_sub.text = tr("UI_CHAPTER_1_SUB")
	card1_desc.text = tr("UI_CHAPTER_1_DESC")
	if c1_completed:
		card1_status.text = tr("UI_STATUS_COMPLETED")
		card1_status.add_theme_color_override("font_color", Color(0.96, 0.85, 0.35, 1.0))
		card1_btn.text = tr("UI_REPLAY_CHAPTER")
	else:
		card1_status.text = tr("UI_STATUS_UNLOCKED")
		card1_status.add_theme_color_override("font_color", Color(0.65, 0.85, 0.7, 1.0))
		card1_btn.text = tr("UI_PLAY_CHAPTER")
	card1_btn.disabled = false

	# ---- Case 2 (Sisli Liman) ----
	var c2_unlocked = c1_completed or (case2_data and case2_data.get("unlocked", false))
	var c2_completed = ("case02" in completed) or (case2_data and case2_data.get("completed", false))
	card2_title.text = tr("UI_CHAPTER_2_TITLE")
	card2_sub.text = tr("UI_CHAPTER_2_SUB")
	card2_desc.text = tr("UI_CHAPTER_2_DESC")
	if c2_unlocked:
		if c2_completed:
			card2_status.text = tr("UI_STATUS_COMPLETED")
			card2_status.add_theme_color_override("font_color", Color(0.96, 0.85, 0.35, 1.0))
			card2_btn.text = tr("UI_REPLAY_CHAPTER")
		else:
			card2_status.text = tr("UI_STATUS_UNLOCKED")
			card2_status.add_theme_color_override("font_color", Color(0.65, 0.85, 0.7, 1.0))
			card2_btn.text = tr("UI_PLAY_CHAPTER")
		card2_btn.disabled = false
	else:
		card2_status.text = tr("UI_CASE_LOCKED")
		card2_status.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45, 0.9))
		card2_btn.text = "🔒 " + tr("UI_CASE_LOCKED")
		card2_btn.disabled = true

	# ---- Case 3 (Kuzey Operasyonu) ----
	var c3_unlocked = c2_completed or (case3_data and case3_data.get("unlocked", false))
	var c3_completed = ("case03" in completed) or (case3_data and case3_data.get("completed", false))
	card3_title.text = tr("UI_CHAPTER_3_TITLE")
	card3_sub.text = tr("UI_CHAPTER_3_SUB")
	card3_desc.text = tr("UI_CHAPTER_3_DESC")
	if c3_unlocked:
		if c3_completed:
			card3_status.text = tr("UI_STATUS_COMPLETED")
			card3_status.add_theme_color_override("font_color", Color(0.96, 0.85, 0.35, 1.0))
			card3_btn.text = tr("UI_REPLAY_CHAPTER")
		else:
			card3_status.text = tr("UI_STATUS_UNLOCKED")
			card3_status.add_theme_color_override("font_color", Color(0.65, 0.85, 0.7, 1.0))
			card3_btn.text = tr("UI_PLAY_CHAPTER")
		card3_btn.disabled = false
	else:
		card3_status.text = tr("UI_CASE_LOCKED")
		card3_status.add_theme_color_override("font_color", Color(0.75, 0.45, 0.45, 0.9))
		card3_btn.text = "🔒 " + tr("UI_CASE_LOCKED")
		card3_btn.disabled = true

func _find_case_entry(case_id: String, reg: Array) -> Dictionary:
	for c in reg:
		if c is Dictionary and c.get("id", "") == case_id:
			return c
	return {}

func _on_case_btn_pressed(case_id: String) -> void:
	AudioManager.play_sfx("button_click")
	close_modal()
	case_selected.emit(case_id)
