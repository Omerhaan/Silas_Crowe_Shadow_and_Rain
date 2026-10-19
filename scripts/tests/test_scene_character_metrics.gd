extends SceneTree

## Comprehensive in-scene test suite for:
## 1) Character visible alpha heights and sole y=245 in actual scenes
## 2) Study single exit rule
## 3) Door hotspot rules and locked door messages

func _init() -> void:
	print("\n========================================================")
	print(" RUNNING IN-SCENE CHARACTER & ROOM TRANSITION TEST SUITE ")
	print("========================================================\n")

	var failed = false
	var results = []

	var target_heights = {
		"silas": 100,
		"hale": 102,
		"julian": 98,
		"pike": 98,
		"margaret": 94,
		"edmund": 98
	}

	# ----------------------------------------------------
	# TEST 1: Silas Player Entity in-scene test
	# ----------------------------------------------------
	var player_scene = load("res://scenes/entities/player.tscn")
	if not player_scene:
		print("FAILED: Cannot load player.tscn")
		quit(1)
		return
	var player = player_scene.instantiate()
	player.position = Vector2(240, 245)
	root.add_child(player)
	if player.has_method("_ready"):
		player._ready()

	var p_sprite: Sprite2D = player.get_node_or_null("Sprite2D")
	if not p_sprite:
		print("FAILED: Player does not have Sprite2D child!")
		failed = true
	else:
		var p_tex = p_sprite.texture
		if not p_tex:
			p_tex = load("res://assets/sprites/characters/silas_idle_right.png")
			p_sprite.texture = p_tex
		var p_img = p_tex.get_image()
		var p_used = p_img.get_used_rect()
		var p_vis_h = p_used.size.y
		var p_sole_local_y = p_sprite.offset.y + (p_used.position.y + p_used.size.y)
		var p_sole_screen_y = player.position.y + p_sole_local_y

		var h_diff = abs(p_vis_h - target_heights["silas"])
		var y_diff = abs(p_sole_screen_y - 245.0)

		var pass_p = (h_diff <= 2 and y_diff <= 1.0)
		if not pass_p: failed = true

		results.append({
			"room": "player.tscn",
			"character": "Silas Crowe",
			"target_h": target_heights["silas"],
			"measured_h": p_vis_h,
			"target_y": 245.0,
			"measured_y": p_sole_screen_y,
			"status": "PASS" if pass_p else "FAIL"
		})

	player.queue_free()

	# ----------------------------------------------------
	# TEST 2: In-Scene NPCs across room scenes
	# ----------------------------------------------------
	var room_specs = [
		{"path": "res://scenes/rooms/library.tscn", "room": "Kütüphane", "npc_name": "Dr. Victor Hale", "target_key": "hale"},
		{"path": "res://scenes/rooms/dining_room.tscn", "room": "Yemek Odası", "npc_name": "Raymond Pike", "target_key": "pike"},
		{"path": "res://scenes/rooms/kitchen.tscn", "room": "Mutfak", "npc_name": "Margaret Doyle", "target_key": "margaret"},
		{"path": "res://scenes/rooms/billiard_room.tscn", "room": "Bilardo Odası", "npc_name": "Julian Harlow", "target_key": "julian"}
	]

	for spec in room_specs:
		var r_scene = load(spec["path"])
		if not r_scene:
			print("FAILED: Cannot load scene %s" % spec["path"])
			failed = true
			continue

		var r_inst = r_scene.instantiate()
		root.add_child(r_inst)

		var npc_node: Node2D = null
		for child in r_inst.get_children():
			if child.is_in_group("npcs") or child.has_method("set_character_texture") or child.name.begins_with("NPC_"):
				npc_node = child
				break

		if not npc_node:
			print("FAILED: NPC not found in scene %s" % spec["path"])
			failed = true
			r_inst.queue_free()
			continue

		if npc_node.has_method("_ready"):
			npc_node._ready()

		var sprite: Sprite2D = npc_node.get_node_or_null("Sprite2D")
		if not sprite:
			sprite = npc_node.get_node_or_null("NPCSprite")

		if not sprite:
			print("FAILED: Sprite node not found on NPC in %s" % spec["path"])
			failed = true
			r_inst.queue_free()
			continue

		var tex = sprite.texture
		if not tex:
			var prefix = spec["target_key"]
			tex = load("res://assets/sprites/characters/%s_idle_down.png" % prefix)
			sprite.texture = tex

		var img = tex.get_image()
		var used_rect = img.get_used_rect()
		var vis_h = used_rect.size.y
		var sole_local_y = sprite.offset.y + (used_rect.position.y + used_rect.size.y)
		var sole_screen_y = npc_node.position.y + sole_local_y

		var h_diff = abs(vis_h - target_heights[spec["target_key"]])
		var y_diff = abs(sole_screen_y - 245.0)

		var pass_npc = (h_diff <= 2 and y_diff <= 1.0)
		if not pass_npc: failed = true

		results.append({
			"room": spec["room"],
			"character": spec["npc_name"],
			"target_h": target_heights[spec["target_key"]],
			"measured_h": vis_h,
			"target_y": 245.0,
			"measured_y": sole_screen_y,
			"status": "PASS" if pass_npc else "FAIL"
		})

		r_inst.queue_free()

	# Print Measurement Table
	print("\n--- MEASUREMENT TABLE ---")
	print("| Karakter | Sahne / Oda | Hedef Boy | Ölçülen Boy | Hedef Ayak Y | Ölçülen Ayak Y | Durum |")
	print("| :--- | :--- | :---: | :---: | :---: | :---: | :---: |")
	for r in results:
		print("| %s | %s | %d px | %d px | %.1f | %.1f | **%s** |" % [
			r["character"], r["room"], r["target_h"], r["measured_h"], r["target_y"], r["measured_y"], r["status"]
		])

	# ----------------------------------------------------
	# TEST 3: Study Single Exit Rule & Evidence Sprite Check
	# ----------------------------------------------------
	print("\n--- TESTING STUDY SINGLE EXIT & EVIDENCE ---")
	var study_scene = load("res://scenes/rooms/study.tscn")
	var study = study_scene.instantiate()
	root.add_child(study)

	var doors = []
	for child in study.get_children():
		if child.name.begins_with("Door_") or child.get("target_room_id") != null:
			doors.append(child)

	if doors.size() != 1:
		print("FAILED: Study has %d door nodes, expected exactly 1!" % doors.size())
		failed = true
	else:
		var d = doors[0]
		var tr = str(d.get("target_room_id"))
		if tr != "main_hall" or d.position.x < 400:
			print("FAILED: Study door target must be main_hall and on right wall (x > 400). Found: %s at %s" % [tr, d.position])
			failed = true
		else:
			print("SUCCESS: Study has exactly 1 exit on right wall to main_hall at %s" % d.position)

	# Verify corpse and cognac glass exist
	var e01 = study.find_child("Evidence_E01", true, false)
	var e04 = study.find_child("Evidence_E04", true, false)
	var e02 = study.find_child("Evidence_E02", true, false)
	var e08 = study.find_child("Evidence_E08", true, false)

	if not e01:
		print("FAILED: Evidence_E01 (Ceset) not found in Study")
		failed = true
	else:
		print("SUCCESS: Evidence_E01 (Ceset) verified at %s" % e01.position)

	if not e04:
		print("FAILED: Evidence_E04 (Konyak) not found in Study")
		failed = true
	else:
		print("SUCCESS: Evidence_E04 (Konyak) verified at %s" % e04.position)

	if not e02 or e02.position.x < 440 or e02.position.y < 160:
		print("FAILED: Evidence_E02 not aligned with right door keyhole: %s" % (e02.position if e02 else "null"))
		failed = true
	else:
		print("SUCCESS: Evidence_E02 aligned with right door keyhole at %s" % e02.position)

	if not e08 or e08.position.x < 290 or e08.position.y > 130:
		print("FAILED: Evidence_E08 not aligned with wall sconce: %s" % (e08.position if e08 else "null"))
		failed = true
	else:
		print("SUCCESS: Evidence_E08 aligned with wall sconce at %s" % e08.position)

	study.queue_free()

	# ----------------------------------------------------
	# TEST 4: Kitchen and Main Hall Locked Doors Check
	# ----------------------------------------------------
	print("\n--- TESTING LOCKED DOORS & NEW PLATE DOORS ---")
	var hall_scene = load("res://scenes/rooms/main_hall.tscn")
	var hall = hall_scene.instantiate()
	root.add_child(hall)

	var front_door = hall.find_child("Door_FrontDoor", true, false)
	var front_locked = front_door.get("is_locked") if front_door else null
	var front_target = front_door.get("target_room_id") if front_door else null

	if not front_door or front_locked != true or (front_target != "" and front_target != null):
		print("FAILED: Main Hall front door must be locked with target_room_id=''")
		failed = true
	else:
		print("SUCCESS: Main Hall front door is locked and targetless at %s" % front_door.position)

	var hall_study_door = hall.find_child("Door_To_Study", true, false)
	if not hall_study_door or hall_study_door.get("target_room_id") != "study":
		print("FAILED: Main Hall must have Door_To_Study next to stairs")
		failed = true
	else:
		print("SUCCESS: Main Hall has Door_To_Study next to stairs at %s" % hall_study_door.position)

	hall.queue_free()

	var lib_scene = load("res://scenes/rooms/library.tscn")
	var lib = lib_scene.instantiate()
	root.add_child(lib)
	var lib_billiard_door = lib.find_child("Door_To_Billiard", true, false)
	if not lib_billiard_door or lib_billiard_door.get("target_room_id") != "billiard_room":
		print("FAILED: Library must have Door_To_Billiard on right wall")
		failed = true
	else:
		print("SUCCESS: Library has Door_To_Billiard on right wall at %s" % lib_billiard_door.position)
	lib.queue_free()

	var din_scene = load("res://scenes/rooms/dining_room.tscn")
	var din = din_scene.instantiate()
	root.add_child(din)
	var din_kit_door = din.find_child("Door_To_Kitchen", true, false)
	var din_hall_door = din.find_child("Door_To_MainHall", true, false)
	if not din_kit_door or din_kit_door.get("target_room_id") != "kitchen":
		print("FAILED: Dining room must have Door_To_Kitchen on left wall")
		failed = true
	else:
		print("SUCCESS: Dining room has Door_To_Kitchen at %s" % din_kit_door.position)
	if not din_hall_door or din_hall_door.get("target_room_id") != "main_hall":
		print("FAILED: Dining room must have Door_To_MainHall on right wall")
		failed = true
	else:
		print("SUCCESS: Dining room has Door_To_MainHall at %s" % din_hall_door.position)
	din.queue_free()

	var kitchen_scene = load("res://scenes/rooms/kitchen.tscn")
	var kitchen = kitchen_scene.instantiate()
	root.add_child(kitchen)

	var back_door = kitchen.find_child("Door_KitchenBackDoor", true, false)
	var back_locked = back_door.get("is_locked") if back_door else null
	var back_target = back_door.get("target_room_id") if back_door else null

	if not back_door or back_locked != true or (back_target != "" and back_target != null):
		print("FAILED: Kitchen back door must be locked with target_room_id=''")
		failed = true
	else:
		print("SUCCESS: Kitchen back door is locked and targetless at %s" % back_door.position)

	kitchen.queue_free()

	print("\n========================================================")
	if failed:
		print(" TEST SUITE FAILED!")
		print("========================================================\n")
		quit(1)
	else:
		print(" ALL IN-SCENE CHARACTER & ROOM TESTS PASSED (100%)!")
		print("========================================================\n")
		quit(0)
