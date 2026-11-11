extends Node2D

const ART = preload("res://src/systems/environment_art.gd")
var variant: int = 0
var dimensions := Vector2(30, 23)

func _draw() -> void:
	var texture: Texture2D = ART.FOLIAGE[posmod(variant, ART.FOLIAGE.size())]
	var factor := minf(dimensions.x / texture.get_width(), dimensions.y / texture.get_height())
	var size := (texture.get_size() * factor).round()
	draw_texture_rect(texture, Rect2(Vector2(-size.x / 2, -size.y), size), false)
