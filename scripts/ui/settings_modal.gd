extends Control

## Settings Modal (Ayarlar Menüsü).
## Controls Master Volume, BGM Music, Ambiance (Rain), SFX, Fullscreen, Subtitles, Language, Font Scale, and Intro Replay.

@onready var title_lbl: Label = $Panel/Title
@onready var master_slider: HSlider = $Panel/VBoxContainer/MasterBox/MasterSlider
@onready var master_val_lbl: Label = $Panel/VBoxContainer/MasterBox/MasterVal
@onready var master_lbl: Label = $Panel/VBoxContainer/MasterBox/Label
@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicBox/MusicSlider
@onready var music_val_lbl: Label = $Panel/VBoxContainer/MusicBox/MusicVal
@onready var music_lbl: Label = $Panel/VBoxContainer/MusicBox/Label
@onready var ambiance_slider: HSlider = $Panel/VBoxContainer/AmbianceBox/AmbianceSlider
@onready var ambiance_val_lbl: Label = $Panel/VBoxContainer/AmbianceBox/AmbianceVal
@onready var ambiance_lbl: Label = $Panel/VBoxContainer/AmbianceBox/Label
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SfxBox/SfxSlider
@onready var sfx_val_lbl: Label = $Panel/VBoxContainer/SfxBox/SfxVal
@onready var sfx_lbl: Label = $Panel/VBoxContainer/SfxBox/Label
@onready var subtitle_lbl: Label = $Panel/VBoxContainer/TogglesRow/SubtitleBox/Label
@onready var subtitle_btn: Button = $Panel/VBoxContainer/TogglesRow/SubtitleBox/SubtitleBtn
@onready var fullscreen_lbl: Label = $Panel/VBoxContainer/TogglesRow/FullscreenBox/Label
@onready var fullscreen_btn: Button = $Panel/VBoxContainer/TogglesRow/FullscreenBox/FullscreenBtn
@onready var language_box_lbl: Label = get_node_or_null("Panel/VBoxContainer/LanguageBox/Label")
@onready var language_btn: Button = get_node_or_null("Panel/VBoxContainer/LanguageBox/LanguageBtn")
@onready var font_size_lbl: Label = get_node_or_null("Panel/VBoxContainer/FontSizeBox/Label")
@onready var font_size_btn: Button = get_node_or_null("Panel/VBoxContainer/FontSizeBox/FontSizeBtn")
@onready var replay_intro_btn: Button = $Panel/VBoxContainer/ReplayIntroBtn
@onready var close_btn: Button = $Panel/CloseBtn
@onready var save_btn: Button = $Panel/SaveBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_settings)
	save_btn.pressed.connect(_on_save_pressed)

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	ambiance_slider.value_changed.connect(_on_ambiance_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	subtitle_btn.pressed.connect(_on_subtitle_toggle)
	fullscreen_btn.pressed.connect(_on_fullscreen_toggle)
	if language_btn:
		language_btn.pressed.connect(_on_language_toggle)
	if font_size_btn:
		font_size_btn.pressed.connect(_on_font_size_toggle)
	if replay_intro_btn:
		replay_intro_btn.pressed.connect(_on_replay_intro_pressed)

	if EventBus.has_signal("language_changed"):
		EventBus.language_changed.connect(func(_loc): _update_all_labels())
	
	_update_all_labels()

func open_settings() -> void:
	visible = true
	# Initialize sliders from AudioManager
	master_slider.value = AudioManager.master_volume * 100.0
	music_slider.value = AudioManager.music_volume * 100.0
	ambiance_slider.value = AudioManager.ambiance_volume * 100.0
	sfx_slider.value = AudioManager.sfx_volume * 100.0
	_update_val_labels()
	_update_subtitle_button()
	_update_fullscreen_button()
	_update_language_button()
	_update_font_size_button()
	_update_all_labels()

func close_settings() -> void:
	visible = false

func _on_save_pressed() -> void:
	AudioManager.save_settings()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	var toast = "Settings saved successfully." if is_en else "Ayarlar kaydedildi."
	EventBus.toast_requested.emit(toast)
	close_settings()

func _on_master_changed(val: float) -> void:
	AudioManager.set_master_volume(val / 100.0)
	_update_val_labels()

func _on_music_changed(val: float) -> void:
	AudioManager.set_music_volume(val / 100.0)
	_update_val_labels()

func _on_ambiance_changed(val: float) -> void:
	AudioManager.set_ambiance_volume(val / 100.0)
	_update_val_labels()

func _on_sfx_changed(val: float) -> void:
	AudioManager.set_sfx_volume(val / 100.0)
	_update_val_labels()
	AudioManager.play_sfx("click")

func _on_subtitle_toggle() -> void:
	AudioManager.subtitles_enabled = !AudioManager.subtitles_enabled
	_update_subtitle_button()
	AudioManager.play_sfx("click")

func _on_fullscreen_toggle() -> void:
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_update_fullscreen_button()
	AudioManager.play_sfx("click")

func _on_font_size_toggle() -> void:
	var cur = GameState.get_font_scale()
	var nxt = "medium"
	if cur == "small":
		nxt = "medium"
	elif cur == "medium":
		nxt = "large"
	else:
		nxt = "small"
	
	GameState.set_font_scale(nxt)
	_update_font_size_button()
	AudioManager.play_sfx("click")
	
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	var names_tr = {"small": "Küçük", "medium": "Orta", "large": "Büyük"}
	var names_en = {"small": "Small", "medium": "Medium", "large": "Large"}
	var display_name = names_en.get(nxt, nxt) if is_en else names_tr.get(nxt, nxt)
	var toast = "Font Size: " + display_name if is_en else "Yazı Boyutu: " + display_name
	EventBus.toast_requested.emit(toast)

func _update_val_labels() -> void:
	master_val_lbl.text = "%%%d" % int(master_slider.value)
	music_val_lbl.text = "%%%d" % int(music_slider.value)
	ambiance_val_lbl.text = "%%%d" % int(ambiance_slider.value)
	sfx_val_lbl.text = "%%%d" % int(sfx_slider.value)

func _update_subtitle_button() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	if AudioManager.subtitles_enabled:
		subtitle_btn.text = "ON" if is_en else "AÇIK"
		subtitle_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1.0))
	else:
		subtitle_btn.text = "OFF" if is_en else "KAPALI"
		subtitle_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4, 1.0))

func _update_fullscreen_button() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	var mode = DisplayServer.window_get_mode()
	var is_fs = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if is_fs:
		fullscreen_btn.text = "ON" if is_en else "AÇIK"
		fullscreen_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5, 1.0))
	else:
		fullscreen_btn.text = "OFF" if is_en else "KAPALI"
		fullscreen_btn.add_theme_color_override("font_color", Color(0.8, 0.4, 0.4, 1.0))

func _update_language_button() -> void:
	if not language_btn:
		return
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var loc = loc_mgr.get_locale() if loc_mgr else "tr"
	if loc == "tr":
		language_btn.text = "Türkçe [TR]"
	else:
		language_btn.text = "English [EN]"

func _update_font_size_button() -> void:
	if not font_size_btn:
		return
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	var cur = GameState.get_font_scale()
	var names_tr = {"small": "Küçük", "medium": "Orta", "large": "Büyük"}
	var names_en = {"small": "Small", "medium": "Medium", "large": "Large"}
	font_size_btn.text = names_en.get(cur, "Medium") if is_en else names_tr.get(cur, "Orta")

func _update_all_labels() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	if title_lbl:
		title_lbl.text = "SETTINGS" if is_en else "AYARLAR"
	if master_lbl:
		master_lbl.text = "Master Volume:" if is_en else "Ana Ses:"
	if music_lbl:
		music_lbl.text = "Noir Piano BGM:" if is_en else "Noir Piyano BGM:"
	if ambiance_lbl:
		ambiance_lbl.text = "Rain/Ambiance:" if is_en else "Yağmur/Ambiyans:"
	if sfx_lbl:
		sfx_lbl.text = "Sound Effects:" if is_en else "Ses Efektleri:"
	if subtitle_lbl:
		subtitle_lbl.text = "Subtitles:" if is_en else "Altyazılar:"
	if fullscreen_lbl:
		fullscreen_lbl.text = "Fullscreen:" if is_en else "Tam Ekran:"
	if language_box_lbl:
		language_box_lbl.text = "Language / Dil:" if is_en else "Dil / Language:"
	if font_size_lbl:
		font_size_lbl.text = "Font Size:" if is_en else "Yazı Boyutu:"
	if replay_intro_btn:
		replay_intro_btn.text = "Replay Intro Cutscene" if is_en else "Giriş Hikayesini Tekrar İzle"
	if save_btn:
		save_btn.text = "Save" if is_en else "Kaydet"
		
	_update_subtitle_button()
	_update_fullscreen_button()
	_update_language_button()
	_update_font_size_button()

func _on_language_toggle() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	if loc_mgr:
		loc_mgr.toggle_language()
	_update_all_labels()
	AudioManager.play_sfx("click")
	var new_loc = loc_mgr.get_locale() if loc_mgr else "tr"
	var msg = "Language set to English." if new_loc == "en" else "Dil: Türkçe olarak ayarlandı."
	EventBus.toast_requested.emit(msg)

func _on_replay_intro_pressed() -> void:
	close_settings()
	EventBus.intro_replay_requested.emit()
