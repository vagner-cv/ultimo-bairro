extends RefCounted

const BASE := "res://art/pixel/"
const GRASS: Texture2D = preload(BASE + "grass.png")
const ASPHALT: Texture2D = preload(BASE + "asphalt.png")
const PAVING: Texture2D = preload(BASE + "paving.png")
const WOOD: Texture2D = preload(BASE + "wood_floor.png")
const BUILDINGS: Array[Texture2D] = [preload(BASE + "house_plaster.png"), preload(BASE + "house_blue.png"), preload(BASE + "house_brick.png"), preload(BASE + "house_timber.png"), preload(BASE + "store.png"), preload(BASE + "clinic.png"), preload(BASE + "warehouse.png"), preload(BASE + "house_stucco.png")]
const TREES: Array[Texture2D] = [preload(BASE + "oak.png"), preload(BASE + "pine.png"), preload(BASE + "birch.png"), preload(BASE + "palm.png"), preload(BASE + "willow.png"), preload(BASE + "maple.png"), preload(BASE + "dead_tree.png"), preload(BASE + "fruit_tree.png")]
const FOLIAGE: Array[Texture2D] = [preload(BASE + "flower_bush.png"), preload(BASE + "fern.png"), preload(BASE + "tall_grass.png"), preload(BASE + "wildflowers.png"), preload(BASE + "weeds.png"), preload(BASE + "lavender.png")]
const PROPS := {
	"tree": preload(BASE + "oak.png"), "pine": preload(BASE + "pine.png"),
	"hedge": preload(BASE + "hedge.png"), "bush": preload(BASE + "bush.png"),
	"fence": preload(BASE + "fence.png"), "wood_fence": preload(BASE + "wood_fence.png"),
	"bench": preload(BASE + "bench.png"), "barricade": preload(BASE + "barricade.png"),
	"barrel": preload(BASE + "barrel.png"), "lamp": preload(BASE + "lamp.png"),
	"woodpile": preload(BASE + "woodpile.png"), "car": preload(BASE + "car.png"),
	"leaves": preload(BASE + "leaves.png"), "drain": preload(BASE + "drain.png"),
	"rubble": preload(BASE + "rubble.png"), "bicycle": preload(BASE + "bicycle.png"),
	"sofa": preload(BASE + "sofa.png"), "table": preload(BASE + "table.png"),
	"bed": preload(BASE + "bed.png"), "bookcase": preload(BASE + "bookcase.png"),
	"hospital_bed": preload(BASE + "hospital_bed.png"), "workbench": preload(BASE + "workbench.png"),
	"fridge": preload(BASE + "fridge.png"), "armchair": preload(BASE + "armchair.png"),
	"desk": preload(BASE + "desk.png"), "ivy": preload(BASE + "ivy.png"),
	"well": preload(BASE + "well.png"), "plant": preload(BASE + "plant.png"),
	"crate": preload("res://art/pixel/wood.png")
}
const WALLS: Array[Texture2D] = [preload(BASE + "wall_plaster.png"), preload(BASE + "wall_brick.png"), preload(BASE + "wall_wood.png")]
const DOORS_CLOSED: Array[Texture2D] = [preload(BASE + "door_wood.png"), preload(BASE + "door_blue.png"), preload(BASE + "door_steel.png")]
const DOORS_OPEN: Array[Texture2D] = [preload(BASE + "door_wood_open.png"), preload(BASE + "door_blue_open.png"), preload(BASE + "door_steel_open.png")]

static func building_sprite(title: String, variant: int) -> int:
	var category := building_type(title)
	if category == 1:
		return 4
	if category == 2:
		return 5
	if category == 3:
		return 6
	return [0, 1, 2, 3, 7][posmod(variant, 5)]

static func building_type(title: String) -> int:
	if title.begins_with("GALPÃO") or title in ["OFICINA", "DEPÓSITO", "ARMAZÉM", "TERMINAL"]:
		return 3
	if title in ["CLÍNICA", "DELEGACIA", "ESCOLA", "BIBLIOTECA", "POSTO DE RESGATE", "ABRIGO SUL"]:
		return 2
	if title in ["MERCADO AURORA", "MERCEARIA", "CAFETERIA", "FARMÁCIA"]:
		return 1
	return 0

static func surface(canvas: CanvasItem, texture: Texture2D, rect: Rect2, tile_size: float = 256, color: Color = Color.WHITE) -> void:
	var ratio := texture.get_size() / tile_size
	canvas.draw_texture_rect_region(texture, rect, Rect2(rect.position * ratio, rect.size * ratio), color, false, false)

static func door(canvas: CanvasItem, at: Vector2, opened: bool, variant: int = 0) -> void:
	var texture: Texture2D = DOORS_OPEN[posmod(variant, 3)] if opened else DOORS_CLOSED[posmod(variant, 3)]
	canvas.draw_texture_rect(texture, Rect2(at + Vector2(4, -8), Vector2(56, 76)), false)
