class_name SafeDialModal
extends Control

## Safe Dial Modal (Harlow'un Gizli Çelik Kasası).
## 4-Digit rotary combination wall safe for Case 01: Karanlık Malikâne.
## Target combination: 1 - 9 - 4 - 1 (Northern Operation year from E16 military photo).
## Unlocking yields: E07 ("study_locked_safe_letters" - Blackmail Threat Letters).

const COURIER_FONT = preload("res://assets/fonts/CourierPrime-Regular.ttf")

@onready var modal_panel: Panel = $ModalPanel
@onready var title_label: Label = $ModalPanel/TitleLabel
@onready var subtitle_label: Label = $ModalPanel/SubtitleLabel
@onready var status_label: Label = $ModalPanel/StatusLabel

@onready var digit_label_0: Label = $ModalPanel/LockBox/Col0/DigitPanel/Digit0
@onready var digit_label_1: Label = $ModalPanel/LockBox/Col1/DigitPanel/Digit1
@onready var digit_label_2: Label = $ModalPanel/LockBox/Col2/DigitPanel/Digit2
@onready var digit_label_3: Label = $ModalPanel/LockBox/Col3/DigitPanel/Digit3

@onready var btn_up_0: Button = $ModalPanel/LockBox/Col0/UpBtn0
@onready var btn_dn_0: Button = $ModalPanel/LockBox/Col0/DnBtn0

@onready var btn_up_1: Button = $ModalPanel/LockBox/Col1/UpBtn1
@onready var btn_dn_1: Button = $ModalPanel/LockBox/Col1/DnBtn1

@onready var btn_up_2: Button = $ModalPanel/LockBox/Col2/UpBtn2
@onready var btn_dn_2: Button = $ModalPanel/LockBox/Col2/DnBtn2

@onready var btn_up_3: Button = $ModalPanel/LockBox/Col3/UpBtn3
@onready var btn_dn_3: Button = $ModalPanel/LockBox/Col3/DnBtn3

@onready var unlock_btn: Button = $ModalPanel/ActionButtons/UnlockBtn
@onready var close_btn: Button = $ModalPanel/ActionButtons/CloseBtn
@onready var lock_box: HBoxContainer = $ModalPanel/LockBox

var digits: Array[int] = [0, 0, 0, 0]
var active_col: int = 0
const TARGET_CODE: Array[int] = [1, 9, 4, 4]

func _ready() -> void:
	add_to_group("safe_dial_modal")
	visible = false

	close_btn.pressed.connect(close_modal)
	unlock_btn.pressed.connect(_on_unlock_pressed)

	btn_up_0.pressed.connect(func(): active_col = 0; _change_digit(0, 1))
	btn_dn_0.pressed.connect(func(): active_col = 0; _change_digit(0, -1))

	btn_up_1.pressed.connect(func(): active_col = 1; _change_digit(1, 1))
	btn_dn_1.pressed.connect(func(): active_col = 1; _change_digit(1, -1))

	btn_up_2.pressed.connect(func(): active_col = 2; _change_digit(2, 1))
	btn_dn_2.pressed.connect(func(): active_col = 2; _change_digit(2, -1))

	btn_up_3.pressed.connect(func(): active_col = 3; _change_digit(3, 1))
	btn_dn_3.pressed.connect(func(): active_col = 3; _change_digit(3, -1))

	var p0 = $ModalPanel/LockBox/Col0/DigitPanel
	var p1 = $ModalPanel/LockBox/Col1/DigitPanel
	var p2 = $ModalPanel/LockBox/Col2/DigitPanel
	var p3 = $ModalPanel/LockBox/Col3/DigitPanel
	if p0: p0.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: active_col = 0; _change_digit(0, 1))
	if p1: p1.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: active_col = 1; _change_digit(1, 1))
	if p2: p2.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: active_col = 2; _change_digit(2, 1))
	if p3: p3.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: active_col = 3; _change_digit(3, 1))

	_update_digits_display()

func open_modal() -> void:
	GameState.can_player_move = false
	visible = true
	digits = [0, 0, 0, 0]
	active_col = 0
	_update_digits_display()

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	title_label.text = "HARLOW'S SECRET WALL SAFE" if is_en else "HARLOW'UN GİZLİ ÇELİK KASASI"
	subtitle_label.text = "4-Digit Rotary Safe — [0-9] Type, [←/→] Select, [Enter] Open" if is_en else "4 Haneli Döner Çelik Kasa — [0-9] Rakam, [←/→] Seç, [Enter] Aç"
	status_label.text = "Recall the fateful year of the Northern military expedition (E16)." if is_en else "Kuzey askerî harekâtının yapıldığı o karanlık yılı hatırlayın (E16)."
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	unlock_btn.text = "UNLOCK" if is_en else "KASAYI AÇ"
	close_btn.text = "CLOSE" if is_en else "KAPAT"

func close_modal() -> void:
	visible = false
	GameState.can_player_move = true

func _change_digit(idx: int, delta: int) -> void:
	digits[idx] = (digits[idx] + delta + 10) % 10
	active_col = idx
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("click")
	_update_digits_display()

func _update_digits_display() -> void:
	var labels = [digit_label_0, digit_label_1, digit_label_2, digit_label_3]
	var panels = [
		$ModalPanel/LockBox/Col0/DigitPanel,
		$ModalPanel/LockBox/Col1/DigitPanel,
		$ModalPanel/LockBox/Col2/DigitPanel,
		$ModalPanel/LockBox/Col3/DigitPanel
	]

	for i in range(4):
		if labels[i]:
			labels[i].text = str(digits[i])
			if i == active_col:
				labels[i].add_theme_color_override("font_color", Color(1.0, 0.95, 0.5, 1.0))
			else:
				labels[i].add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
		if panels[i]:
			var sb = StyleBoxFlat.new()
			sb.corner_radius_top_left = 3
			sb.corner_radius_top_right = 3
			sb.corner_radius_bottom_left = 3
			sb.corner_radius_bottom_right = 3
			if i == active_col:
				sb.bg_color = Color(0.18, 0.24, 0.35, 0.95)
				sb.border_width_left = 2
				sb.border_width_right = 2
				sb.border_width_top = 2
				sb.border_width_bottom = 2
				sb.border_color = Color(0.96, 0.89, 0.63, 1.0)
			else:
				sb.bg_color = Color(0.10, 0.13, 0.20, 0.9)
				sb.border_width_left = 1
				sb.border_width_right = 1
				sb.border_width_top = 1
				sb.border_width_bottom = 1
				sb.border_color = Color(0.3, 0.38, 0.5, 0.7)
			panels[i].add_theme_stylebox_override("panel", sb)

func _on_unlock_pressed() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var am = get_node_or_null("/root/AudioManager")
	var eb = get_node_or_null("/root/EventBus")

	if digits[0] == TARGET_CODE[0] and digits[1] == TARGET_CODE[1] and digits[2] == TARGET_CODE[2] and digits[3] == TARGET_CODE[3]:
		# SUCCESS!
		if am and am.has_method("play_sfx"):
			am.play_sfx("chime")
			am.play_sfx("door_open")

		GameState.add_evidence("E07")
		GameState.flags["harlow_safe_opened"] = true

		if eb and eb.has_signal("toast_requested"):
			var toast_msg = "🔓 Safe Unlocked! Discovered Threat Letters (E07)." if is_en else "🔓 Kasa Açıldı! Tehdit Mektupları (E07) Ele Geçirildi."
			eb.toast_requested.emit(toast_msg)

		var voice_msg = "\"The heavy steel safe swung open with a muffled groan. Inside rested blackmail threat letters stating: 'You will pay for the North with your life.'\"" if is_en else "\"Çelik kasanın ağır kapağı boğuk bir iniltiyle açıldı. İçeride 'Kuzey'in bedelini canınla ödeyeceksin' yazılı şantaj ve tehdit mektupları duruyor.\""
		if eb and eb.has_signal("inner_voice_requested"):
			eb.inner_voice_requested.emit(voice_msg)

		close_modal()
	else:
		# INCORRECT CODE
		if am and am.has_method("play_sfx"):
			am.play_sfx("door_locked")

		status_label.text = "The tumbler jammed. Incorrect combination code." if is_en else "Kasa çarkı kilitlendi. Yanlış şifre kombinasyonu."
		status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1))

		if lock_box:
			var orig_pos = lock_box.position
			var t = create_tween()
			t.tween_property(lock_box, "position:x", orig_pos.x - 4, 0.04)
			t.tween_property(lock_box, "position:x", orig_pos.x + 4, 0.04)
			t.tween_property(lock_box, "position:x", orig_pos.x, 0.04)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_modal()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_modal()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_unlock_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_LEFT:
			active_col = (active_col - 1 + 4) % 4
			_update_digits_display()
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"): am.play_sfx("click")
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_RIGHT:
			active_col = (active_col + 1) % 4
			_update_digits_display()
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"): am.play_sfx("click")
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_UP:
			_change_digit(active_col, 1)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_DOWN:
			_change_digit(active_col, -1)
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_BACKSPACE:
			digits[active_col] = 0
			if active_col > 0:
				active_col -= 1
			_update_digits_display()
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"): am.play_sfx("click")
			get_viewport().set_input_as_handled()
			return

		var num = -1
		if event.keycode >= KEY_0 and event.keycode <= KEY_9:
			num = event.keycode - KEY_0
		elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
			num = event.keycode - KEY_KP_0
		if num != -1:
			digits[active_col] = num
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"): am.play_sfx("click")
			if active_col < 3:
				active_col += 1
			_update_digits_display()
			get_viewport().set_input_as_handled()
			return
