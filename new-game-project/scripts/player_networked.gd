extends CharacterBody2D

@export var speed: float = 560.0
@export var jump_velocity: float = -800.0
@export var gravity: float = 3200.0
@export var max_fall_speed: float = 1200.0
@export var crosshair_distance: float = 80.0  # Fixed distance for crosshair

@onready var visual: Sprite2D = $Sprite2D
@onready var nametag: Label = $Nametag
@onready var crosshair: Node2D = $Crosshair
@onready var health_component: HealthComponent = $HealthComponent
@onready var weapon_manager: WeaponManager = $WeaponManager

var player_id: int = -1
var player_name: String = "Player"
var player_color: String = "Red"
var character_scale: float = 1.0
var jumps_remaining: int = 2
var is_dead: bool = false
var weapon_label: Label = null
var last_damage_source: Node = null

signal player_died(killer: Node)

# Analog input state
var move_input: Vector2 = Vector2.ZERO
var aim_input: Vector2 = Vector2.ZERO
var fire_pressed: bool = false
var jump_pressed: bool = false
var weapon_switch_pressed: int = -1  # -1 = no switch, 0-2 = weapon index

# Color mapping
const COLOR_MAP = {
	"Red": Color(0.85, 0.35, 0.35),
	"Blue": Color(0.35, 0.5, 0.85),
	"Green": Color(0.35, 0.8, 0.35),
	"Yellow": Color(0.85, 0.85, 0.35),
	"Purple": Color(0.8, 0.4, 0.85),
	"Orange": Color(0.85, 0.6, 0.35),
	"Cyan": Color(0.35, 0.8, 0.8),
	"Pink": Color(0.85, 0.55, 0.65),
}

func setup_player(id: int, p_name: String, color: String, _p_team: int = 0):
	player_id = id
	player_name = p_name
	player_color = color

	# Apply character scale
	if character_scale != 1.0:
		scale = Vector2(character_scale, character_scale)

	call_deferred("_apply_setup", color, p_name)

func _apply_setup(color: String, p_name: String):
	if visual and COLOR_MAP.has(color):
		visual.modulate = COLOR_MAP[color]

	if nametag:
		nametag.text = p_name

	# Initialize health
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	# Initialize weapon manager
	if weapon_manager:
		weapon_manager.weapon_changed.connect(_on_weapon_changed)

	_create_weapon_label()
	is_dead = false

func handle_input(
	move_x: float, move_y: float, aim_x: float, aim_y: float,
	fire: bool, jump: bool, weapon: int = -1):
	# Update analog inputs
	move_input = Vector2(move_x, move_y)
	aim_input = Vector2(aim_x, aim_y)

	# Handle jump button (trigger on press, not hold)
	if jump and not jump_pressed:
		_try_jump()
	jump_pressed = jump

	# Handle fire button
	fire_pressed = fire

	# Handle weapon switch (trigger on change)
	if weapon != weapon_switch_pressed and weapon >= 0 and weapon <= 2:
		if weapon_manager:
			weapon_manager._equip_weapon(weapon)
	weapon_switch_pressed = weapon

func _try_jump():
	if is_dead:
		return
	if is_on_floor() or jumps_remaining > 0:
		velocity.y = jump_velocity
		if not is_on_floor():
			jumps_remaining -= 1

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Handle weapon attack
	if fire_pressed and aim_input.length() > 0.1:
		if weapon_manager:
			weapon_manager.attack(aim_input.normalized())

	# Apply horizontal movement from analog stick
	velocity.x = move_input.x * speed

	# Apply gravity
	velocity.y += gravity * delta
	velocity.y = min(velocity.y, max_fall_speed)

	# Move
	move_and_slide()

	# Reset jumps when on floor
	if is_on_floor():
		jumps_remaining = 2

	# Update crosshair position based on aim input
	_update_crosshair()

	# Flip sprite based on movement direction (only if moving)
	if move_input.x < -0.1:
		visual.flip_h = true
	elif move_input.x > 0.1:
		visual.flip_h = false

func _update_crosshair():
	if crosshair == null:
		return

	# If there's aim input, position crosshair in that direction
	if aim_input.length() > 0.1:
		var aim_direction = aim_input.normalized()
		crosshair.position = aim_direction * crosshair_distance
		crosshair.visible = true
	else:
		# Hide crosshair when not aiming
		crosshair.visible = false

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead or not health_component:
		return

	last_damage_source = source
	health_component.take_damage(amount, source)

	# Visual feedback
	visual.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		visual.modulate = COLOR_MAP.get(player_color, Color(1, 1, 1, 1))

func _on_health_changed(current: int, max: int) -> void:
	if nametag:
		nametag.text = "%s [%d/%d]" % [player_name, current, max]

func _on_health_depleted() -> void:
	die()

func _on_weapon_changed(weapon: Weapon) -> void:
	_update_weapon_label(weapon)

func collect_coin() -> void:
	GameManager.add_coin()

func die() -> void:
	if is_dead:
		return

	is_dead = true

	# Determine killer
	var killer: Node = null
	if last_damage_source:
		if last_damage_source.is_in_group("players"):
			killer = last_damage_source
		elif last_damage_source is Area2D and last_damage_source.get("shooter"):
			killer = last_damage_source.shooter

	player_died.emit(killer)

	# Visual death effect
	visual.modulate = Color(0.3, 0.3, 0.3, 0.5)

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Hide weapon label
	if weapon_label:
		weapon_label.visible = false

func _create_weapon_label() -> void:
	weapon_label = Label.new()
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.position = Vector2(-30, -55)
	weapon_label.size = Vector2(60, 20)
	weapon_label.add_theme_font_size_override("font_size", 10)
	weapon_label.add_theme_color_override(
		"font_color", Color(1, 1, 1, 0.8))
	weapon_label.add_theme_color_override(
		"font_shadow_color", Color(0, 0, 0, 0.6))
	weapon_label.add_theme_constant_override("shadow_offset_x", 1)
	weapon_label.add_theme_constant_override("shadow_offset_y", 1)
	weapon_label.z_index = 30
	add_child(weapon_label)
	if weapon_manager:
		var current = weapon_manager.get_current_weapon()
		if current:
			_update_weapon_label(current)

func _update_weapon_label(weapon: Weapon) -> void:
	if not weapon_label:
		return
	match weapon.weapon_type:
		Weapon.WeaponType.MELEE_SWORD:
			weapon_label.text = "Sword"
		Weapon.WeaponType.GUN:
			weapon_label.text = "Gun"
		Weapon.WeaponType.LASER_GUN:
			weapon_label.text = "Laser"
		_:
			weapon_label.text = weapon.weapon_name
