extends SceneTree

var game: Node

func _initialize() -> void:
	call_deferred("capture")

func save_frame(path: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	var error := picture.save_png(path)
	assert(error == OK)
	print("Saved ", path)

func capture() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await create_timer(.7).timeout
	await save_frame("res://docs/title.png")
	game.begin()
	for enemy in get_nodes_in_group("zombies"):
		enemy.set_physics_process(false)
	await create_timer(.7).timeout
	await save_frame("res://docs/interior.png")
	game.world.doors[0].interact(game.player)
	game.player.position = Vector2(505, 570)
	game.player.camera.reset_smoothing()
	await create_timer(.7).timeout
	await save_frame("res://docs/gameplay.png")
	game.player.position = Vector2(580, 475)
	game.player.zoom_target = 1.15
	game.player.camera.zoom = Vector2(1.15, 1.15)
	game.player.camera.reset_smoothing()
	await create_timer(.4).timeout
	await save_frame("res://docs/overview.png")
	game.player.zoom_target = 1.8
	game.player.camera.zoom = Vector2(1.8, 1.8)
	game.player.position = Vector2(466, 590)
	await create_timer(.15).timeout
	game.start_dialogue("MARA", game.get_tree().get_nodes_in_group("interactables").filter(func(n: Node) -> bool: return n.get_script() == load("res://src/actors/survivor.gd"))[0].lines)
	await create_timer(.2).timeout
	await save_frame("res://docs/dialogue.png")
	game.end_dialogue()
	game.player.position = Vector2(800, 630)
	game.player.camera.reset_smoothing()
	await create_timer(.3).timeout
	var target = get_nodes_in_group("zombies")[0]
	target.position = Vector2(950, 630)
	await create_timer(.05).timeout
	var cursor: Vector2 = target.get_global_transform_with_canvas() * Vector2(0, -40)
	Input.warp_mouse(cursor)
	await create_timer(.15).timeout
	await save_frame("res://docs/aim.png")
	game.player.cooldown = 0
	game.player.fire_at(target.position + Vector2(0, -40))
	await save_frame("res://docs/combat.png")
	var locker = game.get_tree().get_nodes_in_group("containers").filter(func(n: Node) -> bool: return n.kind == "locker")[0]
	game.player.position = locker.position + Vector2(0, 42)
	game.player.camera.reset_smoothing()
	locker.interact(game.player)
	await create_timer(.3).timeout
	await save_frame("res://docs/inventory.png")
	game.close_inventory()
	game.toggle_map()
	await save_frame("res://docs/map.png")
	game.toggle_map()
	game.player.position = Vector2(3175, 2320)
	game.player.camera.reset_smoothing()
	await create_timer(.5).timeout
	await save_frame("res://docs/industry.png")
	game.toggle_pause()
	await save_frame("res://docs/pause.png")
	game.queue_free()
	await process_frame
	await create_timer(.25).timeout
	quit()
