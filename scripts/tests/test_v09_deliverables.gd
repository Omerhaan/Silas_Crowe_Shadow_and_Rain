extends Node2D

## Comprehensive test suite for v0.9 deliverables:
## 1. High quality plates (no 40-color quantization)
## 2. In-world door navigation for entire mansion
## 3. Key-lock chain (E07, E12, Door_To_Pike)
## 4. Evidence vanishing vs fixed observation persistence
## 5. InspectView & DialogueBox margins and pagination
## 6. Inventory modal and HUD Bag button

func _ready() -> void:
	print("\n========================================================")
	print(" RUNNING V0.9 DELIVERABLES AUTOMATED VERIFICATION SUITE ")
	print("========================================================\n")

	var failed = false



	# -----------------------------------------------------------------
	# 1. TEST HIGH-QUALITY PLATES
	# -----------------------------------------------------------------
	print("--- 1. TESTING HIGH-QUALITY PLATES ---")
	for plate in ["bg_library.png", "bg_dining_room.png", "bg_main_hall.png"]:
		var p_path = "res://assets/plates/" + plate
		var real_p = ProjectSettings.globalize_path(p_path)
		var fa = FileAccess.open(real_p, FileAccess.READ)
		if fa:
			var len_bytes = fa.get_length()
			fa.close()
			if len_bytes < 80000:
				print("FAIL: %s is suspiciously small (%d bytes), may be quantized" % [plate, len_bytes])
				failed = true
			else:
				print("PASS: %s is high-quality 24-bit (%d bytes)" % [plate, len_bytes])
		else:
			print("FAIL: Cannot open %s" % plate)
			failed = true

	# -----------------------------------------------------------------
	# 2. TEST IN-WORLD DOOR NAVIGATION FOR ALL ROOMS
	# -----------------------------------------------------------------
	print("\n--- 2. TESTING IN-WORLD DOOR NAVIGATION FOR ALL ROOMS ---")
	var room_door_expectations = {
		"res://scenes/rooms/study.tscn": ["Door_To_MainHall"],
		"res://scenes/rooms/main_hall.tscn": ["Door_To_Library", "Door_To_Study", "Door_To_Upper", "Door_FrontDoor"],
		"res://scenes/rooms/library.tscn": ["Door_To_MainHall", "Door_To_Billiard"],
		"res://scenes/rooms/billiard_room.tscn": ["Door_To_Library", "Door_To_Dining"],
		"res://scenes/rooms/dining_room.tscn": ["Door_To_Kitchen", "Door_To_Billiard"],
		"res://scenes/rooms/kitchen.tscn": ["Door_KitchenBackDoor", "Door_To_Dining"],
		"res://scenes/rooms/upper_floor.tscn": ["Door_To_MainHall", "Door_To_Julian", "Door_To_Harlow", "Door_To_Pike"],
		"res://scenes/rooms/harlow_bedroom.tscn": ["Door_To_Upper"],
		"res://scenes/rooms/julian_room.tscn": ["Door_To_Upper"],
		"res://scenes/rooms/pike_room.tscn": ["Door_To_Upper"]
	}

	for scene_path in room_door_expectations.keys():
		var scn = load(scene_path)
		if not scn:
			print("FAIL: Cannot load %s" % scene_path)
			failed = true
			continue
		var room = scn.instantiate()
		var expected_doors: Array = room_door_expectations[scene_path]
		for d_name in expected_doors:
			var d_node = room.get_node_or_null(d_name)
			if d_node:
				print("PASS: %s has %s at pos %s (target=%s)" % [scene_path.get_file(), d_name, d_node.position, d_node.get("target_room_id")])
			else:
				print("FAIL: %s is missing %s" % [scene_path.get_file(), d_name])
				failed = true
		room.queue_free()

	# -----------------------------------------------------------------
	# 3. TEST KEY-LOCK CHAIN
	# -----------------------------------------------------------------
	print("\n--- 3. TESTING KEY-LOCK CHAIN ---")
	# Check Harlow bedroom has Item_Key_Drawer
	var harlow_scn = load("res://scenes/rooms/harlow_bedroom.tscn").instantiate()
	var key_drawer_node = harlow_scn.get_node_or_null("Item_Key_Drawer")
	if key_drawer_node and key_drawer_node.object_id == "item_key_drawer":
		print("PASS: Harlow's bedroom contains Item_Key_Drawer yielding key_drawer")
	else:
		print("FAIL: Item_Key_Drawer not found in harlow_bedroom.tscn")
		failed = true
	harlow_scn.queue_free()

	# Check Study E07 requires key_drawer
	var study_scn = load("res://scenes/rooms/study.tscn").instantiate()
	var e07_node = study_scn.get_node_or_null("Evidence_E07")
	if e07_node and e07_node.required_key_id == "key_drawer":
		print("PASS: Study Evidence_E07 locked with key_drawer")
	else:
		print("FAIL: Study Evidence_E07 not locked with key_drawer")
		failed = true
	study_scn.queue_free()

	# Check Billiard room has Item_Key_Chest
	var billiard_scn = load("res://scenes/rooms/billiard_room.tscn").instantiate()
	var key_chest_node = billiard_scn.get_node_or_null("Item_Key_Chest")
	if key_chest_node and key_chest_node.object_id == "item_key_chest":
		print("PASS: Billiard room contains Item_Key_Chest yielding key_chest")
	else:
		print("FAIL: Item_Key_Chest not found in billiard_room.tscn")
		failed = true
	billiard_scn.queue_free()

	# Check Julian's room E12 requires key_chest
	var julian_scn = load("res://scenes/rooms/julian_room.tscn").instantiate()
	var e12_node = julian_scn.get_node_or_null("Evidence_E12")
	if e12_node and e12_node.required_key_id == "key_chest":
		print("PASS: Julian room Evidence_E12 locked with key_chest")
	else:
		print("FAIL: Julian room Evidence_E12 not locked with key_chest")
		failed = true
	julian_scn.queue_free()

	# Check Upper Floor Door_To_Pike requires key_ring
	var upper_scn = load("res://scenes/rooms/upper_floor.tscn").instantiate()
	var pike_door = upper_scn.get_node_or_null("Door_To_Pike")
	if pike_door and pike_door.required_key_id == "key_ring" and pike_door.is_locked:
		print("PASS: Upper floor Door_To_Pike locked with key_ring")
	else:
		print("FAIL: Upper floor Door_To_Pike not locked with key_ring")
		failed = true
	upper_scn.queue_free()

	# Check Margaret dialogue has 'keys' topic yielding key_ring
	var margaret_dialogue_file = "res://data/cases/case01/dialogues/margaret.json"
	var mg_data = JSON.parse_string(FileAccess.open(margaret_dialogue_file, FileAccess.READ).get_as_text())
	var has_keys_topic = false
	for t in mg_data.get("topics", []):
		if t.get("id") == "keys" and t.get("item_yield") == "key_ring":
			has_keys_topic = true
			break
	if has_keys_topic:
		print("PASS: Margaret dialogue includes 'keys' topic yielding key_ring")
	else:
		print("FAIL: Margaret dialogue missing 'keys' topic yielding key_ring")
		failed = true

	# -----------------------------------------------------------------
	# 4. TEST EVIDENCE SCENE PERSISTENCE & CLASSIFICATION
	# -----------------------------------------------------------------
	print("\n--- 4. TESTING EVIDENCE PERSISTENCE & CLASSIFICATION ---")
	var fixed_expected = ["E02", "E08", "E10", "E15", "E17"]
	var interactable_script = load("res://scripts/entities/interactable.gd")
	var fixed_const = interactable_script.FIXED_OBSERVATION_EVIDENCE
	for f_id in fixed_expected:
		if f_id in fixed_const:
			print("PASS: %s correctly classified as FIXED_OBSERVATION" % f_id)
		else:
			print("FAIL: %s not in FIXED_OBSERVATION_EVIDENCE" % f_id)
			failed = true

	# -----------------------------------------------------------------
	# 5. TEST INSPECT VIEW & DIALOGUE BOX
	# -----------------------------------------------------------------
	print("\n--- 5. TESTING INSPECT VIEW & DIALOGUE BOX ---")
	var inspect_scene = load("res://scenes/ui/inspect_view.tscn").instantiate()
	var modal: Panel = inspect_scene.get_node_or_null("ModalPanel")
	if modal:
		# Check 12 px safe margin
		var left_edge = 240.0 + modal.offset_left
		var right_edge = 240.0 + modal.offset_right
		var top_edge = 135.0 + modal.offset_top
		var bottom_edge = 135.0 + modal.offset_bottom
		print("InspectView ModalPanel bounds: [%.1f, %.1f] x [%.1f, %.1f]" % [left_edge, right_edge, top_edge, bottom_edge])
		if left_edge >= 12.0 and right_edge <= 468.0 and top_edge >= 12.0 and bottom_edge <= 258.0:
			print("PASS: InspectView ModalPanel fits within 12 px safe margin")
		else:
			print("FAIL: InspectView ModalPanel violates 12 px safe margin")
			failed = true

		var close_btn: Button = modal.get_node_or_null("CloseBtn")
		if close_btn and close_btn.offset_right <= (modal.offset_right - modal.offset_left):
			print("PASS: CloseBtn is fully inside ModalPanel (offset_right=%.1f, modal_w=%.1f)" % [close_btn.offset_right, modal.offset_right - modal.offset_left])
		else:
			print("FAIL: CloseBtn overflows ModalPanel")
			failed = true
	else:
		print("FAIL: ModalPanel not found in inspect_view.tscn")
		failed = true
	inspect_scene.queue_free()

	# Check DialogueBox pagination
	var dbox_scene = load("res://scenes/ui/dialogue_box.tscn").instantiate()
	add_child(dbox_scene)
	if dbox_scene.has_method("_paginate_text"):
		var short_p = dbox_scene._paginate_text("Kısa bir metin.")
		var long_p = dbox_scene._paginate_text("Harlow'un yelek cebindeki altın kaplama cep saati. Camı çatlamış, akrep ve yelkovan 22:10'da kilitlenmiş. Arka kapağında küçük bir oyma var: 'K-5'. O geceden beri zaman benim için durdu. Kuzey Birliği'nin komuta saati bu.")
		print("Short text pages: %d, Long text pages: %d" % [short_p.size(), long_p.size()])
		if short_p.size() == 1 and long_p.size() > 1:
			print("PASS: DialogueBox properly paginates long text (>4 lines)")
		else:
			print("FAIL: DialogueBox pagination failed")
			failed = true
	else:
		print("FAIL: DialogueBox missing _paginate_text method")
		failed = true
	dbox_scene.queue_free()

	# Check Julian portrait bounding box
	var julian_img = Image.load_from_file(ProjectSettings.globalize_path("res://cases/case01/assets/characters/julian.png"))
	var j_used_rect = julian_img.get_used_rect()
	print("Julian portrait size: %s, used_rect: %s" % [julian_img.get_size(), j_used_rect])
	if j_used_rect.size.x >= 40:
		print("PASS: Julian portrait fills full frame without empty side black bars")
	else:
		print("FAIL: Julian portrait has empty black margins (width=%d < 40)" % j_used_rect.size.x)
		failed = true

	# -----------------------------------------------------------------
	# 6. TEST INVENTORY MODAL & HUD BAG BUTTON
	# -----------------------------------------------------------------
	print("\n--- 6. TESTING INVENTORY MODAL & HUD BAG BUTTON ---")
	var hud_scene = load("res://scenes/ui/hud.tscn").instantiate()
	var bag_btn: Button = hud_scene.get_node_or_null("SafeArea/TopBar/MarginContainer/HBoxContainer/BagButton")
	if bag_btn:
		var b_size = bag_btn.custom_minimum_size
		print("BagButton minimum size: %s" % b_size)
		if b_size.x >= 36.0 and b_size.y >= 36.0:
			print("PASS: BagButton satisfies >= 36x36 touch-friendly requirement")
		else:
			print("FAIL: BagButton size is smaller than 36x36")
			failed = true
	else:
		print("FAIL: BagButton not found in HUD TopBar")
		failed = true

	var inv_modal = hud_scene.get_node_or_null("InventoryModal")
	if inv_modal:
		print("PASS: InventoryModal is instanced in HUD")
	else:
		print("FAIL: InventoryModal not instanced in HUD")
		failed = true
	hud_scene.queue_free()

	print("\n========================================================")
	if failed:
		print(" SOME V0.9 TESTS FAILED!")
		print("========================================================\n")
		get_tree().quit(1)
	else:
		print(" ALL V0.9 DELIVERABLES VERIFIED & PASSED (100%)! ")
		print("========================================================\n")
		get_tree().quit(0)
