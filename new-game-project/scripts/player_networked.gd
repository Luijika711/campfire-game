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
var team: int = 0  # TeamManager.Team.NONE
var character_scale: float = 1.0
var jumps_remaining: int = 2
var is_dead: bool = false

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

func setup_player(id: int, p_name: String, color: String, p_team: int = 0):
	player_id = id
	player_name = p_name
	player_color = color
	team = p_team

	# Apply character scale
	if character_scale != 1.0:
		scale = Vector2(character_scale, character_scale)

	# Register team
	if TeamManager:
		TeamManager.set_team(self, team)

	# Setup visual and nametag (call_deferred ensures nodes are ready)
	call_deferred("_apply_setup", color, p_name, p_team)

func _apply_setup(color: String, p_name: String, p_team: int = 0):
	# Set visual color
	if visual and COLOR_MAP.has(color):
		visual.modulate = COLOR_MAP[color]

	# Setup nametag with team
	if nametag:
		var team_tag = TeamManager.get_team_name(p_team) if TeamManager else ""
		if team_tag != "None" and team_tag != "":
			nametag.text = "[%s] %s" % [team_tag, p_name]
		else:
			nametag.text = p_name

	# Initialize health
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	# Initialize weapon manager
	if weapon_manager:
		weapon_manager.weapon_changed.connect(_on_weapon_changed)

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

	health_component.take_damage(amount, source)

	# Visual feedback
	visual.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		visual.modulate = COLOR_MAP.get(player_color, Color(1, 1, 1, 1))

func _on_health_changed(current: int, max: int) -> void:
	# Update nametag to show health
	if nametag:
		var team_tag = TeamManager.get_team_name(team) if TeamManager else ""
		var prefix = ""
		if team_tag != "None" and team_tag != "":
			prefix = "[%s] " % team_tag
		nametag.text = "%s%s [%d/%d]" % [prefix, player_name, current, max]

func _on_health_depleted() -> void:
	die()

func _on_weapon_changed(_weapon: Weapon) -> void:
	# Could update UI or effects here
	pass

func collect_coin() -> void:
	GameManager.add_coin()

func set_team(new_team: int) -> void:
	team = new_team
	if TeamManager:
		TeamManager.set_team(self, team)

func die() -> void:
	if is_dead:
		return

	is_dead = true

	# Visual death effect
	visual.modulate = Color(0.3, 0.3, 0.3, 0.5)

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Wait then respawn
	await get_tree().create_timer(2.0).timeout
	respawn()

func respawn() -> void:
	is_dead = false

	# Reset health
	if health_component:
		health_component.reset_health()

	# Respawn at random spawn point
	var spawn_points = get_parent().spawn_points
	position = spawn_points[randi() % spawn_points.size()]
	velocity = Vector2.ZERO

	# Re-enable collision
	collision_layer = 1
	collision_mask = 7

	# Reset visual
	if visual and COLOR_MAP.has(player_color):
		visual.modulate = COLOR_MAP[player_color]

	# Reset jumps
	jumps_remaining = 2
