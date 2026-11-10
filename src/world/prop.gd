extends StaticBody2D

var kind: String = "wall"
var size: Vector2 = Vector2(32, 32)
var tint: Color = Color("899280")
var variant: int = 0
var tree_texture: Texture2D = preload("res://art/tree.png")

func _draw() -> void:
	var rect := Rect2(Vector2(-size.x / 2.0, -size.y), size)
	match kind:
		"tree":
			draw_ellipse_shadow(Vector2(0, -4), Vector2(28, 10))
			draw_texture(tree_texture, Vector2(-40, -90))
		"car":
			draw_rect(Rect2(rect.position, rect.size + Vector2(6, 6)), Color(0.03, 0.06, 0.06, .5))
			draw_rect(rect, Color("253a38"))
			draw_rect(rect.grow(-3), tint)
			draw_rect(Rect2(rect.position + Vector2(20, 4), Vector2(size.x - 44, size.y - 8)), Color("263c3c"))
			draw_rect(Rect2(rect.position + Vector2(23, 6), Vector2(size.x - 50, size.y - 12)), Color("64817a"))
			draw_rect(Rect2(rect.position + Vector2(size.x - 25, 4), Vector2(4, size.y - 8)), Color("a0b0a0"))
			draw_rect(Rect2(rect.position + Vector2(6, 6), Vector2(12, size.y - 12)), tint.lightened(.12))
			for px in [-size.x / 2.0 + 16, size.x / 2.0 - 20]:
				draw_rect(Rect2(Vector2(px, -size.y - 2), Vector2(13, 5)), Color("202e2d"))
				draw_rect(Rect2(Vector2(px, -3), Vector2(13, 5)), Color("202e2d"))
			draw_line(rect.position + Vector2(25, 8), rect.position + Vector2(39, 18), Color("a1aca0"), 1)
			draw_rect(Rect2(rect.end - Vector2(4, 8), Vector2(3, 5)), Color("ac7251"))
		"fence":
			for x in range(int(-size.x / 2), int(size.x / 2), 10):
				draw_rect(Rect2(Vector2(x, -22), Vector2(5, 22)), tint)
				draw_rect(Rect2(Vector2(x, -22), Vector2(2, 22)), tint.lightened(.12))
			draw_rect(Rect2(Vector2(-size.x / 2, -17), Vector2(size.x, 3)), tint.darkened(.14))
			draw_rect(Rect2(Vector2(-size.x / 2, -7), Vector2(size.x, 3)), tint.darkened(.14))
		"barricade":
			draw_rect(rect, Color("514d3c"))
			for y in range(int(-size.y), 0, 8):
				draw_rect(Rect2(Vector2(-size.x / 2 + 2, y + 1), Vector2(size.x - 4, 5)), Color("8b7851"))
			for x in range(int(-size.x / 2), int(size.x / 2), 18):
				draw_line(Vector2(x, -size.y), Vector2(x + 8, -2), Color("b29a62"), 3)
		"bed":
			draw_rect(rect, Color("3c4239"))
			draw_rect(rect.grow(-3), Color("899989"))
			draw_rect(Rect2(rect.position + Vector2(4, 4), Vector2(size.x - 8, 14)), Color("c1bda0"))
			draw_rect(Rect2(rect.position + Vector2(4, 22), Vector2(size.x - 8, size.y - 26)), Color("5f7a78"))
			draw_line(rect.position + Vector2(5, 26), rect.position + Vector2(size.x - 5, 26), Color("8a9b8d"), 2)
		"sofa":
			draw_rect(rect, Color("354d48"))
			draw_rect(rect.grow(-3), Color("60786a"))
			draw_rect(Rect2(rect.position + Vector2(5, 12), Vector2(size.x - 10, size.y - 16)), Color("6f8775"))
			draw_line(Vector2(0, -size.y + 13), Vector2(0, -4), Color("435d51"), 2)
		"table":
			draw_rect(rect.grow(2), Color("3c4132"))
			draw_rect(rect, Color("a08a62"))
			draw_rect(rect.grow(-3), Color("8f7856"))
			draw_rect(Rect2(rect.position + Vector2(7, 7), Vector2(12, 9)), Color("b6b39c"))
		"bush":
			draw_rect(rect.grow(3), Color("294332"))
			draw_rect(rect, Color("4b6242"))
			for i in range(7):
				draw_rect(Rect2(rect.position + Vector2((i * 13) % int(size.x), (i * 7) % int(size.y)), Vector2(3, 2)), Color("758057"))
		"lamp":
			draw_ellipse_shadow(Vector2(8, -2), Vector2(12, 4))
			draw_rect(Rect2(-3, -66, 6, 66), Color("293e3a"))
			draw_rect(Rect2(-1, -66, 2, 64), Color("69776a"))
			draw_rect(Rect2(-9, -69, 18, 8), Color("c5b982"))
			draw_rect(Rect2(-10, -71, 20, 3), Color("34483e"))
		_:
			draw_rect(rect, tint.darkened(.25))
			draw_rect(Rect2(rect.position, Vector2(size.x, maxf(3, size.y - 6))), tint)
			draw_line(rect.position, rect.position + Vector2(size.x, 0), tint.lightened(.2), 2)

func draw_ellipse_shadow(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for i in range(16):
		var a := TAU * float(i) / 16.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	draw_colored_polygon(points, Color(0.025, 0.06, 0.045, .4))
