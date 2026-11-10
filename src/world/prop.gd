extends StaticBody2D

const BASE := "res://art/vendor/craftpix/"
const ART = {
	"tree": preload(BASE + "tree.png"), "bush": preload(BASE + "bush.png"),
	"dumpster": preload(BASE + "dumpster.png"), "fence": preload(BASE + "fence.png"),
	"barricade": preload(BASE + "barricade.png"), "bench": preload(BASE + "bench.png"),
	"crate": preload(BASE + "crate.png"), "barrel": preload(BASE + "barrel.png")
}
const KIT = preload("res://src/systems/kit_art.gd")

var kind: String = "wall"
var size: Vector2 = Vector2(32, 32)
var tint: Color = Color("899280")
var variant: int = 0

func _draw() -> void:
	if kind == "wall":
		if size.x > 1000 or size.y > 1000:
			return
		for y in range(0, int(size.y), 32):
			for x in range(0, int(size.x), 32):
				var section := Vector2(minf(32, size.x - x), minf(32, size.y - y))
				draw_texture_rect_region(KIT.ATLAS, Rect2(Vector2(-size.x / 2 + x, -size.y + y), section), Rect2(16 * 2, 16 * 15, section.x / 2, section.y / 2))
		return
	var texture: Texture2D = ART.get(kind, ART.crate)
	if kind in ["fence", "barricade", "bush"]:
		var native_width := texture.get_width() * 2
		var native_height := texture.get_height() * 2
		for x in range(0, int(size.x), native_width):
			var width := minf(native_width, size.x - x)
			draw_texture_rect_region(texture, Rect2(-size.x / 2 + x, -native_height, width, native_height), Rect2(0, 0, width / 2, texture.get_height()))
	else:
		var native_size := texture.get_size() * 2
		draw_texture_rect(texture, Rect2(Vector2(-native_size.x / 2, -native_size.y), native_size), false)
