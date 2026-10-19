extends Node2D

## Silas Crowe's private office / apartment (Hub).
## Features rain outside window, desk props, locked drawer, memory wall, souvenir shelf, and ringing telephone.

@onready var telephone_interact: Node2D = $TelephoneInteract
@onready var phone_ring_timer: Timer = $PhoneRingTimer

enum HubState {
	BEFORE_CALL,
	DURING_CALL,
	AFTER_CALL,
	CASE_SOLVED
}

var current_state: HubState = HubState.BEFORE_CALL
var is_phone_ringing: bool = false
var has_answered: bool = false
var original_phone_pos: Vector2 = Vector2.ZERO

signal phone_picked_up
signal second_call_triggered

func _ready() -> void:
	add_to_group("office_hub")
	phone_ring_timer.timeout.connect(_on_phone_ring_timeout)
	original_phone_pos = telephone_interact.position
	
	if GameState.current_case_id == "case03" and GameState.case_solved:
		current_state = HubState.CASE_SOLVED
		has_answered = true
	elif GameState.current_case_id == "case02" and GameState.case_solved:
		current_state = HubState.CASE_SOLVED
		if not GameState.flags.get("third_call_done", false):
			has_answered = false
			start_phone_timer(2.0)
		else:
			has_answered = true
	elif (GameState.current_case_id == "case01" or GameState.current_case_id.is_empty()) and GameState.case_solved:
		current_state = HubState.CASE_SOLVED
		if not GameState.flags.get("second_call_done", false):
			has_answered = false
			start_phone_timer(2.5)
		else:
			has_answered = true
	else:
		current_state = HubState.BEFORE_CALL
		if not CutsceneManager.is_cutscene_active:
			has_answered = false
			start_phone_timer(3.0)
	
	update_souvenir_shelf()

func on_door_interacted() -> void:
	if "case03" in GameState.completed_cases:
		EventBus.inner_voice_requested.emit("\"1. Sezon vakaları tamamlandı. Yağmur nihayet dindi...\"")
	elif "case02" in GameState.completed_cases:
		EventBus.inner_voice_requested.emit("\"Kraliyet Operası'ndaki suikast beni bekliyor.\"")
		EventBus.case_continue_requested.emit("case03")
	elif "case01" in GameState.completed_cases or GameState.case_solved:
		EventBus.inner_voice_requested.emit("\"Sisli rıhtıma doğru yola çıkmalıyım.\"")
		EventBus.case_continue_requested.emit("case02")
	elif current_state == HubState.AFTER_CALL:
		EventBus.inner_voice_requested.emit("\"Harlow Malikânesi'ne doğru yola çıkmalıyım.\"")
	else:
		EventBus.inner_voice_requested.emit("\"Bu yağmurda dışarı çıkacak bir sebebim yok.\"")

func start_incoming_call(ring_delay: float = 0.5, auto_answer_delay: float = 1.6) -> void:
	current_state = HubState.BEFORE_CALL
	has_answered = false
	is_phone_ringing = false
	phone_ring_timer.stop()
	telephone_interact.position = original_phone_pos
	telephone_interact.display_name = "Telefonu Aç"

	# Start audible ring and visual jitter after ring_delay
	get_tree().create_timer(ring_delay).timeout.connect(func():
		if is_instance_valid(self) and not has_answered:
			_on_phone_ring_timeout()
	)

	# Auto-answer so player seamlessly enters conversation if not clicked manually
	if auto_answer_delay > 0.0:
		get_tree().create_timer(ring_delay + auto_answer_delay).timeout.connect(func():
			if is_instance_valid(self) and not has_answered:
				answer_phone()
		)

func start_phone_timer(delay: float = 3.5) -> void:
	if not has_answered:
		phone_ring_timer.stop()
		phone_ring_timer.start(delay)

func _process(_delta: float) -> void:
	if is_phone_ringing and not has_answered:
		var jitter = sin(Time.get_ticks_msec() * 0.06) * 1.5
		telephone_interact.position.x = original_phone_pos.x + jitter

func _on_phone_ring_timeout() -> void:
	if not has_answered:
		is_phone_ringing = true
		telephone_interact.display_name = "Telefonu Aç"
		telephone_interact.set_highlight(true)
		AudioManager.play_sfx("phone_ring")
		EventBus.toast_requested.emit("📞 Masadaki telefon ısrarla çalıyor...")
		# Ring again every 3.5 seconds until answered
		phone_ring_timer.start(3.5)

func answer_phone() -> void:
	if not has_answered:
		has_answered = true
		is_phone_ringing = false
		phone_ring_timer.stop()
		telephone_interact.position = original_phone_pos
		telephone_interact.display_name = "Telefon"
		telephone_interact.set_highlight(false)
		EventBus.toast_requested.emit("")

		if GameState.current_case_id == "case02" and GameState.case_solved:
			current_state = HubState.CASE_SOLVED
			GameState.flags["third_call_done"] = true
			EventBus.case_continue_requested.emit("case03")
		elif (GameState.current_case_id == "case01" or GameState.current_case_id.is_empty()) and GameState.case_solved and not GameState.flags.get("second_call_done", false):
			current_state = HubState.CASE_SOLVED
			GameState.flags["second_call_done"] = true
			second_call_triggered.emit()
		elif not GameState.case_solved:
			current_state = HubState.DURING_CALL
			phone_picked_up.emit()
	else:
		if "case03" in GameState.completed_cases:
			EventBus.inner_voice_requested.emit("\"Hat sessiz. Greywater şimdilik güvende.\"")
		elif "case02" in GameState.completed_cases:
			EventBus.inner_voice_requested.emit("\"Arayan kişi telefonu kapattı. Kraliyet Operası'na doğru yola çıkmalıyım.\"")
		elif "case01" in GameState.completed_cases or GameState.case_solved:
			EventBus.inner_voice_requested.emit("\"Arayan kişi telefonu kapattı. Sisli rıhtıma doğru yola çıkmalıyım.\"")
		elif current_state == HubState.AFTER_CALL:
			EventBus.inner_voice_requested.emit("\"Arayan kişi telefonu kapattı. Harlow Malikânesi'ne doğru yola çıkmalıyım.\"")
		else:
			EventBus.inner_voice_requested.emit("\"Hat kapalı. Sadece boştaki hattın cızırtısı duyuluyor.\"")

func update_souvenir_shelf() -> void:
	var shelf = get_node_or_null("Interact_SouvenirShelf")
	if not shelf:
		return
	var spr = shelf.get_node_or_null("PropSprite")
	if not spr:
		spr = shelf.get_node_or_null("Sprite2D")
	if spr:
		spr.visible = false # The wooden shelf is naturally painted into the background plate

	# Individual souvenir item slot sprites (Left: Pen, Center: Key, Right: Chalk)
	var pen_placed = GameState.is_souvenir_placed("crystal_pen_holder") or "Kristal" in GameState.selected_souvenir or "Kalem" in GameState.selected_souvenir
	var key_placed = GameState.is_souvenir_placed("manor_old_key") or "Anahtar" in GameState.selected_souvenir
	var chalk_placed = GameState.is_souvenir_placed("billiard_chalk") or "Tebeşir" in GameState.selected_souvenir

	_ensure_souvenir_slot(shelf, "Slot_Pen", "res://assets/sprites/props/souvenir_pen.png", Vector2(-34, -14), pen_placed)
	_ensure_souvenir_slot(shelf, "Slot_Key", "res://assets/sprites/props/souvenir_key.png", Vector2(0, -14), key_placed)
	_ensure_souvenir_slot(shelf, "Slot_Chalk", "res://assets/sprites/props/souvenir_chalk.png", Vector2(34, -14), chalk_placed)

func _ensure_souvenir_slot(parent: Node, node_name: String, tex_path: String, offset: Vector2, is_visible: bool) -> void:
	var slot_spr = parent.get_node_or_null(node_name) as Sprite2D
	if not slot_spr:
		slot_spr = Sprite2D.new()
		slot_spr.name = node_name
		slot_spr.position = offset
		slot_spr.z_index = 1
		if ResourceLoader.exists(tex_path):
			slot_spr.texture = load(tex_path)
		elif FileAccess.file_exists(ProjectSettings.globalize_path(tex_path)):
			var img = Image.load_from_file(ProjectSettings.globalize_path(tex_path))
			if img:
				slot_spr.texture = ImageTexture.create_from_image(img)
		parent.add_child(slot_spr)
	slot_spr.visible = is_visible
