extends RefCounted

const RIG = preload("res://src/systems/weapon_rig.gd")

static func run(suite: SceneTree) -> bool:
	# Check the attachment contract through a full turn, gait, recoil and jump.
	for id: String in RIG.GUNS:
		var attached := true
		var aligned := true
		var finite := true
		var natural_length := true
		var jump_follows := true
		var recoil_follows := true
		for degree in range(0, 360, 15):
			for frame in range(4):
				var target := Vector2.from_angle(deg_to_rad(degree)) * 200 + RIG.pivot(frame, true, 0)
				var orientation := RIG.orient(id, target, frame, true, 0)
				var standing := RIG.pose(id, orientation.direction, orientation.facing, frame, true, 0, 0, orientation.lateral)
				var kicked := RIG.pose(id, orientation.direction, orientation.facing, frame, true, 0, 3.5, orientation.lateral)
				var airborne := RIG.pose(id, orientation.direction, orientation.facing, frame, true, 42, 0, orientation.lateral)
				for pose: Dictionary in [standing, kicked, airborne]:
					var palm: Vector2 = pose.right.wrist + pose.direction * RIG.HAND_SIZE.x * RIG.HAND_PALM
					attached = attached and palm.distance_to(pose.grip) < .001
					if pose.data.two_hands:
						var support: Vector2 = pose.left.wrist + pose.direction * RIG.SUPPORT_SIZE.x * RIG.HAND_PALM
						attached = attached and support.distance_to(pose.support) < .001
					aligned = aligned and absf((pose.muzzle - pose.origin).cross(pose.direction)) < .001
					finite = finite and pose.right.elbow.is_finite() and pose.left.elbow.is_finite() and pose.muzzle.is_finite()
					natural_length = natural_length and pose.right.length < 15.5 and pose.left.length < 15.5
				aligned = aligned and absf((target - standing.origin).normalized().cross(standing.direction)) < .001
				var muzzle_delta: Vector2 = kicked.muzzle - standing.muzzle
				recoil_follows = recoil_follows and (kicked.right.wrist - standing.right.wrist).distance_to(muzzle_delta) < .001
				if standing.data.two_hands:
					recoil_follows = recoil_follows and (kicked.left.wrist - standing.left.wrist).distance_to(muzzle_delta) < .001
				jump_follows = jump_follows and (airborne.muzzle - standing.muzzle).distance_to(Vector2(0, -42)) < .001
				jump_follows = jump_follows and (airborne.right.shoulder - standing.right.shoulder).distance_to(Vector2(0, -42)) < .001
		suite.check(attached, "%s stays in the hands throughout the full aim turn and walk cycle" % id)
		suite.check(aligned, "%s barrel and aim line stay aligned with the cursor" % id)
		suite.check(finite and natural_length, "%s arm joints remain finite and within natural reach" % id)
		suite.check(jump_follows, "%s and its shoulder attachments follow the player during a jump" % id)
		suite.check(recoil_follows, "%s moves both weapon and holding hands together under recoil" % id)
	# Exercise the actual Player renderer/shot entry points, including pellet origins.
	var game = suite.game
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
		actor.fire_at(enemy.position + Vector2(0, -35))
		var muzzle: Vector2 = actor.gun_muzzle()
		var starts_at_barrel := true
		var shots := 0
		for i in range(first_effect, game.effects.entries.size()):
			var entry: Dictionary = game.effects.entries[i]
			if entry.kind == "shot":
				starts_at_barrel = starts_at_barrel and entry.a.distance_to(muzzle) < .001
				shots += 1
		suite.check(starts_at_barrel and shots == actor.weapon.pellets, "%s bullets and muzzle flash start at the held weapon's barrel" % id)
	actor.equip("knife")
	actor.cooldown = 0
	actor.knife_cooldown = 0
	actor.knife_at(enemy.position)
	var start: Dictionary = actor.held_pose()
	actor.knife_animation = .12
	var middle: Dictionary = actor.held_pose()
	actor.knife_animation = .01
	var end: Dictionary = actor.held_pose()
	var holding := true
	for pose: Dictionary in [start, middle, end]:
		holding = holding and (pose.right.wrist + pose.direction * RIG.HAND_SIZE.x * RIG.HAND_PALM).distance_to(pose.grip) < .001
	suite.check(holding and start.muzzle.distance_to(end.muzzle) > 4, "Knife remains in the hand throughout its swing")
	game.restart()
	suite.freeze_zombies()
	await suite.frames()
	return true
