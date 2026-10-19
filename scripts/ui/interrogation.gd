extends Control

## Interrogation (Sorgulama) Interface.
## Allows questioning suspects with topic buttons and presenting evidence (İtiraz / Objection).

const NoirPalette = preload("res://scripts/core/noir_palette.gd")

@onready var name_label: Label = $InterrogationPanel/HeaderBox/NameLabel
@onready var role_label: Label = $InterrogationPanel/HeaderBox/RoleLabel
@onready var portrait_rect: ColorRect = $InterrogationPanel/PortraitBox/PortraitRect
@onready var portrait_texture: TextureRect = $InterrogationPanel/PortraitBox/PortraitTexture
@onready var dialogue_scroll: ScrollContainer = $InterrogationPanel/DialogueScroll
@onready var dialogue_text: Label = $InterrogationPanel/DialogueScroll/DialogueLabel
@onready var topics_scroll: ScrollContainer = $InterrogationPanel/TopicsScroll
@onready var topics_container: VBoxContainer = $InterrogationPanel/TopicsScroll/TopicsList
@onready var present_evidence_btn: Button = $InterrogationPanel/ActionButtons/PresentEvidenceBtn
@onready var exit_btn: Button = $InterrogationPanel/ActionButtons/ExitBtn

# Evidence selector sub-panel
@onready var evidence_panel: Panel = $InterrogationPanel/EvidencePanel
@onready var evidence_list_container: VBoxContainer = $InterrogationPanel/EvidencePanel/Scroll/EvidenceList
@onready var close_evidence_btn: Button = $InterrogationPanel/EvidencePanel/CloseEvidenceBtn

var current_suspect_id: String = ""
var current_dialogue_data: Dictionary = {}
var _typewriter_tween: Tween = null

func _ready() -> void:
	visible = false
	evidence_panel.visible = false
	exit_btn.pressed.connect(_on_exit_pressed)
	present_evidence_btn.pressed.connect(_toggle_evidence_picker)
	close_evidence_btn.pressed.connect(func(): evidence_panel.visible = false)
	for b in [exit_btn, present_evidence_btn, close_evidence_btn]:
		if b:
			b.focus_mode = Control.FOCUS_NONE
	EventBus.interrogation_requested.connect(open_interrogation)
	if EventBus.has_signal("font_scale_changed"):
		EventBus.font_scale_changed.connect(apply_font_scale)
	apply_font_scale(GameState.get_font_scale())

func apply_font_scale(scale: String) -> void:
	var font_dialogue = 8
	var font_topic = 6
	var font_name = 8
	var font_role = 6
	if scale == "small":
		font_dialogue = 7
		font_topic = 5
		font_name = 7
		font_role = 5
	elif scale == "large":
		font_dialogue = 10
		font_topic = 7
		font_name = 9
		font_role = 7

	if dialogue_text:
		dialogue_text.add_theme_font_size_override("font_size", font_dialogue)
	if name_label:
		name_label.add_theme_font_size_override("font_size", font_name)
	if role_label:
		role_label.add_theme_font_size_override("font_size", font_role)
	if exit_btn:
		exit_btn.add_theme_font_size_override("font_size", font_topic)
	if present_evidence_btn:
		present_evidence_btn.add_theme_font_size_override("font_size", font_topic)
	if topics_container:
		for child in topics_container.get_children():
			if child is Button:
				child.add_theme_font_size_override("font_size", font_topic)

func open_interrogation(suspect_id: String) -> void:
	current_suspect_id = suspect_id
	GameState.can_player_move = false
	visible = true
	evidence_panel.visible = false
	if dialogue_scroll:
		dialogue_scroll.scroll_vertical = 0
	if topics_scroll:
		topics_scroll.scroll_vertical = 0

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	var suspect_data = GameState.get_suspect_data(suspect_id)
	name_label.text = suspect_data.get("ad", "Şüpheli")
	var initial_greeting = "\"I await your questions, detective.\"" if is_en else "\"Sorularınızı bekliyorum dedektif.\""
	if current_suspect_id == "elena" and not GameState.flags.get("elena_calmed", false):
		initial_greeting = "\"Elena is trembling in panic, short of breath: 'I can't breathe... That gunshot... Dalton... I can't speak!' (She needs soothing smelling salts from the ticket booth to calm down.)\"" if is_en else "\"Elena panik içinde titriyor, nefes nefese: 'Nefes alamıyorum... O kurşun... Dalton... Konuşamam!' (Kendine gelebilmesi için gişeden yatıştırıcı bir koklama tuzu gerekiyor.)\""
	_display_dialogue(initial_greeting)

	exit_btn.text = "Leave" if is_en else "Ayrıl"
	present_evidence_btn.text = "Present Evidence" if is_en else "İtiraz Et / Kanıt Sun"

	# Setup 48x48 portrait texture from AssetManager
	var portrait_id = "portrait_" + current_suspect_id
	var tex: Texture2D = AssetManager.get_texture(portrait_id)
	if not tex:
		var p_candidates = [
			"res://cases/%s/assets/characters/%s.png" % [GameState.current_case_id, current_suspect_id],
			"res://cases/%s/assets/characters/%s.jpg" % [GameState.current_case_id, current_suspect_id],
			"res://assets/portraits/%s.png" % current_suspect_id,
			"res://assets/portraits/%s.jpg" % current_suspect_id
		]
		for p_path in p_candidates:
			if ResourceLoader.exists(p_path):
				tex = load(p_path)
				break
			var gp = ProjectSettings.globalize_path(p_path)
			if FileAccess.file_exists(gp):
				var img = Image.load_from_file(gp)
				if img:
					tex = ImageTexture.create_from_image(img)
					break
	if tex and portrait_texture:
		portrait_texture.texture = tex
		portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		portrait_texture.custom_minimum_size = Vector2(48, 48)
		portrait_texture.visible = true

	set_portrait_mood("normal")

	match current_suspect_id:
		"margaret": portrait_rect.color = NoirPalette.GREEN_DARK
		"julian": portrait_rect.color = NoirPalette.WOOD_DARK
		"hale": portrait_rect.color = NoirPalette.NIGHT_NAVY_DEEP
		"pike": portrait_rect.color = NoirPalette.CRIMSON_DEEP

	_load_dialogue_topics()

func _load_dialogue_topics() -> void:
	for c in topics_container.get_children():
		topics_container.remove_child(c)
		c.queue_free()

	if topics_scroll:
		topics_scroll.scroll_vertical = 0

	var path = "res://cases/%s/data/dialogues/%s.json" % [GameState.current_case_id, current_suspect_id]
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(ProjectSettings.globalize_path(path)):
		path = "res://data/cases/%s/dialogues/%s.json" % [GameState.current_case_id, current_suspect_id]
	current_dialogue_data = GameState._load_json_file(path)
	var topics: Array = current_dialogue_data.get("topics", [])
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	var font_sz = 5 if GameState.get_font_scale() == "small" else (7 if GameState.get_font_scale() == "large" else 6)
	for topic in topics:
		var hide_flag = topic.get("hide_if_flag", "")
		if hide_flag != "" and GameState.flags.get(hide_flag, false):
			continue

		var hide_unmet = topic.get("hide_if_unmet", false)
		if hide_unmet:
			var r_item = topic.get("required_item", "")
			var r_ev = topic.get("required_evidence", "")
			var r_flg = topic.get("required_flag", "")
			if r_item != "" and not GameState.has_item(r_item):
				continue
			if r_ev != "" and not GameState.has_evidence(r_ev):
				continue
			if r_flg != "" and not GameState.flags.get(r_flg, false):
				continue

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 24)
		btn.add_theme_font_size_override("font_size", font_sz)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = topic.get("label_en", topic.get("label", "")) if is_en else topic.get("label", "")
		btn.pressed.connect(func(): _on_topic_selected(topic))
		topics_container.add_child(btn)

func _display_dialogue(text: String) -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()

	if dialogue_scroll:
		dialogue_scroll.scroll_vertical = 0

	dialogue_text.text = text
	dialogue_text.visible_ratio = 0.0
	var char_count = text.length()
	var duration = clampf(char_count * 0.016, 0.25, 1.2)
	_typewriter_tween = create_tween()
	_typewriter_tween.tween_property(dialogue_text, "visible_ratio", 1.0, duration)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if evidence_panel and evidence_panel.visible:
				evidence_panel.visible = false
			else:
				_on_exit_pressed()
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_E or event.keycode == KEY_SPACE):
			if evidence_panel and evidence_panel.visible:
				evidence_panel.visible = false
				get_viewport().set_input_as_handled()
			elif _typewriter_tween and _typewriter_tween.is_valid() and dialogue_text.visible_ratio < 1.0:
				_typewriter_tween.kill()
				dialogue_text.visible_ratio = 1.0
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		if _typewriter_tween and _typewriter_tween.is_valid() and dialogue_text.visible_ratio < 1.0:
			_typewriter_tween.kill()
			dialogue_text.visible_ratio = 1.0
			get_viewport().set_input_as_handled()

func _on_topic_selected(topic: Dictionary) -> void:
	if topic.get("id") == "present_evidence":
		_toggle_evidence_picker()
		return

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	var condition_met = true
	var req_ev = topic.get("required_evidence", "")
	var alt_req_ev = topic.get("alt_required_evidence", "")
	var req_flag = topic.get("required_flag", "")
	var alt_req_flag = topic.get("alt_required_flag", "")
	var req_item = topic.get("required_item", "")

	if req_ev != "" and not GameState.has_evidence(req_ev):
		if alt_req_flag != "" and GameState.flags.get(alt_req_flag, false):
			pass
		else:
			condition_met = false

	if req_flag != "" and not GameState.flags.get(req_flag, false):
		if alt_req_ev != "" and GameState.has_evidence(alt_req_ev):
			pass
		elif alt_req_flag != "" and GameState.flags.get(alt_req_flag, false):
			pass
		else:
			condition_met = false

	if req_item != "" and not GameState.has_item(req_item):
		condition_met = false

	if not condition_met:
		var locked_resp = topic.get("locked_response_en", topic.get("locked_response", "")) if is_en else topic.get("locked_response", "")
		if locked_resp != "":
			_display_dialogue(locked_resp)
			var locked_mood = topic.get("locked_emotion", "nervous")
			set_portrait_mood(locked_mood)
			return

	var resp = topic.get("response_en", topic.get("response", "")) if is_en else topic.get("response", "")
	_display_dialogue(resp)

	var mood = topic.get("emotion", "nervous" if topic.has("statement_yield") and topic["statement_yield"] != "" else "normal")
	set_portrait_mood(mood)

	var stmt = topic.get("statement_yield_en", topic.get("statement_yield", "")) if is_en else topic.get("statement_yield", "")
	if stmt != "":
		GameState.add_statement(current_suspect_id, stmt)

	var item_yield = topic.get("item_yield", "")
	if item_yield != "":
		var item_name = topic.get("item_yield_name_en", topic.get("item_yield_name", item_yield)) if is_en else topic.get("item_yield_name", item_yield)
		GameState.add_item(item_yield, item_name)

	var set_flag_id = topic.get("set_flag", "")
	if set_flag_id != "":
		GameState.flags[set_flag_id] = true

	if topic.get("refresh_topics", false):
		_load_dialogue_topics()

func set_portrait_mood(mood: String) -> void:
	if not portrait_texture:
		return
	# Check if asset manifest has an emotion-specific portrait
	var mood_id = "portrait_%s_%s" % [current_suspect_id, mood]
	var mood_tex = AssetManager.get_texture(mood_id)
	if not mood_tex:
		var p_candidates = [
			"res://cases/%s/assets/characters/%s_%s.png" % [GameState.current_case_id, current_suspect_id, mood],
			"res://cases/case01/assets/characters/%s_%s.png" % [current_suspect_id, mood],
			"res://assets/portraits/%s_%s.png" % [current_suspect_id, mood]
		]
		for p_path in p_candidates:
			if ResourceLoader.exists(p_path):
				mood_tex = load(p_path)
				break
			var gp = ProjectSettings.globalize_path(p_path)
			if FileAccess.file_exists(gp):
				var img = Image.load_from_file(gp)
				if img:
					mood_tex = ImageTexture.create_from_image(img)
					break
	if not mood_tex and (mood == "normal" or mood == ""):
		var base_candidates = [
			"res://cases/%s/assets/characters/%s.png" % [GameState.current_case_id, current_suspect_id],
			"res://cases/case01/assets/characters/%s.png" % current_suspect_id,
			"res://assets/portraits/%s.png" % current_suspect_id
		]
		for p_path in base_candidates:
			if ResourceLoader.exists(p_path):
				mood_tex = load(p_path)
				break
			var gp = ProjectSettings.globalize_path(p_path)
			if FileAccess.file_exists(gp):
				var img = Image.load_from_file(gp)
				if img:
					mood_tex = ImageTexture.create_from_image(img)
					break
	if mood_tex:
		portrait_texture.texture = mood_tex
	match mood:
		"nervous":
			portrait_texture.modulate = Color(0.92, 0.88, 1.0, 1.0)
		"defensive", "angry":
			portrait_texture.modulate = Color(1.0, 0.88, 0.88, 1.0)
		_:
			portrait_texture.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _toggle_evidence_picker() -> void:
	evidence_panel.visible = !evidence_panel.visible
	if evidence_panel.visible:
		_populate_evidence_picker()

func _populate_evidence_picker() -> void:
	for c in evidence_list_container.get_children():
		evidence_list_container.remove_child(c)
		c.queue_free()

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")
	close_evidence_btn.text = "Close" if is_en else "Kapat"

	var discovered = GameState.discovered_evidence
	if discovered.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.add_theme_font_size_override("font_size", 6)
		empty_lbl.text = "No evidence to present." if is_en else "Sunulabilecek bir kanıt yok."
		evidence_list_container.add_child(empty_lbl)
		return

	var font_sz = 5 if GameState.get_font_scale() == "small" else (7 if GameState.get_font_scale() == "large" else 6)
	for ev_id in discovered:
		var ev_data = GameState.get_evidence_data(ev_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 24)
		btn.add_theme_font_size_override("font_size", font_sz)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = "[%s] %s" % [ev_id, ev_data.get("ad", "")]
		btn.pressed.connect(func(): _present_evidence_to_suspect(ev_id))
		evidence_list_container.add_child(btn)

func _present_evidence_to_suspect(ev_id: String) -> void:
	evidence_panel.visible = false
	var reactions: Dictionary = current_dialogue_data.get("evidence_reactions", {})
	var r_data = reactions.get(ev_id, reactions.get("default", {}))

	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = (loc_mgr and loc_mgr.get_locale() == "en")

	var def_reply = "I know nothing about that, Crowe." if is_en else "Bunun hakkında bir şey bilmiyorum."
	var response_text = r_data.get("response_en", r_data.get("response", def_reply)) if is_en else r_data.get("response", def_reply)
	var statement_text = r_data.get("statement_en", r_data.get("statement", "")) if is_en else r_data.get("statement", "")
	var emotion = r_data.get("emotion", "normal")

	var prompt_notice = "\n\n[Continue: E / Space / Click]" if is_en else "\n\n[Devam: E / Boşluk / Tıkla]"
	_display_dialogue(response_text + prompt_notice)
	set_portrait_mood(emotion)
	if statement_text != "":
		AudioManager.play_sfx("objection")
		GameState.add_statement(current_suspect_id, statement_text)
		if portrait_texture:
			var orig_x = portrait_texture.position.x
			var sh_tween = create_tween()
			sh_tween.tween_property(portrait_texture, "position:x", orig_x - 3.0, 0.04)
			sh_tween.tween_property(portrait_texture, "position:x", orig_x + 3.0, 0.04)
			sh_tween.tween_property(portrait_texture, "position:x", orig_x, 0.04)
	else:
		AudioManager.play_sfx("click")

	var set_flag_id = r_data.get("set_flag", "")
	if set_flag_id != "":
		GameState.flags[set_flag_id] = true

	if r_data.get("refresh_topics", false):
		_load_dialogue_topics()

func _on_exit_pressed() -> void:
	if _typewriter_tween and _typewriter_tween.is_valid():
		_typewriter_tween.kill()
	dialogue_text.visible_ratio = 1.0
	if dialogue_scroll:
		dialogue_scroll.scroll_vertical = 0
	if topics_scroll:
		topics_scroll.scroll_vertical = 0
	visible = false
	evidence_panel.visible = false
	set_portrait_mood("normal")
	if get_viewport().gui_get_focus_owner():
		get_viewport().gui_get_focus_owner().release_focus()
	GameState.can_player_move = true
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].has_method("reset_interaction_state"):
		players[0].reset_interaction_state()
	EventBus.interrogation_finished.emit()
