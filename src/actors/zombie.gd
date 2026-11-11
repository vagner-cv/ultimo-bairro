extends CharacterBody2D

enum State { WANDER, CHASE, DEAD }

const KIT = preload("res://src/systems/kit_art.gd")
var game: Node
var state: State = State.WANDER
var health: int = 90
var max_health: int = 90
var speed: float = 43.0
var animation: float = 0.0
var facing: int = 0
var attack_timer: float = 0.0
var think_timer: float = 0.0
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var path: PackedVector2Array = PackedVector2Array()
var flash: float = 0.0
var knockback: Vector2 = Vector2.ZERO
var tint: Color = Color.WHITE
var last_known: Vector2
var memory: float = 0.0
var idle_animation: float = 0.0
var body_hitbox: Area2D
var body_sprite: Sprite2D
var outline: ShaderMaterial
var targeted: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	collision_layer = 4
	collision_mask = 1 | 2 | 4 | 8 | 16
	add_to_group("zombies")
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9
	collision.shape = shape
	collision.position.y = -8
	add_child(collision)
	body_hitbox = preload("res://src/systems/ballistics.gd").attach_body(self)
	body_sprite = Sprite2D.new()
	body_sprite.texture = KIT.ZOMBIE_IDLE
	body_sprite.hframes = 4
	body_sprite.scale = Vector2(46.0 / 128, 69.0 / 192)
	body_sprite.position = Vector2(0, -31.5)
	outline = ShaderMaterial.new()
	outline.shader = preload("res://shaders/target_outline.gdshader")
	body_sprite.material = outline
	add_child(body_sprite)
	wander_timer = randf_range(.5, 4)
	think_timer = randf_range(0, .5)
	speed = randf_range(37, 49) + minf(18, (game.wave - 1) * 1.5)
	tint = Color.from_hsv(randf_range(.05, .13), randf_range(.02, .16), randf_range(.8, 1))

func _physics_process(delta: float) -> void:
	if state == State.DEAD or not is_instance_valid(game.player):
		return
	attack_timer = maxf(0, attack_timer - delta)
	idle_animation += delta * 4
	flash = maxf(0, flash - delta)
	think_timer -= delta
	memory = maxf(0, memory - delta)
	knockback = knockback.move_toward(Vector2.ZERO, delta * 290)
	var target: Vector2 = game.player.global_position
	var distance := global_position.distance_to(target)
	if think_timer <= 0:
		think_timer = randf_range(.3, .55)
		if distance < 270 and game.world.has_line_of_sight(global_position + Vector2(0, -8), target + Vector2(0, -8)):
			state = State.CHASE
			last_known = target
			memory = 7
		if state == State.CHASE:
			if memory > 0:
				path = game.world.find_path(global_position, last_known)
			else:
				state = State.WANDER
				path.clear()
	var direction := Vector2.ZERO
	if state == State.CHASE:
		if distance < 320 and game.world.has_line_of_sight(global_position + Vector2(0, -8), target + Vector2(0, -8)):
			direction = global_position.direction_to(target)
			last_known = target
			memory = 7
		else:
			while not path.is_empty() and global_position.distance_to(path[0]) < 12:
				path.remove_at(0)
			if not path.is_empty():
				direction = global_position.direction_to(path[0])
		if distance < 27 and attack_timer <= 0 and game.player.health > 0:
			if game.world.has_line_of_sight(global_position + Vector2(0, -8), target + Vector2(0, -8)):
				game.player.take_damage(12)
				attack_timer = 1.1
		if distance < 21:
			direction = Vector2.ZERO
	else:
		wander_timer -= delta
		if wander_timer <= 0:
			wander_timer = randf_range(2, 5)
			wander_direction = Vector2.from_angle(randf() * TAU) if randf() > .45 else Vector2.ZERO
		direction = wander_direction
	velocity = direction * (speed if state == State.CHASE else speed * .3) + knockback
	move_and_slide()
	if velocity.length_squared() > 4:
		animation += delta * (5 if state == State.CHASE else 2)
		if absf(direction.x) > absf(direction.y):
			facing = 1 if direction.x > 0 else 3
		else:
			facing = 0 if direction.y > 0 else 2
	queue_redraw()

func hear(at: Vector2, radius: float) -> void:
	if state != State.DEAD and global_position.distance_to(at) < radius:
		state = State.CHASE
		last_known = at
		memory = 8
		think_timer = 0

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO, _damage_kind: String = "bullet", impact: Vector2 = Vector2.INF) -> void:
	if state == State.DEAD:
		return
	health = maxi(0, health - amount)
	flash = .12
	knockback = direction * 95
	hear(game.player.global_position, 9999)
	game.effects.blood(global_position + Vector2(0, -26) if impact == Vector2.INF else impact, direction)
	game.audio.play("impact", -5)
	if health == 0:
		state = State.DEAD
		collision_layer = 0
		collision_mask = 0
		body_hitbox.collision_layer = 0
		set_targeted(false)
		game.effects.corpse(global_position, Color("647767") * tint)
		game.zombie_killed(global_position)
		queue_free()

func _draw() -> void:
	preload("res://src/systems/shadows.gd").draw_contact(self, Vector2(5, -3), Vector2(35, 17))
	var color := Color(1.6, 1.4, 1.2) if flash > 0 else tint
	var moving := velocity.length_squared() > 4
	var texture: Texture2D = KIT.ZOMBIE_WALK if moving else KIT.ZOMBIE_IDLE
	var frame := int(animation if moving else idle_animation)
	if attack_timer > .8:
		texture = KIT.ZOMBIE_ATTACK
		frame = mini(3, int((1.1 - attack_timer) * 12))
	var left := facing == 3
	if state == State.CHASE and is_instance_valid(game.player):
		left = game.player.global_position.x < global_position.x
	body_sprite.texture = texture
	body_sprite.frame = posmod(frame, 4)
	body_sprite.flip_h = left
	body_sprite.modulate = color
	outline.set_shader_parameter("selected", targeted and not get_tree().paused and not game.dialogue_active)

	if health < max_health:
		draw_rect(Rect2(-13, -73, 26, 3), Color("253a33"))
		draw_rect(Rect2(-13, -73, 26.0 * health / max_health, 3), Color("d89b6a"))

func set_targeted(value: bool) -> void:
	if targeted == value:
		return
	targeted = value
	if outline != null:
		outline.set_shader_parameter("selected", value)
	queue_redraw()
