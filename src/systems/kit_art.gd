extends RefCounted

const BASE := "res://art/environment/"
const NPC_IDLE: Texture2D = preload(BASE + "mara_idle.png")
const ZOMBIE_WALK: Texture2D = preload(BASE + "zombie_walk.png")
const ZOMBIE_IDLE: Texture2D = preload(BASE + "zombie_idle.png")
const ZOMBIE_ATTACK: Texture2D = preload(BASE + "zombie_attack.png")
const ZOMBIE_DEAD: Texture2D = preload(BASE + "zombie_corpse.png")

static func actor(canvas: CanvasItem, texture: Texture2D, frame: int, left: bool, color: Color = Color.WHITE) -> void:
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2(-1 if left else 1, 1))
	canvas.draw_texture_rect_region(texture, Rect2(-23, -66, 46, 69), Rect2(posmod(frame, 4) * 128, 0, 128, 192), color)
	canvas.draw_set_transform(Vector2.ZERO)
