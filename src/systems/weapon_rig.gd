extends RefCounted

# All attachments are defined on the held artwork, independently of UI icons.
const BODY: Texture2D = preload("res://art/rig/leon_body.png")
const UPPER: Texture2D = preload("res://art/rig/upper_arm.png")
const FOREARM: Texture2D = preload("res://art/rig/forearm.png")
const GRIP_HAND: Texture2D = preload("res://art/rig/grip_hand.png")
const SUPPORT_HAND: Texture2D = preload("res://art/rig/support_hand.png")
const HAND_SIZE := Vector2(8.5, 6)
const SUPPORT_SIZE := Vector2(9, 5.1)
const HAND_PALM: float = .51
const GUNS := {
	"pistol": {"texture": preload("res://art/rig/pistol.png"), "width": 18.0, "grip": Vector2(20, 52), "support": Vector2(22, 55), "muzzle": Vector2(92, 12), "reach": 11.0, "two_hands": true},
	"shotgun": {"texture": preload("res://art/rig/shotgun.png"), "width": 40.0, "grip": Vector2(43, 24), "support": Vector2(77, 20), "muzzle": Vector2(111, 8), "reach": 8.0, "two_hands": true},
	"rifle": {"texture": preload("res://art/rig/rifle.png"), "width": 35.0, "grip": Vector2(42, 35), "support": Vector2(78, 23), "muzzle": Vector2(111, 16), "reach": 8.0, "two_hands": true},
	"knife": {"texture": preload("res://art/rig/knife.png"), "width": 20.0, "grip": Vector2(23, 16), "support": Vector2(23, 16), "muzzle": Vector2(106, 15), "reach": 11.0, "two_hands": false}
}

static func frame_bob(frame: int, moving: bool) -> float:
	return [0.0, -.45, 0.0, .45][posmod(frame, 4)] if moving else 0.0

static func pivot(frame: int, moving: bool, height: float) -> Vector2:
	return Vector2(0, -40 + frame_bob(frame, moving) - height)

static func facing_for(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 1 if direction.x > 0 else 3
	return 0 if direction.y > 0 else 2

static func lateral_for(id: String, facing: int) -> float:
	var data: Dictionary = GUNS[id]
	var texture: Texture2D = data.texture
	var scale: float = data.width / texture.get_width()
	return -((data.grip.y - data.muzzle.y) * scale + 4) if facing in [0, 2] else 0.0

static func orient(id: String, target: Vector2, frame: int, moving: bool, height: float) -> Dictionary:
	var delta := target - pivot(frame, moving, height)
	if delta.length_squared() < .0001:
		return {}
	var facing := facing_for(delta)
	var lateral := lateral_for(id, facing)
	if delta.length() <= absf(lateral) + 1:
		lateral = 0
	# A shoulder-side barrel must still point exactly through the cursor.
	var angle := delta.angle() - asin(clampf(lateral / delta.length(), -.99, .99))
	return {"direction": Vector2.from_angle(angle), "facing": facing, "lateral": lateral}

static func solve_arm(shoulder: Vector2, wrist: Vector2, bend: float) -> Dictionary:
	var delta := wrist - shoulder
	var distance := maxf(.01, delta.length())
	var direction := delta / distance
	var upper := maxf(11.5, distance / 2 + .1)
	var forearm := upper
	var along := (upper * upper - forearm * forearm + distance * distance) / (2 * distance)
	var out := sqrt(maxf(0, upper * upper - along * along))
	var elbow := shoulder + direction * along + Vector2(-direction.y, direction.x) * bend * out
	return {"shoulder": shoulder, "elbow": elbow, "wrist": wrist, "length": upper}

static func pose(id: String, direction: Vector2, facing: int, frame: int, moving: bool, height: float, recoil: float, lateral: float) -> Dictionary:
	var data: Dictionary = GUNS[id]
	var texture: Texture2D = data.texture
	var scale: float = data.width / texture.get_width()
	var flip := -1.0 if facing == 3 else 1.0
	var perpendicular := Vector2(-direction.y, direction.x)
	var center := pivot(frame, moving, height)
	var origin := center + perpendicular * lateral
	var gun := origin + direction * (float(data.reach) - minf(recoil, 3.5))
	var basis := Transform2D(direction, perpendicular * flip, gun)
	var axis := Vector2(data.grip.x, data.muzzle.y)
	var grip: Vector2 = basis * ((data.grip - axis) * scale)
	var support: Vector2 = basis * ((data.support - axis) * scale)
	var right_wrist := grip - direction * HAND_SIZE.x * HAND_PALM
	var left_wrist := support - direction * SUPPORT_SIZE.x * HAND_PALM
	var bob := frame_bob(frame, moving) - height
	var shoulders: Array[Vector2] = [Vector2(8, -44), Vector2(-8, -44)]
	if facing == 2:
		shoulders = [Vector2(-8, -44), Vector2(8, -44)]
	elif facing == 1:
		shoulders = [Vector2(3, -44), Vector2(-2, -44)]
	elif facing == 3:
		shoulders = [Vector2(-3, -44), Vector2(2, -44)]
	shoulders[0].y += bob
	shoulders[1].y += bob
	if not data.two_hands:
		left_wrist = shoulders[1] + Vector2(-1 if facing != 3 else 1, 18)
	var bend := 1.0 if facing == 3 else -1.0
	return {
		"id": id, "data": data, "direction": direction, "facing": facing,
		"frame": frame, "moving": moving, "height": height, "bob": bob,
		"origin": origin, "gun": gun, "basis": basis, "flip": flip,
		"scale": scale, "axis": axis, "grip": grip, "support": support,
		"muzzle": basis * ((data.muzzle - axis) * scale),
		"right": solve_arm(shoulders[0], right_wrist, bend),
		"left": solve_arm(shoulders[1], left_wrist, -bend),
		"behind": facing == 2
	}

static func draw(canvas: CanvasItem, state: Dictionary, color: Color = Color.WHITE) -> void:
	if state.behind:
		draw_arms(canvas, state, color)
	draw_body(canvas, state, color)
	if not state.behind:
		draw_arms(canvas, state, color)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_body(canvas: CanvasItem, state: Dictionary, color: Color) -> void:
	canvas.draw_set_transform(Vector2.ZERO)
	canvas.draw_texture_rect_region(BODY, Rect2(-23, -66 + state.bob, 46, 69), Rect2(posmod(state.frame, 4) * 128, state.facing * 192, 128, 192), color)

static func draw_arms(canvas: CanvasItem, state: Dictionary, color: Color) -> void:
	_draw_arm(canvas, state.left, color)
	_draw_arm(canvas, state.right, color)
	canvas.draw_set_transform(state.gun, state.direction.angle(), Vector2(1, state.flip))
	var texture: Texture2D = state.data.texture
	canvas.draw_texture_rect(texture, Rect2(-state.axis * state.scale, texture.get_size() * state.scale), false, color)
	_draw_hand(canvas, GRIP_HAND, state.right.wrist, state.direction, state.flip, HAND_SIZE, color)
	if state.data.two_hands:
		_draw_hand(canvas, SUPPORT_HAND, state.left.wrist, state.direction, state.flip, SUPPORT_SIZE, color)
	else:
		_draw_hand(canvas, GRIP_HAND, state.left.wrist, Vector2.DOWN, 1, HAND_SIZE, color)
	canvas.draw_set_transform(Vector2.ZERO)

static func _draw_arm(canvas: CanvasItem, arm: Dictionary, color: Color) -> void:
	_draw_segment(canvas, UPPER, arm.shoulder, arm.elbow, 6.6, color)
	_draw_segment(canvas, FOREARM, arm.elbow, arm.wrist, 5.8, color)

static func _draw_segment(canvas: CanvasItem, texture: Texture2D, start: Vector2, end: Vector2, width: float, color: Color) -> void:
	canvas.draw_set_transform(start, start.angle_to_point(end))
	canvas.draw_texture_rect(texture, Rect2(-1.0, -width / 2, start.distance_to(end) + 2, width), false, color)

static func _draw_hand(canvas: CanvasItem, texture: Texture2D, wrist: Vector2, direction: Vector2, flip: float, size: Vector2, color: Color) -> void:
	canvas.draw_set_transform(wrist, direction.angle(), Vector2(1, flip))
	canvas.draw_texture_rect(texture, Rect2(-size.x * .14, -size.y / 2, size.x, size.y), false, color)
