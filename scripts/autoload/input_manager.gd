extends Node

## InputManager: Unified input abstraction for both PC (Keyboard/Mouse) and Mobile (Touch).
## Ensures game logic never cares whether input came from a physical key, mouse click, or touch tap.

signal move_target_requested(target_position: Vector2)
signal interact_target_requested(target_node: Node2D)

signal interact_pressed
signal notebook_pressed
signal inventory_pressed
signal menu_pressed
signal skip_pressed

var is_touch_active: bool = false
var has_move_target: bool = false
var move_target_position: Vector2 = Vector2.ZERO

func _ready() -> void:
	notebook_pressed.connect(func():
		EventBus.notebook_toggle_requested.emit()
	)
	inventory_pressed.connect(func():
		EventBus.inventory_toggle_requested.emit()
	)
	
	# Prevent Godot's built-in UI focus navigation from intercepting KEY_TAB
	if InputMap.has_action("ui_focus_next"):
		for ev in InputMap.action_get_events("ui_focus_next"):
			if ev is InputEventKey and ev.keycode == KEY_TAB:
				InputMap.action_erase_event("ui_focus_next", ev)
	if InputMap.has_action("ui_focus_prev"):
		for ev in InputMap.action_get_events("ui_focus_prev"):
			if ev is InputEventKey and ev.keycode == KEY_TAB:
				InputMap.action_erase_event("ui_focus_prev", ev)

func _is_modifier_active(event: InputEvent) -> bool:
	if event is InputEventWithModifiers:
		return event.alt_pressed or event.ctrl_pressed or event.meta_pressed
	return false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_stuck_inputs()
		var vp = get_viewport()
		if vp and vp.gui_get_focus_owner():
			vp.gui_get_focus_owner().release_focus()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
		_release_stuck_inputs()
		var vp = get_viewport()
		if vp and vp.gui_get_focus_owner():
			vp.gui_get_focus_owner().release_focus()

func _release_stuck_inputs() -> void:
	for key in [KEY_ALT, KEY_CTRL, KEY_SHIFT, KEY_META, KEY_ESCAPE, KEY_Q]:
		var ev = InputEventKey.new()
		ev.keycode = key
		ev.physical_keycode = key
		ev.pressed = false
		Input.parse_input_event(ev)
	
	for action in [
		"toggle_notebook", "interact", "toggle_inventory",
		"detective_focus", "ui_cancel",
		"move_left", "move_right", "move_up", "move_down",
		"ui_focus_next", "ui_focus_prev"
	]:
		if Input.is_action_pressed(action):
			Input.action_release(action)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		is_touch_active = true

	# Completely ignore TAB key to prevent any Alt+Tab or browser focus issues
	if event is InputEventKey and event.keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("interact"):
		interact_pressed.emit()
		get_viewport().set_input_as_handled()
	elif not _is_modifier_active(event) and (event.is_action_pressed("toggle_notebook") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_Q)):
		if not Input.is_key_pressed(KEY_ESCAPE):
			EventBus.notebook_toggle_requested.emit()
		get_viewport().set_input_as_handled()
	elif not _is_modifier_active(event) and (event.is_action_pressed("toggle_inventory") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_I or event.keycode == KEY_B))):
		EventBus.inventory_toggle_requested.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		menu_pressed.emit()
		get_viewport().set_input_as_handled()

func get_movement_vector() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func request_move_to(pos: Vector2) -> void:
	has_move_target = true
	move_target_position = pos
	move_target_requested.emit(pos)

func cancel_move_target() -> void:
	has_move_target = false

func request_interact_with(target: Node2D) -> void:
	interact_target_requested.emit(target)

func trigger_interact() -> void:
	interact_pressed.emit()

func trigger_notebook() -> void:
	notebook_pressed.emit()

func trigger_inventory() -> void:
	inventory_pressed.emit()

func trigger_menu() -> void:

	menu_pressed.emit()

func trigger_skip() -> void:
	skip_pressed.emit()
