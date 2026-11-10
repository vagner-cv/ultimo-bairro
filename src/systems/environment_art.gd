extends RefCounted

const BASE := "res://art/environment/"
const GRASS: Texture2D = preload(BASE + "grass.png")
const ASPHALT: Texture2D = preload(BASE + "asphalt.png")
const PAVING: Texture2D = preload(BASE + "paving.png")
const WOOD: Texture2D = preload(BASE + "wood_floor.png")
const BUILDINGS: Array[Texture2D] = [preload(BASE + "house.png"), preload(BASE + "store.png"), preload(BASE + "civic.png"), preload(BASE + "warehouse.png")]
const PROPS := {
	"tree": preload(BASE + "tree.png"), "pine": preload(BASE + "pine.png"),
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
	"crate": preload("res://art/survival/wood.png")
}
const WALLS: Array[Texture2D] = [preload(BASE + "wall_plaster.png"), preload(BASE + "wall_brick.png"), preload(BASE + "wall_wood.png")]
const DOOR_CLOSED: Texture2D = preload(BASE + "door_closed.png")
const DOOR_OPEN: Texture2D = preload(BASE + "door_open.png")
const WINDOW: Texture2D = preload(BASE + "window.png")

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

static func door(canvas: CanvasItem, at: Vector2, opened: bool) -> void:
	var texture: Texture2D = DOOR_OPEN if opened else DOOR_CLOSED
	canvas.draw_texture_rect(texture, Rect2(at + Vector2(4, -8), Vector2(56, 76)), false)
