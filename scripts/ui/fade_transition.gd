extends CanvasLayer

## Fullscreen fade transition for room changes.

@onready var color_rect: ColorRect = $ColorRect

signal fade_out_completed
signal fade_in_completed

func _ready() -> void:
	color_rect.color = Color(0, 0, 0, 0)
	color_rect.visible = false

func fade_out(duration: float = 0.25) -> void:
	color_rect.visible = true
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	await tween.finished
	fade_out_completed.emit()

func fade_in(duration: float = 0.25) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	await tween.finished
	color_rect.visible = false
	fade_in_completed.emit()
