class_name WeaponData
extends Resource

@export var display_name: String = "Pistola"
@export var damage: int = 34
@export var cooldown: float = .22
@export var range_pixels: float = 600
@export var noise_radius: float = 490
@export var infinite_ammo: bool = false
@export var ammo_type: String = "ammo_9mm"
@export var pellets: int = 1
@export var spread: float = 0
@export var icon_id: String = "pistol"

@export var recoil_per_shot: float = .003
@export var max_recoil: float = .008
@export var recoil_recovery: float = .08
