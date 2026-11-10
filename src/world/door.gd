extends StaticBody2D

signal changed
var is_open: bool = false
var caption: String = "Porta"
var collision: CollisionShape2D

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("interactables")
	collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56, 14)
	collision.shape = shape
	collision.position.y = -7
	add_child(collision)
	queue_redraw()

func interact(_actor: Node) -> void:
	is_open = not is_open
	collision.set_deferred("disabled", is_open)
	queue_redraw()
	changed.emit()

func interaction_text() -> String:
	return "Fechar porta" if is_open else "Abrir porta"

func navigation_rect() -> Rect2:
	return Rect2(position + Vector2(-28, -14), Vector2(56, 14))

func _draw() -> void:
	draw_rect(Rect2(-32, -5, 64, 8), Color("5f5844"))
	if is_open:
		draw_rect(Rect2(-30, -50, 8, 46), Color("91754f"))
		draw_rect(Rect2(-28, -47, 2, 40), Color("b09867"))
	else:
		draw_rect(Rect2(-28, -20, 56, 19), Color("6b533c"))
		draw_rect(Rect2(-25, -18, 50, 12), Color("957950"))
		draw_rect(Rect2(17, -12, 4, 3), Color("d5bc7d"))
