extends RefCounted

const ART = preload("res://src/systems/pixel_actor.gd")
const ENV = preload("res://src/systems/environment_art.gd")

static func run(suite: SceneTree) -> bool:
	# Validate the full-frame renderer used by Player, rather than a detached rig.
	for id: String in ART.TEXTURES:
		var texture: Texture2D = ART.TEXTURES[id]
		var image := texture.get_image()
		var complete := texture.get_size() == Vector2(384, 640)
		var jumping := true
		var feet_grounded := true
		var steady := true
		var attached_tip := true
		for row in range(8):
			var head_centers: Array[float] = []
			for col in range(4):
				var pose := ART.pose(id, row, col, 0)
				var airborne := ART.pose(id, row, col, 42)
				var region: Rect2 = pose.region
				var pixels := image.get_region(Rect2i(region)).get_used_rect()
				complete = complete and pixels.size.x >= 12 and pixels.size.y >= 60
				feet_grounded = feet_grounded and pixels.end.y >= 72 and pixels.end.y <= 75
				jumping = jumping and (airborne.bounds.position - pose.bounds.position) == Vector2(0, -42)
				jumping = jumping and (airborne.muzzle - pose.muzzle) == Vector2(0, -42)
				if col < 3:
					var head_sum := 0.0
					var head_pixels := 0
					for y in range(12, 22):
						for x in range(96):
							if image.get_pixel(col * 96 + x, row * 80 + y).a > .7:
								head_sum += x
								head_pixels += 1
					head_centers.append(head_sum / maxf(1, head_pixels))
				var tip: Vector2 = pose.muzzle + ART.BASELINE
				var on_sprite := false
				for dy in range(-2, 3):
					for dx in range(-2, 3):
						var point := Vector2i(tip) + Vector2i(dx, dy)
						if Rect2i(0, 0, 96, 80).has_point(point):
							on_sprite = on_sprite or image.get_pixel(col * 96 + point.x, row * 80 + point.y).a > .5
				attached_tip = attached_tip and on_sprite
			steady = steady and absf(head_centers.max() - head_centers.min()) < 3
		suite.check(complete, "%s has 32 populated complete character frames" % id)
		suite.check(feet_grounded, "%s keeps a common foot baseline through all eight directions and poses" % id)
		suite.check(jumping, "%s full body and barrel move together in a jump" % id)
		suite.check(steady, "%s torso stays centered while the supporting foot alternates" % id)
		if id != "knife":
			suite.check(attached_tip, "%s muzzle metadata remains on the visible held sprite in every frame" % id)
	var directions := true
	for row in range(8):
		directions = directions and ART.facing_for(Vector2.from_angle(PI / 2 - row * PI / 4)) == row
	suite.check(directions, "Full turn selects the correct eight visual directions")
	suite.check(ART.frame_for(false, 0, false, false) == 0 and ART.frame_for(false, 0, true, false) == 3 and ART.frame_for(false, 0, false, true) == 3, "Idle, firing and knife attacks select distinct complete poses")
	suite.check(ART.frame_for(true, 0, false, false) == 1 and ART.frame_for(true, 2, false, false) == 2, "Walking alternates left and right steps")
	var game = suite.game
	var houses := {}
	var doors := {}
	var trees := {}
	for roof in game.world.roofs.get_children():
		houses[ENV.building_sprite(roof.house_name, roof.variant)] = true
	for door in game.world.doors:
		doors[door.variant] = true
	for prop in game.world.actors.get_children():
		if prop.get_script() == load("res://src/world/prop.gd") and prop.kind == "tree":
			trees[prop.variant] = true
	suite.check(houses.size() == 8, "Neighborhood actually places all eight building appearances")
	suite.check(doors.size() == 3 and ENV.DOORS_OPEN.size() == 3, "Neighborhood places all three door types with corresponding open sprites")
	suite.check(trees.size() == 8, "Neighborhood places all eight tree species")
	for enemy in suite.get_nodes_in_group("zombies"):
		enemy.queue_free()
	await suite.frames()
	var actor = game.player
	actor.position = Vector2(2800, 1480)
	actor.velocity = Vector2.ZERO
	actor.animation = 0
	actor.set_physics_process(false)
	var enemy = load("res://tests/aim_checks.gd").spawn_enemy(game, Vector2(3000, 1480))
	await suite.frames()
	for id: String in ["pistol", "shotgun", "rifle"]:
		game.inventory.add(id)
		game.inventory.add({"pistol": "ammo_9mm", "shotgun": "ammo_shell", "rifle": "ammo_rifle"}[id], 20)
		actor.equip(id)
		actor.cooldown = 0
		actor.aim_bloom = 0
		enemy.health = 10000
		var first_effect: int = game.effects.entries.size()
		var target: Vector2 = enemy.position + Vector2(0, -35)
		actor.fire_at(target)
		var muzzle: Vector2 = actor.gun_muzzle()
		var starts_at_barrel := true
		var shots := 0
		for i in range(first_effect, game.effects.entries.size()):
			var entry: Dictionary = game.effects.entries[i]
			if entry.kind == "shot":
				starts_at_barrel = starts_at_barrel and entry.a.distance_to(muzzle) < .001
				shots += 1
		suite.check(starts_at_barrel and shots == actor.weapon.pellets, "%s bullets and flash start at the firing sprite's barrel" % id)
		suite.check(absf((target - actor.gun_origin()).normalized().cross(actor.aim)) < .001, "%s retains precise free aiming between the eight visual directions" % id)
	actor.equip("knife")
	actor.cooldown = 0
	actor.knife_cooldown = 0
	actor.knife_at(enemy.position)
	actor.knife_animation = .12
	suite.check(actor.held_pose().id == "knife" and actor.held_pose().frame == 3, "Knife slash renders a complete hand-held attack frame")
	game.restart()
	suite.freeze_zombies()
	await suite.frames()
	return true
