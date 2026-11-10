extends StaticBody2D

var display_name: String = "MARA"
var texture: Texture2D = preload("res://art/survivor.png")
var lines: Array[String] = [
	"Você acordou. Achei que não fosse sair daquela casa. Sou a Mara.",
	"As saídas do bairro estão bloqueadas. A rua principal está cheia deles... vá com cuidado.",
	"Portas fechadas seguram os infectados. E os tiros chamam atenção. Não deixe que te cerquem."
]

func _ready() -> void:
	collision_layer = 8
	collision_mask = 0
	add_to_group("interactables")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9
	collision.shape = shape
	collision.position.y = -7
	add_child(collision)

func _draw() -> void:
	draw_circle(Vector2(0, -3), 10, Color(0, 0, 0, .2))
	draw_texture_rect_region(texture, Rect2(-16, -30, 32, 32), Rect2(0, 0, 32, 32))
	draw_rect(Rect2(-5, -42, 10, 9), Color("d6ba7d"))
	draw_rect(Rect2(-1, -40, 2, 3), Color("31453d"))
	draw_rect(Rect2(-1, -36, 2, 1), Color("31453d"))

func interaction_text() -> String:
	return "Conversar com Mara"

func interact(actor: Node) -> void:
	actor.game.start_dialogue(display_name, lines)
