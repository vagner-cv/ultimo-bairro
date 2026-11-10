extends RefCounted

signal changed
const ITEMS = preload("res://src/systems/items.gd")
var stacks: Dictionary = {}

func count(id: String) -> int:
	return int(stacks.get(id, 0))

func add(id: String, amount: int = 1) -> bool:
	if amount <= 0 or not ITEMS.DATA.has(id):
		return false
	stacks[id] = count(id) + amount
	changed.emit()
	return true

func remove(id: String, amount: int = 1) -> bool:
	if amount <= 0 or count(id) < amount:
		return false
	stacks[id] = count(id) - amount
	if stacks[id] == 0:
		stacks.erase(id)
	changed.emit()
	return true

func transfer_to(destination: RefCounted, id: String, amount: int) -> bool:
	if destination == self or amount <= 0 or count(id) < amount:
		return false
	# Validate before either model emits changed: transfers cannot duplicate items.
	if not ITEMS.DATA.has(id):
		return false
	stacks[id] = count(id) - amount
	if stacks[id] == 0:
		stacks.erase(id)
	destination.stacks[id] = destination.count(id) + amount
	changed.emit()
	destination.changed.emit()
	return true

func transfer_all_to(destination: RefCounted) -> void:
	for id: String in stacks.keys():
		transfer_to(destination, id, count(id))

func is_empty() -> bool:
	return stacks.is_empty()
