extends Node

func _ready() -> void:
	print("--- TESTING USER FLOW IN MAIN.TSCN ---")
	var main_scn = load("res://scenes/main.tscn")
	var main = main_scn.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame

	print("Initial GameState.current_case_id: ", GameState.current_case_id)
	print("Initial CutsceneManager.is_cutscene_active: ", CutsceneManager.is_cutscene_active)
	print("Initial GameState.can_player_move: ", GameState.can_player_move)

	# Check MainMenu state
	var mm = main.get_node("UIOverlays/MainMenu")
	print("MainMenu visible: ", mm.visible)
	var cont_btn = mm.get_node("Panel/VBoxContainer/ContinueBtn")
	print("ContinueBtn disabled: ", cont_btn.disabled)

	# Simulate clicking ChapterSelect -> Case03
	print("\n--- User clicks ChapterSelect -> case03 ---")
	mm._on_case_modal_selected("case03")
	
	# Give it 0.5s
	await get_tree().create_timer(0.5).timeout
	print("After select case03:")
	print("  GameState.current_case_id: ", GameState.current_case_id)
	print("  CutsceneManager.is_cutscene_active: ", CutsceneManager.is_cutscene_active)
	print("  GameState.can_player_move: ", GameState.can_player_move)
	print("  Current room node: ", main.current_room_node.name if main.current_room_node else "null")
	print("  StoryCutscene visible: ", main.story_cutscene.visible)

	# If cutscene is running, simulate user skipping it with Space/Enter
	var max_steps = 10
	while main.story_cutscene.visible and max_steps > 0:
		print("  Skipping cutscene slide / cutscene...")
		main.story_cutscene._on_skip_pressed()
		await get_tree().create_timer(0.3).timeout
		max_steps -= 1

	print("\nAfter cutscenes finish:")
	print("  GameState.current_case_id: ", GameState.current_case_id)
	print("  CutsceneManager.is_cutscene_active: ", CutsceneManager.is_cutscene_active)
	print("  GameState.can_player_move: ", GameState.can_player_move)
	print("  Current room node: ", main.current_room_node.name if main.current_room_node else "null")
	print("  StoryCutscene visible: ", main.story_cutscene.visible)
	print("  Player position: ", main.player.global_position if main.player else "null")

	get_tree().quit(0)
