extends Node2D

const PROP = preload("res://src/world/prop.gd")
const DOOR = preload("res://src/world/door.gd")
const ROOF = preload("res://src/world/roof.gd")
const SURVIVOR = preload("res://src/actors/survivor.gd")
const MAP_SIZE := Vector2(2304, 1536)
const CELL: int = 32
const SPAWN := Vector2(352, 394)

var game: Node
var actors: Node2D
var roofs: Node2D
var solid_rects: Array[Rect2] = []
var doors: Array[Node] = []
var houses: Array[Dictionary] = []
var astar := AStarGrid2D.new()
var ground: Texture2D = preload("res://art/vendor/craftpix/ground.png")
const DEBRIS: Array[Texture2D] = [
	preload("res://art/vendor/craftpix/bottle.png"),
	preload("res://art/vendor/craftpix/paper.png"),
	preload("res://art/vendor/craftpix/stone.png")
]
var decor: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var spawn_points: Array[Vector2] = [
	Vector2(755, 569), Vector2(863, 737), Vector2(1092, 917),
	Vector2(1284, 736), Vector2(1488, 655), Vector2(1780, 741),
	Vector2(2035, 868), Vector2(658, 930), Vector2(747, 1215),
	Vector2(1160, 1200), Vector2(1676, 1102), Vector2(1890, 1200),
	Vector2(1640, 500), Vector2(1090, 329), Vector2(1380, 920),
	Vector2(320, 846), Vector2(2110, 540), Vector2(2135, 1310)
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	random.seed = 7041
	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	add_child(actors)
	roofs = Node2D.new()
	roofs.z_index = 90
	add_child(roofs)
	_build_map()
	rebuild_navigation()
	queue_redraw()

func _build_map() -> void:
	add_house(Rect2(192, 192, 320, 256), "CASA 07", Color("576d65"), true)
	add_house(Rect2(1280, 192, 288, 256), "CASA 12", Color("756b58"))
	add_house(Rect2(1728, 224, 320, 224), "MERCADO AURORA", Color("5e716b"))
	add_house(Rect2(256, 1024, 288, 224), "CASA 03", Color("71644f"))
	add_house(Rect2(1280, 1024, 288, 224), "CASA 04", Color("5c6961"))
	# Blocked roads establish the boundaries of this first neighborhood.
	add_prop(Rect2(0, 0, MAP_SIZE.x, 24), "wall", Color("2b4234"))
	add_prop(Rect2(0, MAP_SIZE.y - 24, MAP_SIZE.x, 24), "wall", Color("2b4234"))
	add_prop(Rect2(0, 0, 24, MAP_SIZE.y), "wall", Color("2b4234"))
	add_prop(Rect2(MAP_SIZE.x - 24, 0, 24, MAP_SIZE.y), "wall", Color("2b4234"))
	for rect in [Rect2(28, 665, 112, 24), Rect2(86, 734, 112, 24), Rect2(2170, 670, 112, 24), Rect2(2110, 746, 130, 24), Rect2(972, 42, 142, 24), Rect2(972, 1460, 142, 24)]:
		add_prop(rect, "barricade", Color("8b7851"))
	# Park perimeter and residential fences; openings align with paths.
	for rect in [Rect2(1680, 1008, 96, 10), Rect2(1832, 1008, 288, 10), Rect2(1680, 1390, 440, 10), Rect2(176, 506, 112, 10), Rect2(416, 506, 112, 10), Rect2(1264, 506, 96, 10), Rect2(1488, 506, 96, 10)]:
		add_prop(rect, "fence", Color("8b8e70"))
	# Wrecks leave enough space for movement and pathfinding on either side.
	add_prop(Rect2(602, 688, 96, 40), "dumpster")
	add_prop(Rect2(1400, 751, 96, 40), "dumpster")
	add_prop(Rect2(1010, 1060, 96, 40), "dumpster")
	add_prop(Rect2(1868, 650, 96, 40), "dumpster")
	add_prop(Rect2(1000, 194, 96, 40), "dumpster")
	for p in [Vector2(176, 595), Vector2(832, 595), Vector2(1220, 595), Vector2(1988, 595), Vector2(160, 867), Vector2(840, 867), Vector2(1216, 867), Vector2(2050, 867)]:
		add_prop(Rect2(p - Vector2(6, 8), Vector2(12, 16)), "barrel")
	for p in [Vector2(108, 166), Vector2(630, 206), Vector2(762, 368), Vector2(870, 160), Vector2(1660, 180), Vector2(2145, 268), Vector2(120, 1100), Vector2(667, 1100), Vector2(828, 1350), Vector2(1196, 1370), Vector2(1640, 1290), Vector2(1730, 1110), Vector2(1990, 1090), Vector2(2050, 1300), Vector2(1900, 1350), Vector2(2170, 980), Vector2(150, 1390), Vector2(590, 1370), Vector2(2058, 88), Vector2(2180, 1405)]:
		add_prop(Rect2(p - Vector2(10, 12), Vector2(20, 16)), "tree")
	for rect in [Rect2(220, 148, 96, 22), Rect2(380, 148, 112, 22), Rect2(1300, 148, 100, 22), Rect2(1780, 1370, 80, 22), Rect2(1950, 950, 92, 22), Rect2(620, 400, 70, 28)]:
		add_prop(rect, "bush")
	var npc := StaticBody2D.new()
	npc.set_script(SURVIVOR)
	npc.position = Vector2(466, 548)
	actors.add_child(npc)
	for i in range(190):
		var p := Vector2(random.randf_range(40, MAP_SIZE.x - 40), random.randf_range(40, MAP_SIZE.y - 40))
		decor.append({"pos": p, "kind": random.randi_range(0, 2), "rot": random.randf_range(0, TAU)})

func add_house(rect: Rect2, title: String, color: Color, starting: bool = false) -> void:
	var door_x := rect.get_center().x
	houses.append({"rect": rect, "name": title, "door": Vector2(door_x, rect.end.y)})
	add_prop(Rect2(rect.position, Vector2(rect.size.x, 14)), "wall", Color("a0a08a"))
	add_prop(Rect2(rect.position, Vector2(14, rect.size.y)), "wall", Color("999b83"))
	add_prop(Rect2(rect.end.x - 14, rect.position.y, 14, rect.size.y), "wall", Color("999b83"))
	add_prop(Rect2(rect.position.x, rect.end.y - 14, rect.size.x / 2 - 32, 14), "wall", Color("b1ad90"))
	add_prop(Rect2(door_x + 32, rect.end.y - 14, rect.size.x / 2 - 32, 14), "wall", Color("b1ad90"))
	var door := StaticBody2D.new()
	door.set_script(DOOR)
	door.position = Vector2(door_x, rect.end.y)
	door.caption = title
	actors.add_child(door)
	doors.append(door)
	door.changed.connect(func() -> void:
		rebuild_navigation()
		game.audio.play("door", -5)
	)
	add_prop(Rect2(rect.position + Vector2(36, 60), Vector2(64, 32)), "bench")
	add_prop(Rect2(rect.position + Vector2(rect.size.x - 104, 60), Vector2(64, 32)), "bench")
	add_prop(Rect2(rect.position + Vector2(rect.size.x - 90, 116), Vector2(32, 28)), "crate")
	if starting:
		add_prop(Rect2(rect.position + Vector2(36, 154), Vector2(32, 28)), "crate")
	var roof := Node2D.new()
	roof.set_script(ROOF)
	roof.position = rect.position
	roof.size = rect.size
	roof.house_name = title
	roof.roof_color = color
	roof.variant = [0, 1, 3, 4, 2][houses.size() - 1]
	roof.entry = door
	door.changed.connect(roof.queue_redraw)
	roofs.add_child(roof)

func add_prop(rect: Rect2, kind: String, color: Color = Color("84907b")) -> StaticBody2D:
	var prop := StaticBody2D.new()
	prop.set_script(PROP)
	prop.position = Vector2(rect.get_center().x, rect.end.y)
	prop.size = rect.size
	prop.kind = kind
	prop.tint = color
	prop.collision_layer = 1
	prop.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = Vector2(0, -rect.size.y / 2.0)
	prop.add_child(collision)
	actors.add_child(prop)
	solid_rects.append(rect)
	return prop

func set_player(player: Node2D) -> void:
	for roof in roofs.get_children():
		roof.player = player

func rebuild_navigation() -> void:
	astar.region = Rect2i(0, 0, int(MAP_SIZE.x / CELL), int(MAP_SIZE.y / CELL))
	astar.cell_size = Vector2(CELL, CELL)
	astar.offset = Vector2(CELL / 2.0, CELL / 2.0)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	astar.fill_solid_region(astar.region, false)
	var obstacles: Array[Rect2] = solid_rects.duplicate()
	for door in doors:
		if not door.is_open:
			obstacles.append(door.navigation_rect())
	for rect in obstacles:
		var safe_rect := rect.grow(7)
		var a := Vector2i((safe_rect.position / CELL).floor())
		var b := Vector2i((safe_rect.end / CELL).ceil())
		for y in range(maxi(0, a.y), mini(astar.region.size.y, b.y + 1)):
			for x in range(maxi(0, a.x), mini(astar.region.size.x, b.x + 1)):
				var id := Vector2i(x, y)
				if safe_rect.has_point(astar.get_point_position(id)):
					astar.set_point_solid(id)

func _nearest_free(at: Vector2) -> Vector2i:
	var cell := Vector2i((at / CELL).floor()).clamp(Vector2i.ZERO, astar.region.size - Vector2i.ONE)
	if not astar.is_point_solid(cell):
		return cell
	for radius in range(1, 5):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var id := cell + Vector2i(x, y)
				if astar.is_in_boundsv(id) and not astar.is_point_solid(id):
					return id
	return cell

func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := _nearest_free(from)
	var end := _nearest_free(to)
	if astar.is_point_solid(start) or astar.is_point_solid(end):
		return PackedVector2Array()
	return astar.get_point_path(start, end)

func has_line_of_sight(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _ground_region(tile: int, point: Vector2) -> Rect2:
	return Rect2(tile * 128 + posmod(int(point.x), 128), posmod(int(point.y), 128), CELL, CELL)

func _draw() -> void:
	# Ground is one static CanvasItem, rather than thousands of individual nodes.
	for y in range(int(MAP_SIZE.y / CELL)):
		for x in range(int(MAP_SIZE.x / CELL)):
			var p := Vector2(x * CELL, y * CELL)
			var tile := 0
			if (p.y >= 640 and p.y < 800) or (p.x >= 960 and p.x < 1120):
				tile = 1
			elif (p.y >= 608 and p.y < 832) or (p.x >= 928 and p.x < 1152):
				tile = 2
			elif x < 2 or y < 2 or x > 69 or y > 45:
				tile = 5
			draw_texture_rect_region(ground, Rect2(p, Vector2(CELL, CELL)), _ground_region(tile, p))
	for x in range(32, int(MAP_SIZE.x), 64):
		draw_rect(Rect2(x, 716, 30, 3), Color("a3a287"))
	for y in range(48, int(MAP_SIZE.y), 64):
		draw_rect(Rect2(1038, y, 3, 30), Color("a3a287"))
	# Crosswalks on each side of the intersection.
	for i in range(6):
		draw_rect(Rect2(905, 649 + i * 25, 19, 12), Color("b0af97"))
		draw_rect(Rect2(1157, 649 + i * 25, 19, 12), Color("b0af97"))
	for house in houses:
		var rect: Rect2 = house.rect
		var path := Rect2(Vector2(house.door.x - 32, rect.end.y), Vector2(64, maxf(0, 608 - rect.end.y)))
		if path.size.y > 0:
			draw_rect(path.grow(4), Color("5e624b"))
			for py in range(int(path.position.y), int(path.end.y), CELL):
				for px in range(int(path.position.x), int(path.end.x), CELL):
					draw_texture_rect_region(ground, Rect2(px, py, CELL, CELL), _ground_region(2, Vector2(px, py)))
		for py in range(int(rect.position.y), int(rect.end.y), CELL):
			for px in range(int(rect.position.x), int(rect.end.x), CELL):
				draw_texture_rect_region(ground, Rect2(px, py, CELL, CELL), _ground_region(3, Vector2(px, py)))
	# A quiet park, with a looping dirt path.
	for y in range(1008, 1390, CELL):
		draw_texture_rect_region(ground, Rect2(1784, y, CELL, CELL), _ground_region(4, Vector2(1784, y)))
	for x in range(1784, 2084, CELL):
		draw_texture_rect_region(ground, Rect2(x, 1190, CELL, CELL), _ground_region(4, Vector2(x, 1190)))
	for item in decor:
		var p: Vector2 = item.pos
		var indoors := false
		for house in houses:
			if house.rect.has_point(p):
				indoors = true
		if indoors:
			continue
		draw_texture_rect(DEBRIS[item.kind], Rect2(p, Vector2(24, 24)), false)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(480, 781), "RUA DAS ACÁCIAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a5ab91"))
	draw_string(font, Vector2(1820, 1280), "PRAÇA AURORA", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("9ba887"))
