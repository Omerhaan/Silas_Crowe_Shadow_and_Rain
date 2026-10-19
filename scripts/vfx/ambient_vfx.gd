extends CanvasLayer

## Ambient Noir Atmosphere Layer: Rain, Lightning flash, Candle/Lamp breathing, Vignette & Film Grain.

@onready var flash_rect: ColorRect = $FlashRect
@onready var rain_particles: CPUParticles2D = $RainParticles
@onready var ambient_glow: ColorRect = $AmbientGlow
@onready var lightning_timer: Timer = $LightningTimer
@onready var vignette_grain_rect: ColorRect = get_node_or_null("VignetteGrainRect")

var glow_time: float = 0.0

func _ready() -> void:
	layer = 8
	flash_rect.color = Color(1, 1, 1, 0)
	ambient_glow.color = Color(1.0, 0.85, 0.55, 0.02)
	lightning_timer.timeout.connect(_on_lightning_timer_timeout)
	_reset_timer()

func _process(delta: float) -> void:
	# Subtle candlelight / gaslamp breathing
	glow_time += delta * 3.5
	var flicker = sin(glow_time) * 0.008 + sin(glow_time * 2.3) * 0.005 + randf_range(-0.003, 0.003)
	ambient_glow.color.a = clampf(0.025 + flicker, 0.01, 0.05)

func _reset_timer() -> void:
	lightning_timer.start(randf_range(18.0, 32.0))

func _on_lightning_timer_timeout() -> void:
	trigger_lightning()
	_reset_timer()

func trigger_lightning() -> void:
	AudioManager.trigger_thunder()
	EventBus.lightning_occurred.emit()

	# Double thunder flash
	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", 0.70, 0.05)
	tween.tween_property(flash_rect, "color:a", 0.15, 0.06)
	tween.tween_property(flash_rect, "color:a", 0.80, 0.04)
	tween.tween_property(flash_rect, "color:a", 0.0, 0.28)

func set_rain_enabled(enabled: bool) -> void:
	if rain_particles:
		rain_particles.emitting = enabled
		rain_particles.visible = enabled

func set_film_grain_enabled(enabled: bool) -> void:
	if vignette_grain_rect and vignette_grain_rect.material is ShaderMaterial:
		vignette_grain_rect.material.set_shader_parameter("enable_grain", enabled)

func set_vignette_enabled(enabled: bool) -> void:
	if vignette_grain_rect and vignette_grain_rect.material is ShaderMaterial:
		vignette_grain_rect.material.set_shader_parameter("enable_vignette", enabled)
