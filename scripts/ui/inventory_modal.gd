extends Control

## Inventory Modal ("Çanta")
## Displays collected clues and inventory items (keys, documents) in a clean grid with inspection details.
## Bounds are strictly kept within 480x270 with >= 12 px safe margins.

const NoirPalette = preload("res://scripts/core/noir_palette.gd")

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

const SPECIAL_ITEMS = {
	"key_drawer": {
		"id": "key_drawer",
		"ad": "Çalışma Masası Çekmece Anahtarı",
		"aciklama": "Harlow'un yatak odasındaki komodinde bulunan küçük pirinç anahtar. Çalışma masasındaki kilitli çekmeceyi açar.",
		"tur": "Anahtar",
		"icon": "res://assets/sprites/clues/clue_e15_brass_key.png"
	},
	"key_chest": {
		"id": "key_chest",
		"ad": "Antika Sandık Anahtarı",
		"aciklama": "Bilardo odasındaki içki arabasının kül tablasına gizlenmiş süslü demir anahtar. Julian'ın odasındaki seyahat sandığını açar.",
		"tur": "Anahtar",
		"icon": "res://assets/sprites/clues/clue_e15_brass_key.png"
	},
	"key_ring": {
		"id": "key_ring",
		"ad": "Konak Anahtarlığı",
		"aciklama": "Kâhya Margaret'tan alınan misafir odaları anahtarlığı. Pike'ın kilitli odasını açar.",
		"tur": "Anahtar Bağı",
		"icon": "res://assets/sprites/clues/clue_e15_brass_key.png"
	}
}

@onready var modal_panel: Panel = $ModalPanel
@onready var grid_container: GridContainer = $ModalPanel/GridScroll/ItemGrid
@onready var empty_label: Label = $ModalPanel/EmptyLabel
@onready var close_btn: Button = $ModalPanel/CloseBtn

# Details Panel
@onready var detail_icon: TextureRect = $ModalPanel/DetailPanel/DetailIcon
@onready var detail_name: Label = $ModalPanel/DetailPanel/DetailName
@onready var detail_type: Label = $ModalPanel/DetailPanel/DetailType
@onready var detail_desc: Label = $ModalPanel/DetailPanel/DetailDesc

var selected_item_id: String = ""

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_inventory)
	EventBus.inventory_toggled.connect(_on_inventory_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I or event.keycode == KEY_B:
			toggle_inventory()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and visible:
			close_inventory()
			get_viewport().set_input_as_handled()

func _on_inventory_toggled(is_open: bool) -> void:
	if is_open:
		if not visible:
			open_inventory()
		else:
			close_inventory()
	else:
		if visible:
			close_inventory()

func toggle_inventory() -> void:
	if visible:
		close_inventory()
	else:
		open_inventory()

func open_inventory() -> void:
	if visible:
		return
	visible = true
	GameState.can_player_move = false
	_refresh_items()

func close_inventory() -> void:
	if not visible:
		return
	visible = false
	var tree = get_tree()
	var has_other_modal = false
	if tree:
		for modal_name in ["Notebook", "Interrogation", "AccusationModal", "PauseMenu", "MainMenu", "InspectView"]:
			var m = tree.root.find_child(modal_name, true, false)
			if m and m.visible:
				has_other_modal = true
				break
	if not has_other_modal and not CutsceneManager.is_cutscene_active:
		GameState.can_player_move = true
	EventBus.inventory_toggled.emit(false)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var gp = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(gp):
		var img = Image.load_from_file(gp)
		if img:
			return ImageTexture.create_from_image(img)
	return null

func _refresh_items() -> void:
	for c in grid_container.get_children():
		c.queue_free()

	var all_items: Array[Dictionary] = []

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	if close_btn:
		close_btn.text = "Close [ESC]" if is_en else "Kapat [ESC]"

	# 1. Special Keys / Items
	for item_id in GameState.inventory_items:
		if SPECIAL_ITEMS.has(item_id):
			var itm = SPECIAL_ITEMS[item_id].duplicate()
			if is_en:
				if item_id == "key_drawer":
					itm["ad"] = "Desk Drawer Key"
					itm["aciklama"] = "A small brass key from the nightstand in Harlow's bedroom. Unlocks the locked drawer of the study desk."
					itm["tur"] = "Key"
				elif item_id == "key_chest":
					itm["ad"] = "Antique Chest Key"
					itm["aciklama"] = "An ornate iron key hidden in the billiard room bar cart ashtray. Unlocks the travel trunk in Julian's room."
					itm["tur"] = "Key"
				elif item_id == "key_ring":
					itm["ad"] = "Manor Keyring"
					itm["aciklama"] = "Guest room keyring obtained from Housekeeper Margaret. Unlocks Pike's locked guest room."
					itm["tur"] = "Key Ring"
			all_items.append(itm)
		elif item_id == "night_pass":
			all_items.append({
				"id": "night_pass",
				"ad": "Sealed Night Permit" if is_en else "Mühürlü Gece İzin Belgesi",
				"aciklama": "Official pass bearing the harbor master's seal to enter restricted dock areas." if is_en else "Arthur Morris'in imzasını ve liman mührünü taşıyan resmi gece izin belgesi.",
				"tur": "Permit" if is_en else "İzin Belgesi",
				"icon": "res://assets/sprites/clues/clue_e02_half_written_letter.png"
			})

	# 2. Discovered Evidence
	for ev_id in GameState.discovered_evidence:
		var ev_data = GameState.get_evidence_data(ev_id)
		if not ev_data.is_empty():
			var icon_p = CLUE_ICONS.get(ev_id, "res://assets/sprites/clues/clue_e01_pocket_watch.png")
			all_items.append({
				"id": ev_id,
				"ad": ev_data.get("ad", "Clue" if is_en else "Kanıt"),
				"aciklama": ev_data.get("aciklama", ""),
				"tur": ("Clue (" if is_en else "Kanıt (") + ev_id + ")",
				"icon": icon_p
			})

	if all_items.is_empty():
		empty_label.text = "No items or clues in your bag yet." if is_en else "Çantada henüz kanıt veya eşya yok."
		empty_label.visible = true
		_clear_details()
		return

	empty_label.visible = false

	for item in all_items:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(36, 36)
		btn.focus_mode = Control.FOCUS_NONE
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.expand_icon = true

		var tex = _load_tex(item["icon"])
		if tex:
			btn.icon = tex
		else:
			btn.text = item["id"]

		# Instead of massive system tooltip popup, mouse hover dynamically previews item in the noir DetailPanel
		btn.mouse_entered.connect(func(): _select_item(item))
		btn.pressed.connect(func(): _select_item(item))
		grid_container.add_child(btn)

	# Auto-select first item
	_select_item(all_items[0])

func _select_item(item: Dictionary) -> void:
	selected_item_id = item.get("id", "")
	detail_name.text = item.get("ad", "")
	detail_type.text = item.get("tur", "")
	detail_desc.text = item.get("aciklama", "")

	var tex = _load_tex(item.get("icon", ""))
	if tex:
		detail_icon.texture = tex
		detail_icon.visible = true
	else:
		detail_icon.visible = false

func _clear_details() -> void:
	selected_item_id = ""
	detail_name.text = ""
	detail_type.text = ""
	detail_desc.text = ""
	detail_icon.texture = null
	detail_icon.visible = false
