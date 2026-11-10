extends RefCounted

const DATA := {
	"pistol": {"name": "Pistola 9 mm", "kind": "weapon", "icon": "pistol"},
	"shotgun": {"name": "Escopeta", "kind": "weapon", "icon": "shotgun"},
	"rifle": {"name": "Fuzil", "kind": "weapon", "icon": "rifle"},
	"knife": {"name": "Faca de combate", "kind": "weapon", "icon": "knife"},
	"ammo_9mm": {"name": "Munição 9 mm", "kind": "ammo", "icon": "ammo_9mm"},
	"ammo_shell": {"name": "Cartuchos de escopeta", "kind": "ammo", "icon": "ammo_shell"},
	"ammo_rifle": {"name": "Munição de fuzil", "kind": "ammo", "icon": "ammo_rifle"},
	"herb": {"name": "Erva verde · recupera 45 de vida", "kind": "heal", "icon": "herb", "heal": 45}
}

static var textures: Dictionary = {}

static func label(id: String) -> String:
	return DATA.get(id, {"name": id}).name

static func icon(id: String) -> Texture2D:
	if not textures.has(id):
		textures[id] = load("res://art/survival/%s.png" % DATA.get(id, {"icon": "loot"}).icon)
	return textures[id]
