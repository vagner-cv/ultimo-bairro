extends CharacterBody2D

signal health_changed(value: int)
const BALLISTICS = preload("res://src/systems/ballistics.gd")
const SPEED: float = 145
const MAX_HEALTH: int = 100
const ART = preload("res://src/systems/pixel_actor.gd")
const ITEMS = preload("res://src/systems/items.gd")
const SHADOW = preload("res://src/systems/shadows.gd")
const WEAPONS := {"pistol": preload("res://resources/pistol.tres"), "shotgun": preload("res://resources/shotgun.tres"), "rifle": preload("res://resources/rifle.tres")}
var game: Node
var weapon: WeaponData = WEAPONS.pistol
var weapon_id: String = "pistol"
var health: int = MAX_HEALTH
var cooldown: float = 0
var knife_cooldown: float = 0
var invulnerable: float = 0
var animation: float = 0
var facing: int = 0
var aim: Vector2 = Vector2.DOWN
var footstep_timer: float = 0
var shot_count: int = 0
var camera: Camera2D
var recoil: float = 0
var zoom_target: float = 2.0
var idle_animation: float = 0
var height: float = 0
var vertical_speed: float = 0
var knife_animation: float = 0
var jump_count: int = 0
var last_safe: Vector2
var aim_target: Node2D
var aim_bloom: float = 0
var preview_hit: Dictionary = {}

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4 | 8 | 16
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8
	collision.shape = shape
	collision.position.y = -6
	add_child(collision)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * zoom_target
	camera.position = Vector2(0, -20)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8
	camera.limit_right = int(game.world.MAP_SIZE.x)
	camera.limit_bottom = int(game.world.MAP_SIZE.y)
	add_child(camera)
	last_safe = position

func equip(id: String) -> bool:
	if id != "knife" and (not WEAPONS.has(id) or game.inventory.count(id) <= 0):
		return false
	weapon_id = id
	if id != "knife":
		weapon = WEAPONS[id]
	clear_aim_target()
	aim_bloom = minf(aim_bloom, weapon.max_recoil)
	cooldown = maxf(cooldown, .16)
	game.notify(ITEMS.label(id) + " equipada")
	return true

func _physics_process(delta: float) -> void:
	idle_animation += delta * 5
	camera.zoom = Vector2.ONE * lerpf(camera.zoom.x, zoom_target, 1.0 - exp(-delta * 10))
	cooldown = maxf(0, cooldown - delta)
	knife_cooldown = maxf(0, knife_cooldown - delta)
	knife_animation = maxf(0, knife_animation - delta)
	invulnerable = maxf(0, invulnerable - delta)
	recoil = move_toward(recoil, 0, delta * 18)
	aim_bloom = move_toward(aim_bloom, 0, delta * weapon.recoil_recovery)
	if health <= 0 or game.dialogue_active:
		velocity = Vector2.ZERO
		clear_aim_target()
		queue_redraw()
		return
	_update_jump(delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()
	if height <= .1:
		last_safe = position
	if velocity.length() > 1:
		animation += delta * 9
		footstep_timer -= delta
		if footstep_timer <= 0 and height <= .1:
			game.audio.play("step", -14)
			footstep_timer = .32
	else:
		animation = 0
	preview_at(get_global_mouse_position())
	if Input.is_action_pressed("shoot"):
		fire_at(get_global_mouse_position())
	if Input.is_action_pressed("knife"):
		knife_at(get_global_mouse_position())
	queue_redraw()

func _update_jump(delta: float) -> void:
	var support: float = game.world.support_height(global_position)
	if height > support or vertical_speed > 0:
		vertical_speed -= 470 * delta
		height += vertical_speed * delta
		if vertical_speed <= 0 and height <= support and support > 0:
			height = support
			vertical_speed = 0
		elif height <= 0:
			height = 0
			vertical_speed = 0
			game.effects.landing(global_position)
	elif support <= 0 and height > 0:
		vertical_speed -= 470 * delta
	set_collision_mask_value(5, height < 22)
	# A landing must never leave the player embedded inside a low obstacle.
	if height == 0 and game.world.support_height(global_position) > 0:
		position = last_safe

func jump() -> bool:
	if health <= 0 or game.dialogue_active or get_tree().paused or absf(vertical_speed) > .1:
		return false
	vertical_speed = 225
	jump_count += 1
	return true

func _unhandled_input(event: InputEvent) -> void:
	if game.dialogue_active:
		return
	if event.is_action_pressed("jump"):
		jump()
	elif event.is_action_pressed("quick_heal"):
		game.use_item("herb")
	elif event is InputEventKey and event.pressed and not event.echo:
		var slots := {KEY_1: "pistol", KEY_2: "shotgun", KEY_3: "rifle", KEY_4: "knife"}
		if slots.has(event.physical_keycode):
			equip(slots[event.physical_keycode])
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_target = minf(2.6, zoom_target + .15)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_target = maxf(.85, zoom_target - .15)

func fire_at(target: Vector2) -> Dictionary:
	if weapon_id == "knife":
		return knife_at(target)
	if cooldown > 0 or knife_animation > 0 or health <= 0 or game.dialogue_active or get_tree().paused:
		return {}
	if not orient_to(target):
		return {}
	if not game.inventory.remove(weapon.ammo_type):
		cooldown = .3
		game.notify("Sem munição. Use a faca [F / botão direito].")
		return {}
	cooldown = weapon.cooldown
	recoil = 3.5 if weapon_id == "shotgun" else 2
	# Resolve the firing frame before tracing so flash and bullet share its tip.
	orient_to(target)
	var origin := gun_origin()
	var direction := aim
	shot_count += 1
	var first: Dictionary = {}
	var spread := current_spread()
	var actual_muzzle := gun_muzzle()
	for pellet in range(weapon.pellets):
		var angle := 0.0 if spread == 0 else randf_range(-spread, spread)
		var shot_direction := direction.rotated(angle)
		var end := origin + shot_direction * weapon.range_pixels
		var result := BALLISTICS.trace(self, origin, shot_direction, weapon.range_pixels)
		if not result.is_empty():
			end = result.position
			if result.collider.is_in_group("zombies") and result.collider.health > 0:
				result.collider.take_damage(weapon.damage, shot_direction, "bullet", end)
				game.hud.mark_hit()
			elif result.collider.has_method("take_damage"):
				result.collider.take_damage(weapon.damage, shot_direction, "bullet")
			if first.is_empty():
				first = result
		# All pellets share the actual barrel tip; a close obstruction still wins.
		var muzzle := actual_muzzle if origin.distance_to(end) >= origin.distance_to(actual_muzzle) else end
		game.effects.tracer(muzzle, end, not result.is_empty())
	aim_bloom = minf(weapon.max_recoil, aim_bloom + weapon.recoil_per_shot)
	if is_instance_valid(aim_target) and aim_target.health <= 0:
		clear_aim_target()
	game.audio.play("shot", -4 if weapon_id == "shotgun" else -8)
	game.make_noise(global_position, weapon.noise_radius)
	game.shake = 1.5 if weapon_id == "shotgun" else .75
	return first

func knife_at(target: Vector2) -> Dictionary:
	if knife_cooldown > 0 or cooldown > 0 or health <= 0 or game.dialogue_active or get_tree().paused:
		return {}
	var origin := global_position + Vector2(0, -8)
	var direction := origin.direction_to(target)
	if direction == Vector2.ZERO:
		direction = aim
	orient_to(target, "knife")
	knife_cooldown = .48
	knife_animation = .24
	game.effects.slash(origin, direction)
	game.audio.play("step", -5)
	var hits := 0
	for body in get_tree().get_nodes_in_group("zombies") + get_tree().get_nodes_in_group("containers"):
		var to_body: Vector2 = body.global_position + Vector2(0, -8) - origin
		if to_body.length() > 70 or (to_body.length() > 1 and direction.dot(to_body.normalized()) < .4):
			continue
		var query := PhysicsRayQueryParameters2D.create(origin, origin + to_body, 1 | 16)
		query.exclude = [get_rid()]
		var wall := get_world_2d().direct_space_state.intersect_ray(query)
		if not wall.is_empty() and wall.collider != body:
			continue
		body.take_damage(36, direction, "knife")
		hits += 1
	if hits > 0:
		game.hud.mark_hit()
	return {"hits": hits}

func take_damage(amount: int) -> void:
	if health <= 0 or invulnerable > 0 or height >= 22:
		return
	health = maxi(0, health - amount)
	invulnerable = .7
	game.audio.play("hurt", -3)
	game.shake = 2
	health_changed.emit(health)
	if health == 0:
		game.call_deferred("game_over")
	queue_redraw()

func _draw() -> void:
	SHADOW.draw_contact(self, Vector2(7 + height * .12, -2), Vector2(37 + height * .15, 17), maxf(.3, 1 - height / 120))
	var color := Color(1, .63, .52) if invulnerable > 0 and int(invulnerable * 15) % 2 == 0 else Color.WHITE
	ART.draw(self, held_pose(), color)

func body_frame() -> int:
	return ART.frame_for(velocity.length_squared() > 1, animation, recoil > .25, knife_animation > 0 and knife_animation < .19)

func held_pose() -> Dictionary:
	var id := "knife" if knife_animation > 0 else weapon_id
	return ART.pose(id, facing, body_frame(), height)

func gun_origin() -> Vector2:
	return gun_muzzle()

func gun_muzzle() -> Vector2:
	return global_position + Vector2(held_pose().muzzle)

func orient_to(target: Vector2, held_id: String = "") -> bool:
	if target.distance_squared_to(gun_origin()) < .0001:
		return false
	var id := weapon_id if held_id.is_empty() else held_id
	var center := global_position + Vector2(0, -42 - height)
	facing = ART.facing_for(target - center)
	var state := ART.pose(id, facing, body_frame(), height)
	aim = (global_position + Vector2(state.muzzle)).direction_to(target)
	return true

func current_spread() -> float:
	return weapon.spread + aim_bloom

func preview_at(target: Vector2) -> Dictionary:
	clear_aim_target()
	if not orient_to(target, "knife" if knife_animation > 0 else ""):
		return {}
	if weapon_id == "knife" or knife_animation > 0 or health <= 0 or game.dialogue_active or get_tree().paused:
		return {}
	preview_hit = BALLISTICS.trace(self, gun_origin(), aim, weapon.range_pixels)
	if preview_hit.is_empty() or game.inventory.count(weapon.ammo_type) <= 0:
		return preview_hit
	var candidate: Node2D = preview_hit.collider
	if candidate.is_in_group("zombies") and candidate.health > 0 and _target_visible(candidate):
		aim_target = candidate
		aim_target.set_targeted(true)
	return preview_hit

func _target_visible(candidate: Node2D) -> bool:
	for roof in game.world.roofs.get_children():
		if roof.fade > .5 and Rect2(roof.global_position, roof.size).has_point(candidate.global_position):
			return false
	return true

func clear_aim_target() -> void:
	if is_instance_valid(aim_target):
		aim_target.set_targeted(false)
	aim_target = null
	preview_hit = {}
