extends RefCounted

# Feet are used for locomotion. A separate area follows the visible body.
const BODY_LAYER: int = 32
const WORLD_MASK: int = 1 | 8 | 16
const FOOT_OFFSET := Vector2(0, -8)

static func attach_body(actor: CollisionObject2D) -> Area2D:
	var area := Area2D.new()
	area.name = "BodyHitbox"
	area.collision_layer = BODY_LAYER
	area.collision_mask = 0
	area.monitoring = false
	var collision := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 11
	capsule.height = 62
	collision.shape = capsule
	collision.position = Vector2(0, -32)
	area.add_child(collision)
	actor.add_child(area)
	return area

static func trace(shooter: CharacterBody2D, origin: Vector2, direction: Vector2, distance: float) -> Dictionary:
	if direction.is_zero_approx() or distance <= 0:
		return {}
	direction = direction.normalized()
	var space := shooter.get_world_2d().direct_space_state
	var bodies := PhysicsRayQueryParameters2D.create(origin, origin + direction * distance, BODY_LAYER)
	bodies.collide_with_areas = true
	bodies.collide_with_bodies = false
	bodies.hit_from_inside = true
	var visible := space.intersect_ray(bodies)
	var ground_start := shooter.global_position + FOOT_OFFSET
	var mask := WORLD_MASK if float(shooter.get("height")) < 22 else (1 | 8)
	var target_actor: Node2D = null
	var ground_end := ground_start + direction * distance
	if not visible.is_empty():
		target_actor = visible.collider.get_parent()
		# Project the point of impact to the floor for occlusion. This prevents a
		# raised muzzle/body sprite from bypassing a closed door at close range.
		ground_end = Vector2(visible.position.x, target_actor.global_position.y + FOOT_OFFSET.y)
	var solids := PhysicsRayQueryParameters2D.create(ground_start, ground_end, mask)
	var excluded: Array[RID] = [shooter.get_rid()]
	if target_actor is CollisionObject2D:
		excluded.append(target_actor.get_rid())
	solids.exclude = excluded
	solids.hit_from_inside = true
	var blocked := space.intersect_ray(solids)
	if not blocked.is_empty():
		var fraction := 0.0
		if ground_start.distance_squared_to(ground_end) > .001:
			fraction = clampf(ground_start.distance_to(blocked.position) / ground_start.distance_to(ground_end), 0, 1)
		var visual_end: Vector2 = visible.position if not visible.is_empty() else origin + direction * distance
		blocked["position"] = origin.lerp(visual_end, fraction)
		return blocked
	if not visible.is_empty():
		visible["body_area"] = visible.collider
		visible["collider"] = target_actor
	return visible
