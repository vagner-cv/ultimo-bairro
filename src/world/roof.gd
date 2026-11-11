extends Node2D

const ART = preload("res://src/systems/environment_art.gd")
var size: Vector2
var roof_color := Color("51645d")
var house_name: String
var player: Node2D
var entry: Node
var fade: float = 1
var variant: int = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var inside := Rect2(global_position, size).grow(24).has_point(player.global_position)
	fade = move_toward(fade, 0.0 if inside else 1.0, delta * 5)
	modulate.a = fade

func _draw() -> void:
	var kind := ART.building_sprite(house_name, variant)
	var texture: Texture2D = ART.BUILDINGS[kind]
	# The footprint/door match physics; extra height represents the roof elevation.
	var bounds := Rect2(-9, -58, size.x + 18, size.y + 58)
	var color := Color.WHITE.lerp(roof_color, .055)
	draw_texture_rect(texture, bounds, false, color)
	if variant % 3 == 0:
		draw_texture_rect(ART.PROPS.ivy, Rect2(size.x - 67, size.y - 138, 66, 91), false, Color(1, 1, 1, .85))
	var font := preload("res://art/bold.ttf")
	var label_width := font.get_string_size(house_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	var plate := Rect2(size.x / 2 - label_width / 2 - 7, size.y - 99, label_width + 14, 17)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.075, .09, .075, .95)
	style.border_color = Color(.48, .44, .31, .75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	draw_style_box(style, plate)
	draw_string(font, plate.position + Vector2(7, 12), house_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("e5dfc9"))
	ART.door(self, Vector2(size.x / 2 - 32, size.y - 68), is_instance_valid(entry) and entry.is_open, entry.variant if is_instance_valid(entry) else 0)
