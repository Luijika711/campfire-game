extends CharacterBody2D
class_name Enemy

# Difficulty Settings
enum Difficulty { EASY, MEDIUM, HARD }
@export var difficulty: Difficulty = Difficulty.MEDIUM

# Movement
@export var speed: float = 200.0
@export var jump_velocity: float = -450.0
@export var gravity: float = 2000.0

# Detection & Combat
@export var detection_range: float = 500.0
@export var attack_range: float = 300.0
@export var preferred_range: float = 200.0  # Try to stay at this distance
@export var fire_rate: float = 1.0

# AI Behavior
var reaction_time: float = 0.3
var accuracy: float = 0.7
var dodge_chance: float = 0.5

@onready var visual: Sprite2D = $Sprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var health_bar: ProgressBar = $HealthBar
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var attack_timer: Timer = $AttackTimer

# Raycasts for navigation
@onready var floor_check_left: RayCast2D = $FloorCheckLeft
@onready var floor_check_right: RayCast2D = $FloorCheckRight
@onready var wall_check_left: RayCast2D = $WallCheckLeft
@onready var wall_check_right: RayCast2D = $WallCheckRight
@onready var platform_check: RayCast2D = $PlatformCheck

var is_dead: bool = false
var target_player: Node2D = null
var can_attack: bool = true
var facing_direction: int = 1

# AI Memory
var last_known_player_pos: Vector2
var time_since_player_seen: float = 0.0
var is_aggressive: bool = false

# Dodge state
var is_dodging: bool = false
var dodge_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")

	# Apply difficulty settings
	_apply_difficulty()

	# Connect health signals
	if health_component:
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	# Setup timers
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Initialize facing
	facing_direction = 1 if randf() > 0.5 else -1
	_update_visual_facing()

func _apply_difficulty() -> void:
	match difficulty:
		Difficulty.EASY:
			reaction_time = 0.5
			accuracy = 0.5
			dodge_chance = 0.2
			speed = 150.0
			fire_rate = 1.5
		Difficulty.MEDIUM:
			reaction_time = 0.3
			accuracy = 0.7
			dodge_chance = 0.5
			speed = 200.0
			fire_rate = 1.0
		Difficulty.HARD:
			reaction_time = 0.15
			accuracy = 0.9
			dodge_chance = 0.8
			speed = 280.0
			fire_rate = 0.6

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Update AI
	_update_target_detection(delta)
	_check_for_bullets()

	if is_dodging:
		_dodge_update(delta)
	else:
		_execute_ai(delta)

	move_and_slide()

func _update_target_detection(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("players")
	var closest_player = null
	var closest_distance = detection_range

	for player in players:
		if player.is_dead:
			continue

		var distance = global_position.distance_to(player.global_position)

		# Check line of sight
		if distance < closest_distance and _has_line_of_sight(player):
			closest_player = player
			closest_distance = distance

	if closest_player != null:
		target_player = closest_player
		last_known_player_pos = target_player.global_position
		time_since_player_seen = 0.0
		is_aggressive = true
	else:
		time_since_player_seen += delta
		if time_since_player_seen > 3.0:  # Give up after 3 seconds
			is_aggressive = false
			target_player = null

func _has_line_of_sight(player: Node2D) -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		global_position,
		player.global_position,
		2  # Only check ground layer
	)
	var result = space_state.intersect_ray(query)

	# If no collision, we have line of sight
	return result.is_empty()

func _check_for_bullets() -> void:
	if is_dodging:
		return

	# Look for incoming bullets
	var bullets = get_tree().get_nodes_in_group("player_bullets")
	var nearest_threat = null
	var nearest_distance = 150.0  # Dodge range

	for bullet in bullets:
		if not is_instance_valid(bullet):
			continue

		var dist = global_position.distance_to(bullet.global_position)
		if dist < nearest_distance:
			# Check if bullet is heading towards us
			var bullet_dir = bullet.direction.normalized()
			var to_enemy = (global_position - bullet.global_position).normalized()
			var dot = bullet_dir.dot(to_enemy)

			if dot > 0.7:  # Bullet is roughly heading at us
				nearest_threat = bullet
				nearest_distance = dist

	if nearest_threat != null and randf() < dodge_chance:
		_start_dodge(nearest_threat)

func _start_dodge(bullet: Node2D) -> void:
	is_dodging = true
	dodge_timer = 0.4  # Dodge duration

	# Calculate dodge direction (perpendicular to bullet)
	var bullet_dir = bullet.direction.normalized()
	var dodge_dir = Vector2(-bullet_dir.y, bullet_dir.x)  # Perpendicular

	# Choose direction away from walls
	var wall_check = wall_check_right if dodge_dir.x > 0 else wall_check_left
	if wall_check.is_colliding():
		dodge_dir *= -1

	dodge_direction = dodge_dir

	# Jump if bullet is low
	if is_on_floor() and randf() < 0.5:
		velocity.y = jump_velocity

func _dodge_update(delta: float) -> void:
	dodge_timer -= delta
	velocity.x = dodge_direction.x * speed * 2.0

	if dodge_timer <= 0:
		is_dodging = false
		velocity.x = 0

func _execute_ai(_delta: float) -> void:
	if target_player == null:
		# No target - patrol back and forth
		_patrol_behavior()
		return

	var distance_to_player = global_position.distance_to(target_player.global_position)
	var direction_to_player = sign(target_player.global_position.x - global_position.x)

	# Face the player
	facing_direction = direction_to_player
	_update_visual_facing()

	# Decide what to do based on distance
	if distance_to_player <= attack_range:
		# In attack range
		if distance_to_player < preferred_range * 0.8:
			# Too close - back up
			_back_up(direction_to_player)
		elif distance_to_player > preferred_range * 1.2:
			# Too far - move closer
			_approach(direction_to_player)
		else:
			# Sweet spot - attack
			_attack_player()
	else:
		# Outside attack range - pursue
		_pursue(direction_to_player)

	# Try to get to player's height
	if abs(target_player.global_position.y - global_position.y) > 100:
		_find_platform_to_player()

func _patrol_behavior() -> void:
	velocity.x = facing_direction * speed * 0.3

	# Check for edges and walls
	var floor_check = floor_check_right if facing_direction > 0 else floor_check_left
	var wall_check = wall_check_right if facing_direction > 0 else wall_check_left

	if (not floor_check.is_colliding()) or wall_check.is_colliding():
		facing_direction *= -1
		_update_visual_facing()
		velocity.x = facing_direction * speed * 0.3

func _approach(direction: int) -> void:
	# Move towards player
	if _can_move_in_direction(direction):
		velocity.x = direction * speed
	else:
		# Try to jump over obstacle
		if is_on_floor():
			velocity.y = jump_velocity
			velocity.x = direction * speed

func _back_up(direction: int) -> void:
	# Move away from player
	var back_direction = -direction
	if _can_move_in_direction(back_direction):
		velocity.x = back_direction * speed
	else:
		# Can't back up, jump instead
		if is_on_floor():
			velocity.y = jump_velocity

func _pursue(direction: int) -> void:
	# Chase the player aggressively
	if _can_move_in_direction(direction):
		velocity.x = direction * speed * 1.2
	else:
		# Try to find another way
		if is_on_floor():
			# Check if we can jump to platform
			if _can_reach_platform(direction):
				velocity.y = jump_velocity * 1.2
				velocity.x = direction * speed

func _can_move_in_direction(direction: int) -> bool:
	var floor_check = floor_check_right if direction > 0 else floor_check_left
	var wall_check = wall_check_right if direction > 0 else wall_check_left

	# Can move if there's floor and no wall
	return floor_check.is_colliding() and not wall_check.is_colliding()

func _can_reach_platform(direction: int) -> bool:
	# Check if there's a platform we can jump to
	var check_pos = global_position + Vector2(direction * 60, -100)
	platform_check.target_position = check_pos - platform_check.global_position
	return platform_check.is_colliding()

func _find_platform_to_player() -> void:
	if not is_on_floor():
		return

	var player_higher = target_player.global_position.y < global_position.y

	if player_higher:
		# Player is above - look for platform above
		if _can_reach_platform(facing_direction):
			velocity.y = jump_velocity
			velocity.x = facing_direction * speed
	else:
		# Player is below - just drop down if possible
		var floor_check = floor_check_right if facing_direction > 0 else floor_check_left
		if not floor_check.is_colliding():
			# No floor ahead, maybe drop down?
			velocity.x = facing_direction * speed * 0.5

func _attack_player() -> void:
	if not can_attack or target_player == null:
		return

	# Stop moving to aim
	velocity.x = move_toward(velocity.x, 0, speed * 0.1)

	# Calculate aim with accuracy modifier
	var target_pos = target_player.global_position

	# Predict player movement for higher difficulties
	if difficulty >= Difficulty.MEDIUM and target_player is CharacterBody2D:
		var prediction = target_player.velocity * reaction_time
		target_pos += prediction * accuracy

	var aim_direction = (target_pos - global_position).normalized()

	# Add some randomness based on difficulty
	if difficulty < Difficulty.HARD:
		aim_direction = aim_direction.rotated(randf_range(-0.2, 0.2))

	# Attack
	if weapon_manager:
		weapon_manager.attack(aim_direction)
		can_attack = false
		attack_timer.start(fire_rate)

func _update_visual_facing() -> void:
	visual.flip_h = facing_direction < 0

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _on_health_changed(current: int, max_health: int) -> void:
	if health_bar:
		health_bar.update_health(current, max_health)

	# Flash red when damaged
	visual.modulate = Color(1, 0.5, 0.5, 1)
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		visual.modulate = Color(1, 1, 1, 1)

	# Become more aggressive when hurt
	if float(current) / float(max_health) < 0.4:
		is_aggressive = true
		speed *= 1.2  # Get faster when low health

func _on_health_depleted() -> void:
	is_dead = true
	AudioManager.play_named_sfx("enemy_death")

	# Death animation
	visual.modulate = Color(0.3, 0.3, 0.3, 0.5)

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Remove after delay
	await get_tree().create_timer(2.0).timeout
	queue_free()

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead or not health_component:
		return

	health_component.take_damage(amount, source)
	AudioManager.play_named_sfx("enemy_hit")
