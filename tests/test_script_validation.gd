extends Node

func _ready() -> void:
	print("=== SCANNING ALL SCRIPTS IN PROJECT FOR COMPILATION ERRORS ===")
	var scripts_to_check: Array[String] = [
		"res://scripts/main.gd",
		"res://scripts/autoload/game_state.gd",
		"res://scripts/autoload/event_bus.gd",
		"res://scripts/autoload/audio_manager.gd",
		"res://scripts/autoload/save_system.gd",
		"res://scripts/autoload/input_manager.gd",
		"res://scripts/autoload/localization_manager.gd",
		"res://scripts/autoload/asset_manager.gd",
		"res://scripts/autoload/cutscene_manager.gd",
		"res://scripts/hub/silas_office.gd",
		"res://scripts/hub/memory_wall.gd",
		"res://scripts/hub/souvenir_modal.gd",
		"res://scripts/entities/player.gd",
		"res://scripts/entities/character.gd",
		"res://scripts/entities/npc.gd",
		"res://scripts/entities/interactable.gd",
		"res://scripts/entities/door.gd",
		"res://scripts/cutscenes/story_cutscene.gd",
		"res://scripts/cutscenes/arrival_dialogue.gd",
		"res://scripts/cutscenes/confrontation_hale.gd",
		"res://scripts/cutscenes/second_call.gd",
		"res://scripts/cutscenes/flashback_fb01.gd",
		"res://scripts/ui/hud.gd",
		"res://scripts/ui/notebook.gd",
		"res://scripts/ui/inventory_modal.gd",
		"res://scripts/ui/pause_menu.gd",
		"res://scripts/ui/main_menu.gd",
		"res://scripts/ui/dialogue_box.gd",
		"res://scripts/ui/interrogation.gd",
		"res://scripts/ui/accusation_modal.gd",
		"res://scripts/ui/case_ending_modal.gd",
		"res://scripts/ui/case_select_modal.gd",
		"res://scripts/ui/safe_dial_modal.gd",
		"res://scripts/ui/crane_winch_modal.gd",
		"res://scripts/ui/tumbler_lock_modal.gd",
		"res://scripts/ui/light_range_modal.gd",
		"res://scripts/ui/inspect_view.gd",
		"res://scripts/ui/settings_modal.gd",
		"res://scripts/ui/phone_call_dialogue.gd",
		"res://scripts/ui/fade_transition.gd"
	]

	var fail_count: int = 0
	for path in scripts_to_check:
		var res = load(path)
		if res == null:
			printerr("FAILED TO LOAD / SCRIPT ERROR: ", path)
			fail_count += 1
		else:
			print("  [OK] ", path)

	print("=== VALIDATION FINISHED: ", scripts_to_check.size(), " SCRIPTS CHECKED, ", fail_count, " ERRORS ===")
	if fail_count > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
