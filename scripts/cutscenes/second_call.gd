extends Control

## The Second Phone Call Cutscene and Case 1 Completion Summary.
## Uses the shared DialogueBox component.

@onready var phone_container: VBoxContainer = $PhoneContainer
@onready var dialogue_box: Control = $PhoneContainer/DialogueBox
@onready var hangup_btn: Button = $PhoneContainer/Controls/HangupBtn

@onready var summary_box: Panel = $SummaryBox
@onready var title_label: Label = $SummaryBox/TitleLabel
@onready var stats_label: Label = $SummaryBox/StatsLabel
@onready var continue_btn: Button = $SummaryBox/ContinueBtn

func _ready() -> void:
	visible = false
	phone_container.visible = false
	summary_box.visible = false
	hangup_btn.pressed.connect(_on_hangup_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E:
			if phone_container.visible:
				_on_hangup_pressed()
				get_viewport().set_input_as_handled()
			elif summary_box.visible:
				_on_continue_pressed()
				get_viewport().set_input_as_handled()

func start_second_call() -> void:
	visible = true
	phone_container.visible = true
	summary_box.visible = false
	GameState.can_player_move = false

	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].has_method("set_on_phone"):
		players[0].set_on_phone(true)

	dialogue_box.set_dialogue("???", "(Cızırtı... Düzenli bir cep saati tik-tağı duyuluyor)\n\n\"İlk kapı açıldı. Sıradaki seni bekliyor.\"")

func _on_hangup_pressed() -> void:
	phone_container.visible = false
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].has_method("set_on_phone"):
		players[0].set_on_phone(false)

	EventBus.inner_voice_requested.emit("\"Aynı tik-tak sesi... Hat tekrar kapandı. Kimsin sen?\"")

	# Show completion summary
	summary_box.visible = true
	var ev_count = GameState.discovered_evidence.size()
	var ded_count = GameState.unlocked_deductions.size()
	var souv = GameState.selected_souvenir if GameState.selected_souvenir != "" else "Seçilmedi"

	title_label.text = "VAKA 1: KARANLIK MALİKÂNE — TAMAMLANDI"
	stats_label.text = "• Katil: Dr. Victor Hale (Tutuklandı)\n• Toplanan Kanıt: %d / 17\n• Yapılan Dedüksiyon: %d / 10\n• Seçilen Hatıra: %s\n• Anı Duvarı: K-5 Saati ve Birlik Fotoğrafı Eklendi\n\n[GÖLGE VE YAĞMUR: 1. BÖLÜM TAMAMLANDI]" % [ev_count, ded_count, souv]

func _on_continue_pressed() -> void:
	visible = false
	phone_container.visible = false
	summary_box.visible = false
	GameState.can_player_move = true
	EventBus.toast_requested.emit("🚪 Ofis kapısından çıkarak 2. Bölüm'e (Sisli Liman) geçebilirsin.")
	SaveSystem.save_game()
