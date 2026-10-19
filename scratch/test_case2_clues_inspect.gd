extends SceneTree

func _init() -> void:
	print("--- TESTING CASE 2 INSPECT VIEW ON ALL 11 CLUES ---")
	var gs = preload("res://scripts/autoload/game_state.gd").new()
	# Just load main and inspect view
	var main_scene = load("res://scenes/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	
	main._on_case_selected("case02")
	
	var inspect_view = main.find_child("InspectView", true, false)
	if not inspect_view:
		print("ERROR: InspectView not found!")
		quit(1)
		return
	
	var clues = ["E201", "E202", "E203", "E204", "E205", "E206", "E207", "E208", "E209", "E210", "E211"]
	for c in clues:
		var ev_data = GameState.get_evidence_data(c)
		print("\nTesting Clue: ", c, " -> ", ev_data.get("ad", "UNKNOWN"))
		inspect_view.open_evidence(c)
		print("  InspectView visible: ", inspect_view.visible)
		var title_lbl = inspect_view.find_child("ClueTitle", true, false)
		var desc_lbl = inspect_view.find_child("ClueDescription", true, false)
		var tex_rect = inspect_view.find_child("VisualTexture", true, false)
		print("  Title: ", title_lbl.text if title_lbl else "N/A")
		print("  Has Texture: ", tex_rect.texture != null if tex_rect else "N/A")
		if tex_rect and tex_rect.texture:
			print("  Texture path: ", tex_rect.texture.resource_path)
		inspect_view.close()
	
	print("\nALL 11 CASE 2 CLUES TESTED SUCCESSFULLY IN INSPECTVIEW!")
	quit(0)
