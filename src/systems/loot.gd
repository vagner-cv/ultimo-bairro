extends RefCounted

const INVENTORY = preload("res://src/systems/inventory.gd")

static func roll(random: RandomNumberGenerator, source: String, wave: int = 1) -> RefCounted:
	var result = INVENTORY.new()
	if source == "zombie" and random.randf() > .62:
		return result
	if source != "zombie" and random.randf() < .12:
		return result
	var ids := ["ammo_9mm", "ammo_shell", "ammo_rifle", "herb"]
	var rolls := 1 if source == "zombie" else random.randi_range(1, 3)
	for i in range(rolls):
		var id: String = ids[random.randi_range(0, ids.size() - 1)]
		var amount := 1 if id == "herb" else (random.randi_range(2, 5) if id == "ammo_shell" else random.randi_range(6, 15) + mini(wave, 10))
		result.add(id, amount)
	if source != "zombie" and random.randf() < .18:
		result.add("shotgun" if random.randf() < .6 else "rifle")
	return result
