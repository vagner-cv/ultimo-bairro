extends Node2D

const WORLD = preload("res://src/world/neighborhood.gd")
const PLAYER = preload("res://src/actors/player.gd")
const ZOMBIE = preload("res://src/actors/zombie.gd")
const HUD = preload("res://src/ui/hud.gd")
const EFFECTS = preload("res://src/systems/effects.gd")
const INVENTORY = preload("res://src/systems/inventory.gd")
const LOOT = preload("res://src/systems/loot.gd")
const LOOT_BAG = preload("res://src/world/loot_bag.gd")
const INVENTORY_PANEL = preload("res://src/ui/inventory_panel.gd")
const AUDIO = preload("res://src/systems/audio.gd")

var inventory: RefCounted
var inventory_panel: Control
var inventory_open: bool = false
var wave: int = 1
var wave_total: int = 18
var wave_pending: int = 0
var wave_countdown: float = -1
var spawn_timer: float = 0
var toast_message: String = ""
var notification_time: float = 0
var smooth_graphics: bool = true
var world: Node2D
var player: CharacterBody2D
var effects: Node2D
var audio: Node
var hud: Control
var nearby: Node2D
var kills: int = 0
var remaining: int = 0
var elapsed: float = 0.0
var shake: float = 0.0
var met_mara: bool = false
var dialogue_active: bool = false
var dialogue_name: String = ""
var dialogue_lines: Array[String] = []
var dialogue_index: int = 0
var started: bool = false
var quitting: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	get_tree().auto_accept_quit = false
	_setup_inputs()
	audio = AUDIO.new()
	audio.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(audio)
	_build_world()
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	hud = HUD.new()
	hud.game = self
	canvas.add_child(hud)
	inventory_panel = INVENTORY_PANEL.new()
	inventory_panel.game = self
	hud.add_child(inventory_panel)
	get_tree().paused = true

func _setup_inputs() -> void:
	var keys := {"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "interact": [KEY_E], "pause_game": [KEY_ESCAPE], "mute": [KEY_M], "fullscreen": [KEY_F11], "inventory": [KEY_I], "map": [KEY_TAB], "knife": [KEY_F], "jump": [KEY_SPACE], "quick_heal": [KEY_H], "graphics": [KEY_F2]}
	for action: String in keys:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: int in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)
	if not InputMap.has_action("shoot"):
		InputMap.add_action("shoot")
		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("shoot", mouse)
	var knife_mouse := InputEventMouseButton.new()
	knife_mouse.button_index = MOUSE_BUTTON_RIGHT
	InputMap.action_add_event("knife", knife_mouse)

func _build_world() -> void:
	inventory = INVENTORY.new()
	inventory.add("pistol")
	inventory.add("knife")
	inventory.add("ammo_9mm", 60)
	inventory.add("herb", 1)
	wave = 1
	wave_total = 18
	wave_pending = 0
	wave_countdown = -1
	world = WORLD.new()
	world.name = "VilaAurora"
	world.game = self
	add_child(world)
	effects = EFFECTS.new()
	effects.z_index = 2
	world.add_child(effects)
	player = PLAYER.new()
	player.name = "Player"
	player.game = self
	player.position = world.SPAWN
	world.actors.add_child(player)
	world.set_player(player)
	remaining = wave_total
	for at: Vector2 in world.spawn_points:
		_spawn_zombie(at)
	player.camera.reset_smoothing()
	_apply_graphics()

func begin() -> void:
	started = true
	get_tree().paused = false
	hud.show_screen("none")
	# Don't fire the click that closed the menu into the starting room.
	player.cooldown = .28

func restart() -> void:
	if inventory_open:
		close_inventory()
	inventory_panel.hide()
	notification_time = 0
	get_tree().paused = false
	Input.action_release("shoot")
	nearby = null
	dialogue_active = false
	dialogue_lines.clear()
	kills = 0
	elapsed = 0
	met_mara = false
	shake = 0
	remove_child(world)
	world.queue_free()
	_build_world()
	begin()

func toggle_pause() -> void:
	player.clear_aim_target()
	if inventory_open:
		close_inventory()
		return
	if hud.screen == "map":
		toggle_map()
		return
	if hud.screen == "help":
		hud.show_screen(hud.previous_screen)
		return
	if not started or player.health <= 0:
		return
	if dialogue_active:
		end_dialogue()
		return
	get_tree().paused = not get_tree().paused
	hud.show_screen("pause" if get_tree().paused else "none")
	if not get_tree().paused:
		player.cooldown = maxf(player.cooldown, .18)

func _unhandled_input(event: InputEvent) -> void:
	if quitting:
		return
	if event.is_action_pressed("pause_game"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("fullscreen"):
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif event.is_action_pressed("mute"):
		audio.toggle_mute()
	elif event.is_action_pressed("inventory") and started and player.health > 0:
		if inventory_open:
			close_inventory()
		elif not get_tree().paused and not dialogue_active:
			open_inventory()
	elif event.is_action_pressed("map"):
		toggle_map()
	elif event.is_action_pressed("graphics"):
		smooth_graphics = not smooth_graphics
		_apply_graphics()
		notify("Filtro suave" if smooth_graphics else "Texturas nítidas")
	elif event.is_action_pressed("interact") and not get_tree().paused:
		if dialogue_active:
			advance_dialogue()
		elif is_instance_valid(nearby):
			nearby.interact(player)
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not started or get_tree().paused:
		return
	elapsed += delta
	notification_time = maxf(0, notification_time - delta)
	_update_waves(delta)
	nearby = null
	var nearest_distance := 60.0
	for item: Node2D in get_tree().get_nodes_in_group("interactables"):
		var distance := player.global_position.distance_to(item.global_position)
		if distance < nearest_distance and can_interact(item):
			nearest_distance = distance
			nearby = item
	# A closed door is itself the ray obstruction; proximity still permits opening.
	if nearby == null:
		for door in world.doors:
			var distance: float = player.global_position.distance_to(door.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearby = door
	if dialogue_active and player.global_position.distance_to(Vector2(466, 548)) > 90:
		end_dialogue()
	shake = move_toward(shake, 0, delta * 7)
	player.camera.offset = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))

func start_dialogue(speaker: String, lines: Array[String]) -> void:
	player.clear_aim_target()
	dialogue_active = true
	dialogue_name = speaker
	dialogue_lines = lines
	dialogue_index = 0
	met_mara = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud._layout()

func advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		end_dialogue()

func end_dialogue() -> void:
	dialogue_active = false
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if hud.screen == "none" else Input.MOUSE_MODE_VISIBLE
	hud._layout()

func make_noise(at: Vector2, radius: float) -> void:
	for zombie in get_tree().get_nodes_in_group("zombies"):
		zombie.hear(at, radius)

func zombie_killed(at: Vector2 = Vector2.ZERO) -> void:
	kills += 1
	remaining = maxi(0, remaining - 1)
	var drops = LOOT.roll(world.random, "zombie", wave)
	if not drops.is_empty():
		call_deferred("spawn_loot", at, drops)
	if remaining == 0:
		wave_countdown = 12
		notify("Onda %d concluída. Próxima em 12 segundos." % wave)

func game_over() -> void:
	player.clear_aim_target()
	end_dialogue()
	get_tree().paused = true
	hud.show_screen("dead")

func quit_game() -> void:
	if quitting:
		return
	quitting = true
	started = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	audio.shutdown()
	# Let the audio mixer release its last playback before engine shutdown.
	await get_tree().create_timer(.2).timeout
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()

func _exit_tree() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func notify(message: String) -> void:
	toast_message = message
	notification_time = 3.5

func _spawn_zombie(at: Vector2) -> void:
	var zombie := ZOMBIE.new()
	zombie.game = self
	zombie.position = at
	world.actors.add_child(zombie)

func _update_waves(delta: float) -> void:
	if wave_countdown >= 0:
		wave_countdown -= delta
		if wave_countdown <= 0:
			start_wave(wave + 1)
	if wave_pending > 0:
		spawn_timer -= delta
		if spawn_timer <= 0 and get_tree().get_nodes_in_group("zombies").size() < 42:
			_spawn_zombie(world.wave_spawn(player.global_position))
			wave_pending -= 1
			spawn_timer = .2

func start_wave(number: int) -> void:
	wave = number
	wave_total = 18 + (wave - 1) * 8
	remaining = wave_total
	wave_pending = wave_total
	wave_countdown = -1
	spawn_timer = 0
	notify("ONDA %d · %d infectados" % [wave, wave_total])

func spawn_loot(at: Vector2, contents: RefCounted) -> Node2D:
	var bag := LOOT_BAG.new()
	bag.game = self
	bag.inventory = contents
	bag.position = at
	world.actors.add_child(bag)
	return bag

func can_interact(item: Node2D) -> bool:
	var origin := player.global_position + Vector2(0, -8)
	var endpoint := item.global_position + Vector2(0, -8)
	var query := PhysicsRayQueryParameters2D.create(origin, endpoint, 1 | 16)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == item

func open_inventory(container: Node2D = null) -> void:
	if not started or player.health <= 0 or dialogue_active or inventory_open:
		return
	player.clear_aim_target()
	inventory_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	inventory_panel.open(container)

func close_inventory() -> void:
	if not inventory_open:
		return
	if is_instance_valid(inventory_panel.target):
		inventory_panel.target.close()
	inventory_panel.target = null
	inventory_panel.hide()
	inventory_open = false
	get_tree().paused = false
	player.cooldown = maxf(player.cooldown, .25)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func use_item(id: String) -> bool:
	if id != "herb" or player.health <= 0 or player.health >= 100:
		return false
	if not inventory.remove("herb"):
		notify("Você não tem ervas verdes.")
		return false
	player.health = mini(100, player.health + 45)
	player.health_changed.emit(player.health)
	audio.play("step", -8)
	notify("Erva verde utilizada · +45 de vida")
	return true

func toggle_map() -> void:
	if not started or player.health <= 0 or inventory_open or dialogue_active or hud.screen not in ["none", "map"]:
		return
	player.clear_aim_target()
	var opened: bool = hud.screen != "map"
	get_tree().paused = opened
	hud.show_screen("map" if opened else "none")
	player.cooldown = maxf(player.cooldown, .25)

func _apply_graphics() -> void:
	world.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if smooth_graphics else CanvasItem.TEXTURE_FILTER_LINEAR
	world.material = null
	player.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for object in world.actors.get_children() + world.roofs.get_children():
		object.material = null
		object.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS if smooth_graphics else CanvasItem.TEXTURE_FILTER_LINEAR
