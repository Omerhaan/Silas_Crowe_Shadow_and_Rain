extends CharacterBody2D

## Detective Silas Crowe player entity.
## Handles unified 4-directional movement: both keyboard (WASD) and touch/mouse tap-to-move.
## Uses Sprite2D with scale=(1,1), centered=false, offset=(-32, -104) so feet are exactly at node origin (0, 0).

@export var move_speed: float = 110.0
@export var character_height: float = 100.0

@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite_2d: Sprite2D = $Sprite2D

var facing_direction: int = 1 # 1: right, -1: left
var current_interactable: Node2D = null

# Code-driven procedural animation variables
var anim_time: float = 0.0
var walk_frame_timer: float = 0.0
var walk_frame_idx: int = 0
var shudder_timer: float = 0.0
var is_inspecting_anim: bool = false
var is_on_phone: bool = false
var footstep_timer: float = 0.0

# Tap-to-move / Tap-to-interact
var nav_target: Vector2 = Vector2.ZERO
var is_navigating: bool = false
var pending_interact_target: Node2D = null
var nearby_interactables: Array[Node2D] = []

var anim_textures: Dictionary = {}

func _ready() -> void:
	add_to_group("player")
	if interaction_area and not interaction_area.area_entered.is_connected(_on_interaction_area_entered):
		interaction_area.area_entered.connect(_on_interaction_area_entered)
	if interaction_area and not interaction_area.area_exited.is_connected(_on_interaction_area_exited):
		interaction_area.area_exited.connect(_on_interaction_area_exited)
	
	var im = get_node_or_null("/root/InputManager")
	if im:
		im.move_target_requested.connect(_on_move_target_requested)
		im.interact_target_requested.connect(_on_interact_target_requested)
		im.interact_pressed.connect(_on_interact_pressed)
	var eb = get_node_or_null("/root/EventBus")
	if eb:
		eb.notebook_toggled.connect(_on_notebook_toggled)
	
	_load_textures()
	_apply_character_scale()
	_setup_shadow()
	_set_anim("idle_right")

func _on_notebook_toggled(is_open: bool) -> void:
	if is_open:
		velocity = Vector2.ZERO
		is_navigating = false
		_set_anim("notebook")
	else:
		_set_anim("idle_right" if facing_direction > 0 else "idle_left")

func _setup_shadow() -> void:
	var shadow_node = get_node_or_null("Shadow")
	if shadow_node and shadow_node is Sprite2D:
		var shadow_path = ProjectSettings.globalize_path("res://assets/sprites/shadow_silas.png")
		if FileAccess.file_exists(shadow_path):
			var s_img = Image.load_from_file(shadow_path)
			if s_img:
				shadow_node.texture = ImageTexture.create_from_image(s_img)

func _apply_character_scale() -> void:
	if sprite_2d:
		sprite_2d.scale = Vector2(1.0, 1.0)
		sprite_2d.centered = false
		sprite_2d.offset = Vector2(-32.0, -104.0)
		sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	var gpath = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(gpath):
		var img = Image.load_from_file(gpath)
		if img:
			return ImageTexture.create_from_image(img)
	return null

func _load_textures() -> void:
	var anim_paths = {
		"idle_down": ["res://assets/sprites/characters/silas_idle_down.png"],
		"idle_left": ["res://assets/sprites/characters/silas_idle_left.png"],
		"idle_right": ["res://assets/sprites/characters/silas_idle_right.png"],
		"idle_up": ["res://assets/sprites/characters/silas_idle_up.png"],
		"walk_down": [
			"res://assets/sprites/characters/silas_walk_down_1.png",
			"res://assets/sprites/characters/silas_walk_down_2.png",
			"res://assets/sprites/characters/silas_walk_down_3.png",
			"res://assets/sprites/characters/silas_walk_down_4.png"
		],
		"walk_left": [
			"res://assets/sprites/characters/silas_walk_left_1.png",
			"res://assets/sprites/characters/silas_walk_left_2.png",
			"res://assets/sprites/characters/silas_walk_left_3.png",
			"res://assets/sprites/characters/silas_walk_left_4.png",
			"res://assets/sprites/characters/silas_walk_left_5.png",
			"res://assets/sprites/characters/silas_walk_left_6.png"
		],
		"walk_right": [
			"res://assets/sprites/characters/silas_walk_right_1.png",
			"res://assets/sprites/characters/silas_walk_right_2.png",
			"res://assets/sprites/characters/silas_walk_right_3.png",
			"res://assets/sprites/characters/silas_walk_right_4.png",
			"res://assets/sprites/characters/silas_walk_right_5.png",
			"res://assets/sprites/characters/silas_walk_right_6.png"
		],
		"walk_up": [
			"res://assets/sprites/characters/silas_walk_up_1.png",
			"res://assets/sprites/characters/silas_walk_up_2.png"
		],
		"phone": ["res://assets/sprites/characters/silas_phone.png"],
		"inspect": ["res://assets/sprites/characters/silas_inspect.png"],
		"notebook": ["res://assets/sprites/characters/silas_notebook.png"],
		"shudder": ["res://assets/sprites/characters/silas_shudder.png"]
	}

	for anim in anim_paths.keys():
		var frames: Array[Texture2D] = []
		for path in anim_paths[anim]:
			var t = _load_texture(path)
			if t:
				frames.append(t)
		anim_textures[anim] = frames

func _set_anim(anim_name: String, frame: int = 0) -> void:
	if not sprite_2d or not anim_textures.has(anim_name):
		return
	var frames: Array = anim_textures[anim_name]
	if frames.is_empty():
		return
	var idx = frame % frames.size()
	sprite_2d.texture = frames[idx]

func set_on_phone(active: bool) -> void:
	is_on_phone = active
	if is_on_phone:
		velocity = Vector2.ZERO
		is_navigating = false
		pending_interact_target = null
		_set_anim("phone")
	else:
		_set_anim("idle_right")

func _physics_process(delta: float) -> void:
	var gs = get_node_or_null("/root/GameState")
	var can_move = gs.can_player_move if gs else true
	if not can_move and not is_on_phone and not CutsceneManager.is_cutscene_active:
		var has_modal = false
		var tree = get_tree()
		if tree:
			for m_name in ["PauseMenu", "ConfrontationHale", "Interrogation", "AccusationModal", "InspectView", "CaseEndingModal", "Notebook"]:
				var m = tree.root.find_child(m_name, true, false)
				if m and is_instance_valid(m) and m.is_visible_in_tree():
					has_modal = true
					break
		if not has_modal:
			if gs:
				gs.can_player_move = true
			can_move = true

	if is_on_phone or not can_move:
		velocity = Vector2.ZERO
		is_navigating = false
		_update_animation(delta)
		move_and_slide()
		return

	# Side-view horizontal movement (A/D or Left/Right arrows)
	var move_x = Input.get_axis("move_left", "move_right")

	if move_x != 0.0:
		is_navigating = false
		pending_interact_target = null
		velocity.x = move_x * move_speed
		velocity.y = 0.0
		facing_direction = 1 if move_x > 0.0 else -1
	elif is_navigating:
		var dx = nav_target.x - global_position.x
		if pending_interact_target and is_instance_valid(pending_interact_target):
			var dist_to_target = abs(global_position.x - pending_interact_target.global_position.x)
			if dist_to_target <= 50.0:
				velocity = Vector2.ZERO
				is_navigating = false
				var target_to_interact = pending_interact_target
				pending_interact_target = null
				if target_to_interact.has_method("interact"):
					target_to_interact.interact()
			elif abs(dx) > 4.0:
				velocity.x = sign(dx) * move_speed
				velocity.y = 0.0
				facing_direction = 1 if dx > 0.0 else -1
			else:
				velocity = Vector2.ZERO
				is_navigating = false
				var target_to_interact = pending_interact_target
				pending_interact_target = null
				if target_to_interact.has_method("interact"):
					target_to_interact.interact()
		elif abs(dx) > 4.0:
			velocity.x = sign(dx) * move_speed
			velocity.y = 0.0
			facing_direction = 1 if dx > 0.0 else -1
		else:
			velocity = Vector2.ZERO
			is_navigating = false
	else:
		velocity = Vector2.ZERO

	_update_animation(delta)
	move_and_slide()
	if nearby_interactables.size() > 1 and abs(velocity.x) > 2.0:
		_update_current_interactable()

func _update_animation(delta: float) -> void:
	if not sprite_2d:
		return

	if is_on_phone:
		_set_anim("phone")
		return

	if is_inspecting_anim:
		_set_anim("inspect")
		return

	# Shudder effect
	if shudder_timer > 0.0:
		shudder_timer -= delta
		_set_anim("shudder")
		return

	var is_moving = abs(velocity.x) > 2.0

	if is_moving:
		walk_frame_timer += delta
		if walk_frame_timer >= 0.09:
			walk_frame_timer = 0.0
			walk_frame_idx += 1

		footstep_timer -= delta
		if footstep_timer <= 0.0:
			footstep_timer = 0.32
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"):
				am.play_sfx("footstep")

		var anim_name = "walk_right" if facing_direction > 0 else "walk_left"
		_set_anim(anim_name, walk_frame_idx)
	else:
		walk_frame_idx = 0
		walk_frame_timer = 0.0
		footstep_timer = 0.0
		_set_anim("idle_right" if facing_direction > 0 else "idle_left")

func trigger_shudder(duration: float = 0.55) -> void:
	shudder_timer = duration
	_set_anim("shudder")

func play_inspect_lean() -> void:
	if not sprite_2d:
		return
	is_inspecting_anim = true
	_set_anim("inspect")
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(func():
		is_inspecting_anim = false
		_set_anim("idle_right" if facing_direction > 0 else "idle_left")
	)

func _on_lightning_occurred() -> void:
	trigger_shudder(0.6)

func _on_move_target_requested(target_pos: Vector2) -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs and not gs.can_player_move:
		return
	nav_target = target_pos
	is_navigating = true
	pending_interact_target = null

func _on_interact_target_requested(target: Node2D) -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs and not gs.can_player_move:
		var has_modal = false
		var tree = get_tree()
		if tree:
			for m_name in ["PauseMenu", "ConfrontationHale", "Interrogation", "AccusationModal", "InspectView", "CaseEndingModal"]:
				var m = tree.root.find_child(m_name, true, false)
				if m and m.visible:
					has_modal = true
					break
		if not has_modal and not CutsceneManager.is_cutscene_active:
			gs.can_player_move = true
		else:
			return
	var dist = abs(global_position.x - target.global_position.x)
	var is_npc = target.has_method("set_character_texture") or (target.get("object_id") != null and str(target.get("object_id")).begins_with("npc_"))
	var reach_dist = 45.0 if not is_npc else 55.0

	if dist <= reach_dist:
		is_navigating = false
		pending_interact_target = null
		if target.has_method("interact"):
			target.interact()
	else:
		pending_interact_target = target
		if is_npc:
			var target_x = target.global_position.x
			var offset = 35.0 if global_position.x >= target_x else -35.0
			nav_target = Vector2(target_x + offset, 245.0)
		else:
			nav_target = Vector2(target.global_position.x, 245.0)
		is_navigating = true

func _on_interact_pressed() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs and not gs.can_player_move:
		var has_modal = false
		var tree = get_tree()
		if tree:
			for m_name in ["PauseMenu", "ConfrontationHale", "Interrogation", "AccusationModal", "InspectView", "CaseEndingModal"]:
				var m = tree.root.find_child(m_name, true, false)
				if m and m.visible:
					has_modal = true
					break
		if not has_modal and not CutsceneManager.is_cutscene_active:
			gs.can_player_move = true
		else:
			return

	if not current_interactable or not is_instance_valid(current_interactable):
		_update_current_interactable()
	if current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("interact"):
		current_interactable.interact()
	else:
		# Fallback: check closest interactable within reach
		var closest: Node2D = null
		var min_d = 50.0
		for t in nearby_interactables:
			if is_instance_valid(t) and t.has_method("interact"):
				var d = abs(global_position.x - t.global_position.x)
				if d < min_d:
					min_d = d
					closest = t
		if closest:
			closest.interact()

func _on_interaction_area_entered(area: Area2D) -> void:
	var target: Node2D = null
	if area.has_method("interact"):
		target = area
	elif area.get_parent() and area.get_parent().has_method("interact"):
		target = area.get_parent()

	if target:
		if not nearby_interactables.has(target):
			nearby_interactables.append(target)
		_update_current_interactable()
		if pending_interact_target == target:
			target.interact()
			pending_interact_target = null
			is_navigating = false

func _on_interaction_area_exited(area: Area2D) -> void:
	var target: Node2D = null
	if area.has_method("interact"):
		target = area
	elif area.get_parent() and area.get_parent().has_method("interact"):
		target = area.get_parent()

	if target and nearby_interactables.has(target):
		nearby_interactables.erase(target)
		if target.has_method("set_highlight"):
			target.set_highlight(false)
		_update_current_interactable()

func _is_target_active(target: Node) -> bool:
	if not is_instance_valid(target) or not target.is_inside_tree():
		return false
	var p: Node = target
	while p != null:
		if p.is_queued_for_deletion():
			return false
		p = p.get_parent()
	return true

func _update_current_interactable() -> void:
	var valid_nearby: Array[Node2D] = []
	if interaction_area:
		for area in interaction_area.get_overlapping_areas():
			if not _is_target_active(area):
				continue
			var target: Node2D = null
			if area.has_method("interact"):
				target = area
			elif area.get_parent() and area.get_parent().has_method("interact"):
				target = area.get_parent()
			if target and _is_target_active(target):
				if not valid_nearby.has(target):
					valid_nearby.append(target)

	for node in nearby_interactables:
		if _is_target_active(node):
			var dist = abs(global_position.x - node.global_position.x)
			if dist <= 45.0 and not valid_nearby.has(node):
				valid_nearby.append(node)

	nearby_interactables = valid_nearby
	var best_target: Node2D = null

	# 1. Door priority when player is standing right in front of a doorway (<= 28px)
	var immediate_doors = nearby_interactables.filter(func(node):
		var is_door = node.has_method("interact") and (node.get("target_room_id") != null or node.name.begins_with("Door"))
		if is_door:
			return abs(global_position.x - node.global_position.x) <= 28.0
		return false
	)

	if not immediate_doors.is_empty():
		var best_door_dist = INF
		for d in immediate_doors:
			var dx = abs(global_position.x - d.global_position.x)
			if dx < best_door_dist:
				best_door_dist = dx
				best_target = d
	else:
		# 2. High-priority interactive targets: Uncollected Evidence, Key Items, Secret Drawers, and NPCs
		var high_priority_targets = nearby_interactables.filter(func(node):
			var evid = str(node.get("evidence_id")) if node.get("evidence_id") != null else ""
			var oid = str(node.get("object_id")) if node.get("object_id") != null else ""
			var is_sec = node.get("is_secret_drawer") == true
			var is_item = oid.begins_with("item_")
			var is_uncollected = (evid != "" and not GameState.has_evidence(evid))
			var is_npc = (oid.begins_with("npc_") or node.has_method("set_character_texture") or node.is_in_group("npcs"))
			return is_uncollected or is_item or is_sec or is_npc
		)

		if not high_priority_targets.is_empty():
			var best_score = INF
			for t in high_priority_targets:
				var dx = abs(global_position.x - t.global_position.x)
				var evid = str(t.get("evidence_id")) if t.get("evidence_id") != null else ""
				var is_uncollected = (evid != "" and not GameState.has_evidence(evid))
				# Slight priority tie-breaker (4px) for uncollected evidence/items when standing between them and an NPC
				var score = dx - (4.0 if is_uncollected else 0.0)
				if score < best_score:
					best_score = score
					best_target = t
		else:
			# 3. Secondary candidates (inspected evidence, generic props, farther doors)
			var best_dist = INF
			for t in nearby_interactables:
				var dx = abs(global_position.x - t.global_position.x)
				if dx < best_dist:
					best_dist = dx
					best_target = t

	if best_target != current_interactable:
		if current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("set_highlight"):
			current_interactable.set_highlight(false)
		current_interactable = best_target
		var eb = get_node_or_null("/root/EventBus")
		if current_interactable:
			if eb and eb.has_signal("interaction_available"):
				eb.interaction_available.emit(current_interactable)
			if current_interactable.has_method("set_highlight"):
				current_interactable.set_highlight(true)
		else:
			if eb and eb.has_signal("interaction_unavailable"):
				eb.interaction_unavailable.emit(null)

func reset_interaction_state() -> void:
	if current_interactable and is_instance_valid(current_interactable) and current_interactable.has_method("set_highlight"):
		current_interactable.set_highlight(false)
	current_interactable = null
	nearby_interactables.clear()
	pending_interact_target = null
	is_navigating = false
	_update_current_interactable()
