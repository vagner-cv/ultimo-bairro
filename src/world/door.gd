extends StaticBody2D

signal changed
var is_open: bool = false
var caption: String = "Porta"
var collision: CollisionShape2D
const KIT = preload("res://src/systems/environment_art.gd")

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
	KIT.door(self, Vector2(-32, -64), is_open)
