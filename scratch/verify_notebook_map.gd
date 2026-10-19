extends Node

func _ready() -> void:
	print("--- TESTING NOTEBOOK MAP TAB FOR CASE 03 ---")
	GameState.current_case_id = "case03"
	GameState.current_room_id = "royal_box"

	var nb_scn = load("res://scenes/ui/notebook.tscn")
	var nb = nb_scn.instantiate()
	add_child(nb)

	nb._refresh_map_tab()
	print("Current location text: ", nb.current_room_label.text)
	print("UpperFloorGrid visible? ", nb.upper_floor_grid.visible)
	print("Notebook Map tab refreshed cleanly!")

	# Also test changing room to opera_roof
	GameState.current_room_id = "opera_roof"
	nb._refresh_map_tab()
	print("New location text: ", nb.current_room_label.text)

	get_tree().quit(0)
