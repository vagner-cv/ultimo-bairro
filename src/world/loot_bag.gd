extends Node2D

const ICON: Texture2D = preload("res://art/pixel/loot.png")
const SHADOW = preload("res://src/systems/shadows.gd")
var game: Node
var inventory: RefCounted
var caption: String = "Itens encontrados"
var phase: float = 0

func _ready() -> void:
	add_to_group("interactables")
	add_to_group("loot")

func interaction_text() -> String:
	return "Recolher itens"

func interact(_actor: Node) -> void:
	game.open_inventory(self)

func close() -> void:
	if inventory.is_empty():
		queue_free()

func _process(delta: float) -> void:
	phase += delta * 3
	queue_redraw()

func _draw() -> void:
	SHADOW.draw_contact(self, Vector2.ZERO, Vector2(30, 12))
	draw_circle(Vector2(0, -12), 17 + sin(phase), Color(.85, .65, .3, .08))
	draw_texture_rect(ICON, Rect2(-12, -25 + sin(phase), 24, 24), false)
