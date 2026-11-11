extends RefCounted

static func spawn_enemy(game: Node, at: Vector2):
	var enemy = load("res://src/actors/zombie.gd").new()
	enemy.game = game
	enemy.position = at
	game.world.actors.add_child(enemy)
	enemy.set_physics_process(false)
	return enemy

static func ready_shot(actor: Node) -> void:
	actor.cooldown = 0
	actor.knife_animation = 0
	actor.aim_bloom = 0

static func run(suite: SceneTree) -> bool:
	var game = suite.game
	for enemy in suite.get_nodes_in_group("zombies"):
		enemy.queue_free()
	await suite.frames()
	var actor = game.player
	actor.position = Vector2(2800, 1480)
	actor.height = 0
	actor.vertical_speed = 0
	actor.health = 100
	actor.equip("pistol")
	game.inventory.add("ammo_9mm", 150)
	var enemy = spawn_enemy(game, Vector2(2920, 1480))
	var farther = spawn_enemy(game, Vector2(3100, 1480))
	await suite.frames()
	# The visible head, chest and legs are shootable independently of the feet collider.
	for offset in [Vector2(6, -57), Vector2(-6, -57), Vector2(0, -35), Vector2(0, -8)]:
		enemy.health = 90
		ready_shot(actor)
		var ammunition: int = game.inventory.count("ammo_9mm")
		var shots: int = actor.shot_count
		var preview: Dictionary = actor.preview_at(enemy.position + offset)
		suite.check(not preview.is_empty() and preview.collider == enemy and actor.aim_target == enemy and enemy.targeted, "Body aim %s identifies and highlights the visible zombie" % offset)
		suite.check(game.inventory.count("ammo_9mm") == ammunition and actor.shot_count == shots, "Aim preview does not fire or consume ammunition")
		var hit: Dictionary = actor.fire_at(enemy.position + offset)
		suite.check(not hit.is_empty() and hit.collider == enemy and enemy.health == 56, "A shot aimed at %s hits the body for normal weapon damage" % offset)
	enemy.health = 90
	farther.health = 90
	ready_shot(actor)
	var direction: Vector2 = actor.gun_origin().direction_to(enemy.position + Vector2(0, -32))
	var beyond: Vector2 = actor.gun_origin() + direction * 450
	actor.preview_at(beyond)
	suite.check(actor.aim_target == enemy, "Cursor beyond a zombie still highlights the first body in the trajectory")
	actor.fire_at(beyond)
	suite.check(enemy.health == 56 and farther.health == 90, "A bullet stops at the first body instead of damaging the next zombie")
	ready_shot(actor)
	enemy.health = 90
	actor.fire_at(actor.gun_origin() + direction * 35)
	suite.check(enemy.health == 56, "Cursor before the zombie also keeps firing in the freely aimed direction")
	ready_shot(actor)
	enemy.health = 90
	actor.preview_at(enemy.position + Vector2(0, -110))
	actor.fire_at(enemy.position + Vector2(0, -110))
	suite.check(actor.aim_target == null and enemy.health == 90, "Aiming outside the visible body misses without auto-aim snapping")
	# Only the feet remain solid for movement.
	actor.position = Vector2(2870, 1442)
	Input.action_press("move_right")
	await suite.frames(60)
	Input.action_release("move_right")
	suite.check(actor.position.x > 3000, "Body hit areas do not block walking through projected upper-body space")
	actor.position = Vector2(2800, 1480)
	enemy.position = Vector2(3490, 1480)
	farther.position = Vector2(3800, 1480)
	await suite.frames()
	ready_shot(actor)
	actor.preview_at(enemy.position + Vector2(0, -35))
	actor.fire_at(enemy.position + Vector2(0, -35))
	suite.check(actor.aim_target == null and enemy.health == 90, "Bodies beyond the weapon range cannot be highlighted or hit")
	enemy.position = Vector2(2920, 1480)
	farther.position = Vector2(3100, 1480)
	var wall = game.world.add_prop(Rect2(2850, 1440, 14, 80), "wall")
	await suite.frames()
	ready_shot(actor)
	actor.preview_at(enemy.position + Vector2(0, -57))
	var blocked: Dictionary = actor.fire_at(enemy.position + Vector2(0, -57))
	suite.check(actor.aim_target == null and not enemy.targeted, "A wall suppresses the target highlight")
	suite.check(not blocked.is_empty() and blocked.collider == wall and enemy.health == 90, "Head-level aiming cannot bypass a wall below the projected sprite")
	wall.queue_free()
	await suite.frames()
	# A close raised muzzle must not start on the far side of a closed doorway.
	actor.position = Vector2(2800, 1500)
	enemy.position = Vector2(2800, 1460)
	var door = load("res://src/world/door.gd").new()
	door.position = Vector2(2800, 1480)
	game.world.actors.add_child(door)
	await suite.frames()
	ready_shot(actor)
	actor.preview_at(enemy.position + Vector2(0, -35))
	blocked = actor.fire_at(enemy.position + Vector2(0, -35))
	suite.check(actor.aim_target == null and blocked.get("collider") == door and enemy.health == 90, "Closed door blocks a nearby shot even when the muzzle projects above its floor collider")
	door.interact(actor)
	await suite.frames()
	ready_shot(actor)
	actor.preview_at(enemy.position + Vector2(0, -35))
	actor.fire_at(enemy.position + Vector2(0, -35))
	suite.check(actor.aim_target == enemy and enemy.health == 56, "Opening the door restores both body highlight and bullet passage")
	door.queue_free()
	actor.position = Vector2(2800, 1480)
	enemy.position = Vector2(2920, 1480)
	enemy.health = 90
	var survivor = game.world.actors.get_children().filter(func(n: Node) -> bool: return n.get_script() == load("res://src/actors/survivor.gd"))[0]
	var survivor_position: Vector2 = survivor.position
	survivor.position = Vector2(2860, 1480)
	await suite.frames()
	ready_shot(actor)
	actor.preview_at(enemy.position + Vector2(0, -35))
	blocked = actor.fire_at(enemy.position + Vector2(0, -35))
	suite.check(actor.aim_target == null and blocked.get("collider") == survivor and enemy.health == 90, "A survivor's visible body blocks the bullet and is not marked as a hostile target")
	survivor.position = survivor_position
	await suite.frames()
	# Feedback is unavailable when the gun cannot shoot and while menus are open.
	var reserve: int = game.inventory.count("ammo_9mm")
	game.inventory.remove("ammo_9mm", reserve)
	ready_shot(actor)
	var shots: int = actor.shot_count
	actor.preview_at(enemy.position + Vector2(0, -35))
	actor.fire_at(enemy.position + Vector2(0, -35))
	suite.check(actor.aim_target == null and actor.shot_count == shots and enemy.health == 90, "Empty ammo prevents both hostile highlighting and firing")
	game.inventory.add("ammo_9mm", reserve)
	actor.preview_at(enemy.position + Vector2(0, -35))
	game.open_inventory()
	suite.check(actor.aim_target == null and not enemy.targeted, "Inventory clears the targeting outline immediately")
	game.close_inventory()
	actor.preview_at(enemy.position + Vector2(0, -35))
	game.toggle_pause()
	suite.check(actor.aim_target == null and not enemy.targeted, "Pause clears the targeting outline immediately")
	game.toggle_pause()
	actor.preview_at(enemy.position + Vector2(0, -35))
	game.toggle_map()
	suite.check(actor.aim_target == null and not enemy.targeted, "Map clears the targeting outline immediately")
	game.toggle_map()
	actor.preview_at(enemy.position + Vector2(0, -35))
	var dialogue_lines: Array[String] = ["Teste de mira"]
	game.start_dialogue("TESTE", dialogue_lines)
	suite.check(actor.aim_target == null and not enemy.targeted, "Dialogue clears the targeting outline immediately")
	game.end_dialogue()
	actor.preview_at(enemy.position + Vector2(0, -35))
	actor.equip("knife")
	suite.check(actor.aim_target == null and actor.preview_at(enemy.position).is_empty(), "Knife selection does not show a firearm targeting outline")
	actor.equip("pistol")
	ready_shot(actor)
	actor.preview_at(actor.gun_origin())
	shots = actor.shot_count
	actor.fire_at(actor.gun_origin())
	suite.check(actor.aim_target == null and actor.shot_count == shots, "Zero-length aim neither highlights an arbitrary direction nor consumes a shot")
	# Opaque roofs must not reveal hidden enemies through the target indicator.
	actor.position = Vector2(352, 500)
	enemy.position = Vector2(352, 410)
	farther.position = Vector2(3100, 1480)
	var entrance = game.world.doors[0]
	if not entrance.is_open:
		entrance.interact(actor)
	await suite.frames(45)
	actor.preview_at(enemy.position + Vector2(0, -35))
	suite.check(actor.aim_target == null, "Target indicator does not reveal a zombie hidden by an opaque roof")
	actor.position = Vector2(352, 390)
	await suite.frames(45)
	actor.preview_at(enemy.position + Vector2(0, -35))
	suite.check(actor.aim_target == enemy, "Entering a room allows targeting its visible zombie")
	actor.position = Vector2(2800, 1480)
	enemy.position = Vector2(2920, 1480)
	enemy.health = 34
	await suite.frames()
	ready_shot(actor)
	actor.fire_at(enemy.position + Vector2(0, -35))
	suite.check(enemy.health == 0 and enemy.body_hitbox.collision_layer == 0, "Death immediately removes the body's ballistic collision")
	ready_shot(actor)
	actor.fire_at(farther.position + Vector2(0, -35))
	suite.check(farther.health == 56, "A following bullet passes the dead body and reaches the next zombie")
	await suite.frames()
	# Sustained rifle fire expands dispersion; a pause lets it recover.
	game.inventory.add("rifle")
	game.inventory.add("ammo_rifle", 50)
	actor.equip("rifle")
	ready_shot(actor)
	var base_spread: float = actor.current_spread()
	actor.fire_at(actor.gun_origin() + Vector2.RIGHT * 400)
	suite.check(actor.current_spread() > base_spread, "Firing the rifle increases its actual shot dispersion")
	for i in range(8):
		actor.cooldown = 0
		actor.fire_at(actor.gun_origin() + Vector2.RIGHT * 400)
	suite.check(is_equal_approx(actor.aim_bloom, actor.weapon.max_recoil), "Continuous firing is limited to a bounded maximum recoil spread")
	await suite.frames(80)
	suite.check(is_equal_approx(actor.current_spread(), actor.weapon.spread), "Aiming steadies after the player stops firing")
	game.inventory.add("shotgun")
	game.inventory.add("ammo_shell", 5)
	actor.equip("shotgun")
	ready_shot(actor)
	var first_effect: int = game.effects.entries.size()
	seed(15938)
	actor.fire_at(actor.gun_origin() + Vector2.RIGHT * 300)
	var directions: Array[float] = []
	for i in range(first_effect, game.effects.entries.size()):
		var entry: Dictionary = game.effects.entries[i]
		if entry.kind == "shot":
			directions.append((entry.b - entry.a).angle())
	directions.sort()
	suite.check(directions.size() == 6 and directions[-1] - directions[0] > .05, "Shotgun pellets really travel in distinct directions across their spread cone")
	actor.equip("pistol")
	var last_enemy = spawn_enemy(game, actor.position + Vector2(120, 0))
	await suite.frames()
	actor.preview_at(last_enemy.position + Vector2(0, -35))
	actor.invulnerable = 0
	actor.take_damage(100)
	await suite.frames()
	suite.check(game.hud.screen == "dead" and actor.aim_target == null and not last_enemy.targeted, "Game over clears the targeting outline immediately")
	game.restart()
	suite.freeze_zombies()
	await suite.frames()
	suite.check(game.player.aim_target == null and game.player.aim_bloom == 0, "Restart clears target references and recoil state")
	return true
