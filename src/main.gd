extends Node2D

const WORLD = preload("res://src/world/neighborhood.gd")
const PLAYER = preload("res://src/actors/player.gd")
const ZOMBIE = preload("res://src/actors/zombie.gd")
const HUD = preload("res://src/ui/hud.gd")
const EFFECTS = preload("res://src/systems/effects.gd")
const AUDIO = preload("res://src/systems/audio.gd")

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
	get_tree().paused = true

func _setup_inputs() -> void:
	var keys := {"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN], "move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "interact": [KEY_E], "pause_game": [KEY_ESCAPE], "mute": [KEY_M], "fullscreen": [KEY_F11]}
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

func _build_world() -> void:
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
	remaining = world.spawn_points.size()
	for at: Vector2 in world.spawn_points:
		var zombie := ZOMBIE.new()
		zombie.game = self
		zombie.position = at
		world.actors.add_child(zombie)
	player.camera.reset_smoothing()

func begin() -> void:
	started = true
	get_tree().paused = false
	hud.show_screen("none")
	# Don't fire the click that closed the menu into the starting room.
	player.cooldown = .28

func restart() -> void:
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
	nearby = null
	var nearest_distance := 60.0
	for item: Node2D in get_tree().get_nodes_in_group("interactables"):
		var distance := player.global_position.distance_to(item.global_position)
		if distance < nearest_distance and world.has_line_of_sight(player.global_position + Vector2(0, -8), item.global_position + Vector2(0, -24)):
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

func zombie_killed() -> void:
	kills += 1
	remaining = maxi(0, remaining - 1)

func game_over() -> void:
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
