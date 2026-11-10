extends Node2D

var world: Node2D

func _draw() -> void:
	for house in world.houses:
		var rect: Rect2 = house.rect
		for softness in range(6, 0, -1):
			var shadow := Rect2(rect.position + Vector2(20, 16), rect.size).grow(softness * 2)
			draw_style_box(_style(softness), shadow)

func _style(softness: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.014, .025, .03, .042)
	style.set_corner_radius_all(softness * 3)
	return style
