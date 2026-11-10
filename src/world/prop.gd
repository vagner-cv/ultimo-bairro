extends StaticBody2D

const ART = {
	"tree": preload("res://art/world/oak.png"),
	"tree_alt": preload("res://art/world/tree.png"),
	"car": preload("res://art/world/car_rust.png"),
	"car_blue": preload("res://art/world/car_blue.png"),
	"fence": preload("res://art/world/fence.png"),
	"barricade": preload("res://art/world/barricade.png"),
	"bed": preload("res://art/world/bed.png"),
	"sofa": preload("res://art/world/sofa.png"),
	"table": preload("res://art/world/table.png"),
	"bush": preload("res://art/world/bush.png"),
	"lamp": preload("res://art/world/lamp.png")
}
const GROUND: Texture2D = preload("res://art/ground.png")

var kind: String = "wall"
var size: Vector2 = Vector2(32, 32)
var tint: Color = Color("899280")
var variant: int = 0

func _draw() -> void:
	match kind:
		"tree":
			var texture: Texture2D = ART.tree if int(position.x) % 3 == 0 else ART.tree_alt
			draw_texture_rect(texture, Rect2(-64, -146, 128, 148), false)
		"car":
			var texture: Texture2D = ART.car if tint.r > tint.b else ART.car_blue
			draw_texture_rect(texture, Rect2(-size.x / 2 - 6, -size.y - 35, size.x + 12, size.y + 36), false)
		"fence":
			var texture: Texture2D = ART.fence
			for x in range(0, int(size.x), 96):
				var width := minf(96, size.x - x)
				draw_texture_rect_region(texture, Rect2(-size.x / 2 + x, -42, width, 44), Rect2(0, 0, texture.get_width() * width / 96.0, texture.get_height()))
		"barricade":
			draw_texture_rect(ART.barricade, Rect2(-size.x / 2, -74, size.x, 76), false)
		"bed":
			draw_texture_rect(ART.bed, Rect2(-size.x / 2 - 2, -size.y - 8, size.x + 4, size.y + 9), false)
		"sofa":
			draw_texture_rect(ART.sofa, Rect2(-size.x / 2 - 3, -size.y - 20, size.x + 6, size.y + 22), false)
		"table":
			draw_texture_rect(ART.table, Rect2(-size.x / 2 - 2, -size.y - 8, size.x + 4, size.y + 10), false)
		"bush":
			draw_texture_rect(ART.bush, Rect2(-size.x / 2 - 3, -size.y - 34, size.x + 6, size.y + 36), false)
		"lamp":
			draw_texture_rect(ART.lamp, Rect2(-12, -106, 32, 108), false)
		_:
			if size.x > 1000 or size.y > 1000:
				return
			for y in range(0, int(size.y), 32):
				for x in range(0, int(size.x), 32):
					var section := Vector2(minf(32, size.x - x), minf(32, size.y - y))
					draw_texture_rect_region(GROUND, Rect2(Vector2(-size.x / 2 + x, -size.y + y), section), Rect2(Vector2(256 + x % 128, y % 128), section))
			draw_line(Vector2(-size.x / 2, -size.y), Vector2(size.x / 2, -size.y), Color("d3c5a4"), 1)
