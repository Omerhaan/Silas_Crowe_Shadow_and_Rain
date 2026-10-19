class_name CraneWinchModal
extends Control

## Crane Winch & Fuse Terminal Modal (Vinç Sigorta ve Şalter Panosu).
## Electrical phase & winch control puzzle for Case 02: Sisli Rıhtım.
## Target calibration: 2 - 4 - 0 (Tide peak time 02:40 from E206 tide chart).
## Success lowers the freight hoist and reveals E202 ("military_crate" - Contraband Arms).

const COURIER_FONT = preload("res://assets/fonts/CourierPrime-Regular.ttf")

@onready var modal_panel: Panel = $ModalPanel
@onready var title_label: Label = $ModalPanel/TitleLabel
@onready var subtitle_label: Label = $ModalPanel/SubtitleLabel
@onready var status_label: Label = $ModalPanel/StatusLabel

@onready var digit_label_0: Label = $ModalPanel/LockBox/Col0/DigitPanel/Digit0
@onready var digit_label_1: Label = $ModalPanel/LockBox/Col1/DigitPanel/Digit1
@onready var digit_label_2: Label = $ModalPanel/LockBox/Col2/DigitPanel/Digit2

@onready var btn_up_0: Button = $ModalPanel/LockBox/Col0/UpBtn0
@onready var btn_dn_0: Button = $ModalPanel/LockBox/Col0/DnBtn0

@onready var btn_up_1: Button = $ModalPanel/LockBox/Col1/UpBtn1
@onready var btn_dn_1: Button = $ModalPanel/LockBox/Col1/DnBtn1

@onready var btn_up_2: Button = $ModalPanel/LockBox/Col2/UpBtn2
@onready var btn_dn_2: Button = $ModalPanel/LockBox/Col2/DnBtn2

@onready var activate_btn: Button = $ModalPanel/ActionButtons/ActivateBtn
@onready var close_btn: Button = $ModalPanel/ActionButtons/CloseBtn
@onready var lock_box: HBoxContainer = $ModalPanel/LockBox

var digits: Array[int] = [0, 0, 0]
var active_col: int = 0
const TARGET_CODE: Array[int] = [2, 3, 0]

func _ready() -> void:
	add_to_group("crane_winch_modal")
	visible = false

	close_btn.pressed.connect(close_modal)
	activate_btn.pressed.connect(_on_activate_pressed)

	btn_up_0.pressed.connect(func(): active_col = 0; _change_digit(0, 1))
	btn_dn_0.pressed.connect(func(): active_col = 0; _change_digit(0, -1))

	btn_up_1.pressed.connect(func(): active_col = 1; _change_digit(1, 1))
	btn_dn_1.pressed.connect(func(): active_col = 1; _change_digit(1, -1))

	btn_up_2.pressed.connect(func(): active_col = 2; _change_digit(2, 1))
	btn_dn_2.pressed.connect(func(): active_col = 2; _change_digit(2, -1))

	var p0 = $ModalPanel/LockBox/Col0/DigitPanel
	var p1 = $ModalPanel/LockBox/Col1/DigitPanel
	var p2 = $ModalPanel/LockBox/Col2/DigitPanel
	if p0: p0.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: active_col = 0; _change_digit(0, 1))
	if p1: p1.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: active_col = 1; _change_digit(1, 1))
	if p2: p2.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: active_col = 2; _change_digit(2, 1))

	_update_digits_display()

func open_modal() -> void:
	GameState.can_player_move = false
	visible = true
	digits = [0, 0, 0]
	active_col = 0
	_update_digits_display()

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	title_label.text = "CRANE HOIST & POWER BREAKER" if is_en else "VİNÇ MAKARA VE ŞALTER PANOSU"
	subtitle_label.text = "Industrial Phase Synchronizer — [0-9] Type, [←/→] Select, [Enter] Engage" if is_en else "Endüstriyel Faz Senkronizasyonu — [0-9] Rakam, [←/→] Seç, [Enter] Çalıştır"
	status_label.text = "Check the tide chart (E206) for the peak tidal hour of the cargo drop." if is_en else "Konteynerin indirildiği gelgit zirve saatini (E206) hatırlayın."
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	activate_btn.text = "ENGAGE WINCH" if is_en else "VİNCİ ÇALIŞTIR"
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
	var labels = [digit_label_0, digit_label_1, digit_label_2]
	var panels = [
		$ModalPanel/LockBox/Col0/DigitPanel,
		$ModalPanel/LockBox/Col1/DigitPanel,
		$ModalPanel/LockBox/Col2/DigitPanel
	]

	for i in range(3):
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

func _on_activate_pressed() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var am = get_node_or_null("/root/AudioManager")
	var eb = get_node_or_null("/root/EventBus")

	if digits[0] == TARGET_CODE[0] and digits[1] == TARGET_CODE[1] and digits[2] == TARGET_CODE[2]:
		# SUCCESS!
		if am and am.has_method("play_sfx"):
			am.play_sfx("chime")
			am.play_sfx("door_open")

		GameState.add_evidence("E202")
		GameState.flags["crane_winch_lowered"] = true

		if eb and eb.has_signal("toast_requested"):
			var toast_msg = "⚡ Hoist Engaged! Military Contraband Crate Lowered (E202)." if is_en else "⚡ Vinç Çalıştı! Mühürsüz Askerî Sandık İndirildi (E202)."
			eb.toast_requested.emit(toast_msg)

		var voice_msg = "\"The steel gears ground into motion. The crane winch lowered the suspended military crate to the warehouse floor. Inside lay smuggled munitions erased from army manifests.\"" if is_en else "\"Çelik dişliler inleyerek dönmeye başladı. Vinç makarası havada asılı duran mühürsüz sandığı ambar zeminine indirdi. İçeride ordudan kaçırılmış cephaneler var.\""
		if eb and eb.has_signal("inner_voice_requested"):
			eb.inner_voice_requested.emit(voice_msg)

		close_modal()
	else:
		# INCORRECT CODE
		if am and am.has_method("play_sfx"):
			am.play_sfx("door_locked")

		status_label.text = "Circuit spark! Voltage mismatch. Calibration failed." if is_en else "Kıvılcım attı! Voltaj uyumsuzluğu. Kalibrasyon başarısız."
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
			_on_activate_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_LEFT:
			active_col = (active_col - 1 + 3) % 3
			_update_digits_display()
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"): am.play_sfx("click")
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_RIGHT:
			active_col = (active_col + 1) % 3
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
			if active_col < 2:
				active_col += 1
			_update_digits_display()
			get_viewport().set_input_as_handled()
			return
