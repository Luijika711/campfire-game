class_name Weapon
extends Node2D

enum WeaponType {
	MELEE_SWORD,
	GUN,
	LASER_GUN
}

signal weapon_fired()
signal weapon_cooldown_started(duration: float)
signal weapon_cooldown_finished()

@export var weapon_name: String = "Weapon"
@export var weapon_type: WeaponType = WeaponType.GUN
@export var damage: int = 10
@export var cooldown: float = 0.5
@export var icon: Texture2D

var is_melee: bool:
	get:
		return weapon_type == WeaponType.MELEE_SWORD

var is_on_cooldown: bool = false
var cooldown_timer: float = 0.0
var can_attack: bool = true

@onready var player: CharacterBody2D = get_parent().get_parent() if get_parent() else null

func _ready() -> void:
	add_to_group("weapons")
	_create_held_visual()

func _create_held_visual() -> void:
	# Override in subclasses for custom held visuals
	pass

func _process(delta: float) -> void:
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false
			can_attack = true
			weapon_cooldown_finished.emit()

func attack(direction: Vector2) -> void:
	if not can_attack or is_on_cooldown:
		return

	perform_attack(direction)
	start_cooldown()

func perform_attack(_direction: Vector2) -> void:
	# Override in subclasses
	pass

func start_cooldown() -> void:
	is_on_cooldown = true
	can_attack = false
	cooldown_timer = cooldown
	weapon_cooldown_started.emit(cooldown)

func get_weapon_info() -> Dictionary:
	return {
		"name": weapon_name,
		"type": weapon_type,
		"damage": damage,
		"cooldown": cooldown,
		"icon": icon
	}
