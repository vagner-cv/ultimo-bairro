extends Node2D

const HOUSES: Array[Texture2D] = [
	preload("res://art/world/cottage_slate.png"),
	preload("res://art/world/cottage_terracotta.png"),
	preload("res://art/world/cottage_blue.png"),
	preload("res://art/world/store.png"),
	preload("res://art/world/cottage_timber.png")
]

var size: Vector2
var roof_color := Color("51645d")
var house_name: String
var player: Node2D
var fade: float = 1.0
var variant: int = 0

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	var inside := Rect2(global_position, size).grow(30).has_point(player.global_position)
	var target := 0.0 if inside else 1.0
	fade = move_toward(fade, target, delta * 5.0)
	modulate.a = fade

func _draw() -> void:
	draw_texture_rect(HOUSES[variant % HOUSES.size()], Rect2(-9, -48, size.x + 18, size.y + 50), false)
