extends Control

## Detective Notebook (Dedektif Defteri).
## Contains 6 touch-friendly tabs:
## 1. Kanıtlar (Evidence list with Inspect buttons)
## 2. İfadeler (Suspect statements)
## 3. Zaman Çizelgesi (20:00 - 23:00 timeline)
## 4. Çıkarımlar (Tap-to-select deduction combiner: Slot 1 + Slot 2 -> "Birleştir")
## 5. Şüpheliler (Profiles and alibis)
## 6. Kişisel (Arayan Kim? notes C01-C05)

@onready var close_btn: Button = $NotebookPanel/CloseBtn
@onready var tab_container: TabContainer = $NotebookPanel/TabContainer

# Tab 1: Kanıtlar
@onready var evidence_scroll: ScrollContainer = $NotebookPanel/TabContainer/Kanıtlar/Scroll
@onready var evidence_list_container: VBoxContainer = $NotebookPanel/TabContainer/Kanıtlar/Scroll/ListContainer
@onready var evidence_count_label: Label = $NotebookPanel/TabContainer/Kanıtlar/CountLabel

# Tab 2: İfadeler
@onready var statements_container: VBoxContainer = $NotebookPanel/TabContainer/İfadeler/Scroll/StatementsList

# Tab 3: Zaman Çizelgesi
@onready var timeline_container: VBoxContainer = $NotebookPanel/TabContainer/ZamanÇizelgesi/Scroll/TimelineList

# Tab 4: Çıkarımlar (Deduction)
@onready var slot1_btn: Button = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/CombineArea/Slot1Btn
@onready var slot2_btn: Button = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/CombineArea/Slot2Btn
@onready var combine_btn: Button = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/CombineArea/CombineBtn
@onready var clear_btn: Button = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/CombineArea/ClearBtn
@onready var deduction_status_label: Label = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/StatusLabel
@onready var deduction_clues_container: HFlowContainer = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/CluesScroll/CluesContainer
@onready var unlocked_deductions_container: VBoxContainer = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/UnlockedScroll/UnlockedList
@onready var clues_section_header: Label = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/CluesSectionHeader
@onready var unlocked_section_header: Label = $NotebookPanel/TabContainer/Çıkarımlar/DeductionVBox/UnlockedSectionHeader

# Tab 5: Şüpheliler
@onready var suspects_container: VBoxContainer = $NotebookPanel/TabContainer/Şüpheliler/Scroll/SuspectsList

# Tab 6: Harita (Kesit Malikane)
@onready var current_room_label: Label = $NotebookPanel/TabContainer/Harita/MapContainer/CurrentRoomLabel
@onready var upper_floor_grid: HBoxContainer = $NotebookPanel/TabContainer/Harita/MapContainer/UpperFloorGrid
@onready var ground_floor_grid: Container = $NotebookPanel/TabContainer/Harita/MapContainer/GroundFloorGrid
@onready var ground_floor_label: Label = $NotebookPanel/TabContainer/Harita/MapContainer/GroundFloorLabel if has_node("NotebookPanel/TabContainer/Harita/MapContainer/GroundFloorLabel") else null
@onready var upper_floor_label: Label = $NotebookPanel/TabContainer/Harita/MapContainer/UpperFloorLabel if has_node("NotebookPanel/TabContainer/Harita/MapContainer/UpperFloorLabel") else null

@onready var title_label: Label = $NotebookPanel/TitleLabel if has_node("NotebookPanel/TitleLabel") else null
var toggle_cooldown: float = 0.0

var selected_clue_1: String = ""
var selected_clue_2: String = ""

func _ready() -> void:
	visible = false
	if has_node("NotebookPanel"):
		$NotebookPanel.visible = true
	close_btn.pressed.connect(_on_close_pressed)
	combine_btn.pressed.connect(_on_combine_pressed)
	clear_btn.pressed.connect(_on_clear_pressed)
	slot1_btn.pressed.connect(func(): _clear_slot(1))
	slot2_btn.pressed.connect(func(): _clear_slot(2))
	for b in [close_btn, combine_btn, clear_btn, slot1_btn, slot2_btn]:
		if b:
			b.focus_mode = Control.FOCUS_NONE

	if EventBus.has_signal("notebook_toggle_requested"):
		EventBus.notebook_toggle_requested.connect(_on_notebook_toggle_requested)
	EventBus.notebook_toggled.connect(_on_notebook_toggled)
	
	if EventBus.has_signal("language_changed"):
		EventBus.language_changed.connect(func(_loc):
			_update_localization()
			if visible:
				refresh_all_tabs()
		)
	if EventBus.has_signal("font_scale_changed"):
		EventBus.font_scale_changed.connect(func(_sc):
			if visible:
				refresh_all_tabs()
		)
		
	_strip_focus($NotebookPanel)
	_update_slot_labels()
	_update_localization()

func get_font_sizes() -> Dictionary:
	var scale = GameState.get_font_scale()
	if scale == "small":
		return {"text": 6, "title": 7, "btn": 6, "header": 8, "row_h": 24}
	elif scale == "large":
		return {"text": 9, "title": 9, "btn": 8, "header": 10, "row_h": 32}
	else:
		return {"text": 8, "title": 8, "btn": 7, "header": 9, "row_h": 28}

func _update_localization() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	if close_btn:
		close_btn.text = "Close [Q]" if is_en else "Kapat [Q]"
	var title_lbl = get_node_or_null("NotebookPanel/TitleLabel")
	if title_lbl:
		title_lbl.text = "📋 DETECTIVE CASE DOSSIER — CASE 1: THE DARK MANOR" if is_en else "📋 DEDEKTİF VAKA DOSYASI — VAKA 1: KARANLIK MALİKÂNE"

	if tab_container:
		if tab_container.get_tab_count() > 0: tab_container.set_tab_title(0, "🔍 Clues" if is_en else "🔍 Kanıtlar")
		if tab_container.get_tab_count() > 1: tab_container.set_tab_title(1, "💬 Statements" if is_en else "💬 İfadeler")
		if tab_container.get_tab_count() > 2: tab_container.set_tab_title(2, "⏳ Timeline" if is_en else "⏳ Zaman")
		if tab_container.get_tab_count() > 3: tab_container.set_tab_title(3, "🧩 Deductions" if is_en else "🧩 Çıkarım")
		if tab_container.get_tab_count() > 4: tab_container.set_tab_title(4, "👤 Suspects" if is_en else "👤 Şüpheliler")
		if tab_container.get_tab_count() > 5: tab_container.set_tab_title(5, "🗺️ Map" if is_en else "🗺️ Harita")

func _process(delta: float) -> void:
	if toggle_cooldown > 0.0:
		toggle_cooldown -= delta

func _on_notebook_toggle_requested() -> void:
	if toggle_cooldown > 0.0:
		return
	if visible:
		close_notebook()
	else:
		open_notebook()

func _on_notebook_toggled(is_open: bool) -> void:
	if is_open:
		if not visible:
			open_notebook()
	else:
		if visible:
			close_notebook()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN or what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_strip_focus($NotebookPanel)
		var vp = get_viewport()
		if vp and vp.gui_get_focus_owner():
			vp.gui_get_focus_owner().release_focus()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.alt_pressed or event.ctrl_pressed or event.meta_pressed or Input.is_key_pressed(KEY_ALT):
			if event.keycode == KEY_TAB:
				get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("toggle_notebook") or event.keycode == KEY_Q:
			close_notebook()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_cancel") or event.keycode == KEY_ESCAPE:
			close_notebook()
			get_viewport().set_input_as_handled()
			return

func open_notebook() -> void:
	if visible:
		return
	if toggle_cooldown > 0.0:
		return
	if CutsceneManager.is_cutscene_active:
		return
	var tree = get_tree()
	if tree:
		for modal_name in ["PauseMenu", "ConfrontationHale", "AccusationModal", "InspectView", "CaseEndingModal"]:
			var m = tree.root.find_child(modal_name, true, false)
			if m and is_instance_valid(m) and m.is_visible_in_tree() and not m.is_queued_for_deletion():
				return

	toggle_cooldown = 0.15
	if has_node("NotebookPanel"):
		$NotebookPanel.visible = true
	visible = true
	GameState.can_player_move = false
	EventBus.notebook_toggled.emit(true)

	if title_label:
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = loc_mgr and loc_mgr.get_locale() == "en"
		var c_name = "THE DARK MANOR" if is_en else GameState.case_data.get("title", "Karanlık Malikâne").to_upper()
		title_label.text = ("📋 DETECTIVE CASE DOSSIER — " if is_en else "📋 DEDEKTİF VAKA DOSYASI — ") + c_name

	_strip_focus($NotebookPanel)
	refresh_all_tabs()

func close_notebook() -> void:
	if not visible:
		return
	toggle_cooldown = 0.15
	visible = false
	_strip_focus($NotebookPanel)
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()

	var tree = get_tree()
	var has_other_modal = false
	if tree:
		for modal_name in ["Interrogation", "AccusationModal", "InspectView", "ConfrontationHale", "PauseMenu"]:
			var m = tree.root.find_child(modal_name, true, false)
			if m and is_instance_valid(m) and m.is_visible_in_tree():
				has_other_modal = true
				break
	if not has_other_modal and not CutsceneManager.is_cutscene_active:
		GameState.can_player_move = true
	EventBus.notebook_toggled.emit(false)

func _strip_focus(node: Node) -> void:
	if node is Control:
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		_strip_focus(child)

func _on_close_pressed() -> void:
	close_notebook()

func refresh_all_tabs() -> void:
	_refresh_evidence_tab()
	_refresh_statements_tab()
	_refresh_timeline_tab()
	_refresh_deductions_tab()
	_refresh_suspects_tab()
	_refresh_map_tab()

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
	"E301": "res://cases/case03/assets/clues/clue_e301_k4_rifle.png",
	"E302": "res://cases/case03/assets/clues/clue_e302_spent_casing.png",
	"E303": "res://assets/sprites/inspect/inspect_e205_radio_logbook.png",
	"E304": "res://assets/sprites/clues/icon_door_lock.png",
	"E305": "res://assets/sprites/inspect/inspect_e15_keyhole_key.png",
	"E306": "res://cases/case03/assets/clues/clue_e306_marked_score.png",
	"E307": "res://assets/sprites/clues/clue_e03_burned_candle.png",
	"E308": "res://cases/case03/assets/clues/clue_e308_typewriter_note.png",
	"E309": "res://cases/case03/assets/clues/clue_e309_k4_watch.png",
	"E310": "res://assets/sprites/clues/icon_muddy_bootprint.png"
}

func _get_clue_icon(clue_id: String) -> Texture2D:
	if CLUE_ICONS.has(clue_id):
		var p = CLUE_ICONS[clue_id]
		if ResourceLoader.exists(p):
			return load(p) as Texture2D
		var gp_direct = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(gp_direct):
			var img = Image.load_from_file(gp_direct)
			if img:
				return ImageTexture.create_from_image(img)
		var fn = p.get_file()
		var case_p = "res://cases/%s/assets/clues/%s" % [GameState.current_case_id, fn]
		if ResourceLoader.exists(case_p):
			return load(case_p) as Texture2D
		var gp = ProjectSettings.globalize_path(case_p)
		if FileAccess.file_exists(gp):
			var img = Image.load_from_file(gp)
			if img:
				return ImageTexture.create_from_image(img)
	return null

# ----------------- TAB 1: KANITLAR -----------------
func _refresh_evidence_tab() -> void:
	for c in evidence_list_container.get_children():
		c.queue_free()

	var fs = get_font_sizes()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	var discovered = GameState.discovered_evidence
	var total_clues = GameState.evidence_db.size()
	if total_clues <= 0:
		total_clues = 17 if GameState.current_case_id == "case01" else 10
	evidence_count_label.text = ("Collected Clues: %d / %d" if is_en else "Toplanan Kanıt: %d / %d") % [discovered.size(), total_clues]

	# 1. Active Case Briefing Card
	var briefing = PanelContainer.new()
	var b_style = StyleBoxFlat.new()
	b_style.bg_color = Color(0.10, 0.13, 0.18, 0.95)
	b_style.border_color = Color(0.85, 0.75, 0.45, 0.6)
	b_style.set_border_width_all(1)
	b_style.content_margin_left = 6
	b_style.content_margin_right = 6
	b_style.content_margin_top = 4
	b_style.content_margin_bottom = 4
	briefing.add_theme_stylebox_override("panel", b_style)

	var b_vbox = VBoxContainer.new()
	b_vbox.add_theme_constant_override("separation", 2)

	var b_title = Label.new()
	b_title.add_theme_font_size_override("font_size", fs["title"])
	b_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.5, 1.0))
	var c_title = GameState.case_data.get("title", "Karanlık Malikâne")
	var c_sub = GameState.case_data.get("subtitle", "Edmund Harlow Cinayeti")
	if is_en:
		c_title = "The Dark Manor"
		c_sub = "The Murder of Edmund Harlow"
	b_title.text = "★ %s: %s — %s" % ["Case Dossier" if is_en else "Vaka Dosyası", c_title, c_sub]
	b_vbox.add_child(b_title)

	var b_hint = Label.new()
	b_hint.add_theme_font_size_override("font_size", fs["text"])
	b_hint.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 0.9))
	b_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b_hint.text = "Instructions: Search rooms and inspect items with [E]. Press [X] (Focus) to highlight clues." if is_en else "Talimat: Odaları dolaşarak eşyaları [E] ile inceleyin. İpuçlarını vurgulamak için [X] (Odak) tuşuna basın."
	b_vbox.add_child(b_hint)

	briefing.add_child(b_vbox)
	evidence_list_container.add_child(briefing)

	var sep = HSeparator.new()
	evidence_list_container.add_child(sep)

	# 2. All 17 clue slots: discovered clues with icons and inspect, undiscovered slots with placeholders
	var all_evidence_keys: Array = GameState.evidence_db.keys()
	all_evidence_keys.sort()
	if all_evidence_keys.is_empty():
		for i in range(1, 18):
			all_evidence_keys.append("E%02d" % i)

	for ev_id in all_evidence_keys:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, fs["row_h"])

		if ev_id in discovered:
			var ev = GameState.get_evidence_data(ev_id)
			var icon_rect = TextureRect.new()
			icon_rect.custom_minimum_size = Vector2(22, 22)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			var icon_tex = _get_clue_icon(ev_id)
			if icon_tex:
				icon_rect.texture = icon_tex
			row.add_child(icon_rect)

			var info_lbl = Label.new()
			info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_lbl.add_theme_font_size_override("font_size", fs["title"])
			info_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.8, 1.0))
			info_lbl.text = " [%s] %s" % [ev_id, ev.get("ad", "")]
			row.add_child(info_lbl)

			var inspect_btn = Button.new()
			inspect_btn.custom_minimum_size = Vector2(56 if fs["text"] >= 8 else 48, 20)
			inspect_btn.add_theme_font_size_override("font_size", fs["btn"])
			inspect_btn.focus_mode = Control.FOCUS_NONE
			inspect_btn.text = "Inspect [E]" if is_en else "İncele [E]"
			inspect_btn.pressed.connect(func():
				EventBus.inspect_evidence_requested.emit(ev_id)
			)
			row.add_child(inspect_btn)
		else:
			var icon_placeholder = Label.new()
			icon_placeholder.custom_minimum_size = Vector2(22, 22)
			icon_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			icon_placeholder.add_theme_font_size_override("font_size", fs["title"])
			icon_placeholder.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55, 0.7))
			icon_placeholder.text = "[?]"
			row.add_child(icon_placeholder)

			var unk_lbl = Label.new()
			unk_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			unk_lbl.add_theme_font_size_override("font_size", fs["text"])
			unk_lbl.add_theme_color_override("font_color", Color(0.45, 0.48, 0.55, 0.8))
			unk_lbl.text = (" [%s] ??? — Undiscovered" if is_en else " [%s] ??? — Henüz Keşfedilmedi") % ev_id
			row.add_child(unk_lbl)

		evidence_list_container.add_child(row)

# ----------------- TAB 2: İFADELER -----------------
func _refresh_statements_tab() -> void:
	for c in statements_container.get_children():
		c.queue_free()

	var fs = get_font_sizes()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	var susp_keys = GameState.suspects_db.keys()
	if susp_keys.is_empty():
		susp_keys = ["margaret", "julian", "hale", "pike"]

	for susp_id in susp_keys:
		var susp = GameState.get_suspect_data(susp_id)
		var header = Label.new()
		header.add_theme_font_size_override("font_size", fs["header"])
		header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.5, 1.0))
		header.text = "— %s (%s) —" % [susp.get("ad", susp_id), susp.get("rol", "")]
		statements_container.add_child(header)

		var st_list = GameState.collected_statements.get(susp_id, [])
		if st_list.is_empty():
			var no_st = Label.new()
			no_st.add_theme_font_size_override("font_size", fs["text"])
			no_st.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7, 0.9))
			no_st.text = "  [ ? ] Not interrogated yet. Speak with this person [E] to take their statement." if is_en else "  [ ? ] Henüz sorgulanmadı. Bu kişiyle konuşarak [E] ifadesini alın."
			statements_container.add_child(no_st)
		else:
			for st in st_list:
				var st_lbl = Label.new()
				st_lbl.add_theme_font_size_override("font_size", fs["text"])
				st_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				st_lbl.text = "  • " + st
				statements_container.add_child(st_lbl)

# ----------------- TAB 3: ZAMAN ÇİZELGESİ -----------------
func _refresh_timeline_tab() -> void:
	for c in timeline_container.get_children():
		c.queue_free()

	var fs = get_font_sizes()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	var timeline_file = GameState.get_case_data_path(GameState.current_case_id, "timeline.json")
	var raw_timeline = GameState._load_json_file(timeline_file)
	var events = []
	if raw_timeline is Array and not raw_timeline.is_empty():
		for item in raw_timeline:
			var t_time = item.get("time", "")
			var t_text = item.get("en" if is_en else "tr", item.get("text", ""))
			events.append({"time": t_time, "text": t_text})
	else:
		events = [
			{"time": "20:00", "text": "Fırtına başladı." if not is_en else "Storm intensified."},
			{"time": "21:40", "text": "Cinayet işlendi." if not is_en else "Murder committed."},
			{"time": "23:00", "text": "Ceset bulundu." if not is_en else "Body discovered."}
		]

	for ev in events:
		var row = HBoxContainer.new()
		var time_lbl = Label.new()
		time_lbl.custom_minimum_size = Vector2(80 if fs["text"] >= 8 else 70, 0)
		time_lbl.add_theme_font_size_override("font_size", fs["title"])
		time_lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4, 1.0))
		time_lbl.text = ev["time"]
		row.add_child(time_lbl)

		var text_lbl = Label.new()
		text_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text_lbl.add_theme_font_size_override("font_size", fs["text"])
		text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text_lbl.text = ev["text"]
		row.add_child(text_lbl)

		timeline_container.add_child(row)

# ----------------- TAB 4: ÇIKARIMLAR (DEDUCTION COMBINER) -----------------
func _get_clue_display_name(clue_id: String) -> String:
	if clue_id.begins_with("E"):
		var key = "CLUE_" + clue_id + "_NAME"
		var tr_name = tr(key)
		if tr_name != key and tr_name != "":
			return tr_name
		var ev_data = GameState.get_evidence_data(clue_id)
		var ad = ev_data.get("ad", "")
		if ad != "":
			return ad
		var item_d = GameState.get_item_data(clue_id)
		return item_d.get("ad", clue_id)
	elif clue_id.begins_with("D"):
		var ded_data = GameState.deductions_db.get(clue_id, {})
		return ded_data.get("baslik", clue_id)
	return clue_id

func _refresh_deductions_tab() -> void:
	var fs = get_font_sizes()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	if clues_section_header:
		clues_section_header.add_theme_font_size_override("font_size", fs["title"])
		clues_section_header.text = ("── EVIDENCE & CLUE CARDS (%d Found) ──" if is_en else "── KANIT VE İPUCU KARTLARI (%d Bulundu) ──") % (GameState.discovered_evidence.size() + GameState.unlocked_deductions.size())
	if unlocked_section_header:
		unlocked_section_header.add_theme_font_size_override("font_size", fs["title"])
		unlocked_section_header.text = ("── SOLVED DEDUCTIONS (%d / %d) ──" if is_en else "── ÇÖZÜLEN ÇIKARIMLAR (%d / %d) ──") % [GameState.unlocked_deductions.size(), GameState.deductions_db.size()]

	# Populate selectable clue buttons
	for c in deduction_clues_container.get_children():
		deduction_clues_container.remove_child(c)
		c.queue_free()

	deduction_status_label.add_theme_font_size_override("font_size", fs["text"])

	# Check if compound deduction D7 is ready
	var d7_ready = ("D1" in GameState.unlocked_deductions) and ("D2" in GameState.unlocked_deductions) and ("D5" in GameState.unlocked_deductions) and ("D6" in GameState.unlocked_deductions)
	if d7_ready and "D7" not in GameState.unlocked_deductions:
		deduction_status_label.text = "★ All primary deductions solved! Combine D1 and D2 to unlock final deduction (D7)." if is_en else "★ Tüm ana çıkarımlar tamamlandı! Nihai çıkarımı (D7) oluşturmak için D1 ve D2'yi birleştirin."
		deduction_status_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	elif selected_clue_1 == "" and selected_clue_2 == "":
		deduction_status_label.text = "Select two clue cards to connect theories, then press 'Combine'." if is_en else "Bağlantı kurmak için iki ipucu kartı seçin ve 'Birleştir'e basın."
		deduction_status_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45))

	if GameState.discovered_evidence.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.add_theme_font_size_override("font_size", fs["text"])
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
		empty_lbl.text = "No collected evidence yet. Search the rooms." if is_en else "Henüz toplanmış kanıt bulunamadı. Odaları araştırın."
		deduction_clues_container.add_child(empty_lbl)

	for ev_id in GameState.discovered_evidence:
		var ev_data = GameState.get_evidence_data(ev_id)
		var clue_name = _get_clue_display_name(ev_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(110 if fs["text"] >= 8 else 100, fs["row_h"] - 4)
		btn.add_theme_font_size_override("font_size", fs["btn"])
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "  [%s] %s" % [ev_id, clue_name]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var icon_tex = _get_clue_icon(ev_id)
		if icon_tex:
			btn.icon = icon_tex
			btn.expand_icon = true
		btn.tooltip_text = ev_data.get("aciklama", clue_name)
		btn.set_meta("clue_id", ev_id)
		btn.pressed.connect(func(): _select_clue_for_slot(ev_id))
		deduction_clues_container.add_child(btn)

	for ded_id in GameState.unlocked_deductions:
		var ded_data = GameState.deductions_db.get(ded_id, {})
		var ded_name = ded_data.get("baslik", ded_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120 if fs["text"] >= 8 else 110, fs["row_h"] - 4)
		btn.add_theme_font_size_override("font_size", fs["btn"])
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1.0))
		btn.text = " ★ [%s] %s" % [ded_id, ded_name]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.tooltip_text = ded_data.get("aciklama", ded_name)
		btn.set_meta("clue_id", ded_id)
		btn.pressed.connect(func(): _select_clue_for_slot(ded_id))
		deduction_clues_container.add_child(btn)

	# Populate unlocked deductions list
	for c in unlocked_deductions_container.get_children():
		unlocked_deductions_container.remove_child(c)
		c.queue_free()

	if GameState.unlocked_deductions.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.add_theme_font_size_override("font_size", fs["text"])
		empty_lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
		empty_lbl.text = "No deductions solved yet. Match related clues above." if is_en else "Henüz çıkarım yapılmadı. İlgili kanıtları yukarıdan eşleştirin."
		unlocked_deductions_container.add_child(empty_lbl)
	else:
		for ded_id in GameState.unlocked_deductions:
			var d_data = GameState.deductions_db.get(ded_id, {})
			var panel = PanelContainer.new()
			var p_style = StyleBoxFlat.new()
			p_style.bg_color = Color(0.06, 0.08, 0.12, 0.85)
			p_style.border_color = Color(0.25, 0.55, 0.35, 0.9)
			p_style.set_border_width_all(1)
			p_style.content_margin_left = 6
			p_style.content_margin_right = 6
			p_style.content_margin_top = 4
			p_style.content_margin_bottom = 4
			panel.add_theme_stylebox_override("panel", p_style)

			var box = VBoxContainer.new()
			box.add_theme_constant_override("separation", 2)

			var title_lbl = Label.new()
			title_lbl.add_theme_font_size_override("font_size", fs["title"])
			title_lbl.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55, 1.0))
			title_lbl.text = "✔ [%s] %s" % [ded_id, d_data.get("baslik", "")]
			box.add_child(title_lbl)

			# Clues line
			var inputs = d_data.get("inputs", [])
			if not inputs.is_empty():
				var names = []
				for inp in inputs:
					names.append("[%s] %s" % [inp, _get_clue_display_name(inp)])
				var inputs_lbl = Label.new()
				inputs_lbl.add_theme_font_size_override("font_size", fs["btn"])
				inputs_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7, 0.85))
				inputs_lbl.text = ("Connection: " if is_en else "Bağlantı: ") + " + ".join(names)
				box.add_child(inputs_lbl)

			var exp_lbl = Label.new()
			exp_lbl.add_theme_font_size_override("font_size", fs["text"])
			exp_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.95))
			exp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			exp_lbl.text = d_data.get("aciklama", "")
			box.add_child(exp_lbl)

			panel.add_child(box)
			unlocked_deductions_container.add_child(panel)

	_update_slot_labels()

func _select_clue_for_slot(clue_id: String) -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	if selected_clue_1 == clue_id:
		selected_clue_1 = ""
		deduction_status_label.text = "Slot 1 deselected." if is_en else "1. seçim kaldırıldı."
		deduction_status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	elif selected_clue_2 == clue_id:
		selected_clue_2 = ""
		deduction_status_label.text = "Slot 2 deselected." if is_en else "2. seçim kaldırıldı."
		deduction_status_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	elif selected_clue_1 == "":
		selected_clue_1 = clue_id
		var name1 = _get_clue_display_name(clue_id)
		deduction_status_label.text = ("Clue 1: [%s] %s selected. Now pick Clue 2." if is_en else "1. İpucu: [%s] %s seçildi. Şimdi 2. ipucunu seçin.") % [clue_id, name1]
		deduction_status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	elif selected_clue_2 == "":
		selected_clue_2 = clue_id
		var name2 = _get_clue_display_name(clue_id)
		deduction_status_label.text = ("Clue 2: [%s] %s selected. You can press Combine." if is_en else "2. İpucu: [%s] %s seçildi. 'Birleştir'e basabilirsiniz.") % [clue_id, name2]
		deduction_status_label.add_theme_color_override("font_color", Color(0.45, 0.9, 1.0))
	else:
		selected_clue_1 = clue_id
		var name1 = _get_clue_display_name(clue_id)
		deduction_status_label.text = ("Clue 1 updated to [%s] %s." if is_en else "1. İpucu: [%s] %s olarak güncellendi.") % [clue_id, name1]
		deduction_status_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	_update_slot_labels()

func _clear_slot(slot_idx: int) -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	if slot_idx == 1:
		selected_clue_1 = ""
	else:
		selected_clue_2 = ""
	deduction_status_label.text = ("Slot %d cleared." if is_en else "%d. slot boşaltıldı.") % slot_idx
	deduction_status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	_update_slot_labels()

func _on_clear_pressed() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	selected_clue_1 = ""
	selected_clue_2 = ""
	_update_slot_labels()
	deduction_status_label.text = "Selections cleared." if is_en else "Seçimler sıfırlandı."
	deduction_status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _update_slot_labels() -> void:
	var fs = get_font_sizes()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	if slot1_btn:
		slot1_btn.add_theme_font_size_override("font_size", fs["btn"])
		if selected_clue_1 != "":
			var name1 = _get_clue_display_name(selected_clue_1)
			slot1_btn.text = "❶ [%s] %s" % [selected_clue_1, name1]
			slot1_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
			var icon1 = _get_clue_icon(selected_clue_1)
			slot1_btn.icon = icon1
			slot1_btn.expand_icon = (icon1 != null)
		else:
			slot1_btn.text = "❶ Clue 1: [Select]" if is_en else "❶ 1. İpucu: [Seçiniz]"
			slot1_btn.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
			slot1_btn.icon = null

	if slot2_btn:
		slot2_btn.add_theme_font_size_override("font_size", fs["btn"])
		if selected_clue_2 != "":
			var name2 = _get_clue_display_name(selected_clue_2)
			slot2_btn.text = "❷ [%s] %s" % [selected_clue_2, name2]
			slot2_btn.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
			var icon2 = _get_clue_icon(selected_clue_2)
			slot2_btn.icon = icon2
			slot2_btn.expand_icon = (icon2 != null)
		else:
			slot2_btn.text = "❷ Clue 2: [Select]" if is_en else "❷ 2. İpucu: [Seçiniz]"
			slot2_btn.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75))
			slot2_btn.icon = null

	var both_selected = (selected_clue_1 != "" and selected_clue_2 != "")
	if combine_btn:
		combine_btn.add_theme_font_size_override("font_size", fs["btn"])
		combine_btn.disabled = not both_selected
		if both_selected:
			combine_btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
			combine_btn.text = "⚡ Combine" if is_en else "⚡ Birleştir"
		else:
			combine_btn.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
			combine_btn.text = "Combine" if is_en else "Birleştir"

	if clear_btn:
		clear_btn.add_theme_font_size_override("font_size", fs["btn"])
		clear_btn.text = "Clear" if is_en else "Temizle"

	# Update visual highlights on all clue buttons
	if deduction_clues_container:
		for child in deduction_clues_container.get_children():
			if child is Button and child.has_meta("clue_id"):
				var cid = child.get_meta("clue_id")
				var base_name = _get_clue_display_name(cid)
				var is_ded = cid.begins_with("D")
				if cid == selected_clue_1:
					child.text = " ❶ [%s] %s" % [cid, base_name]
					child.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
				elif cid == selected_clue_2:
					child.text = " ❷ [%s] %s" % [cid, base_name]
					child.add_theme_color_override("font_color", Color(0.4, 0.88, 1.0))
				else:
					var prefix = " ★ " if is_ded else "   "
					child.text = "%s[%s] %s" % [prefix, cid, base_name]
					if is_ded:
						child.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1.0))
					else:
						child.remove_theme_color_override("font_color")

func _on_combine_pressed() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	if selected_clue_1 == "" or selected_clue_2 == "":
		deduction_status_label.text = "Please select two clue cards first!" if is_en else "Lütfen önce iki ipucu kartı seçin!"
		deduction_status_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		return

	var match_ded = GameState.check_deduction_pair(selected_clue_1, selected_clue_2)
	if match_ded.is_empty():
		deduction_status_label.text = "✖ No connection could be drawn between these two clues." if is_en else "✖ Bu iki ipucu arasında bir bağlantı kurulamadı."
		deduction_status_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
		if AudioManager:
			AudioManager.play_sfx("door_locked")
		var orig_pos_x = deduction_status_label.position.x
		var shk = create_tween()
		shk.tween_property(deduction_status_label, "position:x", orig_pos_x - 3.0, 0.04)
		shk.tween_property(deduction_status_label, "position:x", orig_pos_x + 3.0, 0.04)
		shk.tween_property(deduction_status_label, "position:x", orig_pos_x, 0.04)
	else:
		var ded_id = match_ded.get("id", "")
		if ded_id in GameState.unlocked_deductions:
			deduction_status_label.text = ("You have already reached this deduction: " if is_en else "Bu çıkarımı zaten yaptınız: ") + match_ded.get("baslik", "")
			deduction_status_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		else:
			GameState.unlock_deduction(ded_id)
			deduction_status_label.text = ("✔ NEW DEDUCTION!: " if is_en else "✔ YENİ ÇIKARIM!: ") + match_ded.get("baslik", "")
			deduction_status_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5))
			deduction_status_label.pivot_offset = deduction_status_label.size / 2.0
			var pls = create_tween()
			pls.tween_property(deduction_status_label, "scale", Vector2(1.06, 1.06), 0.10)
			pls.tween_property(deduction_status_label, "scale", Vector2(1.0, 1.0), 0.12)
			if AudioManager:
				AudioManager.play_sfx("evidence_found")
			EventBus.toast_requested.emit(("✔ Deduction: " if is_en else "✔ Çıkarım: ") + match_ded.get("baslik", ""))
			selected_clue_1 = ""
			selected_clue_2 = ""
			_refresh_deductions_tab()

# ----------------- TAB 5: ŞÜPHELİLER -----------------
func _refresh_suspects_tab() -> void:
	for c in suspects_container.get_children():
		c.queue_free()

	var fs = get_font_sizes()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	var susp_keys = GameState.suspects_db.keys()
	if susp_keys.is_empty():
		susp_keys = ["margaret", "julian", "hale", "pike"]

	for susp_id in susp_keys:
		var s = GameState.get_suspect_data(susp_id)
		var card = VBoxContainer.new()

		var role_str = s.get("rol", "")
		var age_val = s.get("yas", 0)
		var age_str = (" (%d)" % age_val) if age_val > 0 else ""
		var name_lbl = Label.new()
		name_lbl.add_theme_font_size_override("font_size", fs["title"])
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.85, 0.6, 1.0))
		name_lbl.text = "%s%s — %s" % [s.get("ad", susp_id), age_str, role_str]
		card.add_child(name_lbl)

		var alibi_lbl = Label.new()
		alibi_lbl.add_theme_font_size_override("font_size", fs["text"])
		alibi_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		alibi_lbl.text = ("Alibi: " if is_en else "Delil / Alibi: ") + s.get("alibi_ozeti", "---")
		card.add_child(alibi_lbl)

		var motive_lbl = Label.new()
		motive_lbl.add_theme_font_size_override("font_size", fs["text"])
		motive_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		motive_lbl.text = ("Apparent Motive: " if is_en else "Görünür Motif: ") + s.get("gorunur_motif", "---")
		card.add_child(motive_lbl)

		var sep = HSeparator.new()
		card.add_child(sep)

		suspects_container.add_child(card)

# ----------------- TAB 6: HARİTA -----------------
func _refresh_map_tab() -> void:
	var fs = get_font_sizes()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	var cur_room = GameState.current_room_id
	var room_names_tr = {
		"main_hall": "Ana Hol (Giriş)",
		"study": "Çalışma Odası (Suç Mahalli - Tek Giriş)",
		"library": "Kütüphane",
		"dining_room": "Büyük Yemek Salonu",
		"kitchen": "Mutfak (Çıkmaz)",
		"billiard_room": "Bilardo Odası (Çıkmaz)",
		"upper_floor": "Üst Kat (Yatak Odaları Koridoru)",
		"harlow_bedroom": "Harlow'un Yatak Odası",
		"julian_room": "Julian'ın Odası",
		"pike_room": "Pike'ın Misafir Odası",
		"silas_office": "Silas Crowe Ofisi (Hub)",
		"dock_pier": "4 No'lu Rıhtım (Suç Mahalli - Sabotaj Vinci)",
		"dock_warehouse": "2 No'lu Gümrük Hangarı (Sevkiyat & Boris)",
		"dock_office": "Liman İdare Ofisi (Morris)",
		"dock_saloon": "Gizli Kumarhane & Saloon (Corley)",
		"captain_cabin": "SS Mary Kaptan Kamarası (Vance)",
		"opera_foyer": "Kraliyet Operası Fuayesi (Giriş & Henderson)",
		"opera_auditorium": "Tiyatro Salonu (1812 Uvertürü & Sahne)",
		"royal_box": "Kraliyet Locası (Suç Mahalli - Reeve & Sterling)",
		"backstage": "Sahne Arkası (Kulis & Finch & Elena)",
		"prop_room": "Aksesuar Atölyesi (Barut Topu & Patch)",
		"light_bridge": "Işık Köprüsü (Spotlar & Kovan)",
		"opera_roof": "Opera Çatısı (Tüfek & Kaçış Merdiveni)"
	}
	var room_names_en = {
		"main_hall": "Main Hall (Entrance)",
		"study": "Study (Crime Scene - Single Entry)",
		"library": "Library",
		"dining_room": "Grand Dining Room",
		"kitchen": "Kitchen (Cul-de-sac)",
		"billiard_room": "Billiard Room (Cul-de-sac)",
		"upper_floor": "Upper Floor (Bedrooms Hallway)",
		"harlow_bedroom": "Harlow's Bedroom",
		"julian_room": "Julian's Bedroom",
		"pike_room": "Pike's Guest Room",
		"silas_office": "Silas Crowe's Office (Hub)",
		"dock_pier": "Pier 4 (Crime Scene - Sabotaged Crane)",
		"dock_warehouse": "Warehouse #2 (Cargo & Boris)",
		"dock_office": "Dockmaster Office (Morris)",
		"dock_saloon": "Secret Saloon & Gambling Den (Corley)",
		"captain_cabin": "SS Mary Captain's Cabin (Vance)",
		"opera_foyer": "Royal Opera Foyer (Grand Entrance & Henderson)",
		"opera_auditorium": "Auditorium Hall (1812 Overture & Stage)",
		"royal_box": "Royal Box (Crime Scene - Reeve & Sterling)",
		"backstage": "Backstage (Wings & Finch & Elena)",
		"prop_room": "Prop Room (Stage Cannon & Patch)",
		"light_bridge": "Light Bridge (Spotlights & Casing)",
		"opera_roof": "Opera Roof (Rifle & Fire Escape)"
	}
	var r_dict = room_names_en if is_en else room_names_tr
	current_room_label.add_theme_font_size_override("font_size", fs["title"])
	current_room_label.text = ("Current Location: " if is_en else "Mevcut Konumunuz: ") + r_dict.get(cur_room, cur_room)

	# Reset all panel modulates
	for child in upper_floor_grid.get_children():
		if child is Panel:
			child.self_modulate = Color(1, 1, 1, 1)
	for child in ground_floor_grid.get_children():
		if child is Panel:
			child.self_modulate = Color(1, 1, 1, 1)

	var active_panel: Panel = null

	if GameState.current_case_id == "case02":
		upper_floor_grid.visible = false
		if ground_floor_label:
			ground_floor_label.text = "▲ Kargo Gemisi (Ortadan) | Gümrük İdaresi ◀──▶ Sisli Rıhtım ◀──▶ Liman Ambarı ◀──▶ Tuzlu Çapa" if not is_en else "▲ Cargo Ship (Center) | Customs Office ◀──▶ Foggy Pier ◀──▶ Port Warehouse ◀──▶ Salty Anchor"
		
		# Set dock layout labels:
		# Gümrük İdaresi (sol) <-> Sisli Rıhtım (orta: ▲ Kargo Gemisi) <-> Liman Ambarı (sağ) <-> Tuzlu Çapa
		var p_study_lbl = ground_floor_grid.get_node_or_null("RoomStudy/Lbl")
		if p_study_lbl:
			p_study_lbl.text = "Kargo Gemisi\n[Vance] ▼" if not is_en else "Cargo Ship\n[Vance] ▼"
		var p_kitch_lbl = ground_floor_grid.get_node_or_null("RoomKitchen/Lbl")
		if p_kitch_lbl:
			p_kitch_lbl.text = ""
		var p_kitch_panel = ground_floor_grid.get_node_or_null("RoomKitchen")
		if p_kitch_panel:
			p_kitch_panel.modulate.a = 0.0
		var p_dining_lbl = ground_floor_grid.get_node_or_null("RoomDining/Lbl")
		if p_dining_lbl:
			p_dining_lbl.text = "Gümrük İdaresi\n[Morris] ▶" if not is_en else "Customs Office\n[Morris] ▶"
		var p_hall_lbl = ground_floor_grid.get_node_or_null("RoomHall/Lbl")
		if p_hall_lbl:
			p_hall_lbl.text = "Sisli Rıhtım [Suç]\n◀ İdare | ▲ Gemi | Ambar ▶" if not is_en else "Foggy Pier [Crime]\n◀ Office | ▲ Ship | Whs ▶"
		var p_lib_lbl = ground_floor_grid.get_node_or_null("RoomLibrary/Lbl")
		if p_lib_lbl:
			p_lib_lbl.text = "Liman Ambarı\n◀ Rıhtım | [Boris] Çapa ▶" if not is_en else "Port Warehouse\n◀ Pier | [Boris] Saloon ▶"
		var p_bill_lbl = ground_floor_grid.get_node_or_null("RoomBilliard/Lbl")
		if p_bill_lbl:
			p_bill_lbl.text = "Tuzlu Çapa\n[Corley] ◀" if not is_en else "Salty Anchor\n[Corley] ◀"

		match cur_room:
			"captain_cabin": active_panel = ground_floor_grid.get_node_or_null("RoomStudy")
			"dock_office": active_panel = ground_floor_grid.get_node_or_null("RoomDining")
			"dock_pier": active_panel = ground_floor_grid.get_node_or_null("RoomHall")
			"dock_warehouse": active_panel = ground_floor_grid.get_node_or_null("RoomLibrary")
			"dock_saloon": active_panel = ground_floor_grid.get_node_or_null("RoomBilliard")
	elif GameState.current_case_id == "case03":
		upper_floor_grid.visible = true
		if upper_floor_label:
			upper_floor_label.text = "▲ ÇATI & IŞIK KATMANI: Işık Köprüsü ◀──▶ Opera Çatısı" if not is_en else "▲ ROOF & LIGHT LEVEL: Light Bridge ◀──▶ Opera Roof"
		if ground_floor_label:
			ground_floor_label.text = "▼ KRALİYET OPERASI: Loca [Suç] ◀── Fuaye ──▶ Salon | Kulis ◀──▶ Atölye" if not is_en else "▼ ROYAL OPERA: Royal Box [Crime] ◀── Foyer ──▶ Hall | Backstage ◀──▶ Props"

		var p_julian = upper_floor_grid.get_node_or_null("RoomJulian")
		var p_julian_lbl = upper_floor_grid.get_node_or_null("RoomJulian/Lbl")
		if p_julian_lbl:
			p_julian_lbl.text = "Opera Çatısı\n[Tüfek & Kaçış]" if not is_en else "Opera Roof\n[Rifle & Escape]"
		if p_julian: p_julian.modulate.a = 1.0

		var p_harlow = upper_floor_grid.get_node_or_null("RoomHarlow")
		var p_harlow_lbl = upper_floor_grid.get_node_or_null("RoomHarlow/Lbl")
		if p_harlow_lbl:
			p_harlow_lbl.text = "Işık Köprüsü\n[Spotlar & Kovan]" if not is_en else "Light Bridge\n[Spotlights & Casing]"
		if p_harlow: p_harlow.modulate.a = 1.0

		var p_pike = upper_floor_grid.get_node_or_null("RoomPike")
		if p_pike: p_pike.modulate.a = 0.0
		var p_uf = upper_floor_grid.get_node_or_null("RoomUpperFloor")
		if p_uf: p_uf.modulate.a = 0.0

		var p_kitch_panel = ground_floor_grid.get_node_or_null("RoomKitchen")
		if p_kitch_panel: p_kitch_panel.modulate.a = 0.0

		var p_study_lbl = ground_floor_grid.get_node_or_null("RoomStudy/Lbl")
		if p_study_lbl:
			p_study_lbl.text = "Kraliyet Locası [Suç]\n[Reeve & Saat]" if not is_en else "Royal Box [Crime]\n[Reeve & Watch]"

		var p_dining_lbl = ground_floor_grid.get_node_or_null("RoomDining/Lbl")
		if p_dining_lbl:
			p_dining_lbl.text = "Aksesuar Atölyesi\n[Barut Topu] ▶" if not is_en else "Prop Room\n[Stage Cannon] ▶"

		var p_hall_lbl = ground_floor_grid.get_node_or_null("RoomHall/Lbl")
		if p_hall_lbl:
			p_hall_lbl.text = "Sahne Arkası (Kulis)\n◀ Atölye | ▲ Köprü | Fuaye ▶" if not is_en else "Backstage\n◀ Props | ▲ Bridge | Foyer ▶"

		var p_lib_lbl = ground_floor_grid.get_node_or_null("RoomLibrary/Lbl")
		if p_lib_lbl:
			p_lib_lbl.text = "Kraliyet Fuayesi\n◀ Kulis | ▲ Loca | Salon ▶" if not is_en else "Royal Foyer\n◀ Backstage | ▲ Box | Hall ▶"

		var p_bill_lbl = ground_floor_grid.get_node_or_null("RoomBilliard/Lbl")
		if p_bill_lbl:
			p_bill_lbl.text = "Tiyatro Salonu\n◀ Fuaye (Uvertür)" if not is_en else "Auditorium Hall\n◀ Foyer (Overture)"

		match cur_room:
			"opera_roof": active_panel = upper_floor_grid.get_node_or_null("RoomJulian")
			"light_bridge": active_panel = upper_floor_grid.get_node_or_null("RoomHarlow")
			"royal_box": active_panel = ground_floor_grid.get_node_or_null("RoomStudy")
			"prop_room": active_panel = ground_floor_grid.get_node_or_null("RoomDining")
			"backstage": active_panel = ground_floor_grid.get_node_or_null("RoomHall")
			"opera_foyer": active_panel = ground_floor_grid.get_node_or_null("RoomLibrary")
			"opera_auditorium": active_panel = ground_floor_grid.get_node_or_null("RoomBilliard")
	else:
		upper_floor_grid.visible = true
		if upper_floor_label:
			upper_floor_label.text = "▲ ÜST KAT" if not is_en else "▲ UPPER FLOOR"
		var p_pike_rst = upper_floor_grid.get_node_or_null("RoomPike")
		if p_pike_rst: p_pike_rst.modulate.a = 1.0
		var p_uf_rst = upper_floor_grid.get_node_or_null("RoomUpperFloor")
		if p_uf_rst: p_uf_rst.modulate.a = 1.0
		if ground_floor_label:
			ground_floor_label.text = "▼ ZEMİN KAT (Mutfak ◀──▶ Yemek ◀──▶ Hol ◀──▶ Kütüphane ◀──▶ Bilardo)"
		var p_kitch_panel = ground_floor_grid.get_node_or_null("RoomKitchen")
		if p_kitch_panel:
			p_kitch_panel.modulate.a = 1.0
		var p_study_lbl = ground_floor_grid.get_node_or_null("RoomStudy/Lbl")
		if p_study_lbl:
			p_study_lbl.text = "Çalışma [Suç]\n▲ Tek Giriş: Hol"
		var p_kitch_lbl = ground_floor_grid.get_node_or_null("RoomKitchen/Lbl")
		if p_kitch_lbl:
			p_kitch_lbl.text = "Mutfak\n[E06 Reçete] ▶"
		var p_dining_lbl = ground_floor_grid.get_node_or_null("RoomDining/Lbl")
		if p_dining_lbl:
			p_dining_lbl.text = "Yemek Odası\n◀ Mutfak | Hol ▶"
		var p_hall_lbl = ground_floor_grid.get_node_or_null("RoomHall/Lbl")
		if p_hall_lbl:
			p_hall_lbl.text = "Ana Hol\n◀ Yemek | ▲ Çalışma | Ktp ▶"
		var p_lib_lbl = ground_floor_grid.get_node_or_null("RoomLibrary/Lbl")
		if p_lib_lbl:
			p_lib_lbl.text = "Kütüphane\n◀ Hol | Bilardo ▶"
		var p_bill_lbl = ground_floor_grid.get_node_or_null("RoomBilliard/Lbl")
		if p_bill_lbl:
			p_bill_lbl.text = "Bilardo Odası\n◀ (Çıkmaz)"
		match cur_room:
			"kitchen": active_panel = ground_floor_grid.get_node_or_null("RoomKitchen")
			"dining_room": active_panel = ground_floor_grid.get_node_or_null("RoomDining")
			"main_hall": active_panel = ground_floor_grid.get_node_or_null("RoomHall")
			"study": active_panel = ground_floor_grid.get_node_or_null("RoomStudy")
			"library": active_panel = ground_floor_grid.get_node_or_null("RoomLibrary")
			"billiard_room": active_panel = ground_floor_grid.get_node_or_null("RoomBilliard")
			"upper_floor": active_panel = upper_floor_grid.get_node_or_null("RoomUpperFloor")
			"harlow_bedroom": active_panel = upper_floor_grid.get_node_or_null("RoomHarlow")
			"julian_room": active_panel = upper_floor_grid.get_node_or_null("RoomJulian")
			"pike_room": active_panel = upper_floor_grid.get_node_or_null("RoomPike")

	if active_panel:
		active_panel.self_modulate = Color(0.3, 0.7, 1.0, 1.0)
