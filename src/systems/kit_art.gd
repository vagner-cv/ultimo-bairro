extends RefCounted

const ATLAS: Texture2D = preload("res://art/vendor/craftpix/tiles.png")
const PLAYER_WALK: Texture2D = preload("res://art/vendor/craftpix/player_walk.png")
const PLAYER_IDLE: Texture2D = preload("res://art/vendor/craftpix/player_idle.png")
const PLAYER_SHOT: Texture2D = preload("res://art/vendor/craftpix/player_shot.png")
const NPC_IDLE: Texture2D = preload("res://art/vendor/craftpix/npc_idle.png")
const ZOMBIE_WALK: Texture2D = preload("res://art/vendor/craftpix/zombie_walk.png")
const ZOMBIE_IDLE: Texture2D = preload("res://art/vendor/craftpix/zombie_idle.png")
const ZOMBIE_ATTACK: Texture2D = preload("res://art/vendor/craftpix/zombie_attack.png")
const ZOMBIE_DEAD: Texture2D = preload("res://art/vendor/craftpix/zombie_dead.png")
const DOOR_CLOSED: Texture2D = preload("res://art/vendor/craftpix/door_closed.png")
const DOOR_OPEN: Texture2D = preload("res://art/vendor/craftpix/door_open.png")

static func tile(canvas: CanvasItem, id: int, at: Vector2, color: Color = Color.WHITE) -> void:
	canvas.draw_texture_rect_region(ATLAS, Rect2(at, Vector2(32, 32)), Rect2(id % 22 * 16, id / 22 * 16, 16, 16), color)

static func actor(canvas: CanvasItem, texture: Texture2D, frame: int, left: bool, color: Color = Color.WHITE) -> void:
	var columns := maxi(1, texture.get_width() / 32)
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if left else 1, 1))
	canvas.draw_texture_rect_region(texture, Rect2(-32, -64, 64, 64), Rect2(posmod(frame, columns) * 32, 0, 32, 32), color)
	canvas.draw_set_transform(Vector2.ZERO)

static func door(canvas: CanvasItem, at: Vector2, opened: bool) -> void:
	canvas.draw_texture_rect(DOOR_OPEN if opened else DOOR_CLOSED, Rect2(at, Vector2(64, 64)), false)
	if opened:
		canvas.draw_rect(Rect2(at + Vector2(20, 22), Vector2(24, 40)), Color("252532"))
		canvas.draw_texture_rect_region(DOOR_CLOSED, Rect2(at + Vector2(2, 23), Vector2(17, 39)), Rect2(10, 11, 5, 19))
