extends Node

## CutsceneManager: Manages skippable narrative cutscenes, phone call sequences, and travel cinematic.

signal cutscene_started(cutscene_id: String)
signal cutscene_finished(cutscene_id: String)

var is_cutscene_active: bool = false
var active_cutscene_id: String = ""

func start_cutscene(cutscene_id: String) -> void:
	is_cutscene_active = true
	active_cutscene_id = cutscene_id
	GameState.can_player_move = false
	cutscene_started.emit(cutscene_id)

func finish_cutscene(cutscene_id: String) -> void:
	is_cutscene_active = false
	active_cutscene_id = ""
	GameState.can_player_move = true
	cutscene_finished.emit(cutscene_id)
