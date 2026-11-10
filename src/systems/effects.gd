extends Node2D

var entries: Array[Dictionary] = []
var corpses: Array[Dictionary] = []

func tracer(start: Vector2, end: Vector2, hit: bool) -> void:
	entries.append({"kind": "shot", "a": start, "b": end, "life": .12, "max": .12, "hit": hit})

func blood(at: Vector2, direction: Vector2) -> void:
	for i in range(7):
		var angle := direction.angle() + randf_range(-.8, .8)
		entries.append({"kind": "blood", "a": at, "velocity": Vector2.from_angle(angle) * randf_range(25, 70), "life": .32, "max": .32})

func corpse(at: Vector2, tint: Color) -> void:
	corpses.append({"at": at, "tint": tint, "angle": randf_range(-.6, .6)})

func _process(delta: float) -> void:
	for i in range(entries.size() - 1, -1, -1):
		entries[i].life -= delta
		if entries[i].kind == "blood":
			entries[i].a += entries[i].velocity * delta
		if entries[i].life <= 0:
			entries.remove_at(i)
	queue_redraw()

func _draw() -> void:
	for body in corpses:
		var p: Vector2 = body.at
		draw_circle(p, 13, Color(.23, .14, .12, .35))
		draw_rect(Rect2(p + Vector2(-13, -6), Vector2(26, 10)), Color(body.tint).darkened(.25))
		draw_rect(Rect2(p + Vector2(10, -5), Vector2(8, 8)), Color("7a8263"))
		draw_rect(Rect2(p + Vector2(-19, -5), Vector2(9, 4)), Color("2b3d3b"))
	for entry in entries:
		var alpha: float = entry.life / entry.max
		if entry.kind == "shot":
			draw_line(entry.a, entry.b, Color(1, .85, .52, alpha * .85), 1.5)
			draw_circle(entry.a, 5 * alpha, Color(1, .85, .5, alpha))
			if entry.hit:
				draw_rect(Rect2(entry.b - Vector2(2, 2), Vector2(4, 4)), Color(.95, .78, .47, alpha))
		else:
			draw_rect(Rect2(entry.a, Vector2(2, 2)), Color(.50, .24, .18, alpha))
