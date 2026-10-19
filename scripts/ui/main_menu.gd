extends Control

## Main Menu / Title Screen for Gölge ve Yağmur.
## Features:
## - New Game: starts Silas in his office; phone rings; answering triggers call dialogue & animation.
## - Continue: enables if savegame exists and loads directly to last saved room.
## - Settings: opens SettingsModal for audio & subtitles.
## - Quit: exits application.

signal game_started
signal game_continued
signal case_selected(case_id: String)

@onready var new_game_btn: Button = $Panel/VBoxContainer/NewGameBtn
@onready var chapter_select_btn: Button = $Panel/VBoxContainer/ChapterSelectBtn
@onready var continue_btn: Button = $Panel/VBoxContainer/ContinueBtn
@onready var settings_btn: Button = $Panel/VBoxContainer/SettingsBtn
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitBtn
@onready var settings_modal: Control = $SettingsModal
@onready var case_select_modal: Control = $CaseSelectModal
@onready var save_info_lbl: Label = $Panel/SaveInfoLabel

func _ready() -> void:
	visible = true
	new_game_btn.pressed.connect(_on_new_game_pressed)
	chapter_select_btn.pressed.connect(_on_chapter_select_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	if case_select_modal:
		case_select_modal.case_selected.connect(_on_case_modal_selected)

	if EventBus.has_signal("language_changed"):
		EventBus.language_changed.connect(func(_loc): _check_save_status())

	_check_save_status()

func _tr_fallback(key: String, default_text: String) -> String:
	var val = tr(key)
	if val == key or val.strip_edges() == "":
		return default_text
	return val

func _check_save_status() -> void:
	SaveSystem.sync_case_progress()
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"

	new_game_btn.text = _tr_fallback("UI_NEW_GAME", "Yeni Oyun")
	chapter_select_btn.text = _tr_fallback("UI_CHAPTER_SELECT", "Bölüm Seçimi")
	settings_btn.text = _tr_fallback("UI_SETTINGS", "Ayarlar")
	quit_btn.text = _tr_fallback("UI_QUIT", "Çıkış")

	var continue_text = _tr_fallback("UI_CONTINUE", "Devam Et")
	if SaveSystem.has_save_file():
		continue_btn.disabled = false
		continue_btn.text = continue_text
		if "case01" in GameState.completed_cases:
			save_info_lbl.text = "Chapter 1 Completed. Chapter 2 Unlocked!" if is_en else "Bölüm 1 Tamamlandı. Bölüm 2 Açık!"
		else:
			save_info_lbl.text = "Saved investigation: Chapter 1 - The Dark Manor" if is_en else "Kayıtlı soruşturma: Bölüm 1 - Karanlık Malikâne"
	else:
		continue_btn.disabled = true
		continue_btn.text = continue_text + (" (No Save)" if is_en else " (Kayıt Yok)")
		save_info_lbl.text = "Yeni bir soruşturmaya başlayın."

func open_menu() -> void:
	visible = true
	_check_save_status()

func close_menu() -> void:
	visible = false

func _on_chapter_select_pressed() -> void:
	case_select_modal.open_modal()

func _on_case_modal_selected(case_id: String) -> void:
	close_menu()
	case_selected.emit(case_id)

func _on_new_game_pressed() -> void:
	# Reset game progression for a clean start
	GameState.discovered_evidence.clear()
	GameState.collected_statements.clear()
	GameState.unlocked_deductions.clear()
	GameState.inspected_objects.clear()
	GameState.accusation_chances_left = 3
	GameState.case_solved = false
	GameState.selected_souvenir = ""
	GameState.flags.clear()
	GameState.inventory_items.clear()
	GameState.intro_seen = false
	GameState.current_room_id = "silas_office"
	
	close_menu()
	game_started.emit()

func _on_continue_pressed() -> void:
	if SaveSystem.has_save_file():
		var success = SaveSystem.load_game()
		if success:
			close_menu()
			game_continued.emit()
		else:
			save_info_lbl.text = "Kayıt dosyası yüklenemedi!"
	else:
		continue_btn.disabled = true

func _on_settings_pressed() -> void:
	settings_modal.open_settings()

func _on_quit_pressed() -> void:
	get_tree().quit()
