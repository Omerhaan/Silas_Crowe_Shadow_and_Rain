extends Control

## Close-up Inspect View for discovered clues.
## Displays pixel visual, detailed description, and special interactive actions (e.g. watch flip).

@onready var modal_panel: Panel = $ModalPanel
@onready var title_label: Label = $ModalPanel/TitleLabel
@onready var visual_rect: ColorRect = $ModalPanel/VisualBox/VisualRect
@onready var visual_texture: TextureRect = $ModalPanel/VisualBox/VisualTexture
@onready var visual_label: Label = $ModalPanel/VisualBox/VisualLabel
@onready var dialogue_box: Control = $ModalPanel/DialogueBox
@onready var special_btn: Button = $ModalPanel/SpecialActionBtn
@onready var close_btn: Button = $ModalPanel/CloseBtn

var current_evidence_id: String = ""
var is_flipped: bool = false

var inspect_textures = {
	"E01_front": "res://assets/sprites/inspect/inspect_e01_pocket_watch.png",
	"E01_back": "res://assets/sprites/story/story_pocket_watch_back.png",
	"E02": "res://assets/sprites/inspect/inspect_e15_keyhole_key.png",
	"E03": "res://assets/sprites/clues/clue_e02_half_written_letter.png",
	"E04": "res://assets/sprites/inspect/inspect_e04_brandy_poison.png",
	"E05": "res://assets/sprites/inspect/inspect_e05_desk_drawer.png",
	"E06": "res://assets/sprites/clues/clue_e06_prescription.png",
	"E07": "res://assets/sprites/inspect/inspect_e07_threat_letters.png",
	"E08": "res://assets/sprites/inspect/inspect_e03_burned_candle.png",
	"E09": "res://assets/sprites/inspect/inspect_e09_cold_fireplace.png",
	"E10": "res://assets/sprites/inspect/inspect_e09_cold_fireplace.png",
	"E11": "res://assets/sprites/inspect/inspect_e11_billiard_corner.png",
	"E12": "res://assets/sprites/clues/clue_e13_debt_letter.png",
	"E13": "res://assets/sprites/clues/clue_e14_typewriter_ribbon.png",
	"E14": "res://assets/sprites/inspect/inspect_e08_wastebasket.png",
	"E15": "res://assets/sprites/clues/icon_muddy_bootprint.png",
	"E16": "res://assets/sprites/inspect/inspect_e16_torn_photo.png",
	"E17": "res://assets/sprites/inspect/inspect_e17_phone_off_hook.png",
	# Case 2 Inspect Textures
	"E201": "res://assets/sprites/inspect/inspect_e201_crane_cable.png",
	"E202": "res://assets/sprites/inspect/inspect_e202_military_crate.png",
	"E203": "res://assets/sprites/inspect/inspect_e203_bloody_lantern.png",
	"E204": "res://assets/sprites/inspect/inspect_e204_acid_coat.png",
	"E205": "res://assets/sprites/inspect/inspect_e205_radio_logbook.png",
	"E206": "res://assets/sprites/inspect/inspect_e206_tide_chart.png",
	"E207": "res://assets/sprites/inspect/inspect_e207_typewriter_note.png",
	"E208": "res://assets/sprites/inspect/inspect_e208_k3_watch.png",
	"E208_front": "res://assets/sprites/inspect/inspect_e208_k3_watch.png",
	"E208_back": "res://assets/sprites/inspect/inspect_e208_k3_watch_back.png",
	"E209": "res://assets/sprites/inspect/inspect_e209_night_pass.png",
	"E210": "res://assets/sprites/inspect/inspect_e210_bribe_ledger.png",
	"E211": "res://assets/sprites/inspect/inspect_e205_radio_logbook.png",
	"E301": "res://cases/case03/assets/clues/clue_e301_k4_rifle_preview.png",
	"E302": "res://cases/case03/assets/clues/clue_e302_spent_casing_preview.png",
	"E303": "res://assets/sprites/inspect/inspect_e205_radio_logbook.png",
	"E304": "res://assets/sprites/clues/icon_door_lock.png",
	"E305": "res://assets/sprites/inspect/inspect_e15_keyhole_key.png",
	"E306": "res://cases/case03/assets/clues/clue_e306_marked_score_preview.png",
	"E307": "res://assets/sprites/clues/clue_e03_burned_candle.png",
	"E308": "res://cases/case03/assets/clues/clue_e308_typewriter_note_preview.png",
	"E309": "res://cases/case03/assets/clues/clue_e309_k4_watch_preview.png",
	"E309_front": "res://cases/case03/assets/clues/clue_e309_k4_watch_preview.png",
	"E309_back": "res://cases/case03/assets/clues/clue_e309_k4_watch_preview.png",
	"E310": "res://assets/sprites/clues/icon_muddy_bootprint.png"
}

var custom_title: String = ""
var custom_desc: String = ""
var custom_tex_path: String = ""
var custom_alt_tex_path: String = ""
var custom_alt_desc: String = ""
var is_custom_inspect: bool = false
var inspect_cooldown: float = 0.0

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close_pressed)
	special_btn.pressed.connect(_on_special_action_pressed)
	EventBus.inspect_evidence_requested.connect(open_inspect)
	EventBus.inspect_custom_requested.connect(open_custom_inspect)
	if dialogue_box:
		dialogue_box.advance_requested.connect(close_inspect)
	if EventBus.has_signal("font_scale_changed"):
		EventBus.font_scale_changed.connect(apply_font_scale)
	apply_font_scale(GameState.get_font_scale())
	_update_close_btn()

func _update_close_btn() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	close_btn.text = "Close [E]" if is_en else "Kapat [E]"

func apply_font_scale(scale: String) -> void:
	var font_title = 8
	var font_btn = 7
	if scale == "small":
		font_title = 7
		font_btn = 6
	elif scale == "large":
		font_title = 10
		font_btn = 8

	if title_label:
		title_label.add_theme_font_size_override("font_size", font_title)
	if close_btn:
		close_btn.add_theme_font_size_override("font_size", font_btn)
	if special_btn:
		special_btn.add_theme_font_size_override("font_size", font_btn)

func _process(delta: float) -> void:
	if visible and inspect_cooldown > 0.0:
		inspect_cooldown -= delta

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			close_inspect()
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_E or event.is_action_pressed("interact")) and inspect_cooldown <= 0.0:
			close_inspect()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_SPACE and inspect_cooldown <= 0.0:
			if dialogue_box:
				dialogue_box.advance()
			else:
				close_inspect()
			get_viewport().set_input_as_handled()

func open_custom_inspect(title: String, desc: String, texture_path: String, alt_texture_path: String = "", alt_desc: String = "") -> void:
	is_custom_inspect = true
	inspect_cooldown = 0.25
	is_flipped = false
	current_evidence_id = ""
	custom_title = title
	custom_desc = desc
	custom_tex_path = texture_path
	custom_alt_tex_path = alt_texture_path
	custom_alt_desc = alt_desc

	GameState.can_player_move = false
	visible = true
	title_label.text = title
	dialogue_box.set_dialogue("INNER_VOICE", desc)

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	if custom_alt_tex_path != "":
		special_btn.visible = true
		special_btn.text = "View Back" if is_en else "Arka Yüzü Gör"
	else:
		special_btn.visible = false

	_display_texture_path(custom_tex_path)

func open_inspect(evidence_id: String) -> void:
	_update_close_btn()
	is_custom_inspect = false
	inspect_cooldown = 0.25
	current_evidence_id = evidence_id
	is_flipped = false
	var ev_data = GameState.get_evidence_data(evidence_id)
	if ev_data.is_empty():
		return

	GameState.can_player_move = false
	visible = true
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	title_label.text = ev_data.get("ad", "Evidence Inspection" if is_en else "Kanıt İnceleme")
	dialogue_box.set_dialogue("INNER_VOICE", ev_data.get("aciklama", ""))
	_update_visual(false)

func _update_visual(flipped: bool) -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	special_btn.visible = false
	var tex_key = current_evidence_id
	if current_evidence_id == "E01":
		special_btn.visible = true
		if not flipped:
			special_btn.text = "Open Back Cover" if is_en else "Arka Kapağı Aç"
			tex_key = "E01_front"
		else:
			special_btn.text = "Show Front" if is_en else "Ön Yüzü Göster"
			tex_key = "E01_back"
			var back_desc = "Military engraving on the back: 'K-5'. Silas pulls out his own pocket watch: 'K-1'. Both are officer watches from the same unit!" if is_en else "Arka kapakta askerî oyma: 'K-5'. Silas kendi cebindeki saati çıkarıp bakar: 'K-1'. İkisi de aynı birliğin subay saatleri!"
			dialogue_box.set_dialogue("INNER_VOICE", back_desc)
	elif current_evidence_id == "E208":
		special_btn.visible = true
		if not flipped:
			special_btn.text = "Open Back Lid" if is_en else "Arka Kapağı Aç"
			tex_key = "E208_front"
		else:
			special_btn.text = "Show Dial" if is_en else "Ön Yüzü Göster"
			tex_key = "E208_back"
			var back_desc = "Military engraving on the back: 'K-3 - Signals & Radio'. Silas holds his own K-1 watch: 'Teddy was there that night too...'" if is_en else "Arka kapakta askerî oyma: 'K-3 - Sinyal ve Muhabere'. Silas cebindeki K-1 saatine bakar: 'Teddy de o gece oradaydı...'"
			dialogue_box.set_dialogue("INNER_VOICE", back_desc)
	elif current_evidence_id == "E309":
		special_btn.visible = true
		if not flipped:
			special_btn.text = "Open Back Lid" if is_en else "Arka Kapağı Aç"
			tex_key = "E309_front"
		else:
			special_btn.text = "Show Dial" if is_en else "Ön Yüzü Göster"
			tex_key = "E309_back"
			var back_desc = "Military engraving on the back: 'K-4 - Marksman'. Silas holds his own K-1 watch: 'Dalton Reeve... He covered our retreat that night...'" if is_en else "Arka kapakta askerî oyma: 'K-4 - Keskin Nişancı'. Silas kendi K-1 saatine bakar: 'Dalton Reeve... O gece geri çekilmemizi koruyan nişancıydı...'"
			dialogue_box.set_dialogue("INNER_VOICE", back_desc)
	elif current_evidence_id == "E16":
		special_btn.visible = true
		special_btn.text = "View Memory (Flashback)" if is_en else "Anıyı Gör (Flashback)"

	# Load texture if available
	var p = ""
	if inspect_textures.has(tex_key):
		var configured_path = inspect_textures[tex_key]
		if ResourceLoader.exists(configured_path) or FileAccess.file_exists(ProjectSettings.globalize_path(configured_path)):
			p = configured_path

	if p == "":
		var base_names = [
			"clue_%s" % tex_key.to_lower(),
			"inspect_%s" % tex_key.to_lower(),
			"clue_%s_bloody_lantern" % tex_key.to_lower(),
			"clue_%s_military_crate" % tex_key.to_lower(),
			"clue_%s_acid_coat" % tex_key.to_lower(),
			"clue_%s_tide_chart" % tex_key.to_lower(),
			"clue_%s_night_pass" % tex_key.to_lower(),
			"clue_%s_bribe_ledger" % tex_key.to_lower(),
			"clue_%s_crane_cable" % tex_key.to_lower(),
			"clue_%s_radio_logbook" % tex_key.to_lower(),
			"clue_%s_typewriter_note" % tex_key.to_lower(),
			"clue_%s_k3_watch" % tex_key.to_lower(),
			"clue_%s_ships_logbook" % tex_key.to_lower(),
			"inspect_%s_bloody_lantern" % tex_key.to_lower(),
			"inspect_%s_military_crate" % tex_key.to_lower(),
			"inspect_%s_acid_coat" % tex_key.to_lower(),
			"inspect_%s_tide_chart" % tex_key.to_lower(),
			"inspect_%s_night_pass" % tex_key.to_lower(),
			"inspect_%s_bribe_ledger" % tex_key.to_lower(),
			"inspect_%s_crane_cable" % tex_key.to_lower(),
			"inspect_%s_radio_logbook" % tex_key.to_lower(),
			"inspect_%s_typewriter_note" % tex_key.to_lower(),
			"inspect_%s_k3_watch" % tex_key.to_lower(),
			"inspect_%s_ships_logbook" % tex_key.to_lower()
		]
		var dirs = [
			"res://cases/case02/assets/clues/",
			"res://assets/sprites/inspect/",
			"res://assets/sprites/clues/"
		]
		for d in dirs:
			for b in base_names:
				for ext in [".png", ".jpg", ".jpeg"]:
					var c = d + b + ext
					if ResourceLoader.exists(c) or FileAccess.file_exists(ProjectSettings.globalize_path(c)):
						p = c
						break
				if p != "":
					break
			if p != "":
				break
	_display_texture_path(p)

func _display_texture_path(p: String) -> void:
	var tex: Texture2D = null
	if p != "":
		if ResourceLoader.exists(p):
			tex = load(p)
		else:
			var gp = ProjectSettings.globalize_path(p)
			if FileAccess.file_exists(gp):
				var img = Image.load_from_file(gp)
				if img:
					tex = ImageTexture.create_from_image(img)

	if tex and visual_texture:
		visual_texture.texture = tex
		visual_texture.visible = true
		visual_label.visible = false
	else:
		if visual_texture:
			visual_texture.visible = false
		visual_label.visible = true
		visual_label.text = current_evidence_id if current_evidence_id != "" else custom_title

func _on_special_action_pressed() -> void:
	if is_custom_inspect:
		is_flipped = !is_flipped
		if is_flipped:
			special_btn.text = "Ön Yüzü Göster"
			dialogue_box.set_dialogue("INNER_VOICE", custom_alt_desc if custom_alt_desc != "" else custom_desc)
			_display_texture_path(custom_alt_tex_path)
		else:
			special_btn.text = "Arka Yüzü Gör"
			dialogue_box.set_dialogue("INNER_VOICE", custom_desc)
			_display_texture_path(custom_tex_path)
		return

	if current_evidence_id == "E01":
		is_flipped = !is_flipped
		_update_visual(is_flipped)
		if is_flipped:
			EventBus.inner_voice_requested.emit("\"Aynı model. Aynı oyma. Bunu nereden biliyorum?\"")
	elif current_evidence_id == "E208":
		is_flipped = !is_flipped
		_update_visual(is_flipped)
		if is_flipped:
			EventBus.inner_voice_requested.emit("\"K-3... Teddy de Kuzey Birimi'ndeydi. Sinyalleri o kesmişti.\"")
	elif current_evidence_id == "E16":
		close_inspect()
		EventBus.flashback_requested.emit("FB01")

func _on_close_pressed() -> void:
	close_inspect()

func close_inspect() -> void:
	visible = false
	inspect_cooldown = 0.0
	var tree = get_tree()
	var has_other_modal = false
	if tree:
		for modal_name in ["Notebook", "Interrogation", "AccusationModal", "PauseMenu", "MainMenu"]:
			var m = tree.root.find_child(modal_name, true, false)
			if m and m.visible:
				has_other_modal = true
				break
	if not has_other_modal and not CutsceneManager.is_cutscene_active:
		GameState.can_player_move = true
