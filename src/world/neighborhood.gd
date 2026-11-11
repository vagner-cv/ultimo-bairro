extends Node2D

const ART = preload("res://src/systems/environment_art.gd")
const PROP = preload("res://src/world/prop.gd")
const DOOR = preload("res://src/world/door.gd")
const ROOF = preload("res://src/world/roof.gd")
const SURVIVOR = preload("res://src/actors/survivor.gd")
const FOLIAGE = preload("res://src/world/foliage.gd")
const MAP_SIZE := Vector2(4608, 3072)
const CELL: int = 32
const ROAD_X := [960, 2464, 3776]
const ROAD_Y := [640, 1600, 2560]
const CONTAINER = preload("res://src/world/container.gd")
const LOOT = preload("res://src/systems/loot.gd")
const SHADOW = preload("res://src/world/building_shadows.gd")
const SPAWN := Vector2(352, 394)

var game: Node
var actors: Node2D
var roofs: Node2D
var solid_rects: Array[Rect2] = []
var dynamic_obstacles: Array[Node] = []
var doors: Array[Node] = []
var houses: Array[Dictionary] = []
var astar := AStarGrid2D.new()
const DEBRIS: Array[Texture2D] = [ART.PROPS.leaves, ART.PROPS.rubble, ART.PROPS.leaves]
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
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	random.randomize()
	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	actors.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	add_child(actors)
	roofs = Node2D.new()
	roofs.z_index = 90
	roofs.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	add_child(roofs)
	var shadows := SHADOW.new()
	shadows.world = self
	shadows.z_index = 0
	add_child(shadows)
	move_child(shadows, 0)
	_build_map()
	rebuild_navigation()
	queue_redraw()

func _build_map() -> void:
	add_house(Rect2(192, 192, 320, 256), "CASA 07", Color("576d65"), true)
	add_house(Rect2(1280, 192, 288, 256), "CASA 12", Color("756b58"))
	add_house(Rect2(1728, 224, 320, 224), "MERCADO AURORA", Color("5e716b"))
	add_house(Rect2(256, 1024, 288, 224), "CASA 03", Color("71644f"))
	add_house(Rect2(1280, 1024, 288, 224), "CASA 04", Color("5c6961"))
	# Districts are all explorable; every building has its own door and storage.
	var additions := [
	 [Rect2(608, 192, 256, 256), "CASA 09"],
	 [Rect2(2080, 192, 256, 288), "FARMÁCIA"],
	 [Rect2(2784, 192, 320, 288), "CLÍNICA"],
	 [Rect2(3264, 192, 320, 256), "DELEGACIA"],
	 [Rect2(4032, 192, 384, 288), "OFICINA"],
	 [Rect2(640, 1024, 224, 224), "CASA 05"],
	 [Rect2(1728, 1024, 320, 256), "MERCEARIA"],
	 [Rect2(2080, 1024, 256, 288), "CAFETERIA"],
	 [Rect2(2784, 1024, 320, 288), "ESCOLA"],
	 [Rect2(3264, 1024, 320, 256), "BIBLIOTECA"],
	 [Rect2(4032, 1024, 384, 288), "POSTO DE RESGATE"],
	 [Rect2(192, 1920, 320, 256), "CASA 18"],
	 [Rect2(608, 1920, 256, 256), "CASA 19"],
	 [Rect2(1280, 1920, 320, 288), "HORTA COMUNITÁRIA"],
	 [Rect2(1728, 1920, 320, 256), "CASA 22"],
	 [Rect2(2080, 1920, 256, 288), "ARMAZÉM"],
	 [Rect2(2752, 1888, 384, 352), "GALPÃO A"],
	 [Rect2(3264, 1888, 384, 352), "GALPÃO B"],
	 [Rect2(192, 2784, 320, 224), "CASA 27"],
	 [Rect2(1280, 2784, 320, 224), "ABRIGO SUL"],
	 [Rect2(2784, 2784, 320, 224), "DEPÓSITO"],
	 [Rect2(4032, 2784, 384, 224), "TERMINAL"],
	]
	for index in range(additions.size()):
		add_house(additions[index][0], additions[index][1], Color.from_hsv(.08 + index % 4 * .055, .18, .52))
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
	add_container(Rect2(602, 688, 96, 40), "dumpster", "Lixeira")
	add_container(Rect2(1400, 751, 96, 40), "dumpster", "Lixeira")
	add_container(Rect2(1010, 1060, 96, 40), "dumpster", "Lixeira")
	add_container(Rect2(1868, 650, 96, 40), "dumpster", "Lixeira")
	add_container(Rect2(1000, 194, 96, 40), "dumpster", "Lixeira")
	for p in [Vector2(176, 595), Vector2(832, 595), Vector2(1220, 595), Vector2(1988, 595), Vector2(160, 867), Vector2(840, 867), Vector2(1216, 867), Vector2(2050, 867)]:
		add_prop(Rect2(p - Vector2(6, 8), Vector2(12, 16)), "barrel")
	for p in [Vector2(108, 166), Vector2(630, 206), Vector2(762, 368), Vector2(870, 160), Vector2(1660, 180), Vector2(2145, 268), Vector2(120, 1100), Vector2(667, 1100), Vector2(828, 1350), Vector2(1196, 1370), Vector2(1640, 1290), Vector2(1730, 1110), Vector2(1990, 1090), Vector2(2050, 1300), Vector2(1900, 1350), Vector2(2170, 980), Vector2(150, 1390), Vector2(590, 1370), Vector2(2058, 88), Vector2(2180, 1405)]:
		add_prop(Rect2(p - Vector2(10, 12), Vector2(20, 16)), "tree")
	for rect in [Rect2(220, 148, 96, 22), Rect2(380, 148, 112, 22), Rect2(1300, 148, 100, 22), Rect2(1780, 1370, 80, 22), Rect2(1950, 950, 92, 22), Rect2(620, 400, 70, 28)]:
		add_prop(rect, "bush")
	# Park east: benches, paths, foliage, bins and an accessible central lawn.
	for p in [Vector2(3910, 1890), Vector2(4420, 1890), Vector2(3910, 2390), Vector2(4420, 2390), Vector2(4180, 1820), Vector2(4470, 2150)]:
		add_prop(Rect2(p, Vector2(20, 16)), "tree")
	for p in [Vector2(3950, 2030), Vector2(4350, 2260), Vector2(3950, 2280), Vector2(4350, 2030)]:
		add_prop(Rect2(p, Vector2(64, 28)), "bench")
	for ry in ROAD_Y:
		for rx in ROAD_X:
			add_container(Rect2(rx + 200, ry + 18, 80, 34), "dumpster", "Lixeira da rua")
			add_prop(Rect2(rx + 220, ry - 60, 20, 16), "tree")
	for p in [Vector2(2740, 2310), Vector2(2800, 2310), Vector2(3270, 2340), Vector2(3330, 2340), Vector2(3400, 2340)]:
		add_container(Rect2(p, Vector2(38, 28)), "wood", "Caixa de madeira")
	for p in [Vector2(4250, 1450), Vector2(3290, 1450), Vector2(2150, 1450), Vector2(2810, 530)]:
		add_container(Rect2(p, Vector2(36, 26)), "cardboard", "Caixa de papelão")
	for y in [900, 1810, 2440]:
		for x in [120, 600, 1210, 1660, 2700, 3180, 3650, 4490]:
			add_prop(Rect2(x, y, 20, 16), "tree")
	# Orchard and park clusters leave the streets and all entrances accessible.
	for p in [Vector2(1450, 2340), Vector2(1580, 2340), Vector2(1450, 2460), Vector2(1580, 2460)]:
		var tree := add_prop(Rect2(p, Vector2(20, 16)), "tree")
		if tree:
			tree.variant = 7
	for p in [Vector2(4080, 2360), Vector2(4290, 1880), Vector2(4490, 2380)]:
		var tree := add_prop(Rect2(p, Vector2(20, 16)), "tree")
		if tree:
			tree.variant = 3
	_plant_gardens()
	# Street dressing uses the same detailed materials as interactive objects.
	for p in [Vector2(460, 760), Vector2(2830, 730), Vector2(4160, 1650), Vector2(1320, 2640)]:
		add_prop(Rect2(p, Vector2(126, 44)), "car")
	for ry in ROAD_Y:
		for rx in ROAD_X:
			add_prop(Rect2(rx - 47, ry - 50, 12, 12), "lamp")
			add_prop(Rect2(rx + 191, ry + 195, 12, 12), "lamp")
	for p in [Vector2(1670, 1280), Vector2(4420, 2240), Vector2(2740, 2400)]:
		add_prop(Rect2(p, Vector2(54, 23)), "woodpile")
	add_prop(Rect2(4120, 2150, 48, 28), "well")
	var npc := StaticBody2D.new()
	npc.set_script(SURVIVOR)
	npc.position = Vector2(466, 548)
	actors.add_child(npc)
	for i in range(700):
		var p := Vector2(random.randf_range(40, MAP_SIZE.x - 40), random.randf_range(40, MAP_SIZE.y - 40))
		decor.append({"pos": p, "kind": random.randi_range(0, 2), "rot": random.randf_range(0, TAU)})

func add_house(rect: Rect2, title: String, color: Color, starting: bool = false) -> void:
	var door_x := rect.get_center().x
	var residential_variant := 0
	for house in houses:
		if ART.building_type(house.name) == 0:
			residential_variant += 1
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
	door.variant = (houses.size() - 1) % 3
	actors.add_child(door)
	doors.append(door)
	door.changed.connect(func() -> void:
		rebuild_navigation()
		game.audio.play("door", -5)
	)
	add_container(Rect2(rect.position + Vector2(36, 60), Vector2(46, 26)), "drawer", "Gaveteiro")
	var locker = add_container(Rect2(rect.position + Vector2(rect.size.x - 84, 56), Vector2(34, 22)), "locker", "Armário")
	if starting:
		locker.inventory.add("rifle")
		locker.inventory.add("ammo_rifle", 45)
	add_container(Rect2(rect.position + Vector2(rect.size.x - 90, 124), Vector2(36, 26)), "cardboard", "Caixa de papelão")
	if starting:
		var box = add_container(Rect2(rect.position + Vector2(36, 154), Vector2(38, 28)), "wood", "Caixa de madeira")
		box.inventory.add("shotgun")
		box.inventory.add("ammo_shell", 12)
	if title in ["CLÍNICA", "FARMÁCIA"]:
		locker.caption = "Armário de medicamentos"
		locker.inventory.add("herb", 4)
	elif title == "DELEGACIA":
		locker.caption = "Armário de armamento"
		locker.inventory.add("rifle")
		locker.inventory.add("ammo_rifle", 60)
		locker.inventory.add("ammo_shell", 12)
	elif title.begins_with("GALPÃO") or title == "DEPÓSITO":
		for x in [56, int(rect.size.x) - 96]:
			add_container(Rect2(rect.position + Vector2(x, rect.size.y - 100), Vector2(38, 28)), "wood", "Caixa de suprimentos")
	elif title == "ESCOLA":
		for x in [36, int(rect.size.x) - 100]:
			add_prop(Rect2(rect.position + Vector2(x, 170), Vector2(64, 28)), "bench")
	elif title == "BIBLIOTECA":
		add_container(Rect2(rect.position + Vector2(36, 160), Vector2(46, 26)), "drawer", "Gaveta de arquivos")
	_furnish(rect, title)
	var roof := Node2D.new()
	roof.set_script(ROOF)
	roof.position = rect.position
	roof.size = rect.size
	roof.house_name = title
	roof.roof_color = color
	roof.variant = residential_variant
	roof.entry = door
	door.changed.connect(roof.queue_redraw)
	roofs.add_child(roof)

func add_prop(rect: Rect2, kind: String, color: Color = Color("84907b")) -> StaticBody2D:
	if kind in ["tree", "bush"]:
		for house in houses:
			if house.rect.grow(14).has_point(rect.get_center()):
				return null
	var prop := StaticBody2D.new()
	prop.set_script(PROP)
	prop.position = Vector2(rect.get_center().x, rect.end.y)
	prop.size = rect.size
	prop.kind = kind
	prop.variant = (absi(int(rect.position.x / 80) + int(rect.position.y / 64)) % ART.TREES.size()) if kind == "tree" else houses.size() % 3
	prop.tint = color
	prop.collision_layer = 16 if kind in ["bench", "crate", "barrel", "barricade", "sofa", "bed", "hospital_bed", "table", "armchair", "woodpile", "desk"] else 1
	if prop.collision_layer == 16:
		prop.add_to_group("platforms")
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

func _plant_gardens() -> void:
	# Plants are decorative: only tree trunks/large hedges obstruct movement.
	var garden_random := RandomNumberGenerator.new()
	garden_random.seed = 73419
	for index in range(houses.size()):
		var house: Dictionary = houses[index]
		for side in [-1, 1]:
			for step in range(3):
				var plant := FOLIAGE.new()
				plant.position = Vector2(house.door.x + side * (57 + step * 26), house.rect.end.y + 30)
				plant.variant = (index + step) % 6
				plant.dimensions = Vector2(32, 28)
				actors.add_child(plant)
	for i in range(380):
		var p := Vector2(garden_random.randf_range(50, MAP_SIZE.x - 50), garden_random.randf_range(50, MAP_SIZE.y - 50))
		var blocked := false
		for rx in ROAD_X:
			if p.x > rx - 36 and p.x < rx + 196:
				blocked = true
		for ry in ROAD_Y:
			if p.y > ry - 36 and p.y < ry + 196:
				blocked = true
		for house in houses:
			if house.rect.grow(12).has_point(p) or absf(p.x - house.door.x) < 40:
				blocked = true
		if blocked:
			continue
		var plant := FOLIAGE.new()
		plant.position = p.round()
		plant.variant = 1 + i % 5
		plant.dimensions = Vector2(19, 17) if i % 3 else Vector2(32, 28)
		actors.add_child(plant)

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
	for obstacle in dynamic_obstacles:
		if is_instance_valid(obstacle) and not obstacle.broken:
			obstacles.append(obstacle.navigation_rect())
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
	var query := PhysicsRayQueryParameters2D.create(from, to, 1 | 16)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _draw() -> void:
	# Detailed repeating materials are batched into large quads, keeping the map light.
	ART.surface(self, ART.GRASS, Rect2(Vector2.ZERO, MAP_SIZE), 256)
	for rx in ROAD_X:
		ART.surface(self, ART.PAVING, Rect2(rx - 32, 0, 224, MAP_SIZE.y), 192)
	for ry in ROAD_Y:
		ART.surface(self, ART.PAVING, Rect2(0, ry - 32, MAP_SIZE.x, 224), 192)
	for rx in ROAD_X:
		ART.surface(self, ART.ASPHALT, Rect2(rx, 0, 160, MAP_SIZE.y), 256)
	for ry in ROAD_Y:
		ART.surface(self, ART.ASPHALT, Rect2(0, ry, MAP_SIZE.x, 160), 256)
	for ry in ROAD_Y:
		for x in range(32, int(MAP_SIZE.x), 72):
			var worn := .3 if x % 5 == 0 else .58
			draw_rect(Rect2(x, ry + 78, 30, 2), Color(.79, .71, .47, worn))
		for rx in ROAD_X:
			for i in range(6):
				draw_rect(Rect2(rx - 27, ry + 10 + i * 24, 18, 10), Color(.79, .78, .69, .55))
				draw_rect(Rect2(rx + 169, ry + 10 + i * 24, 18, 10), Color(.79, .78, .69, .55))
	for rx in ROAD_X:
		for y in range(40, int(MAP_SIZE.y), 72):
			draw_rect(Rect2(rx + 78, y, 2, 30), Color(.79, .71, .47, .5))
	for rx in ROAD_X:
		for ry in ROAD_Y:
			draw_texture_rect(ART.PROPS.drain, Rect2(rx + 139, ry - 30, 18, 14), false)
			draw_texture_rect(ART.PROPS.drain, Rect2(rx - 28, ry + 141, 18, 14), false)
	for house in houses:
		var rect: Rect2 = house.rect
		var road_below: float = MAP_SIZE.y - 48
		for ry in ROAD_Y:
			if ry > rect.end.y:
				road_below = ry - 32
				break
		var path := Rect2(Vector2(house.door.x - 32, rect.end.y), Vector2(64, maxf(0, road_below - rect.end.y)))
		if path.size.y > 0:
			ART.surface(self, ART.PAVING, path, 192, Color(.92, .94, .89))
		var kind := ART.building_type(house.name)
		var material: Texture2D = ART.WOOD if kind in [0, 1] else ART.PAVING
		ART.surface(self, material, rect, 224 if kind == 0 else 160, Color(.88, .85, .79) if kind == 3 else Color.WHITE)
	for park in [Rect2(1680, 1008, 440, 382), Rect2(3900, 1820, 580, 600)]:
		ART.surface(self, ART.PAVING, Rect2(park.get_center().x - 16, park.position.y, 32, park.size.y), 192, Color(.81, .78, .67))
		ART.surface(self, ART.PAVING, Rect2(park.position.x, park.get_center().y - 16, park.size.x, 32), 192, Color(.81, .78, .67))
	for item in decor:
		var p: Vector2 = item.pos
		var indoors := false
		for house in houses:
			if house.rect.has_point(p):
				indoors = true
				break
		if indoors:
			continue
		var texture: Texture2D = DEBRIS[item.kind]
		var dimensions := Vector2(30, 24) if item.kind != 0 else Vector2(49, 35)
		draw_set_transform(p, item.rot)
		draw_texture_rect(texture, Rect2(-dimensions / 2, dimensions), false, Color(1, 1, 1, .7 if item.kind == 0 else .85))
	draw_set_transform(Vector2.ZERO)
	var font := preload("res://art/regular.ttf")
	for district in [[Vector2(480, 781), "RUA DAS ACÁCIAS"], [Vector2(1820, 1280), "PRAÇA AURORA"], [Vector2(2820, 1740), "DISTRITO INDUSTRIAL"], [Vector2(4030, 2130), "PARQUE DAS PALMEIRAS"], [Vector2(2810, 780), "AVENIDA DO COMÉRCIO"]]:
		draw_string(font, district[0], district[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(.76, .74, .63, .65))

func _furnish(rect: Rect2, title: String) -> void:
	var kind := ART.building_type(title)
	if kind == 0:
		if rect.size.x >= 288:
			add_prop(Rect2(rect.position + Vector2(100, 68), Vector2(76, 24)), "sofa")
		add_prop(Rect2(rect.position + Vector2(38, 116), Vector2(40, 36)), "bed")
		add_prop(Rect2(rect.position + Vector2(rect.size.x / 2 - 18, 140), Vector2(47, 24)), "table")
	elif title in ["CLÍNICA", "POSTO DE RESGATE"]:
		for x in [36, int(rect.size.x) - 90]:
			add_prop(Rect2(rect.position + Vector2(x, 152), Vector2(43, 38)), "hospital_bed")
	elif title == "BIBLIOTECA":
		add_prop(Rect2(rect.position + Vector2(105, 50), Vector2(62, 21)), "bookcase")
		add_prop(Rect2(rect.position + Vector2(130, 150), Vector2(68, 26)), "desk")
	elif kind == 3:
		add_prop(Rect2(rect.position + Vector2(36, 160), Vector2(75, 28)), "workbench")
		if rect.size.x >= 320:
			add_prop(Rect2(rect.position + Vector2(120, 50), Vector2(62, 21)), "bookcase")
	elif title == "DELEGACIA":
		add_prop(Rect2(rect.position + Vector2(100, 156), Vector2(68, 26)), "desk")
	else:
		add_prop(Rect2(rect.position + Vector2(102, 50), Vector2(62, 21)), "bookcase")
		add_prop(Rect2(rect.position + Vector2(rect.size.x / 2 - 20, 166), Vector2(47, 24)), "table")
	if rect.size.x >= 288 and kind == 0:
		add_prop(Rect2(rect.position + Vector2(rect.size.x - 66, rect.size.y - 64), Vector2(22, 18)), "armchair")

func add_container(rect: Rect2, kind: String, caption: String) -> StaticBody2D:
	var object = CONTAINER.new()
	object.game = game
	object.kind = kind
	object.caption = caption
	object.size = rect.size
	object.position = Vector2(rect.get_center().x, rect.end.y)
	object.inventory = LOOT.roll(random, kind)
	actors.add_child(object)
	dynamic_obstacles.append(object)
	return object

func support_height(at: Vector2) -> float:
	var result := 0.0
	for platform in get_tree().get_nodes_in_group("platforms"):
		if platform.navigation_rect().has_point(at + Vector2(0, -6)):
			result = maxf(result, platform.platform_height)
	return result

func wave_spawn(at: Vector2) -> Vector2:
	var half_view: Vector2 = get_viewport_rect().size / game.player.camera.zoom / 2
	var radius: float = maxf(520, half_view.length() + 80)
	for attempt in range(80):
		var point := at + Vector2.from_angle(random.randf() * TAU) * random.randf_range(radius, radius + 400)
		point = point.clamp(Vector2(64, 64), MAP_SIZE - Vector2(64, 64))
		var cell := Vector2i((point / CELL).floor())
		if astar.is_in_boundsv(cell) and not astar.is_point_solid(cell) and point.distance_to(at) > 450:
			var indoors := false
			for house in houses:
				if house.rect.grow(24).has_point(point):
					indoors = true
					break
			if not indoors:
				return astar.get_point_position(cell)
	return Vector2(752, 880)
