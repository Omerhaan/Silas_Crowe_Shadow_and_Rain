class_name DialogueBox
extends PanelContainer

## Shared DialogueBox component for all dialogue text in Gölge ve Yağmur.
## Features:
##   - Framed 48x48 portrait on the left
##   - Speaker name label above dialogue text
##   - "İç Ses" badge for Silas internal thoughts
##   - Glitch silhouette icon for mysterious caller ("???")
##   - Pure text layout (hidden portrait & name) for SYSTEM / NARRATOR
##   - Spoiler-safe (protects secret names)

signal advance_requested

const NoirPalette = preload("res://scripts/core/noir_palette.gd")

@onready var portrait_container: Control = $Margin/HBox/PortraitBox
@onready var portrait_texture: TextureRect = $Margin/HBox/PortraitBox/PortraitTexture
@onready var portrait_border: ReferenceRect = $Margin/HBox/PortraitBox/PortraitBorder
@onready var speaker_name_label: Label = $Margin/HBox/ContentBox/Header/SpeakerName
@onready var inner_voice_badge: Label = $Margin/HBox/ContentBox/Header/InnerVoiceBadge
@onready var dialogue_label: Label = $Margin/HBox/ContentBox/DialogueLabel
@onready var advance_hint: Label = $Margin/HBox/ContentBox/AdvanceHint

var portraits = {
	"silas": "res://assets/portraits/silas.png",
	"silas_thoughtful": "res://assets/portraits/silas_thoughtful.png",
	"silas_suspicious": "res://assets/portraits/silas_suspicious.png",
	"silas_haunted": "res://assets/portraits/silas_haunted.png",
	"silas_angry": "res://assets/portraits/silas_angry.png",
	"silas_sad": "res://assets/portraits/silas_sad.png",
	"silas_shocked": "res://assets/portraits/silas_shocked.png",
	"silas_relieved": "res://assets/portraits/silas_relieved.png",
	"caller": "res://assets/portraits/caller_silhouette.png"
}

var _pages: Array[String] = []
var _current_page: int = 0
var type_tween: Tween = null

func _ready() -> void:
	if portrait_texture:
		portrait_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	gui_input.connect(_on_gui_input)
	if EventBus.has_signal("font_scale_changed"):
		EventBus.font_scale_changed.connect(apply_font_scale)
	apply_font_scale(GameState.get_font_scale())

func apply_font_scale(scale: String) -> void:
	var font_sz = 8
	var min_h = 56
	if scale == "small":
		font_sz = 6
		min_h = 48
	elif scale == "large":
		font_sz = 10
		min_h = 66
	else:
		font_sz = 8
		min_h = 56

	custom_minimum_size = Vector2(custom_minimum_size.x, min_h)
	if dialogue_label:
		dialogue_label.add_theme_font_size_override("font_size", font_sz)
	if speaker_name_label:
		speaker_name_label.add_theme_font_size_override("font_size", font_sz)
	if advance_hint:
		advance_hint.add_theme_font_size_override("font_size", max(5, font_sz - 2))

func _start_typewriter() -> void:
	if type_tween and type_tween.is_valid():
		type_tween.kill()
	dialogue_label.visible_ratio = 0.0
	var text_length = dialogue_label.text.length()
	var duration = clampf(text_length * 0.016, 0.25, 1.4)
	type_tween = create_tween()
	type_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)

func advance() -> void:
	# If typewriter is still typing, first click instantly finishes the current text
	if type_tween and type_tween.is_valid() and dialogue_label.visible_ratio < 0.95:
		type_tween.kill()
		dialogue_label.visible_ratio = 1.0
		return

	if _current_page + 1 < _pages.size():
		_current_page += 1
		dialogue_label.text = _pages[_current_page]
		_start_typewriter()
		advance_hint.text = "[Devam: Dokun / E] (%d/%d)" % [_current_page + 1, _pages.size()]
	else:
		advance_requested.emit()

func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		advance()
		accept_event()

func _paginate_text(full_text: String, max_chars: int = 180) -> Array[String]:
	var clean = full_text.strip_edges()
	if clean.length() <= max_chars:
		return [clean]

	var pages: Array[String] = []
	var paragraphs = clean.split("\n")
	var current_page = ""

	for para in paragraphs:
		var sentences = para.split(". ")
		for s_idx in range(sentences.size()):
			var s = sentences[s_idx].strip_edges()
			if s.is_empty():
				continue
			var s_full = s if s_idx == sentences.size() - 1 else s + "."
			if current_page.is_empty():
				current_page = s_full
			elif current_page.length() + s_full.length() + 1 <= max_chars:
				current_page += " " + s_full
			else:
				pages.append(current_page)
				current_page = s_full

		if not current_page.is_empty() and para != paragraphs[-1]:
			pages.append(current_page)
			current_page = ""

	if not current_page.is_empty():
		pages.append(current_page)

	return pages if not pages.is_empty() else [clean]

func _set_paginated_text(raw_text: String) -> void:
	_pages = _paginate_text(raw_text, 180)
	_current_page = 0
	dialogue_label.text = _pages[0] if not _pages.is_empty() else ""
	_start_typewriter()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	if _pages.size() > 1:
		advance_hint.visible = true
		advance_hint.text = ("[Continue: Tap / E] (1/%d)" if is_en else "[Devam: Dokun / E] (1/%d)") % _pages.size()
	else:
		advance_hint.visible = true
		advance_hint.text = "[Close: Tap / E]" if is_en else "[Kapat: Dokun / E]"

func _load_portrait_tex(path_or_id: String) -> Texture2D:
	if path_or_id.is_empty():
		return null

	var cid = GameState.current_case_id
	var id_clean = path_or_id.get_file().get_basename()
	var candidates: Array[String] = []

	if path_or_id.begins_with("res://"):
		candidates.append(path_or_id)

	if portraits.has(path_or_id):
		candidates.append(portraits[path_or_id])
	if portraits.has(id_clean):
		candidates.append(portraits[id_clean])

	# Priority 1: Current active case character assets
	if not cid.is_empty():
		candidates.append("res://cases/%s/assets/characters/%s.png" % [cid, id_clean])
		candidates.append("res://cases/%s/assets/characters/%s_preview.png" % [cid, id_clean])
		candidates.append("res://cases/%s/assets/characters/%s.jpg" % [cid, id_clean])

	# Priority 2: Other case modular character assets
	candidates.append("res://cases/case01/assets/characters/%s.png" % id_clean)
	candidates.append("res://cases/case01/assets/characters/%s_preview.png" % id_clean)
	candidates.append("res://cases/case02/assets/characters/%s.png" % id_clean)
	candidates.append("res://cases/case02/assets/characters/%s_preview.png" % id_clean)
	candidates.append("res://cases/case03/assets/characters/%s.png" % id_clean)
	candidates.append("res://cases/case03/assets/characters/%s_preview.png" % id_clean)

	# Priority 3: Global portraits / sprites (Silas, caller)
	candidates.append("res://assets/portraits/%s.png" % id_clean)
	candidates.append("res://assets/sprites/characters/%s.png" % id_clean)

	for p in candidates:
		if ResourceLoader.exists(p):
			var res = load(p)
			if res is Texture2D:
				return res
		var gp = ProjectSettings.globalize_path(p)
		if FileAccess.file_exists(gp):
			var img = Image.load_from_file(gp)
			if img:
				return ImageTexture.create_from_image(img)
	return null

func set_dialogue(speaker: String, text: String, emotion: String = "normal") -> void:
	var spk_clean = speaker.strip_edges()
	var spk_upper = spk_clean.to_upper()

	# Protection against accidental spoilers
	if ("ELIAS" in spk_upper or "ELIAS WREN" in spk_upper) and not GameState.case_solved:
		spk_clean = "???"
		spk_upper = "???"

	# 1. SYSTEM / NARRATOR / OBSERVATION
	if spk_upper in ["SYSTEM", "NARRATOR", "GÖZLEM", "ANLATICI", ""]:
		portrait_container.visible = false
		speaker_name_label.visible = false
		inner_voice_badge.visible = false
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 0.95))
		return

	# Show portrait and header for character speech
	portrait_container.visible = true
	speaker_name_label.visible = true

	# 2. INNER VOICE
	if spk_upper in ["INNER_VOICE", "İÇ SES", "IC SES", "SILAS_INNER"]:
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = loc_mgr and loc_mgr.get_locale() == "en"
		speaker_name_label.text = "SILAS CROWE" if is_en else "SİLAS CROWE"
		speaker_name_label.add_theme_color_override("font_color", Color(0.65, 0.82, 0.95, 1.0))
		inner_voice_badge.visible = true
		inner_voice_badge.text = "[INNER VOICE]" if is_en else "[İÇ SES]"

		var s_tex = _load_portrait_tex(portraits["silas_thoughtful"])
		if not s_tex:
			s_tex = _load_portrait_tex(portraits["silas"])
		portrait_texture.texture = s_tex

		# Ensure text has quotes and pale blue styling
		var formatted = text.strip_edges()
		if not formatted.begins_with("\""):
			formatted = "\"" + formatted
		if not formatted.ends_with("\""):
			formatted = formatted + "\""
		_set_paginated_text(formatted)
		dialogue_label.add_theme_color_override("font_color", Color(0.72, 0.84, 0.94, 1.0))
		return

	inner_voice_badge.visible = false

	# 3. CALLER
	if spk_upper in ["???", "CALLER", "ARAYAN"]:
		speaker_name_label.text = "???"
		speaker_name_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9, 1.0))
		portrait_texture.texture = _load_portrait_tex(portraits["caller"])
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1.0))
		return

	# 4. SILAS CROWE
	if spk_upper in ["SILAS", "SİLAS", "SILAS CROWE", "SİLAS CROWE"]:
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = loc_mgr and loc_mgr.get_locale() == "en"
		speaker_name_label.text = "SILAS CROWE" if is_en else "SİLAS CROWE"
		speaker_name_label.add_theme_color_override("font_color", Color(0.96, 0.89, 0.63, 1.0))
		var tex_key = "silas_" + emotion if portraits.has("silas_" + emotion) else "silas"
		portrait_texture.texture = _load_portrait_tex(portraits[tex_key])
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 5. DR. VICTOR HALE
	if "HALE" in spk_upper:
		speaker_name_label.text = "DR. VICTOR HALE"
		speaker_name_label.add_theme_color_override("font_color", Color(0.5, 0.85, 0.75, 1.0))
		var p_tex = _load_portrait_tex("hale_" + emotion) if emotion != "normal" and not emotion.is_empty() else null
		if not p_tex:
			p_tex = _load_portrait_tex("hale")
		portrait_texture.texture = p_tex
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 6. MARGARET DOYLE
	if "MARGARET" in spk_upper:
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = loc_mgr and loc_mgr.get_locale() == "en"
		speaker_name_label.text = "MARGARET DOYLE (HOUSEKEEPER)" if is_en else "MARGARET DOYLE (KÂHYA)"
		speaker_name_label.add_theme_color_override("font_color", Color(0.95, 0.8, 0.45, 1.0))
		var p_tex = _load_portrait_tex("margaret_" + emotion) if emotion != "normal" and not emotion.is_empty() else null
		if not p_tex:
			p_tex = _load_portrait_tex("margaret")
		portrait_texture.texture = p_tex
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 7. RAYMOND PIKE
	if "PIKE" in spk_upper:
		speaker_name_label.text = "RAYMOND PIKE"
		speaker_name_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.45, 1.0))
		var p_tex = _load_portrait_tex("pike_" + emotion) if emotion != "normal" and not emotion.is_empty() else null
		if not p_tex:
			p_tex = _load_portrait_tex("pike")
		portrait_texture.texture = p_tex
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 8. JULIAN HARLOW
	if "JULIAN" in spk_upper:
		speaker_name_label.text = "JULIAN HARLOW"
		speaker_name_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.85, 1.0))
		var p_tex = _load_portrait_tex("julian_" + emotion) if emotion != "normal" and not emotion.is_empty() else null
		if not p_tex:
			p_tex = _load_portrait_tex("julian")
		portrait_texture.texture = p_tex
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 9. CAPTAIN VANCE
	if "VANCE" in spk_upper:
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = loc_mgr and loc_mgr.get_locale() == "en"
		speaker_name_label.text = "CAPTAIN VANCE" if is_en else "KAPTAN VANCE"
		speaker_name_label.add_theme_color_override("font_color", Color(0.85, 0.65, 0.45, 1.0))
		portrait_texture.texture = _load_portrait_tex("vance")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 10. SEAN MORRIS
	if "MORRIS" in spk_upper:
		speaker_name_label.text = "SEAN MORRIS"
		speaker_name_label.add_theme_color_override("font_color", Color(0.65, 0.85, 0.7, 1.0))
		portrait_texture.texture = _load_portrait_tex("morris")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 11. OLD BORIS
	if "BORIS" in spk_upper:
		var loc_mgr = get_node_or_null("/root/LocalizationManager")
		var is_en = loc_mgr and loc_mgr.get_locale() == "en"
		speaker_name_label.text = "OLD BORIS" if is_en else "İHTİYAR BORIS"
		speaker_name_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9, 1.0))
		portrait_texture.texture = _load_portrait_tex("boris")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 12. BRANDT & CORLEY
	if "BRANDT" in spk_upper:
		speaker_name_label.text = "BRANDT"
		speaker_name_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.65, 1.0))
		portrait_texture.texture = _load_portrait_tex("brandt")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	if "CORLEY" in spk_upper:
		speaker_name_label.text = "CORLEY"
		speaker_name_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.7, 1.0))
		portrait_texture.texture = _load_portrait_tex("corley")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# 13. CASE 03 SUSPECTS (FINCH, ELENA, STERLING, PATCH, HENDERSON, SNIPER)
	if "FINCH" in spk_upper:
		speaker_name_label.text = "ARTHUR FINCH"
		speaker_name_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.65, 1.0))
		portrait_texture.texture = _load_portrait_tex("finch")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	if "ELENA" in spk_upper:
		speaker_name_label.text = "ELENA VANE"
		speaker_name_label.add_theme_color_override("font_color", Color(0.95, 0.7, 0.8, 1.0))
		portrait_texture.texture = _load_portrait_tex("elena")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	if "STERLING" in spk_upper:
		speaker_name_label.text = "CYRIL STERLING"
		speaker_name_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.95, 1.0))
		portrait_texture.texture = _load_portrait_tex("sterling")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	if "PATCH" in spk_upper:
		speaker_name_label.text = "BARNABY 'PATCH' MILLER"
		speaker_name_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.7, 1.0))
		portrait_texture.texture = _load_portrait_tex("patch")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	if "HENDERSON" in spk_upper:
		speaker_name_label.text = "ARCHIE HENDERSON"
		speaker_name_label.add_theme_color_override("font_color", Color(0.85, 0.7, 0.6, 1.0))
		portrait_texture.texture = _load_portrait_tex("henderson")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	if "TETİKÇİ" in spk_upper or "SNIPER" in spk_upper:
		speaker_name_label.text = "GÖLGEDEKİ TETİKÇİ"
		speaker_name_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 1.0))
		portrait_texture.texture = _load_portrait_tex("unknown_sniper")
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# Fallback: check dynamic modular portrait
	var spk_key = spk_clean.to_lower()
	var dyn_p = _load_portrait_tex(spk_key)
	if dyn_p:
		speaker_name_label.text = spk_clean
		speaker_name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
		portrait_texture.texture = dyn_p
		portrait_container.visible = true
		_set_paginated_text(text)
		dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))
		return

	# Fallback without portrait
	speaker_name_label.text = spk_clean
	speaker_name_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7, 1.0))
	portrait_container.visible = false
	_set_paginated_text(text)
	dialogue_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))

