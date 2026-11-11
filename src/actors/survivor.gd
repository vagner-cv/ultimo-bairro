extends StaticBody2D

var display_name: String = "MARA"
const KIT = preload("res://src/systems/kit_art.gd")
var idle_animation: float = 0.0
var lines: Array[String] = [
	"Você acordou. Achei que não fosse sair daquela casa. Sou a Mara.",
	"As saídas do bairro estão bloqueadas. A rua principal está cheia deles... vá com cuidado.",
	"Portas fechadas seguram os infectados. Use E nos armários, F para cortar caixas e H para usar ervas. A próxima horda chega quando você eliminar esta."
]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	collision_layer = 8
	collision_mask = 0
	add_to_group("interactables")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9
	collision.shape = shape
	collision.position.y = -7
	add_child(collision)
	preload("res://src/systems/ballistics.gd").attach_body(self)

func _draw() -> void:
	draw_circle(Vector2(0, -3), 10, Color(0, 0, 0, .2))
	KIT.actor(self, KIT.NPC_IDLE, int(idle_animation), false)
	draw_circle(Vector2(0, -74), 7, Color("d6ba7d"))
	draw_string(ThemeDB.fallback_font, Vector2(-2, -70), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("31453d"))

func _process(delta: float) -> void:
	idle_animation += delta * 4
	queue_redraw()

func interaction_text() -> String:
	return "Conversar com Mara"

func interact(actor: Node) -> void:
	actor.game.start_dialogue(display_name, lines)
