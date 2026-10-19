extends Node

## Save and Load system (saves discovered evidence, statements, deductions, current room, and multi-case progress).
const SAVE_PATH = "user://savegame.json"

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> bool:
	GameState.store_current_case_state()
	var save_dict = {
		"save_version": 2,
		"current_case_id": GameState.current_case_id,
		"current_room_id": GameState.current_room_id,
		"completed_cases": GameState.completed_cases,
		"case_registry": GameState.case_registry,
		"case_states": GameState.case_states,
		"case_state": GameState.case_states,
		"discovered_evidence": GameState.discovered_evidence,
		"collected_statements": GameState.collected_statements,
		"unlocked_deductions": GameState.unlocked_deductions,
		"inspected_objects": GameState.inspected_objects,
		"accusation_chances_left": GameState.accusation_chances_left,
		"inner_voice_count": GameState.inner_voice_count,
		"secret_drawers_opened": GameState.secret_drawers_opened,
		"case_solved": GameState.case_solved,
		"selected_souvenir": GameState.selected_souvenir,
		"selected_souvenirs": GameState.selected_souvenirs,
		"flags": GameState.flags,
		"memory_wall_items": GameState.memory_wall_items,
		"unlocked_achievements": GameState.unlocked_achievements,
		"inventory_items": GameState.inventory_items,
		"intro_seen": GameState.intro_seen
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(save_dict, "\t"))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json_str = file.get_as_text()
	var json = JSON.new()
	if json.parse(json_str) != OK:
		return false
	var data = json.data
	if data is Dictionary:
		var save_version = data.get("save_version", 1)
		GameState.current_case_id = data.get("current_case_id", "case01")
		GameState.completed_cases = Array(data.get("completed_cases", []), TYPE_STRING, "", null)
		if data.has("case_registry") and data["case_registry"] is Array:
			GameState.case_registry = data["case_registry"]

		var loaded_case_states = data.get("case_states", data.get("case_state", {}))
		if loaded_case_states is Dictionary and not loaded_case_states.is_empty():
			GameState.case_states = loaded_case_states.duplicate(true)
		else:
			GameState.case_states = {}

		if GameState.case_states.has(GameState.current_case_id):
			GameState.restore_case_state(GameState.current_case_id)
			if data.has("current_room_id"):
				GameState.current_room_id = data.get("current_room_id")
		else:
			GameState.discovered_evidence = Array(data.get("discovered_evidence", []), TYPE_STRING, "", null)
			GameState.collected_statements = data.get("collected_statements", {})
			GameState.unlocked_deductions = Array(data.get("unlocked_deductions", []), TYPE_STRING, "", null)
			GameState.inspected_objects = Array(data.get("inspected_objects", []), TYPE_STRING, "", null)
			GameState.accusation_chances_left = data.get("accusation_chances_left", 3)
			GameState.case_solved = data.get("case_solved", false)
			GameState.current_room_id = data.get("current_room_id", "main_hall")
			GameState.store_current_case_state()

		GameState.inner_voice_count = data.get("inner_voice_count", 0)
		GameState.secret_drawers_opened = data.get("secret_drawers_opened", 0)
		GameState.selected_souvenir = data.get("selected_souvenir", "")
		if data.has("selected_souvenirs") and data["selected_souvenirs"] is Array:
			GameState.selected_souvenirs = Array(data["selected_souvenirs"], TYPE_STRING, "", null)
		elif GameState.selected_souvenir != "":
			GameState.selected_souvenirs = [GameState.selected_souvenir]
		GameState.flags = data.get("flags", {})
		GameState.memory_wall_items = Array(data.get("memory_wall_items", []), TYPE_STRING, "", null)
		GameState.unlocked_achievements = Array(data.get("unlocked_achievements", []), TYPE_STRING, "", null)
		GameState.inventory_items = Array(data.get("inventory_items", []), TYPE_STRING, "", null)
		GameState.intro_seen = data.get("intro_seen", false)
		return true
	return false

## Syncs unlocked and completed states of cases from existing savegame without loading room/inventory
func sync_case_progress() -> void:
	if not has_save_file():
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_str = file.get_as_text()
	var json = JSON.new()
	if json.parse(json_str) == OK and json.data is Dictionary:
		var data: Dictionary = json.data
		if data.has("completed_cases") and data["completed_cases"] is Array:
			GameState.completed_cases = Array(data["completed_cases"], TYPE_STRING, "", null)
		if data.has("case_registry") and data["case_registry"] is Array:
			var saved_reg: Array = data["case_registry"]
			for target in GameState.case_registry:
				var target_id = target.get("id", "")
				for saved_item in saved_reg:
					if saved_item is Dictionary and saved_item.get("id", "") == target_id:
						target["unlocked"] = saved_item.get("unlocked", target.get("unlocked", false))
						target["completed"] = saved_item.get("completed", target.get("completed", false))
						break
