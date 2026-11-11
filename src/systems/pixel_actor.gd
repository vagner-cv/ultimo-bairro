extends RefCounted

# Every atlas frame contains the complete body, both hands and held weapon.
# Rows: S, SE, E, NE, N, NW, W, SW. Columns: idle, left step, right step, attack.
const CELL := Vector2(96, 80)
const BASELINE := Vector2(48, 74)
const TEXTURES := {
	"pistol": preload("res://art/pixel/hero_pistol.png"),
	"shotgun": preload("res://art/pixel/hero_shotgun.png"),
	"rifle": preload("res://art/pixel/hero_rifle.png"),
	"knife": preload("res://art/pixel/hero_knife.png")
}
# Barrel tips measured on the packed, complete sprites, relative to the feet.
const MUZZLES := {
	"pistol": [
		[Vector2(0, -30), Vector2(0, -34), Vector2(0, -34), Vector2(-1, -37)],
		[Vector2(15, -33), Vector2(15, -33), Vector2(15, -34), Vector2(16, -35)],
		[Vector2(23, -44), Vector2(22, -44), Vector2(22, -44), Vector2(23, -45)],
		[Vector2(21, -53), Vector2(21, -53), Vector2(21, -53), Vector2(23, -53)],
		[Vector2(2, -64), Vector2(2, -64), Vector2(2, -64), Vector2(2, -64)],
		[Vector2(-20, -55), Vector2(-19, -55), Vector2(-19, -54), Vector2(-20, -56)],
		[Vector2(-24, -46), Vector2(-24, -46), Vector2(-24, -46), Vector2(-25, -46)],
		[Vector2(-20, -37), Vector2(-19, -37), Vector2(-19, -35), Vector2(-20, -39)],
	],
	"shotgun": [
		[Vector2(7, -25), Vector2(7, -25), Vector2(8, -25), Vector2(8, -28)],
		[Vector2(22, -29), Vector2(21, -28), Vector2(21, -29), Vector2(24, -30)],
		[Vector2(32, -44), Vector2(32, -44), Vector2(32, -44), Vector2(32, -43)],
		[Vector2(24, -54), Vector2(24, -54), Vector2(24, -55), Vector2(25, -56)],
		[Vector2(2, -64), Vector2(2, -64), Vector2(2, -64), Vector2(2, -64)],
		[Vector2(-26, -56), Vector2(-27, -56), Vector2(-27, -56), Vector2(-28, -55)],
		[Vector2(-33, -44), Vector2(-34, -46), Vector2(-34, -46), Vector2(-35, -46)],
		[Vector2(-24, -30), Vector2(-24, -31), Vector2(-23, -32), Vector2(-23, -32)],
	],
	"rifle": [
		[Vector2(0, -31), Vector2(0, -31), Vector2(0, -30), Vector2(9, -35)],
		[Vector2(20, -30), Vector2(21, -30), Vector2(21, -30), Vector2(24, -29)],
		[Vector2(28, -43), Vector2(28, -43), Vector2(28, -43), Vector2(30, -44)],
		[Vector2(26, -52), Vector2(26, -54), Vector2(26, -54), Vector2(26, -56)],
		[Vector2(2, -64), Vector2(2, -64), Vector2(2, -64), Vector2(2, -64)],
		[Vector2(-24, -54), Vector2(-23, -55), Vector2(-23, -55), Vector2(-24, -57)],
		[Vector2(-30, -44), Vector2(-30, -46), Vector2(-30, -46), Vector2(-31, -44)],
		[Vector2(-19, -30), Vector2(-19, -32), Vector2(-19, -32), Vector2(-21, -30)],
	],
	"knife": [
		[Vector2(-20, -16), Vector2(-20, -16), Vector2(-18, -16), Vector2(-25, -19)],
		[Vector2(16, -28), Vector2(19, -31), Vector2(20, -34), Vector2(21, -39)],
		[Vector2(7, -42), Vector2(13, -34), Vector2(11, -36), Vector2(33, -36)],
		[Vector2(21, -42), Vector2(21, -48), Vector2(22, -50), Vector2(32, -55)],
		[Vector2(11, -44), Vector2(11, -44), Vector2(11, -44), Vector2(11, -44)],
		[Vector2(-25, -47), Vector2(-23, -50), Vector2(-22, -54), Vector2(-30, -55)],
		[Vector2(-27, -34), Vector2(-27, -34), Vector2(-28, -34), Vector2(-40, -34)],
		[Vector2(-28, -22), Vector2(-26, -22), Vector2(-23, -26), Vector2(-33, -21)],
	],
}

static func facing_for(direction: Vector2) -> int:
	return posmod(roundi((PI / 2 - direction.angle()) / (PI / 4)), 8)

static func frame_for(moving: bool, animation: float, firing: bool, slashing: bool) -> int:
	if slashing:
		return 3
	if moving:
		return [1, 0, 2, 0][posmod(int(animation), 4)]
	return 3 if firing else 0

static func pose(id: String, facing: int, frame: int, height: float) -> Dictionary:
	var row := posmod(facing, 8)
	var column := clampi(frame, 0, 3)
	var tip: Vector2 = MUZZLES[id][row][column]
	return {"id": id, "facing": row, "frame": column, "height": height,
		"texture": TEXTURES[id], "region": Rect2(Vector2(column, row) * CELL, CELL),
		"bounds": Rect2(-BASELINE + Vector2(0, -height), CELL),
		"muzzle": tip + Vector2(0, -height)}

static func draw(canvas: CanvasItem, state: Dictionary, color: Color = Color.WHITE) -> void:
	canvas.draw_texture_rect_region(state.texture, state.bounds, state.region, color)
