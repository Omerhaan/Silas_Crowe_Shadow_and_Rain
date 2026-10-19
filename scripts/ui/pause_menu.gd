extends Control

## Pause Menu (Duraklatma Menüsü).
## Triggered by ESC or HUD Menu button.
## Allows Resume, Save Game, Load Game, Restart Case, and Quit.

@onready var resume_btn: Button = $Panel/VBoxContainer/ResumeBtn
@onready var save_btn: Button = $Panel/VBoxContainer/SaveBtn
@onready var load_btn: Button = $Panel/VBoxContainer/LoadBtn
@onready var settings_btn: Button = $Panel/VBoxContainer/SettingsBtn
@onready var restart_btn: Button = $Panel/VBoxContainer/RestartBtn
@onready var quit_btn: Button = $Panel/VBoxContainer/QuitBtn
@onready var title_lbl: Label = $Panel/Title
@onready var status_lbl: Label = $Panel/StatusLabel
@onready var settings_modal: Control = $SettingsModal

var menu_cooldown: float = 0.0

func _ready() -> void:
	visible = false
	InputManager.menu_pressed.connect(_on_menu_pressed)
	resume_btn.pressed.connect(close_menu)
	save_btn.pressed.connect(_on_save_pressed)
	load_btn.pressed.connect(_on_load_pressed)
	settings_btn.pressed.connect(func(): settings_modal.open_settings())
	restart_btn.pressed.connect(_on_restart_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	if EventBus.has_signal("language_changed"):
		EventBus.language_changed.connect(func(_loc): _update_labels())

	for btn in [resume_btn, save_btn, load_btn, settings_btn, restart_btn, quit_btn]:
		if btn:
			btn.focus_mode = Control.FOCUS_NONE

	_update_labels()

func _update_labels() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	if title_lbl:
		title_lbl.text = "PAUSED" if is_en else "DURAKLATILDI"
	if resume_btn:
		resume_btn.text = "Resume" if is_en else "Oyuna Dön"
	if save_btn:
		save_btn.text = "Save Game" if is_en else "Oyunu Kaydet"
	if load_btn:
		load_btn.text = "Load Game" if is_en else "Kayıt Yükle"
	if settings_btn:
		settings_btn.text = "Settings" if is_en else "Ayarlar"
	if restart_btn:
		restart_btn.text = "Restart Case" if is_en else "Vakayı Yeniden Başlat"
	if quit_btn:
		quit_btn.text = "Return to Menu" if is_en else "Ana Menüye Dön"

func _process(delta: float) -> void:
	if menu_cooldown > 0.0:
		menu_cooldown -= delta

func _on_menu_pressed() -> void:
	if menu_cooldown > 0.0:
		return

	# If settings modal is open inside pause menu, ESC closes settings first
	if settings_modal and is_instance_valid(settings_modal) and settings_modal.is_visible_in_tree():
		if settings_modal.has_method("close_settings"):
			settings_modal.close_settings()
		else:
			settings_modal.visible = false
		return

	if visible:
		close_menu()
		return

	# If currently interacting with an item, inspecting, or in a modal/dialogue, close it first.
	if _try_close_active_interaction():
		return

	open_menu()

func _find_active_node(group_name: String, node_name: String) -> Node:
	var tree = get_tree()
	if not tree:
		return null
	for n in tree.get_nodes_in_group(group_name):
		if is_instance_valid(n) and n.is_inside_tree() and n.is_visible_in_tree() and not n.is_queued_for_deletion():
			return n
	var found = tree.root.find_child(node_name, true, false)
	if found and is_instance_valid(found) and found.is_visible_in_tree() and not found.is_queued_for_deletion():
		return found
	return null

func _try_close_active_interaction() -> bool:
	var tree = get_tree()
	if not tree:
		return false

	# 1. Settings modal inside pause menu
	if settings_modal and is_instance_valid(settings_modal) and settings_modal.is_visible_in_tree():
		if settings_modal.has_method("close_settings"):
			settings_modal.close_settings()
		else:
			settings_modal.visible = false
		return true

	# 2. Minigame: Light-Range Board (Işık ve Menzil Panosu)
	var lrm = _find_active_node("light_range_modal", "LightRangeModal")
	if lrm:
		if lrm.has_method("close_board"):
			lrm.close_board()
		else:
			lrm.visible = false
			GameState.can_player_move = true
		return true

	# 3. Password Modal: Harlow's Secret Wall Safe (SafeDialModal)
	var sdm = _find_active_node("safe_dial_modal", "SafeDialModal")
	if sdm:
		if sdm.has_method("close_modal"):
			sdm.close_modal()
		else:
			sdm.visible = false
			GameState.can_player_move = true
		return true

	# 4. Password Modal: Crane Hoist Breaker (CraneWinchModal)
	var cwm = _find_active_node("crane_winch_modal", "CraneWinchModal")
	if cwm:
		if cwm.has_method("close_modal"):
			cwm.close_modal()
		else:
			cwm.visible = false
			GameState.can_player_move = true
		return true

	# 5. Password Modal: Brass Tumbler Chest (TumblerLockModal)
	var tlm = _find_active_node("tumbler_lock_modal", "TumblerLockModal")
	if tlm:
		if tlm.has_method("close_modal"):
			tlm.close_modal()
		else:
			tlm.visible = false
			GameState.can_player_move = true
		return true

	# 6. Case Select Modal (Bölüm Seçimi Paneli)
	var csm = _find_active_node("case_select_modal", "CaseSelectModal")
	if csm:
		if csm.has_method("close_modal"):
			csm.close_modal()
		else:
			csm.visible = false
		return true

	# 7. InspectView (item / evidence examination)
	var iv = tree.root.find_child("InspectView", true, false)
	if iv and is_instance_valid(iv) and iv.is_visible_in_tree() and not iv.is_queued_for_deletion():
		if iv.has_method("close_inspect"):
			iv.close_inspect()
		else:
			iv.visible = false
			GameState.can_player_move = true
		return true

	# 3. HUD dialogue / inner voice
	var hud = tree.root.find_child("HUD", true, false)
	if hud and is_instance_valid(hud) and not hud.is_queued_for_deletion():
		var is_inner = hud.get("is_showing_inner_voice")
		var dbox = hud.find_child("DialogueBox", true, false)
		if (is_inner and is_inner == true) or (dbox and dbox.is_visible_in_tree()):
			if hud.has_method("close_inner_voice"):
				hud.close_inner_voice()
			elif dbox:
				dbox.visible = false
				GameState.can_player_move = true
			return true

	# 4. InventoryModal (Bag / Çanta)
	var inv = tree.root.find_child("InventoryModal", true, false)
	if inv and is_instance_valid(inv) and inv.is_visible_in_tree() and not inv.is_queued_for_deletion():
		if inv.has_method("close_inventory"):
			inv.close_inventory()
		else:
			inv.visible = false
			GameState.can_player_move = true
		return true

	# 5. Notebook (Defter)
	var nb = tree.root.find_child("Notebook", true, false)
	if nb and is_instance_valid(nb) and nb.is_visible_in_tree() and not nb.is_queued_for_deletion():
		if nb.has_method("close_notebook"):
			nb.close_notebook()
		else:
			nb.visible = false
			GameState.can_player_move = true
		return true

	# 6. Interrogation (Sorgulama)
	var interr = tree.root.find_child("Interrogation", true, false)
	if interr and is_instance_valid(interr) and interr.is_visible_in_tree() and not interr.is_queued_for_deletion():
		if interr.has_method("_on_exit_pressed"):
			interr._on_exit_pressed()
		else:
			interr.visible = false
			GameState.can_player_move = true
		return true

	# 7. AccusationModal (Suçlama)
	var acc = tree.root.find_child("AccusationModal", true, false)
	if acc and is_instance_valid(acc) and acc.is_visible_in_tree() and not acc.is_queued_for_deletion():
		if acc.has_method("_on_cancel_pressed"):
			acc._on_cancel_pressed()
		else:
			acc.visible = false
			GameState.can_player_move = true
		return true

	# 8. MemoryWall (Anı Duvarı)
	var mw = tree.root.find_child("MemoryWall", true, false)
	if mw and is_instance_valid(mw) and mw.is_visible_in_tree() and not mw.is_queued_for_deletion():
		mw.visible = false
		GameState.can_player_move = true
		return true

	# 9. SouvenirModal (Hatıra Rafı)
	var sm = tree.root.find_child("SouvenirModal", true, false)
	if sm and is_instance_valid(sm) and sm.is_visible_in_tree() and not sm.is_queued_for_deletion():
		sm.visible = false
		GameState.can_player_move = true
		return true

	return false

func open_menu() -> void:
	menu_cooldown = 0.15
	visible = true
	GameState.can_player_move = false
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	status_lbl.text = "Game Paused" if is_en else "Oyun Duraklatıldı"
	load_btn.disabled = not SaveSystem.has_save_file()
	var vp = get_viewport()
	if vp and vp.gui_get_focus_owner():
		vp.gui_get_focus_owner().release_focus()

func close_menu() -> void:
	menu_cooldown = 0.15
	visible = false
	var vp = get_viewport()
	if vp and vp.gui_get_focus_owner():
		vp.gui_get_focus_owner().release_focus()
	GameState.can_player_move = true

func _on_save_pressed() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	var success = SaveSystem.save_game()
	if success:
		status_lbl.text = "✔ Game saved successfully." if is_en else "✔ Oyun başarıyla kaydedildi."
		EventBus.toast_requested.emit("✔ Game saved." if is_en else "✔ Oyun kaydedildi.")
	else:
		status_lbl.text = "✖ Save failed." if is_en else "✖ Kayıt başarısız oldu."

func _on_load_pressed() -> void:
	var loc_mgr = get_node_or_null("/root/LocalizationManager")
	var is_en = loc_mgr and loc_mgr.get_locale() == "en"
	if SaveSystem.has_save_file():
		var success = SaveSystem.load_game()
		if success:
			status_lbl.text = "✔ Game loaded." if is_en else "✔ Kayıt yüklendi."
			EventBus.toast_requested.emit("✔ Game loaded." if is_en else "✔ Kayıt yüklendi.")
			close_menu()
			EventBus.room_change_requested.emit(GameState.current_room_id, "default")
		else:
			status_lbl.text = "✖ Load failed." if is_en else "✖ Kayıt yüklenemedi."
	else:
		status_lbl.text = "No save file found." if is_en else "Kayıt dosyası bulunamadı."

func _on_restart_pressed() -> void:
	GameState.discovered_evidence.clear()
	GameState.collected_statements.clear()
	GameState.unlocked_deductions.clear()
	GameState.inspected_objects.clear()
	GameState.accusation_chances_left = 3
	GameState.case_solved = false
	GameState.selected_souvenir = ""
	GameState.flags.clear()
	close_menu()
	EventBus.room_change_requested.emit("silas_office", "default")

func _on_quit_pressed() -> void:
	close_menu()
	EventBus.main_menu_requested.emit()
