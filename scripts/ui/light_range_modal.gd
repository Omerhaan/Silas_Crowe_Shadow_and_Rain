class_name LightRangeModal
extends Control

## Light-Range Board (Işık-Menzil Panosu).
## Cross-section schematic puzzle for Case 03: The Blind Spot.
## Player aligns 3 spot toggles and selects the candidate sniper position.
## Correct solution: Spot A OFF, Spot B ON, Spot C OFF, Target: Light Bridge.
## Yields deduction D302 upon successful test.

const COURIER_FONT = preload("res://assets/fonts/CourierPrime-Regular.ttf")

@onready var modal_panel: Panel = $ModalPanel
@onready var title_label: Label = $ModalPanel/TitleLabel
@onready var subtitle_label: Label = $ModalPanel/SubtitleLabel
@onready var schematic_rect: TextureRect = $ModalPanel/SchematicBox/SchematicRect
@onready var schematic_box: Control = $ModalPanel/SchematicBox

@onready var btn_spot_a: Button = $ModalPanel/Controls/SpotsHBox/SpotABtn
@onready var btn_spot_b: Button = $ModalPanel/Controls/SpotsHBox/SpotBBtn
@onready var btn_spot_c: Button = $ModalPanel/Controls/SpotsHBox/SpotCBtn

@onready var btn_pos_balcony: Button = $ModalPanel/Controls/PositionsHBox/PosBalconyBtn
@onready var btn_pos_vent: Button = $ModalPanel/Controls/PositionsHBox/PosVentBtn
@onready var btn_pos_bridge: Button = $ModalPanel/Controls/PositionsHBox/PosBridgeBtn

@onready var test_btn: Button = $ModalPanel/Buttons/TestBtn
@onready var close_btn: Button = $ModalPanel/Buttons/CloseBtn
@onready var status_label: Label = $ModalPanel/StatusLabel

var spot_a_on: bool = true
var spot_b_on: bool = false
var spot_c_on: bool = true
var selected_position: String = "balcony" # "balcony", "vent", "bridge"

# Dynamic visual & animation variables
var overlay: Control = null
var anim_time: float = 0.0
var dash_offset: float = 0.0
var spot_a_alpha: float = 1.0
var spot_b_alpha: float = 0.0
var spot_c_alpha: float = 1.0

# Test simulation animation
var is_simulating: bool = false
var sim_progress: float = 0.0
var sim_success: bool = false
var impact_timer: float = 0.0

# Schematic anchor coordinates (relative to 390x115 schematic box)
# Centered 16:9 texture rect is [92, 0] to [298, 115]
const TARGET_POS = Vector2(130, 84)        # Royal Box
const POS_BALCONY = Vector2(223, 72)      # Candidate 1: Balcony
const POS_VENT = Vector2(190, 12)         # Candidate 2: Vent
const POS_OBSTACLE = Vector2(160, 48)     # Steel Truss obstruction
const POS_BRIDGE = Vector2(178, 32)       # Candidate 3: Light Bridge Catwalk

const SPOT_A_APEX = Vector2(168, 36)
const SPOT_B_APEX = Vector2(201, 36)
const SPOT_C_APEX = Vector2(223, 40)

func _ready() -> void:
	add_to_group("light_range_modal")
	visible = false
	close_btn.pressed.connect(close_board)
	test_btn.pressed.connect(_on_test_pressed)

	btn_spot_a.pressed.connect(func(): spot_a_on = !spot_a_on; _play_toggle_sfx(); _update_ui())
	btn_spot_b.pressed.connect(func(): spot_b_on = !spot_b_on; _play_toggle_sfx(); _update_ui())
	btn_spot_c.pressed.connect(func(): spot_c_on = !spot_c_on; _play_toggle_sfx(); _update_ui())

	btn_pos_balcony.pressed.connect(func(): selected_position = "balcony"; _play_toggle_sfx(); _update_ui())
	btn_pos_vent.pressed.connect(func(): selected_position = "vent"; _play_toggle_sfx(); _update_ui())
	btn_pos_bridge.pressed.connect(func(): selected_position = "bridge"; _play_toggle_sfx(); _update_ui())

	_load_schematic_texture()
	_setup_overlay()
	_update_ui()

func _setup_overlay() -> void:
	if not overlay and schematic_box:
		overlay = Control.new()
		overlay.name = "LightBeamOverlay"
		overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		schematic_box.add_child(overlay)
		overlay.draw.connect(_draw_schematic_overlay)

func _load_schematic_texture() -> void:
	if not schematic_rect:
		return
	if schematic_rect.texture != null:
		return
	var tex_paths = [
		"res://cases/case03/assets/ui/light_range_schematic.png",
		"res://cases/case03/assets/ui/light_range_schematic.jpg"
	]
	for p in tex_paths:
		if ResourceLoader.exists(p):
			var res = load(p)
			if res:
				schematic_rect.texture = res
				return
		var gp = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(gp):
			var img = Image.load_from_file(gp)
			if img:
				schematic_rect.texture = ImageTexture.create_from_image(img)
				return

func open_board() -> void:
	GameState.can_player_move = false
	visible = true
	is_simulating = false
	impact_timer = 0.0
	status_label.text = "Işık cue talimatına (E303) göre spotları ayarlayın ve atış hattını seçin."
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and is_instance_valid(hud):
		hud.visible = false
	_update_ui()

func close_board() -> void:
	visible = false
	is_simulating = false
	GameState.can_player_move = true
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and is_instance_valid(hud):
		hud.visible = true

func _play_toggle_sfx() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("click")

func _process(delta: float) -> void:
	if not visible:
		return

	anim_time += delta
	dash_offset = fmod(dash_offset + delta * 35.0, 20.0)

	var target_a = 1.0 if spot_a_on else 0.0
	var target_b = 1.0 if spot_b_on else 0.0
	var target_c = 1.0 if spot_c_on else 0.0

	spot_a_alpha = lerp(spot_a_alpha, target_a, clampf(delta * 9.0, 0.0, 1.0))
	spot_b_alpha = lerp(spot_b_alpha, target_b, clampf(delta * 9.0, 0.0, 1.0))
	spot_c_alpha = lerp(spot_c_alpha, target_c, clampf(delta * 9.0, 0.0, 1.0))

	if is_simulating:
		sim_progress += delta * 2.2
		if sim_progress >= 1.0:
			is_simulating = false
			sim_progress = 1.0
			impact_timer = 0.8
			_finish_test_resolution()

	if impact_timer > 0.0:
		impact_timer -= delta

	if overlay:
		overlay.queue_redraw()

func _update_ui() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	title_label.text = "LIGHT & RANGE BOARD — BLIND SPOT SCHEMATIC" if is_en else "IŞIK VE MENZİL PANOSU — KÖR NOKTA ŞEMASI"
	subtitle_label.text = "[A/B/C] Spot Toggle  •  [1/2/3] Sniper Position  •  [Enter] Test Fire" if is_en else "[A/B/C] Spot Aç/Kapat  •  [1/2/3] Konum Seç  •  [Enter] Atışı Test Et"

	btn_spot_a.text = ("Spot A [A]: [ON]" if spot_a_on else "Spot A [A]: [OFF]") if is_en else ("Spot A [A]: [AÇIK]" if spot_a_on else "Spot A [A]: [KAPALI]")
	btn_spot_b.text = ("Spot B [B]: [ON]" if spot_b_on else "Spot B [B]: [OFF]") if is_en else ("Spot B [B]: [AÇIK]" if spot_b_on else "Spot B [B]: [KAPALI]")
	btn_spot_c.text = ("Spot C [C]: [ON]" if spot_c_on else "Spot C [C]: [OFF]") if is_en else ("Spot C [C]: [AÇIK]" if spot_c_on else "Spot C [C]: [KAPALI]")

	btn_pos_balcony.text = "[1] Balcony" if is_en else "[1] Karşı Balkon"
	btn_pos_vent.text = "[2] Roof Vent" if is_en else "[2] Çatı Havalandırması"
	btn_pos_bridge.text = "[3] Light Bridge" if is_en else "[3] Işık Köprüsü"

	test_btn.text = "Test [Enter]" if is_en else "Test Et [Enter]"
	close_btn.text = "Close [Esc]" if is_en else "Kapat [Esc]"

	_style_toggle_btn(btn_spot_a, spot_a_on)
	_style_toggle_btn(btn_spot_b, spot_b_on)
	_style_toggle_btn(btn_spot_c, spot_c_on)

	_style_choice_btn(btn_pos_balcony, selected_position == "balcony")
	_style_choice_btn(btn_pos_vent, selected_position == "vent")
	_style_choice_btn(btn_pos_bridge, selected_position == "bridge")

func _style_toggle_btn(btn: Button, is_on: bool) -> void:
	if is_on:
		btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45, 1.0))
	else:
		btn.add_theme_color_override("font_color", Color(0.5, 0.55, 0.62, 1.0))

func _style_choice_btn(btn: Button, is_selected: bool) -> void:
	if is_selected:
		btn.add_theme_color_override("font_color", Color(0.96, 0.89, 0.35, 1.0))
	else:
		btn.add_theme_color_override("font_color", Color(0.68, 0.74, 0.82, 1.0))

func _draw_schematic_overlay() -> void:
	if not overlay:
		return

	# 1. Architectural blueprint grid accents
	for gx in range(40, 380, 45):
		overlay.draw_line(Vector2(gx, 0), Vector2(gx, 115), Color(0.12, 0.25, 0.38, 0.12), 1.0)
	overlay.draw_line(Vector2(0, 108), Vector2(390, 108), Color(0.2, 0.35, 0.45, 0.25), 1.0)

	# 2. Dynamic Spotlight Beams
	_draw_spotlights()

	# 3. Target (Royal Box)
	_draw_target_box()

	# 4. Candidate Positions & Active Trajectory Laser
	_draw_candidate_positions_and_laser()

	# 5. Test Simulation Animation (Tracer bullet & Impact burst)
	_draw_simulation_effects()

func _draw_spotlights() -> void:
	var pulse_sin = sin(anim_time * 3.8) * 0.08 + 0.92

	# Spot A (Stage Focus - Warm Gold Cone)
	if spot_a_alpha > 0.01:
		var poly_a = PackedVector2Array([SPOT_A_APEX, Vector2(100, 112), Vector2(165, 112)])
		var cols_a = PackedColorArray([
			Color(1.0, 0.88, 0.42, 0.30 * spot_a_alpha * pulse_sin),
			Color(1.0, 0.82, 0.28, 0.10 * spot_a_alpha * pulse_sin),
			Color(1.0, 0.82, 0.28, 0.10 * spot_a_alpha * pulse_sin)
		])
		overlay.draw_polygon(poly_a, cols_a)
		overlay.draw_line(SPOT_A_APEX, Vector2(100, 112), Color(1.0, 0.92, 0.55, 0.55 * spot_a_alpha), 1.5)
		overlay.draw_line(SPOT_A_APEX, Vector2(165, 112), Color(1.0, 0.92, 0.55, 0.55 * spot_a_alpha), 1.5)
		overlay.draw_circle(SPOT_A_APEX, 3.5, Color(1.0, 0.95, 0.65, 0.95 * spot_a_alpha))

	# Spot B (Cross-Beam Blinding Light - Theatrical Cold White/Cyan)
	if spot_b_alpha > 0.01:
		var poly_b = PackedVector2Array([SPOT_B_APEX, Vector2(145, 112), Vector2(245, 112)])
		var cols_b = PackedColorArray([
			Color(0.72, 0.90, 1.0, 0.38 * spot_b_alpha * pulse_sin),
			Color(0.55, 0.82, 1.0, 0.15 * spot_b_alpha * pulse_sin),
			Color(0.55, 0.82, 1.0, 0.15 * spot_b_alpha * pulse_sin)
		])
		overlay.draw_polygon(poly_b, cols_b)
		overlay.draw_line(SPOT_B_APEX, Vector2(145, 112), Color(0.85, 0.96, 1.0, 0.75 * spot_b_alpha), 2.0)
		overlay.draw_line(SPOT_B_APEX, Vector2(245, 112), Color(0.85, 0.96, 1.0, 0.75 * spot_b_alpha), 2.0)
		overlay.draw_circle(SPOT_B_APEX, 4.5, Color(0.9, 0.98, 1.0, 1.0 * spot_b_alpha))

	# Spot C (Balcony Wash - Amber Cone)
	if spot_c_alpha > 0.01:
		var poly_c = PackedVector2Array([SPOT_C_APEX, Vector2(205, 112), Vector2(285, 112)])
		var cols_c = PackedColorArray([
			Color(1.0, 0.65, 0.25, 0.26 * spot_c_alpha * pulse_sin),
			Color(0.9, 0.52, 0.15, 0.09 * spot_c_alpha * pulse_sin),
			Color(0.9, 0.52, 0.15, 0.09 * spot_c_alpha * pulse_sin)
		])
		overlay.draw_polygon(poly_c, cols_c)
		overlay.draw_line(SPOT_C_APEX, Vector2(205, 112), Color(1.0, 0.75, 0.35, 0.50 * spot_c_alpha), 1.5)
		overlay.draw_line(SPOT_C_APEX, Vector2(285, 112), Color(1.0, 0.75, 0.35, 0.50 * spot_c_alpha), 1.5)
		overlay.draw_circle(SPOT_C_APEX, 3.5, Color(1.0, 0.78, 0.40, 0.95 * spot_c_alpha))

func _draw_target_box() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var is_blind_spot_ready = (selected_position == "bridge" and (!spot_a_on and spot_b_on and !spot_c_on))

	var target_col = Color(0.25, 1.0, 0.45, 0.95) if is_blind_spot_ready else Color(0.95, 0.35, 0.3, 0.9)

	# Target box brackets around Royal Box
	var r = Rect2(TARGET_POS.x - 12, TARGET_POS.y - 9, 24, 18)
	var bk_col = Color(target_col.r, target_col.g, target_col.b, 0.15)
	overlay.draw_rect(r, bk_col, true)

	# 4 bracket corners
	var arm = 5.0
	overlay.draw_line(r.position, r.position + Vector2(arm, 0), target_col, 1.5)
	overlay.draw_line(r.position, r.position + Vector2(0, arm), target_col, 1.5)

	overlay.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x - arm, r.position.y), target_col, 1.5)
	overlay.draw_line(Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.position.y + arm), target_col, 1.5)

	overlay.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x + arm, r.end.y), target_col, 1.5)
	overlay.draw_line(Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.end.y - arm), target_col, 1.5)

	overlay.draw_line(r.end, r.end - Vector2(arm, 0), target_col, 1.5)
	overlay.draw_line(r.end, r.end - Vector2(0, arm), target_col, 1.5)

	# Rotating reticle crosshair
	var rot = anim_time * 1.6
	var rad = 7.0 + 1.0 * sin(anim_time * 4.0)
	for i in range(4):
		var ang = rot + i * (PI / 2.0)
		var p1 = TARGET_POS + Vector2(cos(ang), sin(ang)) * 2.5
		var p2 = TARGET_POS + Vector2(cos(ang), sin(ang)) * rad
		overlay.draw_line(p1, p2, target_col, 1.2)

	# Target tag below target box (no collision with Bridge above)
	var tag = "ROYAL BOX (TARGET)" if is_en else "KRALİYET LOCASI (HEDEF)"
	_draw_badge(Vector2(TARGET_POS.x - 36, TARGET_POS.y + 12), tag, target_col, 6)

func _draw_candidate_positions_and_laser() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	# Candidate 1: Balcony
	_draw_position_pin(POS_BALCONY, selected_position == "balcony", "1. BALKON" if not is_en else "1. BALCONY")

	# Candidate 2: Vent
	_draw_position_pin(POS_VENT, selected_position == "vent", "2. HAVALANDIRMA" if not is_en else "2. ROOF VENT")

	# Candidate 3: Light Bridge
	_draw_position_pin(POS_BRIDGE, selected_position == "bridge", "3. IŞIK KÖPRÜSÜ" if not is_en else "3. LIGHT BRIDGE")

	# Active Aiming Trajectory Laser
	if selected_position == "balcony":
		# Direct line across hall, but completely exposed
		var col = Color(1.0, 0.35, 0.2, 0.9)
		_draw_dashed_line(overlay, POS_BALCONY, TARGET_POS, col, 1.8, 6.0, 4.0, dash_offset)
		var note = "EXPOSED: VISIBLE TO AUDITORIUM" if is_en else "AÇIKTA: SALONDAN %100 GÖRÜNÜR"
		_draw_badge(Vector2(POS_BALCONY.x - 45, POS_BALCONY.y + 14), note, col, 6)

	elif selected_position == "vent":
		# Line blocked by roof trusses
		var col = Color(1.0, 0.55, 0.2, 0.9)
		_draw_dashed_line(overlay, POS_VENT, POS_OBSTACLE, col, 1.8, 6.0, 4.0, dash_offset)
		_draw_dashed_line(overlay, POS_OBSTACLE, TARGET_POS, Color(0.5, 0.5, 0.5, 0.35), 1.0, 4.0, 4.0, 0.0)

		# Pulsing obstacle 'X'
		var x_pulse = 5.0 + 1.2 * sin(anim_time * 5.0)
		var obs_col = Color(1.0, 0.2, 0.2, 0.95)
		overlay.draw_line(POS_OBSTACLE - Vector2(x_pulse, x_pulse), POS_OBSTACLE + Vector2(x_pulse, x_pulse), obs_col, 2.4)
		overlay.draw_line(POS_OBSTACLE + Vector2(-x_pulse, x_pulse), POS_OBSTACLE + Vector2(x_pulse, -x_pulse), obs_col, 2.4)
		var note = "BLOCKED: STEEL TRUSS OBSTACLE" if is_en else "ENGEL: ÇATI MAKASI - AÇI YOK"
		_draw_badge(Vector2(POS_OBSTACLE.x - 30, POS_OBSTACLE.y - 12), note, obs_col, 6)

	elif selected_position == "bridge":
		# Light Bridge Catwalk
		var is_stealth = (!spot_a_on and spot_b_on and !spot_c_on)
		if is_stealth:
			var col = Color(0.25, 1.0, 0.45, 0.95)
			# Clean laser beam
			overlay.draw_line(POS_BRIDGE, TARGET_POS, col, 2.2)
			_draw_dashed_line(overlay, POS_BRIDGE, TARGET_POS, Color(1.0, 1.0, 1.0, 0.9), 1.2, 4.0, 6.0, dash_offset * 1.5)

			# Stealth Zone Shadow & Radar indicator around Bridge
			var radar_r = 12.0 + 1.8 * sin(anim_time * 4.0)
			overlay.draw_arc(POS_BRIDGE, radar_r, 0, TAU, 24, Color(0.25, 1.0, 0.45, 0.5), 1.2)
			var note = "★ 100% BLIND SPOT VERIFIED" if is_en else "★ %100 KÖR NOKTA DOĞRULANDI"
			_draw_badge(Vector2(115, 50), note, col, 6)
		else:
			var col = Color(1.0, 0.4, 0.25, 0.9)
			_draw_dashed_line(overlay, POS_BRIDGE, TARGET_POS, col, 1.8, 6.0, 4.0, dash_offset)
			var note = "EXPOSED: SPOTLIGHT ILLUMINATES CATWALK" if is_en else "AÇIKTA: SPOT IŞIĞI KÖPRÜYÜ AYDINLATIYOR"
			_draw_badge(Vector2(115, 50), note, col, 6)

func _draw_position_pin(pos: Vector2, is_selected: bool, label_text: String) -> void:
	var col = Color(0.96, 0.89, 0.35, 1.0) if is_selected else Color(0.5, 0.58, 0.68, 0.75)
	var r = 4.5 if is_selected else 3.0

	overlay.draw_circle(pos, r, col)
	if is_selected:
		var ring_r = r + 2.5 + sin(anim_time * 4.5) * 1.0
		overlay.draw_arc(pos, ring_r, 0, TAU, 18, Color(col.r, col.g, col.b, 0.65), 1.2)

	var label_offset = Vector2(-20, -11)
	if pos.y < 16:
		label_offset = Vector2(-22, 6)
	_draw_badge(pos + label_offset, label_text, col, 5)

func _draw_simulation_effects() -> void:
	var origin_pt = POS_BALCONY
	var end_pt = TARGET_POS
	if selected_position == "vent":
		origin_pt = POS_VENT
		end_pt = POS_OBSTACLE
	elif selected_position == "bridge":
		origin_pt = POS_BRIDGE
		end_pt = TARGET_POS

	# 1. Active tracer bullet traveling along path
	if is_simulating:
		var cur_pos = origin_pt.lerp(end_pt, sim_progress)
		var dir = (end_pt - origin_pt).normalized()

		# Glowing tracer bullet
		overlay.draw_circle(cur_pos, 3.5, Color(1.0, 1.0, 1.0, 0.95))
		var trail_col = Color(0.25, 1.0, 0.45, 0.8) if (selected_position == "bridge" and (!spot_a_on and spot_b_on and !spot_c_on)) else Color(1.0, 0.35, 0.2, 0.8)
		overlay.draw_line(cur_pos - dir * 16.0, cur_pos, trail_col, 2.5)

		# Muzzle flash at origin
		if sim_progress < 0.25:
			var flash_alpha = 1.0 - (sim_progress / 0.25)
			overlay.draw_circle(origin_pt, 7.0, Color(1.0, 0.95, 0.6, flash_alpha * 0.9))

	# 2. Impact feedback
	if impact_timer > 0.0:
		var progress_impact = 1.0 - (impact_timer / 0.8)
		if sim_success:
			# Expanding green shockwave ring
			var shock_r = 10.0 + progress_impact * 35.0
			var shock_alpha = 1.0 - progress_impact
			overlay.draw_arc(end_pt, shock_r, 0, TAU, 32, Color(0.25, 1.0, 0.45, shock_alpha * 0.9), 2.5)
		else:
			# Red spark burst
			var spark_len = 6.0 + progress_impact * 12.0
			var spark_alpha = 1.0 - progress_impact
			var spark_col = Color(1.0, 0.3, 0.2, spark_alpha)
			for k in range(8):
				var ang = k * (PI / 4.0) + anim_time * 3.0
				var p1 = end_pt + Vector2(cos(ang), sin(ang)) * 3.0
				var p2 = end_pt + Vector2(cos(ang), sin(ang)) * spark_len
				overlay.draw_line(p1, p2, spark_col, 1.8)

func _draw_badge(pos: Vector2, text: String, col: Color, font_sz: int = 6) -> void:
	if not overlay: return
	var text_w = text.length() * (font_sz * 0.58)
	var bg_rect = Rect2(pos.x - 2, pos.y - font_sz, text_w + 4, font_sz + 3)
	overlay.draw_rect(bg_rect, Color(0.04, 0.06, 0.10, 0.88), true)
	overlay.draw_rect(bg_rect, Color(col.r, col.g, col.b, 0.4), false, 1.0)
	overlay.draw_string(COURIER_FONT, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_sz, col)

func _draw_dashed_line(canvas: Control, from: Vector2, to: Vector2, color: Color, width: float, dash_len: float, gap_len: float, offset: float) -> void:
	var dir = (to - from).normalized()
	var total_len = from.distance_to(to)
	var step = dash_len + gap_len
	var curr = fposmod(-offset, step)
	while curr < total_len:
		var p1 = from + dir * max(0.0, curr)
		var p2 = from + dir * min(total_len, curr + dash_len)
		if curr + dash_len > 0.0 and curr < total_len:
			canvas.draw_line(p1, p2, color, width)
		curr += step

func _on_test_pressed() -> void:
	if is_simulating:
		return

	is_simulating = true
	sim_progress = 0.0
	sim_success = (selected_position == "bridge" and (!spot_a_on and spot_b_on and !spot_c_on))

	var am = get_node_or_null("/root/AudioManager")
	if am and am.has_method("play_sfx"):
		am.play_sfx("click")

func _finish_test_resolution() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	var am = get_node_or_null("/root/AudioManager")

	if selected_position == "balcony":
		status_label.text = "Karşı balkon tüm salondan doğrudan görünüyor; gizlenmek imkânsız!" if not is_en else "The opposite balcony is directly visible to the entire hall; concealment impossible!"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1.0))
		if am and am.has_method("play_sfx"): am.play_sfx("error")
		_shake_schematic()
		return
	elif selected_position == "vent":
		status_label.text = "Çatı havalandırmasından locaya görüş hattı yok; çatı makasları açıyı kapatıyor!" if not is_en else "No line of sight from the vent; steel trusses block the angle to the royal box!"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1.0))
		if am and am.has_method("play_sfx"): am.play_sfx("error")
		_shake_schematic()
		return

	# Selected position is bridge
	if not (!spot_a_on and spot_b_on and !spot_c_on):
		status_label.text = "Spot ayarı hatalı! Spot A veya C açıkken ışık köprüsündeki nişancı salondakilere görünür!" if not is_en else "Incorrect lighting! When Spot A or C is lit, the sniper is fully exposed!"
		status_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1.0))
		if am and am.has_method("play_sfx"): am.play_sfx("error")
		_shake_schematic()
		return

	# Correct solution!
	status_label.text = "✔ KÖR NOKTA DOĞRULANDI! Spot B sahneyi kör ederken ışık köprüsü mutlak gölgede kalıyor ve Kraliyet Locası'na doğrudan atış açısı veriyor!" if not is_en else "✔ BLIND SPOT VERIFIED! Spot B blinds the hall while the light bridge remains in pitch black, granting a clean line of fire into the Royal Box!"
	status_label.add_theme_color_override("font_color", Color(0.3, 0.95, 0.4, 1.0))
	if am and am.has_method("play_sfx"): am.play_sfx("clue_found")

	# Unlock D302 deduction
	if not "D302" in GameState.unlocked_deductions:
		GameState.unlocked_deductions.append("D302")
		EventBus.deduction_made.emit("D302")
		var toast = "💡 Çıkarım Açıldı: D302 Kör Nokta Atış Hattı" if not is_en else "💡 Deduction Unlocked: D302 Blind Spot Line of Fire"
		EventBus.toast_requested.emit(toast)
	SaveSystem.save_game()

func _shake_schematic() -> void:
	if not schematic_rect:
		return
	var orig_pos = schematic_rect.position
	var t = create_tween()
	t.tween_property(schematic_rect, "position:x", orig_pos.x - 5, 0.04)
	t.tween_property(schematic_rect, "position:x", orig_pos.x + 5, 0.04)
	t.tween_property(schematic_rect, "position:x", orig_pos.x - 3, 0.04)
	t.tween_property(schematic_rect, "position:x", orig_pos.x, 0.04)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_board()
			get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_board()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_on_test_pressed()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_A:
			spot_a_on = !spot_a_on
			_play_toggle_sfx()
			_update_ui()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_B:
			spot_b_on = !spot_b_on
			_play_toggle_sfx()
			_update_ui()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_C:
			spot_c_on = !spot_c_on
			_play_toggle_sfx()
			_update_ui()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			selected_position = "balcony"
			_play_toggle_sfx()
			_update_ui()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			selected_position = "vent"
			_play_toggle_sfx()
			_update_ui()
			get_viewport().set_input_as_handled()
			return
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			selected_position = "bridge"
			_play_toggle_sfx()
			_update_ui()
			get_viewport().set_input_as_handled()
			return
