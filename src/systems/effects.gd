extends Node2D

var entries: Array[Dictionary] = []
var corpses: Array[Dictionary] = []
var corpse_sprites: Array[Sprite2D] = []
const KIT = preload("res://src/systems/kit_art.gd")

func tracer(start: Vector2, end: Vector2, hit: bool) -> void:
	entries.append({"kind": "shot", "a": start, "b": end, "life": .12, "max": .12, "hit": hit})

func blood(at: Vector2, direction: Vector2) -> void:
	for i in range(7):
		var angle := direction.angle() + randf_range(-.8, .8)
		entries.append({"kind": "blood", "a": at, "velocity": Vector2.from_angle(angle) * randf_range(25, 70), "life": .32, "max": .32})

func corpse(at: Vector2, tint: Color) -> void:
	corpses.append({"at": at, "tint": tint, "angle": randf_range(-.6, .6)})
	var sprite := Sprite2D.new()
	sprite.texture = KIT.ZOMBIE_DEAD
	sprite.region_enabled = true
	sprite.region_rect = Rect2(32, 0, 32, 32)
	sprite.scale = Vector2(2, 2)
	sprite.position = at + Vector2(0, -30)
	sprite.flip_h = corpses[-1].angle < 0
	sprite.modulate = Color(.85, .85, .85)
	get_parent().actors.add_child(sprite)
	corpse_sprites.append(sprite)
	if corpse_sprites.size() > 100:
		corpse_sprites.pop_front().queue_free()
		corpses.pop_front()

func slash(at: Vector2, direction: Vector2) -> void:
	entries.append({"kind": "slash", "a": at, "angle": direction.angle(), "life": .24, "max": .24})

func landing(at: Vector2) -> void:
	entries.append({"kind": "dust", "a": at, "life": .28, "max": .28})

func splinters(at: Vector2) -> void:
	for i in range(12):
		entries.append({"kind": "splinter", "a": at, "velocity": Vector2.from_angle(randf() * TAU) * randf_range(25, 90), "life": .5, "max": .5})

func _process(delta: float) -> void:
	for i in range(entries.size() - 1, -1, -1):
		entries[i].life -= delta
		if entries[i].kind in ["blood", "splinter"]:
			entries[i].a += entries[i].velocity * delta
		if entries[i].life <= 0:
			entries.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for entry in entries:
		var alpha: float = entry.life / entry.max
		if entry.kind == "shot":
			draw_line(entry.a, entry.b, Color(1, .85, .52, alpha * .85), 1.5)
			draw_circle(entry.a, 5 * alpha, Color(1, .85, .5, alpha))
			if entry.hit:
				draw_rect(Rect2(entry.b - Vector2(2, 2), Vector2(4, 4)), Color(.95, .78, .47, alpha))
		elif entry.kind == "slash":
			var angle: float = entry.angle
			draw_arc(entry.a, 52, angle - 1, angle + 1, 18, Color(.9, .89, .74, alpha * .7), 3, true)
		elif entry.kind == "dust":
			draw_arc(entry.a, 10 + (1 - alpha) * 17, 0, TAU, 20, Color(.65, .62, .45, alpha * .4), 2, true)
		else:
			draw_rect(Rect2(entry.a, Vector2(2, 2)), Color(.50, .24, .18, alpha))
