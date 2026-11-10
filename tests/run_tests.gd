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
	check(game.world.houses.size() == 27 and game.world.doors.size() == 27, "27 enterable buildings have physical doors")
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
	check(distance > 140 and distance < 150, "Diagonal movement keeps walking speed (145 px/s)")
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
	check(game.effects.corpses.size() == 1, "Dead zombie leaves a corpse")
	shots = game.player.shot_count
	for i in range(24):
		await frames(15)
		game.player.fire_at(Vector2(770, 450))
	check(game.player.shot_count == shots + 24 and game.inventory.count("ammo_9mm") == 33, "Pistol consumes finite ammunition while firing")
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
	check(game.wave_countdown > 0, "Clearing a wave schedules automatic respawn after a breather")
	await frames(725)
	freeze_zombies()
	check(game.wave == 2 and game.wave_total == 26 and game.remaining == 26, "Second wave automatically contains eight more zombies")
	check(get_nodes_in_group("zombies").size() > 0, "Automatic wave respawn creates actual enemies")
	await survival_checks()

	print("\nRESULT: %d/%d passed" % [checks - failures, checks])
	game.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures == 0 else 1)

func survival_checks() -> void:
	freeze_zombies()
	var actor = game.player
	check(game.world.MAP_SIZE == Vector2(4608, 3072), "Neighborhood has four times the previous area")
	check(game.world.find_path(Vector2(1168, 880), Vector2(4112, 2464)).size() > 0, "Navigation connects the new districts")
	check(get_nodes_in_group("containers").size() >= 90, "World includes many persistent loot containers")
	# Inventory transactions validate amounts and preserve totals, including large stacks.
	var model = load("res://src/systems/inventory.gd").new()
	var other = load("res://src/systems/inventory.gd").new()
	model.add("ammo_9mm", 1000000)
	check(model.count("ammo_9mm") == 1000000, "Inventory has no carry-capacity limit")
	check(not model.remove("ammo_9mm", 1000001) and not model.add("missing") and not model.remove("ammo_9mm", -2), "Invalid item and quantity operations are rejected")
	check(model.transfer_to(other, "ammo_9mm", 27) and model.count("ammo_9mm") == 999973 and other.count("ammo_9mm") == 27, "Transfers conserve item quantities")
	check(not model.transfer_to(other, "ammo_9mm", 1000000) and not model.transfer_to(model, "ammo_9mm", 1), "Invalid transfers cannot create or lose items")
	other.transfer_all_to(model)
	check(other.is_empty() and model.count("ammo_9mm") == 1000000, "Take-all moves every stack exactly once")
	actor.health = 72
	game.inventory.add("herb", 1)
	var herbs: int = game.inventory.count("herb")
	check(game.use_item("herb") and actor.health == 100 and game.inventory.count("herb") == herbs - 1, "Green herb heals and is consumed without exceeding max health")
	herbs = game.inventory.count("herb")
	check(not game.use_item("herb") and game.inventory.count("herb") == herbs, "Full health does not waste herbs")
	# Empty ammo cannot fire or damage anything. Each weapon uses only its own ammo.
	actor.position = Vector2(730, 540)
	actor.cooldown = 0
	var count: int = game.inventory.count("ammo_9mm")
	game.inventory.remove("ammo_9mm", count)
	var shots: int = actor.shot_count
	actor.fire_at(Vector2(900, 540))
	check(actor.shot_count == shots, "Empty pistol cannot shoot")
	check(not actor.equip("shotgun"), "Unowned weapons cannot be equipped")
	game.inventory.add("shotgun")
	game.inventory.add("rifle")
	game.inventory.add("ammo_shell", 5)
	game.inventory.add("ammo_rifle", 15)
	actor.equip("shotgun")
	actor.cooldown = 0
	var shells: int = game.inventory.count("ammo_shell")
	var bullets: int = game.inventory.count("ammo_rifle")
	actor.fire_at(Vector2(900, 540))
	check(game.inventory.count("ammo_shell") == shells - 1 and game.inventory.count("ammo_rifle") == bullets, "Shotgun fires six pellets using one shell and no rifle rounds")
	check(actor.weapon.pellets == 6 and actor.weapon.damage * 6 > 34, "Shotgun has distinct close-range damage")
	actor.equip("rifle")
	actor.cooldown = 0
	actor.fire_at(Vector2(900, 540))
	check(game.inventory.count("ammo_rifle") == bullets - 1 and actor.weapon.damage == 25 and actor.weapon.cooldown < .22, "Rifle has its own ammunition, damage and fire rate")
	var melee_target = get_nodes_in_group("zombies")[0]
	melee_target.position = Vector2(218, 350)
	actor.position = Vector2(177, 350)
	actor.cooldown = 0
	actor.knife_cooldown = 0
	await frames()
	var melee_health: int = melee_target.health
	actor.knife_at(melee_target.position)
	check(melee_target.health == melee_health, "Knife cannot damage an enemy through a building wall")
	actor.position = Vector2(700, 540)
	melee_target.position = Vector2(750, 540)
	actor.knife_cooldown = 0
	await frames()
	actor.knife_at(Vector2(640, 540))
	check(melee_target.health == melee_health, "Knife hits only enemies in the aimed forward arc")
	# World containers retain changes between openings; no reroll on reopening.
	var locker = get_nodes_in_group("containers").filter(func(n: Node) -> bool: return n.kind == "locker")[0]
	actor.position = locker.position + Vector2(0, 26)
	await frames()
	check(game.can_interact(locker), "Target container itself does not obstruct interaction")
	var e := InputEventAction.new()
	e.action = "interact"
	e.pressed = true
	Input.parse_input_event(e)
	await frames(8)
	check(locker.lid > .5, "Cabinet opening animation continues while the inventory pauses gameplay")
	check(paused and game.inventory_open and game.inventory_panel.visible and game.inventory_panel.source_list.item_count > 0, "E opens side-by-side container and player inventory while pausing the world")
	var panel = game.inventory_panel
	panel._take_all()
	check(locker.inventory.is_empty(), "Take-all empties a locker")
	panel.selected_player = "ammo_rifle"
	panel.quantity.value = 3
	panel._store()
	check(locker.inventory.count("ammo_rifle") == 3, "Player can put a selected quantity into storage")
	game.close_inventory()
	locker.interact(actor)
	check(locker.inventory.count("ammo_rifle") == 3 and paused, "Reopening storage preserves its exact contents")
	panel.selected_source = "ammo_rifle"
	panel.quantity.value = 2
	panel._take()
	check(locker.inventory.count("ammo_rifle") == 1, "Taking a partial stack preserves remaining contents")
	game.close_inventory()
	check(not paused and not game.inventory_open and not locker.is_open, "Closing inventory closes the cabinet and resumes gameplay")
	# Equipped guns stored in full fall back to an always-available knife.
	locker.interact(actor)
	panel.selected_player = "rifle"
	panel.quantity.value = 100
	panel._store()
	check(actor.weapon_id == "knife" and game.inventory.count("rifle") == 0, "Storing the equipped weapon safely selects the knife")
	game.close_inventory()
	# Both box kinds ignore bullets and are cut with an aimed knife cone.
	var wood = get_nodes_in_group("containers").filter(func(n: Node) -> bool: return n.kind == "wood")[0]
	actor.position = wood.position + Vector2(0, 52)
	actor.cooldown = 0
	actor.knife_cooldown = 0
	var durability: int = wood.durability
	wood.take_damage(999, Vector2.UP, "bullet")
	check(wood.durability == durability and not wood.broken, "Wooden boxes require knife strikes")
	actor.knife_at(wood.position)
	check(wood.durability == durability - 36 and not wood.broken, "Aimed knife damages a nearby box")
	var after: int = wood.durability
	actor.knife_at(wood.position)
	check(wood.durability == after, "Knife cooldown prevents repeated damage in one frame")
	await frames(32)
	actor.knife_at(wood.position)
	await frames()
	check(wood.broken and wood.collision_layer == 0 and not wood.is_in_group("platforms"), "Second knife strike breaks wood and removes collision/navigation")
	check(get_nodes_in_group("loot").size() > 0, "Breaking a stocked box exposes collectable loot")
	var cardboard = get_nodes_in_group("containers").filter(func(n: Node) -> bool: return n.kind == "cardboard")[0]
	cardboard.take_damage(36, Vector2.UP, "knife")
	check(cardboard.broken, "Cardboard breaks in one knife strike")
	var bag = game.spawn_loot(Vector2(800, 550), other)
	other.add("herb")
	bag.interact(actor)
	panel._take_all()
	game.close_inventory()
	await frames()
	check(not is_instance_valid(bag), "Empty ground loot bags are removed after collection")
	# Loot rolls are deterministic under a seed but contain both drops and empty corpses.
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var drops := 0
	var empty := 0
	for i in range(100):
		var rolled = load("res://src/systems/loot.gd").roll(rng, "zombie", 2)
		if rolled.is_empty():
			empty += 1
		else:
			drops += 1
	check(drops > 20 and empty > 10, "Zombie drops are random and do not happen on every kill")
	# Jumping really lands on a low platform; a separate full-height wall stays solid.
	var platform = game.world.add_prop(Rect2(744, 480, 64, 30), "bench")
	game.world.rebuild_navigation()
	actor.position = Vector2(710, 501)
	actor.height = 0
	actor.vertical_speed = 0
	actor.last_safe = actor.position
	actor.cooldown = 0
	check(actor.jump() and not actor.jump(), "Jump starts from ground and prevents mid-air double jumps")
	Input.action_press("move_right")
	await frames(22)
	Input.action_release("move_right")
	await frames(50)
	check(actor.height == 26 and actor.position.x > 744, "Jump lands on the top of a low object")
	Input.action_press("move_right")
	await frames(42)
	Input.action_release("move_right")
	await frames(40)
	check(actor.height == 0, "Walking off a platform falls back to ground")
	actor.position = Vector2(220, 350)
	actor.last_safe = actor.position
	actor.jump()
	Input.action_press("move_left")
	await frames(45)
	Input.action_release("move_left")
	await frames(25)
	check(actor.position.x >= 213, "Jump cannot pass through full-height building walls")
	actor.position = Vector2(730, 540)
	actor.jump()
	await frames(15)
	var hp: int = actor.health
	actor.invulnerable = 0
	actor.take_damage(12)
	check(actor.height >= 22 and actor.health == hp, "Zombies on the ground cannot reach a player above them")
	await frames(60)
	game.open_inventory()
	check(game.inventory_open and panel.player_list.item_count > 0 and panel.source_list.item_count == 0, "I opens carried items without a container")
	game.toggle_pause()
	check(not paused and not game.inventory_open, "Escape closes inventory before opening pause")
	game.toggle_map()
	check(paused and game.hud.screen == "map", "Tab opens the expanded neighborhood map and pauses gameplay")
	game.toggle_pause()
	check(not paused and game.hud.screen == "none", "Escape returns from map to gameplay")
	game.restart()
	freeze_zombies()
	await frames()
	check(game.wave == 1 and game.inventory.count("ammo_9mm") == 60 and game.inventory.count("shotgun") == 0 and actor != game.player, "Restart resets waves, inventory and player state")
	for enemy in get_nodes_in_group("zombies"):
		enemy.queue_free()
	await frames()
	game.start_wave(6)
	for i in range(70):
		game._update_waves(.21)
	freeze_zombies()
	check(get_nodes_in_group("zombies").size() == 42 and game.wave_pending == 16 and game.remaining == 58, "Large waves queue excess enemies while retaining the full remaining count")
	get_nodes_in_group("zombies")[0].take_damage(999)
	await frames()
	game._update_waves(.21)
	freeze_zombies()
	check(game.wave_pending == 15 and game.remaining == 57 and get_nodes_in_group("zombies").size() == 42, "Queued zombies replenish a slot after a kill without increasing remaining count")
