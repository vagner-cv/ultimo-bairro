extends RefCounted

static var contact: Texture2D

static func texture() -> Texture2D:
	if contact == null:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color(.018, .028, .035, .42), Color(.018, .028, .035, .22), Color(.018, .028, .035, 0)])
		gradient.offsets = PackedFloat32Array([0, .38, 1])
		var image := GradientTexture2D.new()
		image.gradient = gradient
		image.width = 128
		image.height = 64
		image.fill = GradientTexture2D.FILL_RADIAL
		image.fill_from = Vector2(.5, .5)
		image.fill_to = Vector2(1, .5)
		contact = image
	return contact

static func draw_contact(canvas: CanvasItem, at: Vector2, size: Vector2 = Vector2(36, 17), alpha: float = 1.0) -> void:
	canvas.draw_texture_rect(texture(), Rect2(at - size / 2, size), false, Color(1, 1, 1, alpha))
