extends StaticBody2D

const INVENTORY = preload("res://src/systems/inventory.gd")
const ITEMS = preload("res://src/systems/items.gd")
const SHADOW = preload("res://src/systems/shadows.gd")
const DUMPSTER: Texture2D = preload("res://art/vendor/craftpix/dumpster.png")
const BENCH: Texture2D = preload("res://art/vendor/craftpix/bench.png")
const ART := {"locker": preload("res://art/survival/locker.png"), "locker_open": preload("res://art/survival/locker_open.png"), "wood": preload("res://art/survival/wood.png"), "cardboard": preload("res://art/survival/cardboard.png"), "drawer": preload("res://art/survival/drawer.png"), "drawer_open": preload("res://art/survival/drawer_open.png"), "dumpster": preload("res://art/survival/dumpster.png"), "dumpster_open": preload("res://art/survival/dumpster_open.png")}
var game: Node
var kind: String = "locker"
var caption: String = "Armário"
var inventory: RefCounted = INVENTORY.new()
var is_open: bool = false
var broken: bool = false
var durability: int = 60
var size := Vector2(38, 24)
var collision: CollisionShape2D
var lid: float = 0
var flash: float = 0
var platform_height: float = 26

func _ready() -> void:
	# Keep lid animation running while the inventory pauses world simulation.
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("containers")
	add_to_group("interactables")
	collision_layer = 16 if kind in ["wood", "cardboard", "drawer", "dumpster"] else 1
	collision_mask = 0
	durability = 28 if kind == "cardboard" else 60
	collision = CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = Vector2(0, -size.y / 2)
	add_child(collision)
	if collision_layer == 16:
		add_to_group("platforms")

func navigation_rect() -> Rect2:
	return Rect2(global_position - Vector2(size.x / 2, size.y), size)

func interaction_text() -> String:
	if kind in ["wood", "cardboard"] and not broken:
		return "Corte a caixa com a faca [F / botão direito]"
	return "Vasculhar " + caption.to_lower()

func interact(_actor: Node) -> void:
	if broken or kind in ["wood", "cardboard"]:
		return
	is_open = true
	game.audio.play("door", -12)
	game.open_inventory(self)

func close() -> void:
	is_open = false

func take_damage(amount: int, _direction: Vector2 = Vector2.ZERO, damage_kind: String = "bullet") -> void:
	if broken or kind not in ["wood", "cardboard"] or damage_kind != "knife":
		return
	durability -= amount
	flash = .16
	game.audio.play("impact", -7)
	if durability <= 0:
		broken = true
		remove_from_group("interactables")
		remove_from_group("platforms")
		collision_layer = 0
		collision.set_deferred("disabled", true)
		game.world.call_deferred("rebuild_navigation")
		game.effects.splinters(global_position)
		if not inventory.is_empty():
			game.call_deferred("spawn_loot", global_position + Vector2(0, 16), inventory)
	queue_redraw()

func _process(delta: float) -> void:
	lid = move_toward(lid, 1.0 if is_open else 0.0, delta * 6)
	flash = maxf(0, flash - delta)
	queue_redraw()

func _draw() -> void:
	SHADOW.draw_contact(self, Vector2(7, -3), size * Vector2(1.6, 1.0))
	if broken:
		draw_texture_rect(preload("res://art/vendor/craftpix/paper.png"), Rect2(-22, -16, 44, 20), false, Color(.68, .55, .4))
		return
	var color := Color(1.5, 1.3, 1.1) if flash > 0 else Color.WHITE
	if kind in ["dumpster", "drawer"]:
		var art: Texture2D = ART[kind + ("_open" if lid > .4 else "")]
		var visual_size := Vector2(94, 72) if kind == "dumpster" else Vector2(59, 51)
		draw_texture_rect(art, Rect2(Vector2(-visual_size.x / 2, -visual_size.y), visual_size), false, color)
	else:
		var art: Texture2D = ART["locker_open" if kind == "locker" and lid > .5 else kind]
		var visual_size := Vector2(49, 73) if kind == "locker" else Vector2(47, 43)
		draw_texture_rect(art, Rect2(Vector2(-visual_size.x / 2, -visual_size.y), visual_size), false, color)
