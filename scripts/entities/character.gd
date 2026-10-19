class_name Character
extends CharacterBody2D

## Base class for all humanoid characters (Silas Crowe and NPCs).
## Standardizes:
## - Sprite2D with scale = (1, 1)
## - Sole at node origin: centered = false, offset = (-w/2, -h) = (-32, -104)
## - Placed in scenes at y = 245
## - No node scale or custom height in scene files

@export var character_id: String = ""
@export var character_name: String = ""

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = get_node_or_null("Shadow")

var facing_direction: String = "down" # down, left, right, up
var directional_textures: Dictionary = {}

func _ready() -> void:
	if sprite_2d:
		sprite_2d.scale = Vector2(1.0, 1.0)
		sprite_2d.centered = false
		sprite_2d.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_update_sprite_offset()

func _update_sprite_offset() -> void:
	if not sprite_2d:
		return
	var tex = sprite_2d.texture
	if tex:
		var w = tex.get_width()
		var h = tex.get_height()
		sprite_2d.offset = Vector2(-w / 2.0, -h)
	else:
		sprite_2d.offset = Vector2(-32, -104)

func set_character_texture(tex: Texture2D) -> void:
	if sprite_2d and tex:
		sprite_2d.texture = tex
		_update_sprite_offset()

func set_facing(dir: String) -> void:
	facing_direction = dir
	if directional_textures.has(dir):
		set_character_texture(directional_textures[dir])
