extends Control

## Accusation Modal (Suçlama Ekranı).
## 1. Select Suspect
## 2. Select Method
## 3. Select 3 Key Evidence
## Validates the deduction chain and triggers confrontation or failure feedback.

const COURIER_FONT = preload("res://assets/fonts/CourierPrime-Regular.ttf")

@onready var title_label: Label = $ModalPanel/TitleLabel
@onready var suspect_label: Label = $ModalPanel/SuspectLabel
@onready var method_label: Label = $ModalPanel/MethodLabel
@onready var evidence_label: Label = $ModalPanel/EvidenceLabel
@onready var suspect_btn: Button = $ModalPanel/SuspectButton
@onready var method_btn: Button = $ModalPanel/MethodButton
@onready var dropdown_dimmer: Button = $ModalPanel/DropdownDimmer
@onready var suspect_dropdown: PanelContainer = $ModalPanel/SuspectDropdown
@onready var suspect_list: VBoxContainer = $ModalPanel/SuspectDropdown/Margin/SuspectList
@onready var method_dropdown: PanelContainer = $ModalPanel/MethodDropdown
@onready var method_list: VBoxContainer = $ModalPanel/MethodDropdown/Margin/MethodList

@onready var evidence_container: HFlowContainer = $ModalPanel/EvidenceScroll/EvidenceContainer
@onready var status_label: Label = $ModalPanel/StatusLabel
@onready var accuse_btn: Button = $ModalPanel/Buttons/AccuseBtn
@onready var cancel_btn: Button = $ModalPanel/Buttons/CancelBtn

var selected_suspect_id: String = ""
var selected_method_id: String = ""
var selected_evidence_ids: Array[String] = []

var suspect_data_list: Array = []
var method_data_list: Array = []

var suspect_marquee: Dictionary = {}
var method_marquee: Dictionary = {}
var _current_font_base: int = 7

func _ready() -> void:
	visible = false
	accuse_btn.pressed.connect(_on_accuse_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)
	EventBus.accusation_requested.connect(open_accusation)

	suspect_btn.pressed.connect(_on_suspect_btn_pressed)
	method_btn.pressed.connect(_on_method_btn_pressed)
	dropdown_dimmer.pressed.connect(_close_dropdowns)

	_style_dropdown_panel(suspect_dropdown)
	_style_dropdown_panel(method_dropdown)
	_style_selector_button(suspect_btn)
	_style_selector_button(method_btn)

	_setup_marquee_button(suspect_btn, suspect_marquee)
	_setup_marquee_button(method_btn, method_marquee)

	if EventBus.has_signal("language_changed"):
		EventBus.language_changed.connect(func(_loc): _update_localization())
	if EventBus.has_signal("font_scale_changed"):
		EventBus.font_scale_changed.connect(apply_font_scale)

	apply_font_scale(GameState.get_font_scale())
	_update_localization()

func apply_font_scale(scale: String) -> void:
	var font_base = 7
	var font_lbl = 6
	var font_title = 8
	if scale == "small":
		font_base = 6
		font_lbl = 5
		font_title = 7
	elif scale == "large":
		font_base = 8
		font_lbl = 7
		font_title = 9

	_current_font_base = font_base

	if title_label: title_label.add_theme_font_size_override("font_size", font_title)
	if suspect_label: suspect_label.add_theme_font_size_override("font_size", font_lbl)
	if method_label: method_label.add_theme_font_size_override("font_size", font_lbl)
	if evidence_label: evidence_label.add_theme_font_size_override("font_size", font_lbl)
	if status_label: status_label.add_theme_font_size_override("font_size", font_lbl)
	if suspect_btn: suspect_btn.add_theme_font_size_override("font_size", font_base)
	if method_btn: method_btn.add_theme_font_size_override("font_size", font_base)
	if accuse_btn: accuse_btn.add_theme_font_size_override("font_size", font_base)
	if cancel_btn: cancel_btn.add_theme_font_size_override("font_size", font_base)

	if suspect_marquee.has("label") and is_instance_valid(suspect_marquee.get("label")):
		suspect_marquee["label"].add_theme_font_size_override("font_size", font_base)
	if method_marquee.has("label") and is_instance_valid(method_marquee.get("label")):
		method_marquee["label"].add_theme_font_size_override("font_size", font_base)

func _update_localization() -> void:
	if title_label: title_label.text = tr("ACCUSE_TITLE")
	if suspect_label: suspect_label.text = tr("ACCUSE_SUSPECT_LBL")
	if method_label: method_label.text = tr("ACCUSE_METHOD_LBL")
	if evidence_label: evidence_label.text = tr("ACCUSE_EVIDENCE_LBL")
	if accuse_btn: accuse_btn.text = tr("ACCUSE_BTN")
	if cancel_btn: cancel_btn.text = tr("ACCUSE_CANCEL")
	if status_label: status_label.text = tr("ACCUSE_HINT")
	_setup_options()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if suspect_dropdown.visible or method_dropdown.visible:
			_close_dropdowns()
		else:
			_on_cancel_pressed()
		get_viewport().set_input_as_handled()

func _style_selector_button(btn: Button) -> void:
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	btn.add_theme_font_override("font", COURIER_FONT)
	btn.add_theme_font_size_override("font_size", 7)
	btn.focus_mode = Control.FOCUS_NONE

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.15, 0.95)
	sb.border_color = Color(0.75, 0.65, 0.40, 0.9)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_right = 3
	sb.corner_radius_bottom_left = 3
	sb.content_margin_left = 8
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4

	var sb_hover = sb.duplicate()
	sb_hover.bg_color = Color(0.14, 0.18, 0.26, 1.0)
	sb_hover.border_color = Color(0.96, 0.88, 0.55, 1.0)

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("focus", sb)

func _style_dropdown_panel(panel: PanelContainer) -> void:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.12, 0.98)
	sb.border_color = Color(0.85, 0.75, 0.45, 0.95)
	sb.set_border_width_all(1)
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_right = 3
	sb.corner_radius_bottom_left = 3
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 4
	panel.add_theme_stylebox_override("panel", sb)

func _on_suspect_btn_pressed() -> void:
	if suspect_dropdown.visible:
		_close_dropdowns()
	else:
		method_dropdown.visible = false
		suspect_dropdown.visible = true
		dropdown_dimmer.visible = true

func _on_method_btn_pressed() -> void:
	if method_dropdown.visible:
		_close_dropdowns()
	else:
		suspect_dropdown.visible = false
		method_dropdown.visible = true
		dropdown_dimmer.visible = true

func _close_dropdowns() -> void:
	suspect_dropdown.visible = false
	method_dropdown.visible = false
	dropdown_dimmer.visible = false

func _setup_options() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	suspect_data_list.clear()
	if not GameState.suspects_db.is_empty():
		for s_id in GameState.suspects_db.keys():
			var s_info = GameState.suspects_db[s_id]
			var s_name = s_info.get("ad", s_id)
			var s_role_tr = s_info.get("rol", "")
			if " (" in s_role_tr:
				s_role_tr = s_role_tr.split(" (")[0]
			var s_en_info = GameState.get_suspect_data(s_id)
			var s_role_en = s_en_info.get("rol", s_role_tr)
			if " (" in s_role_en:
				s_role_en = s_role_en.split(" (")[0]
			suspect_data_list.append({
				"id": s_id,
				"tr": "• %s (%s)" % [s_name, s_role_tr],
				"en": "• %s (%s)" % [s_name, s_role_en]
			})
	else:
		suspect_data_list = [
			{"id": "margaret", "tr": "• Margaret Doyle (Hizmetçi)", "en": "• Margaret Doyle (Housekeeper)"},
			{"id": "julian", "tr": "• Julian Harlow (Üvey Kardeş)", "en": "• Julian Harlow (Stepson)"},
			{"id": "hale", "tr": "• Dr. Victor Hale (Aile Doktoru)", "en": "• Dr. Victor Hale (Physician)"},
			{"id": "pike", "tr": "• Raymond Pike (Eski Ortak)", "en": "• Raymond Pike (Attorney)"}
		]

	var case_methods = GameState.case_data.get("methods", [])
	if not case_methods.is_empty():
		method_data_list = case_methods
	else:
		method_data_list = [
			{"id": "poison", "tr": "• Gecikmeli Zehirleme (Digitalis)", "en": "• Delayed Poisoning (Digitalis)"},
			{"id": "strangulation", "tr": "• Boğma / Nefessiz Bırakma", "en": "• Strangulation / Suffocation"},
			{"id": "stabbing", "tr": "• Bıçaklama", "en": "• Stabbing"},
			{"id": "gunshot", "tr": "• Ateşli Silah", "en": "• Firearm"}
		]

	if not suspect_data_list.is_empty():
		var valid_s = false
		for s in suspect_data_list:
			if s["id"] == selected_suspect_id:
				valid_s = true
				break
		if not valid_s:
			selected_suspect_id = suspect_data_list[0]["id"]

	if not method_data_list.is_empty():
		var valid_m = false
		for m in method_data_list:
			if m["id"] == selected_method_id:
				valid_m = true
				break
		if not valid_m:
			selected_method_id = method_data_list[0]["id"]

	# Suspects
	for c in suspect_list.get_children():
		c.queue_free()
	for s_entry in suspect_data_list:
		var s_id = s_entry["id"]
		var s_text = s_entry["en"] if is_en else s_entry["tr"]
		var item_btn = _create_dropdown_item(s_text, func():
			selected_suspect_id = s_id
			_update_button_labels()
			_close_dropdowns()
		)
		suspect_list.add_child(item_btn)

	# Methods
	for c in method_list.get_children():
		c.queue_free()
	for m_entry in method_data_list:
		var m_id = m_entry["id"]
		var m_text = m_entry["en"] if is_en else m_entry["tr"]
		var item_btn = _create_dropdown_item(m_text, func():
			selected_method_id = m_id
			_update_button_labels()
			_close_dropdowns()
		)
		method_list.add_child(item_btn)

	_update_button_labels()

func _create_dropdown_item(label_text: String, on_click: Callable) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.tooltip_text = label_text
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.clip_text = true
	btn.custom_minimum_size = Vector2(168, 20)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	btn.add_theme_font_override("font", COURIER_FONT)
	btn.add_theme_font_size_override("font_size", 7)
	btn.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.60, 1.0))
	btn.focus_mode = Control.FOCUS_NONE

	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = Color(0.08, 0.10, 0.14, 0.0)
	sb_norm.content_margin_left = 6
	sb_norm.content_margin_right = 6
	sb_norm.content_margin_top = 2
	sb_norm.content_margin_bottom = 2

	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.18, 0.22, 0.32, 1.0)
	sb_hover.border_color = Color(0.96, 0.85, 0.45, 0.8)
	sb_hover.set_border_width_all(1)
	sb_hover.corner_radius_top_left = 2
	sb_hover.corner_radius_top_right = 2
	sb_hover.corner_radius_bottom_right = 2
	sb_hover.corner_radius_bottom_left = 2
	sb_hover.content_margin_left = 6
	sb_hover.content_margin_right = 6
	sb_hover.content_margin_top = 2
	sb_hover.content_margin_bottom = 2

	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_norm)

	btn.pressed.connect(on_click)
	return btn

func _setup_marquee_button(btn: Button, marquee_dict: Dictionary) -> void:
	btn.clip_text = false
	btn.text = ""

	var container = Control.new()
	container.name = "MarqueeContainer"
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.clip_contents = true
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.offset_left = 8
	container.offset_right = -18
	container.offset_top = 0
	container.offset_bottom = 0
	btn.add_child(container)

	var label = Label.new()
	label.name = "MarqueeLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.anchor_top = 0.0
	label.anchor_bottom = 1.0
	label.offset_left = 0
	label.offset_top = 0
	label.offset_bottom = 0
	label.add_theme_font_override("font", COURIER_FONT)
	label.add_theme_font_size_override("font_size", _current_font_base)
	label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88, 1.0))
	container.add_child(label)

	var arrow = Label.new()
	arrow.name = "DropdownArrow"
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.text = "▼"
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.anchor_left = 1.0
	arrow.anchor_right = 1.0
	arrow.anchor_top = 0.0
	arrow.anchor_bottom = 1.0
	arrow.offset_left = -16
	arrow.offset_right = -4
	arrow.offset_top = 0
	arrow.offset_bottom = 0
	arrow.add_theme_font_override("font", COURIER_FONT)
	arrow.add_theme_font_size_override("font_size", 6)
	arrow.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45, 0.9))
	btn.add_child(arrow)

	marquee_dict["btn"] = btn
	marquee_dict["container"] = container
	marquee_dict["label"] = label
	marquee_dict["arrow"] = arrow
	marquee_dict["offset"] = 0.0
	marquee_dict["direction"] = 1.0
	marquee_dict["pause_timer"] = 1.5
	marquee_dict["speed"] = 28.0
	marquee_dict["full_text"] = ""

	btn.mouse_entered.connect(func():
		if is_instance_valid(label):
			label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.65, 1.0))
		if is_instance_valid(arrow):
			arrow.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55, 1.0))
	)
	btn.mouse_exited.connect(func():
		if is_instance_valid(label):
			label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.88, 1.0))
		if is_instance_valid(arrow):
			arrow.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45, 0.9))
	)

func _process(delta: float) -> void:
	if not visible:
		return
	if (suspect_dropdown and suspect_dropdown.visible) or (method_dropdown and method_dropdown.visible):
		return
	_update_marquee(suspect_marquee, delta)
	_update_marquee(method_marquee, delta)

func _update_marquee(m: Dictionary, delta: float) -> void:
	if not m.has("label") or m["label"] == null or not is_instance_valid(m["label"]):
		return
	var label: Label = m["label"]
	var container: Control = m["container"]
	var visible_w: float = container.size.x
	var text_w: float = label.get_minimum_size().x
	var overflow: float = text_w - visible_w

	if overflow <= 2.0:
		label.position.x = 0
		m["offset"] = 0.0
		m["pause_timer"] = 1.5
		m["direction"] = 1.0
		return

	var move_delta: float = delta
	if m["pause_timer"] > 0.0:
		m["pause_timer"] -= delta
		if m["pause_timer"] > 0.0:
			return
		move_delta = -m["pause_timer"]

	var speed: float = m.get("speed", 28.0)
	var dir: float = m.get("direction", 1.0)
	var cur_offset: float = m.get("offset", 0.0)

	cur_offset += speed * dir * move_delta

	if cur_offset >= overflow:
		cur_offset = overflow
		m["direction"] = -1.0
		m["pause_timer"] = 1.5
	elif cur_offset <= 0.0:
		cur_offset = 0.0
		m["direction"] = 1.0
		m["pause_timer"] = 1.5

	m["offset"] = cur_offset
	label.position.x = -cur_offset

func _set_marquee_text(m: Dictionary, text: String) -> void:
	if not m.has("label") or m["label"] == null or not is_instance_valid(m["label"]):
		return
	var label: Label = m["label"]
	if label.text != text:
		label.text = text
		_reset_marquee(m)
	var btn: Button = m.get("btn")
	if btn and is_instance_valid(btn):
		btn.tooltip_text = text

func _reset_marquee(m: Dictionary) -> void:
	m["offset"] = 0.0
	m["direction"] = 1.0
	m["pause_timer"] = 1.5
	if m.has("label") and m["label"] and is_instance_valid(m["label"]):
		m["label"].position.x = 0

func _update_button_labels() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	var susp_text = ""
	for s in suspect_data_list:
		if s["id"] == selected_suspect_id:
			susp_text = s["en"] if is_en else s["tr"]
			break
	_set_marquee_text(suspect_marquee, susp_text)

	var meth_text = ""
	for m in method_data_list:
		if m["id"] == selected_method_id:
			meth_text = m["en"] if is_en else m["tr"]
			break
	_set_marquee_text(method_marquee, meth_text)

func open_accusation() -> void:
	GameState.can_player_move = false
	visible = true
	_close_dropdowns()
	selected_evidence_ids.clear()
	_setup_options()
	status_label.text = tr("ACCUSE_HINT")
	_populate_evidence_choices()
	_reset_marquee(suspect_marquee)
	_reset_marquee(method_marquee)

class EvidenceChoiceButton extends Button:
	var tooltip_font: Font = null

	func _make_custom_tooltip(for_text: String) -> Object:
		var panel = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.10, 0.15, 0.95)
		sb.border_color = Color(0.85, 0.75, 0.45, 0.95)
		sb.set_border_width_all(1)
		sb.corner_radius_top_left = 3
		sb.corner_radius_top_right = 3
		sb.corner_radius_bottom_right = 3
		sb.corner_radius_bottom_left = 3
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		sb.shadow_color = Color(0, 0, 0, 0.8)
		sb.shadow_size = 4
		panel.add_theme_stylebox_override("panel", sb)

		var lbl = Label.new()
		lbl.text = for_text
		if tooltip_font:
			lbl.add_theme_font_override("font", tooltip_font)
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.add_theme_color_override("font_color", Color(0.96, 0.93, 0.86, 1.0))
		lbl.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		panel.add_child(lbl)
		return panel

const CLUE_ICONS = {
	"E01": "res://assets/sprites/clues/clue_e01_pocket_watch.png",
	"E02": "res://assets/sprites/clues/icon_door_lock.png",
	"E03": "res://assets/sprites/clues/clue_e02_half_written_letter.png",
	"E04": "res://assets/sprites/clues/clue_e04_brandy_glass.png",
	"E05": "res://assets/sprites/clues/clue_e05_dropper_bottle.png",
	"E06": "res://assets/sprites/clues/clue_e06_prescription.png",
	"E07": "res://assets/sprites/clues/clue_e07_threat_letters.png",
	"E08": "res://assets/sprites/clues/clue_e03_burned_candle.png",
	"E09": "res://assets/sprites/clues/clue_e09_digitalis_vial.png",
	"E10": "res://assets/sprites/clues/clue_e10_fireplace_ash.png",
	"E11": "res://assets/sprites/clues/clue_e11_billiard_chalk.png",
	"E12": "res://assets/sprites/clues/icon_cigar_ashtray.png",
	"E13": "res://assets/sprites/clues/clue_e13_debt_letter.png",
	"E14": "res://assets/sprites/clues/clue_e14_typewriter_ribbon.png",
	"E15": "res://assets/sprites/clues/icon_muddy_bootprint.png",
	"E16": "res://assets/sprites/clues/clue_e16_torn_photo.png",
	"E17": "res://assets/sprites/clues/clue_e17_rotary_phone.png",
	"E201": "res://assets/sprites/inspect/inspect_e201_crane_cable.png",
	"E202": "res://assets/sprites/inspect/inspect_e202_military_crate.png",
	"E203": "res://assets/sprites/inspect/inspect_e203_bloody_lantern.png",
	"E204": "res://assets/sprites/inspect/inspect_e204_acid_coat.png",
	"E205": "res://assets/sprites/inspect/inspect_e205_radio_logbook.png",
	"E206": "res://assets/sprites/inspect/inspect_e206_tide_chart.png",
	"E207": "res://assets/sprites/inspect/inspect_e207_typewriter_note.png",
	"E208": "res://assets/sprites/inspect/inspect_e208_k3_watch.png",
	"E209": "res://assets/sprites/inspect/inspect_e209_night_pass.png",
	"E210": "res://assets/sprites/inspect/inspect_e210_bribe_ledger.png",
	"E211": "res://assets/sprites/clues/icon_medic_registry.png",
	"E301": "res://assets/sprites/clues/clue_e01_pocket_watch.png",
	"E302": "res://assets/sprites/inspect/inspect_e03_burned_candle.png",
	"E303": "res://assets/sprites/inspect/inspect_e205_radio_logbook.png",
	"E304": "res://assets/sprites/clues/icon_door_lock.png",
	"E305": "res://assets/sprites/inspect/inspect_e15_keyhole_key.png",
	"E306": "res://assets/sprites/clues/clue_e02_half_written_letter.png",
	"E307": "res://assets/sprites/clues/clue_e03_burned_candle.png",
	"E308": "res://assets/sprites/inspect/inspect_e207_typewriter_note.png",
	"E309": "res://assets/sprites/inspect/inspect_e208_k3_watch.png",
	"E310": "res://assets/sprites/clues/icon_muddy_bootprint.png"
}

func _get_clue_icon(clue_id: String) -> Texture2D:
	if CLUE_ICONS.has(clue_id):
		var p = CLUE_ICONS[clue_id]
		if ResourceLoader.exists(p):
			return load(p) as Texture2D
		var gp = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(gp):
			var img = Image.load_from_file(gp)
			if img:
				return ImageTexture.create_from_image(img)
	return null

func _populate_evidence_choices() -> void:
	for c in evidence_container.get_children():
		c.queue_free()

	for ev_id in GameState.discovered_evidence:
		var ev_data = GameState.get_evidence_data(ev_id)
		var ev_name = ev_data.get("ad", "")
		var short_name = ev_name
		if short_name.length() > 14:
			short_name = short_name.substr(0, 13) + "…"

		var btn = EvidenceChoiceButton.new()
		btn.tooltip_font = COURIER_FONT
		btn.custom_minimum_size = Vector2(98, 24)
		btn.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		btn.add_theme_font_override("font", COURIER_FONT)
		btn.add_theme_font_size_override("font_size", 6)
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.clip_text = true
		btn.text = short_name
		btn.tooltip_text = "[%s] %s" % [ev_id, ev_name]

		var icon_tex = _get_clue_icon(ev_id)
		if icon_tex:
			btn.icon = icon_tex
			btn.expand_icon = true

		btn.mouse_entered.connect(func():
			if status_label:
				status_label.text = "[%s] %s" % [ev_id, ev_name]
		)
		btn.mouse_exited.connect(func():
			if status_label:
				status_label.text = tr("ACCUSE_HINT")
		)

		btn.toggled.connect(func(pressed: bool):
			if pressed:
				if not ev_id in selected_evidence_ids:
					selected_evidence_ids.append(ev_id)
				btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
			else:
				selected_evidence_ids.erase(ev_id)
				btn.remove_theme_color_override("font_color")
		)
		evidence_container.add_child(btn)

func _on_accuse_pressed() -> void:
	var susp_id = selected_suspect_id
	var method_id = selected_method_id

	# Dynamic validation based on current case solution
	var solution = GameState.case_data.get("solution", {})
	var target_killer = solution.get("killer_id", "hale")
	var target_method = solution.get("weapon_method", "digitalis_poison")
	var required_ev = solution.get("required_evidence", [])

	var correct_culprit = (susp_id == target_killer)
	var correct_method = (method_id == target_method or (target_method == "digitalis_poison" and method_id == "poison"))

	var matched_key_count = 0
	for cl in selected_evidence_ids:
		if cl in required_ev:
			matched_key_count += 1
		elif target_killer == "hale" and cl in ["E06", "E09", "E04", "E05", "E10", "E02"]:
			matched_key_count += 1

	var required_threshold = 2 if not required_ev.is_empty() else 0
	if correct_culprit and correct_method and (matched_key_count >= required_threshold or required_ev.is_empty()):
		status_label.text = tr("ACCUSE_SUCCESS")
		visible = false
		EventBus.accusation_resolved.emit(true, target_killer)
	else:
		GameState.accusation_chances_left -= 1
		if GameState.accusation_chances_left <= 0:
			status_label.text = tr("ACCUSE_GAME_OVER")
			status_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			accuse_btn.disabled = true
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var toast = "The murder was left unsolved... The killer vanished into the dark." if is_en else "Cinayet çözülemedi... Katil karanlığa karıştı."
			var iv = "\"I accused the wrong person... And the real killer didn't miss this opportunity.\"" if is_en else "\"Yanlış kişiyi suçladım... Ve gerçek katil bu fırsatı kaçırmadı.\""
			EventBus.toast_requested.emit(toast)
			EventBus.inner_voice_requested.emit(iv)
			EventBus.accusation_resolved.emit(false, susp_id)
		else:
			status_label.text = tr("ACCUSE_FAIL") % GameState.accusation_chances_left
			var loc_mgr = get_node_or_null("/root/LocalizationManager")
			var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
			var iv = "\"No... There are flaws in this deduction. The evidence does not align.\"" if is_en else "\"Hayır... Bu teoride boşluklar var. Kanıtlar birbirini tutmuyor.\""
			EventBus.inner_voice_requested.emit(iv)

func _on_cancel_pressed() -> void:
	_close_dropdowns()
	visible = false
	GameState.can_player_move = true
