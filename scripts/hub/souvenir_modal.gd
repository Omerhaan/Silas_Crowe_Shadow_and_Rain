extends Control

## Souvenir Shelf Selection Modal (Hatıra Rafı).
## Allows selecting 1 souvenir from Case 1 to keep on the hub shelf.

@onready var close_btn: Button = $Panel/CloseBtn
@onready var desc_label: Label = $Panel/DescLabel
@onready var btn_item1: Button = $Panel/VBox/Item1Btn
@onready var btn_item2: Button = $Panel/VBox/Item2Btn
@onready var btn_item3: Button = $Panel/VBox/Item3Btn

var souvenirs_data: Array = []

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(func():
		visible = false
		GameState.can_player_move = true
	)
	_load_souvenirs_data()

func _load_souvenirs_data() -> void:
	var loaded = GameState._load_json_file("res://data/hub/souvenirs.json")
	if loaded is Array:
		souvenirs_data = loaded

func open_shelf() -> void:
	visible = true
	GameState.can_player_move = false

	if souvenirs_data.is_empty():
		_load_souvenirs_data()

	_refresh_ui()

func _refresh_ui() -> void:
	if not GameState.case_solved:
		desc_label.text = "Raf şu an boş. Bir vakayı tamamladığınızda buradan hatıraları rafa dizebilirsiniz."
		btn_item1.visible = false
		btn_item2.visible = false
		btn_item3.visible = false
		return

	var placed_count = 0
	for item in souvenirs_data:
		var item_id = item.get("id", "")
		var item_name = item.get("ad", "")
		if GameState.is_souvenir_placed(item_id) or GameState.is_souvenir_placed(item_name):
			placed_count += 1

	if placed_count == 0:
		desc_label.text = "Vaka 1 tamamlandı. Rafta sergilemek istediğiniz hatıraları seçin:"
	else:
		desc_label.text = "Raftaki Hatıralar (%d/3 yerleştirildi). İstediğinizi ekleyip kaldırabilirsiniz:" % placed_count

	_setup_button(btn_item1, 0)
	_setup_button(btn_item2, 1)
	_setup_button(btn_item3, 2)

func _setup_button(btn: Button, index: int) -> void:
	if index < souvenirs_data.size():
		var item = souvenirs_data[index]
		var item_id = item.get("id", "")
		var item_name = item.get("ad", "Hatıra %d" % (index + 1))
		var is_placed = GameState.is_souvenir_placed(item_id) or GameState.is_souvenir_placed(item_name)
		
		if is_placed:
			btn.text = "✓ [Rafta] %s (Kaldır)" % item_name
			btn.add_theme_color_override("font_color", Color(0.95, 0.85, 0.45, 1.0))
		else:
			btn.text = "+ [Boş] %s (Rafa Koy)" % item_name
			btn.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 1.0))
		
		btn.visible = true
		for conn in btn.pressed.get_connections():
			btn.pressed.disconnect(conn.callable)
		btn.pressed.connect(func(): _toggle_item(item))
	else:
		btn.visible = false

func _toggle_item(item: Dictionary) -> void:
	var item_id = item.get("id", "")
	var item_name = item.get("ad", "")
	var now_placed = GameState.toggle_souvenir(item_id, item_name)
	
	_refresh_ui()

	# Update shelf visual in office
	for office in get_tree().get_nodes_in_group("office_hub"):
		if office.has_method("update_souvenir_shelf"):
			office.update_souvenir_shelf()

	var ic_ses = ""
	if now_placed:
		ic_ses = item.get("ic_ses", "\"Bunu rafa yerleştiriyorum. Bu geceden geriye kalan küçük bir anı.\"")
	else:
		ic_ses = "\"Bunu raftan kaldırıp çekmeceye koydum.\""
	EventBus.inner_voice_requested.emit(ic_ses)
