extends CharacterBody2D

signal health_changed(value: int)

const SPEED: float = 125.0
const MAX_HEALTH: int = 100
const SPRITES: Texture2D = preload("res://art/player.png")

var game: Node
var weapon: WeaponData = preload("res://resources/pistol.tres")
var health: int = MAX_HEALTH
var cooldown: float = 0.0
var invulnerable: float = 0.0
var animation: float = 0.0
var facing: int = 0
var aim: Vector2 = Vector2.DOWN
var footstep_timer: float = 0.0
var shot_count: int = 0
var camera: Camera2D
var recoil: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4 | 8
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8
	collision.shape = shape
	collision.position.y = -6
	add_child(collision)
	camera = Camera2D.new()
	camera.zoom = Vector2(2, 2)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 2304
	camera.limit_bottom = 1536
	add_child(camera)

func _physics_process(delta: float) -> void:
	cooldown = maxf(0, cooldown - delta)
	invulnerable = maxf(0, invulnerable - delta)
	recoil = move_toward(recoil, 0, delta * 18)
	if health <= 0 or game.dialogue_active:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * SPEED
	move_and_slide()
	if velocity.length() > 1:
		animation += delta * 9
		footstep_timer -= delta
		if footstep_timer <= 0:
			game.audio.play("step", -14)
			footstep_timer = .32
	else:
		animation = 0
	var to_mouse := get_global_mouse_position() - (global_position + Vector2(0, -14))
	if to_mouse.length_squared() > 1:
		aim = to_mouse.normalized()
	if absf(aim.x) > absf(aim.y):
		facing = 1 if aim.x > 0 else 3
	else:
		facing = 0 if aim.y > 0 else 2
	if Input.is_action_pressed("shoot"):
		fire_at(get_global_mouse_position())
	queue_redraw()

func fire_at(target: Vector2) -> Dictionary:
	if cooldown > 0 or health <= 0 or game.dialogue_active or get_tree().paused:
		return {}
	var origin := global_position + Vector2(0, -14)
	var direction := origin.direction_to(target)
	if direction == Vector2.ZERO:
		return {}
	aim = direction
	cooldown = weapon.cooldown
	recoil = 2.5
	shot_count += 1
	var end := origin + direction * weapon.range_pixels
	var query := PhysicsRayQueryParameters2D.create(origin, end, 1 | 4 | 8)
	query.exclude = [get_rid()]
	var result := get_world_2d().direct_space_state.intersect_ray(query)
	if not result.is_empty():
		end = result.position
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(weapon.damage, direction)
			game.hud.mark_hit()
	game.effects.tracer(origin + direction * 10, end, not result.is_empty())
	game.audio.play("shot", -6)
	game.make_noise(global_position, weapon.noise_radius)
	game.shake = .9
	return result

func take_damage(amount: int) -> void:
	if health <= 0 or invulnerable > 0:
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
	draw_circle(Vector2(0, -3), 10, Color(0.015, .04, .035, .34))
	var color := Color("f2c4a2") if invulnerable > 0 and int(invulnerable * 15) % 2 == 0 else Color.WHITE
	draw_texture_rect_region(SPRITES, Rect2(-16, -30, 32, 32), Rect2((int(animation) % 4) * 32, facing * 32, 32, 32), color)
	var shoulder := Vector2(0, -14)
	var hand := shoulder + aim * (9 - recoil)
	var muzzle := shoulder + aim * (20 - recoil)
	draw_line(shoulder + aim.orthogonal() * 4, hand, Color("947250"), 5)
	draw_line(hand, muzzle, Color("25383a"), 4)
	draw_line(hand + Vector2(0, -1), muzzle + Vector2(0, -1), Color("9ca89b"), 1)
	draw_rect(Rect2(hand - Vector2(2, 2), Vector2(4, 4)), Color("d5ae82"))
