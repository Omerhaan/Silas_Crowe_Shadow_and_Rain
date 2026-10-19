extends Control

## Flashback FB01 "Kar" (Winter 1944).
## Noir memory cutscene with pale blue-white palette and a single red badge.
## Features the ambiguous curled-hand gesture and the command "Git!".

@onready var bg: ColorRect = $Background
@onready var panel_texture: TextureRect = $PanelTexture
@onready var snow_particles: CPUParticles2D = $SnowParticles
@onready var badge_rect: ColorRect = $VisualContainer/BadgeRect
@onready var badge_cross: Label = $VisualContainer/BadgeRect/Cross
@onready var hand_silhouette: Node2D = $VisualContainer/HandSilhouette
@onready var hand_palm: ColorRect = $VisualContainer/HandSilhouette/Palm
@onready var finger_curled_1: ColorRect = $VisualContainer/HandSilhouette/Finger1
@onready var finger_curled_2: ColorRect = $VisualContainer/HandSilhouette/Finger2
@onready var finger_curled_3: ColorRect = $VisualContainer/HandSilhouette/Finger3
@onready var text_label: Label = $TextLabel
@onready var flash_rect: ColorRect = $FlashRect
@onready var skip_btn: Button = $SkipBtn

var elapsed_time: float = 0.0
var is_active: bool = false
const TOTAL_DURATION: float = 10.0

var panel_textures: Array[Texture2D] = []

func _ready() -> void:
	visible = false
	skip_btn.pressed.connect(_finish_flashback)
	EventBus.flashback_requested.connect(_on_flashback_requested)

	var paths = [
		"res://assets/sprites/flashback/flashback_fb01_01_battlefield.png",
		"res://assets/sprites/flashback/flashback_fb01_02_medic_bag.png",
		"res://assets/sprites/flashback/flashback_fb01_03_clutched_hand.png",
		"res://assets/sprites/flashback/flashback_fb01_04_explosion_flare.png"
	]
	for p in paths:
		if ResourceLoader.exists(p):
			panel_textures.append(load(p))
		else:
			var gp = ProjectSettings.globalize_path(p)
			if FileAccess.file_exists(gp):
				var img = Image.load_from_file(gp)
				if img:
					panel_textures.append(ImageTexture.create_from_image(img))

var current_fb_id: String = "FB01"

func _on_flashback_requested(fb_id: String) -> void:
	if fb_id == "FB01" or fb_id == "FB02":
		start_flashback(fb_id)

func start_flashback(fb_id: String = "FB01") -> void:
	current_fb_id = fb_id
	visible = true
	is_active = true
	elapsed_time = 0.0
	GameState.can_player_move = false

	# Reset visual elements
	flash_rect.color = Color(1, 1, 1, 0)
	if has_node("VisualContainer"):
		$VisualContainer.visible = panel_textures.is_empty()
	badge_rect.modulate = Color(1, 1, 1, 0)
	hand_silhouette.modulate = Color(1, 1, 1, 0)
	text_label.modulate = Color(1, 1, 1, 0)
	text_label.text = ""

	if panel_textures.size() > 0 and panel_texture:
		panel_texture.texture = panel_textures[0]
		panel_texture.visible = true

	snow_particles.emitting = true

func _process(delta: float) -> void:
	if not is_active:
		return

	elapsed_time += delta

	if current_fb_id == "FB02":
		_process_fb02()
		return

	# Sequence timeline for FB01
	if elapsed_time < 2.5:
		if panel_textures.size() > 0 and panel_texture:
			panel_texture.texture = panel_textures[0]
		text_label.text = "1944 Kışı... Kuzey."
		text_label.modulate.a = clampf(elapsed_time / 1.5, 0.0, 1.0)
	elif elapsed_time < 5.0:
		if panel_textures.size() > 1 and panel_texture:
			panel_texture.texture = panel_textures[1]
		if panel_textures.is_empty():
			var t = (elapsed_time - 2.5) / 1.5
			badge_rect.modulate.a = clampf(t, 0.0, 1.0)
		text_label.text = "Pusu. Telsizler sustu."
	elif elapsed_time < 7.5:
		if panel_textures.size() > 2 and panel_texture:
			panel_texture.texture = panel_textures[2]
		if panel_textures.is_empty():
			var t = (elapsed_time - 5.0) / 1.5
			hand_silhouette.modulate.a = clampf(t, 0.0, 1.0)
			hand_silhouette.position.x = 160.0 + sin(elapsed_time * 3.0) * 3.0
		text_label.text = ""
	elif elapsed_time < 8.8:
		if panel_textures.size() > 2 and panel_texture:
			panel_texture.texture = panel_textures[2]
		text_label.text = "\"GİT!\""
		text_label.modulate = Color(1, 0.95, 0.9, 1.0)
		if panel_textures.is_empty():
			hand_silhouette.position.y = 80.0 + randf_range(-1.5, 1.5)
	elif elapsed_time < 9.5:
		if panel_textures.size() > 3 and panel_texture:
			panel_texture.texture = panel_textures[3]
		var t = (elapsed_time - 8.8) / 0.4
		flash_rect.color = Color(0.95, 0.98, 1.0, clampf(t, 0.0, 1.0))
	elif elapsed_time < TOTAL_DURATION:
		var t = (elapsed_time - 9.5) / 0.5
		flash_rect.color = Color(0.05, 0.07, 0.1, clampf(t, 0.0, 1.0))
	else:
		_finish_flashback()

func _process_fb02() -> void:
	if elapsed_time < 2.5:
		text_label.text = "14 Aralık 1944... Gece 02:50."
		text_label.modulate.a = clampf(elapsed_time / 1.5, 0.0, 1.0)
	elif elapsed_time < 5.0:
		text_label.text = "Makineli tüfek ateşi... Telsiz direği devrildi."
	elif elapsed_time < 7.5:
		text_label.text = "'Mayday! Kuzey Birimi kuşatıldı! Destek çağırıyorum!'"
	elif elapsed_time < 9.0:
		text_label.text = "Teddy şalteri indirdi: 'Bizi unuttular!'"
		text_label.modulate = Color(1, 0.9, 0.7, 1.0)
	elif elapsed_time < 10.0:
		var t = (elapsed_time - 9.0) / 0.5
		flash_rect.color = Color(0.8, 0.4, 0.2, clampf(t, 0.0, 0.8))
	elif elapsed_time < 11.5:
		var t = (elapsed_time - 10.0) / 0.5
		flash_rect.color = Color(0.05, 0.07, 0.1, clampf(t, 0.0, 1.0))
		text_label.text = "Frekans 312 sustu... Telsiz kapandı."
	else:
		_finish_flashback()

func _finish_flashback() -> void:
	if not is_active:
		return
	is_active = false
	visible = false
	snow_particles.emitting = false
	GameState.can_player_move = true
	EventBus.flashback_finished.emit(current_fb_id)
	if current_fb_id == "FB02":
		EventBus.inner_voice_requested.emit("\"Teddy telsizi kapattığında... hepimiz bir diğerini o karların altında bıraktık.\"")
	else:
		EventBus.inner_voice_requested.emit("\"Zihnimde... o kar fırtınası ve bir el... Neden unutamıyorum?\"")
