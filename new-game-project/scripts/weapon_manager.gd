class_name WeaponManager
extends Node2D

signal weapon_changed(weapon: Weapon)
signal weapon_ammo_changed(weapon_index: int, ammo_text: String)

@export var weapon_slots: Array[PackedScene] = []

var current_weapons: Array[Weapon] = []
var current_weapon_index: int = 0
var max_weapons: int = 3

func _ready() -> void:
	# Initialize weapon slots
	for i in range(max_weapons):
		if i < weapon_slots.size() and weapon_slots[i] != null:
			var weapon = weapon_slots[i].instantiate()
			add_child(weapon)
			current_weapons.append(weapon)
		else:
			current_weapons.append(null)

	# Equip first available weapon
	_equip_weapon(0)

func _input(event: InputEvent) -> void:
	# Weapon switching with number keys
	if event.is_action_pressed("weapon_1"):
		_equip_weapon(0)
	elif event.is_action_pressed("weapon_2"):
		_equip_weapon(1)
	elif event.is_action_pressed("weapon_3"):
		_equip_weapon(2)

	# Mouse wheel weapon switching
	if event.is_action_pressed("weapon_next"):
		_switch_weapon(1)
	elif event.is_action_pressed("weapon_prev"):
		_switch_weapon(-1)

func _process(_delta: float) -> void:
	# Update ammo displays
	for i in range(current_weapons.size()):
		if current_weapons[i] != null:
			var weapon = current_weapons[i]
			if weapon.has_method("get_ammo_text"):
				weapon_ammo_changed.emit(i, weapon.get_ammo_text())

func _equip_weapon(index: int) -> void:
	if index < 0 or index >= max_weapons:
		return

	if current_weapons[index] == null:
		return

	# Hide current weapon
	if current_weapons[current_weapon_index] != null:
		current_weapons[current_weapon_index].visible = false

	current_weapon_index = index

	# Show new weapon
	current_weapons[current_weapon_index].visible = true

	weapon_changed.emit(current_weapons[current_weapon_index])

func _switch_weapon(direction: int) -> void:
	var new_index = current_weapon_index
	var attempts = 0

	while attempts < max_weapons:
		new_index = (new_index + direction + max_weapons) % max_weapons
		if current_weapons[new_index] != null:
			_equip_weapon(new_index)
			break
		attempts += 1

func get_current_weapon() -> Weapon:
	if current_weapon_index < current_weapons.size():
		return current_weapons[current_weapon_index]
	return null

func attack(direction: Vector2) -> void:
	var weapon = get_current_weapon()
	if weapon != null:
		weapon.attack(direction)

func get_weapon_at_slot(index: int) -> Weapon:
	if index >= 0 and index < current_weapons.size():
		return current_weapons[index]
	return null

func has_weapon(weapon_type: Weapon.WeaponType) -> bool:
	for weapon in current_weapons:
		if weapon != null and weapon.weapon_type == weapon_type:
			return true
	return false

func add_weapon(weapon_scene: PackedScene, slot: int = -1) -> bool:
	if slot >= 0 and slot < max_weapons:
		# Add to specific slot
		if current_weapons[slot] == null:
			var weapon = weapon_scene.instantiate()
			add_child(weapon)
			weapon.visible = false
			current_weapons[slot] = weapon
			return true
	else:
		# Add to first empty slot
		for i in range(max_weapons):
			if current_weapons[i] == null:
				var weapon = weapon_scene.instantiate()
				add_child(weapon)
				weapon.visible = false
				current_weapons[i] = weapon
				return true
	return false
