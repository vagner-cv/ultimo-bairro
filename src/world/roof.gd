extends Node2D

var size: Vector2
var roof_color := Color("51645d")
var house_name: String
var player: Node2D
var fade: float = 1.0

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var inside := Rect2(global_position, size).grow(24).has_point(player.global_position)
	var target := 0.0 if inside else 1.0
	fade = move_toward(fade, target, delta * 5.0)
	modulate.a = fade

func _draw() -> void:
	draw_rect(Rect2(Vector2(-7, -10), size + Vector2(18, 20)), Color(0.025, .045, .04, .5))
	draw_rect(Rect2(Vector2(-6, -14), size + Vector2(12, 20)), roof_color.darkened(.15))
	for y in range(-12, int(size.y), 12):
		var c := roof_color.lightened(.045) if y < size.y / 2 else roof_color.darkened(.035)
		draw_rect(Rect2(Vector2(-4, y), Vector2(size.x + 8, 10)), c)
		for x in range(0, int(size.x), 24):
			var offset := 12 if (y / 12) % 2 == 0 else 0
			draw_line(Vector2(x + offset, y), Vector2(x + offset, y + 9), c.darkened(.1))
	draw_rect(Rect2(-7, size.y / 2 - 3, size.x + 14, 6), roof_color.lightened(.2))
	draw_rect(Rect2(40, 28, 24, 32), Color("655b4b"))
	draw_rect(Rect2(37, 25, 30, 8), Color("8a7e63"))
	draw_rect(Rect2(42, 27, 20, 3), Color("3a443b"))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(14, size.y - 12), house_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b9c1a2"))
