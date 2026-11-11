extends SceneTree

const RIG = preload("res://src/systems/weapon_rig.gd")
const FONT: Font = preload("res://art/regular.ttf")

class Avatar extends Node2D:
	var weapon: String
	var direction: Vector2
	var frame: int = 0
	var walking: bool = false
	var lift: float = 0
	var kick: float = 0
	func _ready() -> void:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	func _draw() -> void:
		var orientation := RIG.orient(weapon, direction * 180 + Vector2(0, -40), frame, walking, lift)
		var state := RIG.pose(weapon, orientation.direction, orientation.facing, frame, walking, lift, kick, orientation.lateral)
		RIG.draw(self, state)

class Sheet extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("28302c"))
		var labels := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
		for i in range(8):
			draw_string(FONT, Vector2(100 + i * 150, 26), labels[i], HORIZONTAL_ALIGNMENT_CENTER, 50, 14, Color("d8d5bc"))
		var weapons := ["PISTOLA", "ESCOPETA", "FUZIL", "FACA"]
		for i in range(4):
			draw_line(Vector2(8, 40 + i * 165), Vector2(1272, 40 + i * 165), Color("46524a"))
			draw_string(FONT, Vector2(12, 60 + i * 165), weapons[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("dfb579"))

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var sheet := Sheet.new()
	root.add_child(sheet)
	var directions := [Vector2.UP, Vector2(1, -1).normalized(), Vector2.RIGHT, Vector2(1, 1).normalized(), Vector2.DOWN, Vector2(-1, 1).normalized(), Vector2.LEFT, Vector2(-1, -1).normalized()]
	var weapons := ["pistol", "shotgun", "rifle", "knife"]
	for row in range(4):
		for col in range(8):
			var avatar := Avatar.new()
			avatar.weapon = weapons[row]
			avatar.direction = directions[col]
			avatar.position = Vector2(112 + col * 150, 175 + row * 165)
			avatar.scale = Vector2(1.9, 1.9)
			sheet.add_child(avatar)
	await create_timer(.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/weapon-poses.png")
	print("Saved weapon poses")
	quit()
