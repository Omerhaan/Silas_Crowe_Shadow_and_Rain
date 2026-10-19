extends Node

## Localization Manager for Gölge ve Yağmur (Turkish & English support).
## Automatically loads data/localization/translations.csv, registers Translation objects
## with Godot's TranslationServer, and provides seamless runtime language switching.

const TRANSLATIONS_PATH = "res://data/localization/translations.csv"

var current_locale: String = "tr"
var tr_translation: Translation = null
var en_translation: Translation = null

func _ready() -> void:
	load_translations()
	# Check saved language from settings if available
	var saved_lang = _load_saved_language()
	set_locale(saved_lang)

func load_translations() -> void:
	var tr_res_path = "res://data/localization/translations.tr.translation"
	var en_res_path = "res://data/localization/translations.en.translation"

	if ResourceLoader.exists(tr_res_path):
		tr_translation = ResourceLoader.load(tr_res_path) as Translation
	if not tr_translation:
		tr_translation = Translation.new()
		tr_translation.locale = "tr"
		TranslationServer.add_translation(tr_translation)

	if ResourceLoader.exists(en_res_path):
		en_translation = ResourceLoader.load(en_res_path) as Translation
	if not en_translation:
		en_translation = Translation.new()
		en_translation.locale = "en"
		TranslationServer.add_translation(en_translation)

	# Read CSV to ensure latest keys are added
	if FileAccess.file_exists(TRANSLATIONS_PATH):
		var file = FileAccess.open(TRANSLATIONS_PATH, FileAccess.READ)
		if file:
			var is_header = true
			while not file.eof_reached():
				var line = file.get_csv_line()
				if line.size() < 3:
					continue
				if is_header:
					is_header = false
					continue

				var key = line[0].strip_edges()
				var tr_text = line[1].strip_edges()
				var en_text = line[2].strip_edges()

				if key != "":
					tr_translation.add_message(key, tr_text)
					en_translation.add_message(key, en_text)

func set_locale(locale_code: String) -> void:
	if locale_code != "tr" and locale_code != "en":
		locale_code = "tr"
	current_locale = locale_code
	TranslationServer.set_locale(locale_code)
	_save_language(locale_code)
	EventBus.language_changed.emit(locale_code)

func get_locale() -> String:
	return current_locale

func toggle_language() -> String:
	if current_locale == "tr":
		set_locale("en")
	else:
		set_locale("tr")
	return current_locale

func tr_text(key: String, fallback: String = "") -> String:
	var res = tr(key)
	if res == key and fallback != "":
		return fallback
	return res

func _load_saved_language() -> String:
	var path = "user://game_settings.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			return json.data.get("language", "tr")
	return "tr"

func _save_language(lang: String) -> void:
	var path = "user://game_settings.json"
	var data: Dictionary = {}
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
			data = json.data
	data["language"] = lang
	var out = FileAccess.open(path, FileAccess.WRITE)
	if out:
		out.store_string(JSON.stringify(data, "\t"))
