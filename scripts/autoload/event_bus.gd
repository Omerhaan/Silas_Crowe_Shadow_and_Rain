extends Node

## Global EventBus for decouple communication across rooms, UI, and systems.

signal room_change_requested(target_room_id: String, target_spawn: String)
signal room_changed(room_id: String)

signal interaction_available(interactable: Node2D)
signal interaction_unavailable(interactable: Node2D)

signal inner_voice_requested(text: String)
signal toast_requested(message: String)
signal evidence_collected(evidence_id: String)
signal statement_collected(suspect_id: String, statement_text: String)
signal dialogue_requested(suspect_id: String)
signal dialogue_finished()

signal notebook_toggle_requested()
signal notebook_toggled(is_open: bool)
signal inventory_toggle_requested()
signal inventory_toggled(is_open: bool)
signal deduction_made(deduction_id: String)
signal lightning_occurred()
signal focus_pulse_requested()

signal inspect_evidence_requested(evidence_id: String)
signal inspect_custom_requested(title: String, desc: String, texture_path: String, alt_texture_path: String, alt_desc: String)
signal flashback_requested(flashback_id: String)
signal flashback_finished(flashback_id: String)

signal interrogation_requested(suspect_id: String)
signal interrogation_finished()

signal accusation_requested()
signal accusation_resolved(success: bool, culprit_id: String)
signal light_range_requested()
signal tumbler_lock_requested()
signal safe_dial_requested()
signal crane_winch_requested()

signal memory_wall_requested()
signal souvenir_shelf_requested()
signal case_completed(case_id: String)
signal achievement_unlocked(ach_id: String, title: String, desc: String)
signal intro_replay_requested()
signal language_changed(locale: String)
signal font_scale_changed(scale_name: String)
signal case_ending_requested()
signal case_ending_completed()
signal case_continue_requested(next_case_id: String)
signal main_menu_requested()
