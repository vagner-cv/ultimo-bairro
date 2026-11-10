extends SceneTree

var game: Node
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func frames(count: int = 2) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func freeze_zombies() -> void:
	for zombie in get_nodes_in_group("zombies"):
		zombie.set_physics_process(false)

func run() -> void:
	seed(41)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames()
	check(paused and game.hud.screen == "title", "Title screen pauses the simulation")
	game.begin()
	freeze_zombies()
	await frames()
	check(game.remaining == 18 and get_nodes_in_group("zombies").size() == 18, "Neighborhood starts with exactly 18 zombies")
	check(game.world.houses.size() == 5 and game.world.doors.size() == 5, "Five enterable buildings have physical doors")
	check(game.world.houses[0].rect.has_point(game.player.position), "Player starts inside the first house")
	# Actual physics movement, including normalization of diagonal input.
	game.player.position = Vector2(730, 480)
	var start: Vector2 = game.player.position
	Input.action_press("move_right")
	Input.action_press("move_down")
	await frames(60)
	Input.action_release("move_right")
	Input.action_release("move_down")
	var distance: float = start.distance_to(game.player.position)
	check(distance > 120 and distance < 130, "Diagonal movement keeps walking speed (125 px/s)")
	game.player.position = Vector2(230, 350)
	Input.action_press("move_left")
	await frames(50)
	Input.action_release("move_left")
	check(game.player.position.x >= 213, "Player cannot walk through a house wall")
	var door = game.world.doors[0]
	game.player.position = Vector2(352, 410)
	Input.action_press("move_down")
	await frames(40)
	Input.action_release("move_down")
	check(game.player.position.y < 434, "Closed door blocks the player")
	check(game.world.find_path(Vector2(352, 380), Vector2(352, 500)).is_empty(), "Closed doors also block zombie navigation")
	# Send a real input event through the main interaction handler.
	await frames()
	var interaction := InputEventAction.new()
	interaction.action = "interact"
	interaction.pressed = true
	Input.parse_input_event(interaction)
	await frames()
	check(door.is_open, "E opens the nearby door")
	check(not game.world.find_path(Vector2(352, 380), Vector2(352, 500)).is_empty(), "Opening a door updates zombie navigation")
	Input.action_press("move_down")
	await frames(55)
	Input.action_release("move_down")
	check(game.player.position.y > 480, "Player can leave through the open doorway")
	# Shooting uses physics rays, damage, cooldown, and kill accounting.
	game.player.position = Vector2(730, 540)
	var zombie = get_nodes_in_group("zombies")[0]
	zombie.position = Vector2(830, 540)
	await frames()
	game.player.cooldown = 0
	var hit: Dictionary = game.player.fire_at(zombie.position + Vector2(0, -14))
	check(not hit.is_empty() and hit.collider == zombie and zombie.health == 56, "Aimed shot damages the zombie in its path")
	var shots: int = game.player.shot_count
	game.player.fire_at(zombie.position)
	check(game.player.shot_count == shots, "Fire rate prevents a second immediate shot")
	await frames(15)
	game.player.fire_at(zombie.position + Vector2(0, -14))
	await frames(15)
	game.player.fire_at(zombie.position + Vector2(0, -14))
	await frames()
	check(game.remaining == 17 and game.kills == 1 and not is_instance_valid(zombie), "Three pistol hits kill one zombie and update counters")
	check(game.effects.corpses.size() == 1, "Dead zombie leaves a non-lootable corpse")
	shots = game.player.shot_count
	for i in range(24):
		await frames(15)
		game.player.fire_at(Vector2(770, 450))
	check(game.player.shot_count == shots + 24, "Pistol keeps firing without ammunition or reloading")
	# A wall occludes both bullets and visual detection.
	zombie = get_nodes_in_group("zombies")[0]
	zombie.position = Vector2(250, 350)
	game.player.position = Vector2(160, 350)
	await frames()
	var before: int = zombie.health
	game.player.cooldown = 0
	hit = game.player.fire_at(zombie.position + Vector2(0, -14))
	check(not hit.is_empty() and zombie.health == before, "Bullets hit walls instead of enemies behind them")
	check(not game.world.has_line_of_sight(Vector2(160, 335), Vector2(250, 335)), "Walls occlude zombie sight")
	zombie.position = Vector2(800, 500)
	zombie.state = 0
	game.player.position = Vector2(700, 500)
	game.make_noise(game.player.position, 490)
	check(zombie.state == 1, "Nearby gunfire attracts zombies")
	# Exercise autonomous behavior, rather than only the damage methods.
	game.player.position = Vector2(730, 500)
	zombie.position = Vector2(850, 500)
	zombie.state = 0
	zombie.memory = 0
	zombie.think_timer = 0
	zombie.set_physics_process(true)
	await frames(35)
	check(zombie.state == 1 and zombie.position.distance_to(game.player.position) < 110, "Visible player triggers autonomous pursuit")
	await frames(150)
	check(game.player.health < 100, "Pursuing zombie reaches and attacks the player")
	if door.is_open:
		door.interact(game.player)
	game.player.health = 100
	game.player.invulnerable = 0
	game.player.position = Vector2(352, 430)
	zombie.position = Vector2(352, 456)
	zombie.attack_timer = 0
	await frames(75)
	check(game.player.health == 100, "Zombie cannot attack through a closed door")
	zombie.set_physics_process(false)
	# Conversation is contextual and stops walking / shooting.
	game.player.position = Vector2(466, 590)
	await frames()
	check(is_instance_valid(game.nearby) and game.nearby.has_method("interaction_text") and game.nearby.interaction_text() == "Conversar com Mara", "Survivor becomes interactable at conversational distance")
	game.nearby.interact(game.player)
	check(game.dialogue_active and game.met_mara, "Conversation opens and advances the objective")
	shots = game.player.shot_count
	game.player.cooldown = 0
	game.player.fire_at(Vector2(700, 590))
	check(game.player.shot_count == shots, "Dialogue prevents accidental firing")
	for i in range(3):
		game.advance_dialogue()
	check(not game.dialogue_active, "Conversation ends after the final line")
	game.toggle_pause()
	var elapsed_before: float = game.elapsed
	start = game.player.position
	Input.action_press("move_right")
	await frames(15)
	Input.action_release("move_right")
	check(paused and game.hud.screen == "pause" and game.player.position == start and game.elapsed == elapsed_before, "Pause freezes movement and survival time")
	game.toggle_pause()
	check(not paused and game.hud.screen == "none", "Resume returns to gameplay")
	game.player.take_damage(100)
	await frames()
	check(paused and game.player.health == 0 and game.hud.screen == "dead", "Lethal damage shows game over and pauses the world")
	game.restart()
	freeze_zombies()
	await frames()
	check(not paused and game.remaining == 18 and game.kills == 0 and game.player.health == 100 and not game.met_mara, "Restart restores the neighborhood, health and objectives")
	for enemy in get_nodes_in_group("zombies"):
		enemy.take_damage(100)
	await frames()
	check(game.remaining == 0 and game.kills == 18 and get_nodes_in_group("zombies").is_empty(), "Clearing the neighborhood counts every zombie once")
	check(not root.has_node("Inventory") and get_nodes_in_group("loot").is_empty(), "No collection or loot system is active")
	print("\nRESULT: %d/%d passed" % [checks - failures, checks])
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)
