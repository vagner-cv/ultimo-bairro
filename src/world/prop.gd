extends StaticBody2D

const ART = preload("res://src/systems/environment_art.gd")
const SHADOW = preload("res://src/systems/shadows.gd")
var kind: String = "wall"
var size: Vector2 = Vector2(32, 32)
var tint: Color = Color("899280")
var variant: int = 0
var platform_height: float = 26
var visual_size: Vector2 = Vector2.ZERO

func navigation_rect() -> Rect2:
	return Rect2(global_position - Vector2(size.x / 2, size.y), size)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if kind == "lamp":
		var glow := PointLight2D.new()
		glow.texture = SHADOW.glow_texture()
		glow.color = Color(1.0, .73, .38)
		glow.energy = .35
		glow.texture_scale = .8
		glow.position = Vector2(0, -97)
		glow.shadow_enabled = false
		add_child(glow)

func _draw() -> void:
	if kind == "wall":
		_draw_wall()
		return
	var art_kind := "pine" if kind == "tree" and variant == 1 else kind
	var texture: Texture2D = ART.PROPS.get(art_kind, ART.PROPS.crate)
	var dimensions := visual_size if visual_size != Vector2.ZERO else _dimensions(texture)
	SHADOW.draw_contact(self, Vector2(10, -2), Vector2(maxf(26, dimensions.x * .85), 18))
	if kind in ["tree", "pine"]:
		for sample in range(3):
			draw_set_transform(Vector2(19 + sample * 3, -3), -.5, Vector2(1.1, .34))
			draw_texture_rect(texture, Rect2(Vector2(-dimensions.x / 2, -dimensions.y), dimensions), false, Color(.025, .035, .04, .09))
			draw_set_transform(Vector2.ZERO)
	if kind in ["fence", "wood_fence", "barricade", "bush", "hedge"]:
		var native_width := 94 if kind != "bush" else 66
		var count := maxi(1, ceili(size.x / native_width))
		var width := size.x / count
		for i in range(count):
			var height := 38.0 if kind in ["bush", "hedge"] else 48.0
			draw_texture_rect(texture, Rect2(-size.x / 2 + i * width, -height, width + 1, height), false)
	else:
		draw_texture_rect(texture, Rect2(Vector2(-dimensions.x / 2, -dimensions.y), dimensions), false)

func _dimensions(texture: Texture2D) -> Vector2:
	var limits := {
		"tree": Vector2(145, 172), "pine": Vector2(110, 185), "bench": Vector2(75, 46),
		"barrel": Vector2(31, 45), "lamp": Vector2(34, 126), "car": Vector2(154, 83),
		"woodpile": Vector2(77, 46), "bicycle": Vector2(69, 53), "sofa": Vector2(89, 61),
		"table": Vector2(68, 59), "bed": Vector2(52, 96), "bookcase": Vector2(65, 91),
		"hospital_bed": Vector2(55, 98), "workbench": Vector2(88, 67), "fridge": Vector2(42, 81),
		"armchair": Vector2(47, 52), "desk": Vector2(82, 58), "well": Vector2(65, 53), "plant": Vector2(29, 43)
	}
	var limit: Vector2 = limits.get(kind, Vector2(48, 44))
	var factor := minf(limit.x / texture.get_width(), limit.y / texture.get_height())
	return texture.get_size() * factor

func _draw_wall() -> void:
	if size.x > 1000 or size.y > 1000:
		return
	var texture: Texture2D = ART.WALLS[variant % ART.WALLS.size()]
	if size.x >= size.y:
		var count := maxi(1, ceili(size.x / 84))
		var width := size.x / count
		for i in range(count):
			draw_texture_rect(texture, Rect2(-size.x / 2 + i * width, -43, width + .5, 43), false)
	else:
		# Narrow top edges keep cutaway side walls readable from above.
		var count := maxi(1, ceili(size.y / 64))
		var height := size.y / count
		for i in range(count):
			draw_texture_rect_region(texture, Rect2(-size.x / 2, -size.y + i * height, size.x, height + .5), Rect2(0, 0, texture.get_width(), texture.get_height() * .14))
