extends Node2D

const KIT = preload("res://src/systems/kit_art.gd")
var size: Vector2
var roof_color := Color("51645d")
var house_name: String
var player: Node2D
var entry: Node
var fade: float = 1.0
var variant: int = 0

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var inside := Rect2(global_position, size).grow(24).has_point(player.global_position)
	fade = move_toward(fade, 0.0 if inside else 1.0, delta * 5.0)
	modulate.a = fade

func _draw() -> void:
	var columns := roundi(size.x / 32)
	var rows := roundi(size.y / 32)
	var roof_rows := maxi(3, rows / 2)
	for y in range(rows):
		for x in range(columns):
			var tile := 138
			if y == 0:
				tile = 48 if x == 0 else (50 if x == columns - 1 else 49)
			elif y < roof_rows - 1:
				tile = 70 if x == 0 else (73 if x == columns - 1 else 94)
				if x > 0 and x < columns - 1 and (x * 7 + y * 3 + variant) % 9 == 0:
					tile = 71
			elif y == roof_rows - 1:
				tile = 114 if x == 0 else (117 if x == columns - 1 else 116)
			elif y == rows - 2:
				tile = 180 if x == 0 else (183 if x == columns - 1 else 181)
			elif y == rows - 1:
				tile = 202 if x == 0 else (205 if x == columns - 1 else 203)
			elif x == 0:
				tile = 136
			elif x == columns - 1:
				tile = 139
			KIT.tile(self, tile, Vector2(x * 32, y * 32), Color.WHITE.lerp(roof_color, .18))
	for x in range(1, columns - 1, 2):
		if absf(x * 32 - size.x / 2) < 36:
			continue
		KIT.tile(self, 31, Vector2(x * 32, roof_rows * 32))
		KIT.tile(self, 53, Vector2(x * 32, (roof_rows + 1) * 32))
	if variant % 2 == 0:
		KIT.tile(self, 186, Vector2(32, 32))
		KIT.tile(self, 208, Vector2(32, 64))
	var font := ThemeDB.fallback_font
	var label_width := font.get_string_size(house_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var plate := Rect2(size.x / 2 - label_width / 2 - 8, size.y - 92, label_width + 16, 19)
	draw_rect(plate, Color(.08, .13, .12, .91))
	draw_string(font, plate.position + Vector2(8, 14), house_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e5e1cd"))
	KIT.door(self, Vector2(size.x / 2 - 32, size.y - 64), is_instance_valid(entry) and entry.is_open)

func _ready() -> void:
	material = preload("res://shaders/soft_pixel.tres")
