extends CharacterBody2D

@export var speed: float = 560.0
@export var jump_velocity: float = -800.0
@export var fast_fall_speed: float = 600.0
@export var gravity: float = 3200.0
@export var max_fall_speed: float = 1200.0
@export var rotation_lerp_speed: float = 25.0

@export var dash_speed: float = 700.0
@export var dash_duration: float = 0.12
@export var double_tap_window: float = 0.35

@export var max_health: int = 100
@export var character_scale: float = 1.0

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var weapon_manager: WeaponManager = $WeaponManager
@onready var health_bar: ProgressBar = $HealthBar

# Particle effects
@onready var walk_dust: GPUParticles2D = $Particles/WalkDust
@onready var jump_dust: GPUParticles2D = $Particles/JumpDust
@onready var land_dust: GPUParticles2D = $Particles/LandDust
@onready var dash_trail: GPUParticles2D = $Particles/DashTrail

var jumps_remaining: int = 2
var is_dashing: bool = false
var dash_timer: float = 0.0
var can_dash: bool = true
var was_on_floor: bool = false

var last_left_time: int = 0
var last_right_time: int = 0
var last_direction: int = 0

var target_rotation: float = 0.0
var current_slope_angle: float = 0.0

var last_aim_direction: Vector2 = Vector2.RIGHT
var is_dead: bool = false
var is_attacking: bool = false
var facing_direction: String = "right"
var base_color: Color = Color(1, 1, 1, 1)

# Device-specific input
var input_device: String = "keyboard"
var device_id: int = -1
var _action_states: Dictionary = {}
var _action_just_pressed: Dictionary = {}
var _action_just_released: Dictionary = {}
var _joy_move_axis: float = 0.0
var _joy_aim: Vector2 = Vector2.ZERO

# Aim indicator
var aim_indicator: Polygon2D = null

signal player_died
signal health_changed(current: int, max: int)
signal weapon_changed(weapon: Weapon)

func _ready() -> void:
	floor_snap_length = 8.0
	add_to_group("players")

	# Apply character scale
	if character_scale != 1.0:
		scale = Vector2(character_scale, character_scale)

	# Initialize health
	if health_component:
		health_component.max_health = max_health
		health_component.health_changed.connect(_on_health_changed)
		health_component.health_depleted.connect(_on_health_depleted)

	# Initialize weapon manager
	if weapon_manager:
		weapon_manager.weapon_changed.connect(_on_weapon_changed)

	# Connect animation finished signal
	visual.animation_finished.connect(_on_animation_finished)

	# Initialize device-specific input
	input_device = get_meta("input_device", "keyboard")
	device_id = get_meta("device_id", -1)

	# Store base color from visual (may be set externally before _ready)
	base_color = visual.modulate

	# Create aim indicator
	_create_aim_indicator()

	is_dead = false

# --- Device-specific input handling ---

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if input_device == "keyboard":
		_handle_keyboard_input(event)
	elif input_device == "gamepad":
		_handle_gamepad_input(event)

func _handle_keyboard_input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	for action in ["move_left", "move_right", "jump", "shoot", "move_down"]:
		if event.is_action(action):
			var pressed = event.is_pressed()
			var was = _action_states.get(action, false)
			if pressed and not was:
				_action_just_pressed[action] = true
			elif not pressed and was:
				_action_just_released[action] = true
			_action_states[action] = pressed

func _handle_gamepad_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.device == device_id:
		var action = _joy_button_to_action(event.button_index)
		if action != "":
			var was = _action_states.get(action, false)
			if event.pressed and not was:
				_action_just_pressed[action] = true
			elif not event.pressed and was:
				_action_just_released[action] = true
			_action_states[action] = event.pressed
	elif event is InputEventJoypadMotion and event.device == device_id:
		_handle_joy_axis(event)

func _joy_button_to_action(button: int) -> String:
	match button:
		JOY_BUTTON_A: return "jump"
		JOY_BUTTON_RIGHT_SHOULDER: return "shoot"
		JOY_BUTTON_B: return "shoot"
		JOY_BUTTON_X: return "weapon_next"
		JOY_BUTTON_Y: return "weapon_prev"
		JOY_BUTTON_DPAD_DOWN: return "move_down"
	return ""

func _handle_joy_axis(event: InputEventJoypadMotion) -> void:
	match event.axis:
		JOY_AXIS_LEFT_X:
			var old = _joy_move_axis
			var val = event.axis_value if abs(event.axis_value) > 0.2 else 0.0
			_joy_move_axis = val
			# Track just_pressed for dash detection
			if val < -0.5 and old >= -0.5:
				_action_just_pressed["move_left"] = true
			if val > 0.5 and old <= 0.5:
				_action_just_pressed["move_right"] = true
		JOY_AXIS_LEFT_Y:
			_action_states["move_down"] = event.axis_value > 0.5
		JOY_AXIS_RIGHT_X:
			_joy_aim.x = event.axis_value if abs(event.axis_value) > 0.15 else 0.0
		JOY_AXIS_RIGHT_Y:
			_joy_aim.y = event.axis_value if abs(event.axis_value) > 0.15 else 0.0
		JOY_AXIS_TRIGGER_RIGHT:
			var pressed = event.axis_value > 0.5
			var was = _action_states.get("shoot", false)
			if pressed and not was:
				_action_just_pressed["shoot"] = true
			elif not pressed and was:
				_action_just_released["shoot"] = true
			_action_states["shoot"] = pressed

func _pressed(action: String) -> bool:
	return _action_states.get(action, false)

func _just_pressed(action: String) -> bool:
	return _action_just_pressed.get(action, false)

func _just_released(action: String) -> bool:
	return _action_just_released.get(action, false)

func _get_move_x() -> float:
	if input_device == "gamepad":
		return _joy_move_axis
	var left = 1.0 if _action_states.get("move_left", false) else 0.0
	var right = 1.0 if _action_states.get("move_right", false) else 0.0
	return right - left

func _get_aim_direction() -> Vector2:
	if input_device == "gamepad":
		if _joy_aim.length() > 0.1:
			return _joy_aim.normalized()
		if abs(_joy_move_axis) > 0.2:
			return Vector2(_joy_move_axis, 0).normalized()
		return last_aim_direction
	else:
		var mouse_pos = get_global_mouse_position()
		return (mouse_pos - global_position).normalized()

func _clear_just_states() -> void:
	_action_just_pressed.clear()
	_action_just_released.clear()

# --- Main loop ---

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Handle shooting with weapon manager
	_handle_weapon_attack()

	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			can_dash = true
		move_and_slide()
		_update_animation()
		_update_aim_indicator()
		_clear_just_states()
		return

	# Get movement input
	var direction := _get_move_x()

	# Check for jump input first (before slope handling)
	if _just_pressed("jump") and jumps_remaining > 0:
		velocity.y = jump_velocity
		jumps_remaining -= 1
		# Re-enable floor snap after jumping
		floor_snap_length = 8.0
		target_rotation = 0.0  # Reset rotation when jumping
		# Emit jump particles
		if jump_dust:
			jump_dust.restart()
			jump_dust.emitting = true

	# SLOPE SLIDING: Check when on floor with no input
	var on_slope := false
	var is_sliding := false

	if is_on_floor() and direction == 0 and velocity.y >= 0:  # Not jumping
		var collision: KinematicCollision2D = get_last_slide_collision()
		if collision != null:
			var floor_normal: Vector2 = collision.get_normal()
			var slope_angle: float = abs(floor_normal.angle_to(Vector2.UP))

			if slope_angle > 0.1:  # Slope detected
				on_slope = true
				is_sliding = true
				current_slope_angle = slope_angle

				# Calculate slide speed based on steepness
				var slide_speed: float = gravity * delta * slope_angle * 5.0

				# Set velocity to slide down the slope
				velocity.x = -floor_normal.x * slide_speed
				velocity.y = slide_speed

				# Disable floor snapping to allow sliding off
				floor_snap_length = 0.0

				# Apply gravity on top for extra pull
				velocity.y += gravity * delta

				# Calculate target rotation to match slope
				# The slope angle tells us how much to rotate
				# If slope tilts right (normal.x < 0), we rotate clockwise (positive)
				# If slope tilts left (normal.x > 0), we rotate counter-clockwise (negative)
				target_rotation = sign(floor_normal.x) * slope_angle
			else:
				# Flat ground
				_apply_gravity(delta)
				velocity.x = 0
				floor_snap_length = 8.0
				target_rotation = 0.0
		else:
			_apply_gravity(delta)
			velocity.x = 0
			floor_snap_length = 8.0
			target_rotation = 0.0
	else:
		# In air or moving
		_apply_gravity(delta)
		floor_snap_length = 8.0
		target_rotation = 0.0

	# Normal movement (only if not sliding)
	if not is_sliding:
		if direction != 0:
			velocity.x = direction * speed
		elif not on_slope:  # Don't zero x velocity on slopes
			velocity.x = 0

	# Variable jump height
	if _just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5

	# Move
	move_and_slide()

	# Smoothly rotate visual to match slope
	visual.rotation = lerp(visual.rotation, target_rotation, rotation_lerp_speed * delta)

	# Reset jumps when on floor (including slopes!)
	if is_on_floor():
		jumps_remaining = 2
		can_dash = true
		# Emit land dust when just landing
		if not was_on_floor and land_dust:
			land_dust.restart()
			land_dust.emitting = true
		# Emit walk dust when moving on ground
		if abs(velocity.x) > 10 and walk_dust:
			walk_dust.emitting = true
		elif walk_dust:
			walk_dust.emitting = false
	was_on_floor = is_on_floor()

	_check_double_tap_dash()
	_update_animation()
	_update_aim_indicator()

	# Handle gamepad weapon switching
	if input_device == "gamepad" and weapon_manager:
		if _just_pressed("weapon_next"):
			weapon_manager._switch_weapon(1)
		elif _just_pressed("weapon_prev"):
			weapon_manager._switch_weapon(-1)

	_clear_just_states()

func _apply_gravity(delta: float) -> void:
	if _pressed("move_down"):
		velocity.y = move_toward(velocity.y, fast_fall_speed, gravity * 2 * delta)
	else:
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_fall_speed)

func _check_double_tap_dash() -> void:
	if not can_dash:
		return

	var current_time := Time.get_ticks_msec()
	var window_ms := int(double_tap_window * 1000)

	if _just_pressed("move_left"):
		if last_direction == -1 and (current_time - last_left_time) < window_ms:
			_trigger_dash(-1)
			last_direction = 0
		else:
			last_left_time = current_time
			last_direction = -1

	if _just_pressed("move_right"):
		if last_direction == 1 and (current_time - last_right_time) < window_ms:
			_trigger_dash(1)
			last_direction = 0
		else:
			last_right_time = current_time
			last_direction = 1

func _trigger_dash(direction: int) -> void:
	is_dashing = true
	can_dash = false
	dash_timer = dash_duration
	velocity.x = direction * dash_speed
	velocity.y = 0
	visual.modulate = Color(1, 1, 0, 1)
	# Emit dash trail
	if dash_trail:
		dash_trail.restart()
		dash_trail.emitting = true
	await get_tree().create_timer(dash_duration).timeout
	visual.modulate = base_color
	if dash_trail:
		dash_trail.emitting = false

func _update_animation() -> void:
	if is_dead:
		return

	if is_attacking:
		return

	# Determine facing direction based on movement when moving, aim when stopped
	if abs(velocity.x) > 10:
		# Moving: face movement direction
		if velocity.x > 0:
			facing_direction = "right"
		else:
			facing_direction = "left"
	else:
		# Stopped: face aim direction
		var aim = _get_aim_direction()
		if abs(aim.x) > abs(aim.y):
			if aim.x > 0:
				facing_direction = "right"
			else:
				facing_direction = "left"
		else:
			if aim.y > 0:
				facing_direction = "down"
			else:
				facing_direction = "up"

	# Determine animation state
	var animation_name: String

	if is_dashing:
		animation_name = "dash_" + facing_direction
	elif not is_on_floor():
		animation_name = "jump_" + facing_direction
	elif abs(velocity.x) > 10:
		# Running or walking based on speed
		if abs(velocity.x) > speed * 0.8:
			animation_name = "run_" + facing_direction
		else:
			animation_name = "walk_" + facing_direction
	else:
		animation_name = "idle_" + facing_direction

	# Play animation if different
	if visual.animation != animation_name:
		visual.play(animation_name)

func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead or not health_component:
		return

	health_component.take_damage(amount, source)

	# Visual feedback
	visual.modulate = Color(1, 0, 0, 1)
	await get_tree().create_timer(0.1).timeout
	if not is_dead:
		visual.modulate = base_color

func die() -> void:
	if is_dead:
		return

	is_dead = true
	player_died.emit()

	# Play death animation
	visual.play("death")

	# Disable collision
	collision_layer = 0
	collision_mask = 0

	# Wait for death animation then reload scene
	await visual.animation_finished
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()

func collect_coin() -> void:
	GameManager.add_coin()

func _on_hazard_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("hazards"):
		take_damage(100)  # Instant death from hazards

func _on_health_changed(current: int, max: int) -> void:
	health_changed.emit(current, max)
	if health_bar:
		health_bar.update_health(current, max)

func _on_health_depleted() -> void:
	die()

func _on_weapon_changed(weapon: Weapon) -> void:
	weapon_changed.emit(weapon)

func get_current_weapon() -> Weapon:
	if weapon_manager:
		return weapon_manager.get_current_weapon()
	return null

func heal(amount: int) -> void:
	if health_component:
		health_component.heal(amount)

func set_team(new_team: int) -> void:
	team = new_team
	if TeamManager:
		TeamManager.set_team(self, team)

func _handle_weapon_attack() -> void:
	# Get aim direction (device-aware)
	var aim_direction = _get_aim_direction()

	# Update last aim direction if aiming
	if aim_direction.length() > 0.1:
		last_aim_direction = aim_direction

	# Check for shoot/attack input
	if _pressed("shoot") and weapon_manager:
		# Play attack animation for melee weapons
		var current_weapon = weapon_manager.get_current_weapon()
		if current_weapon and current_weapon.is_melee and not is_attacking:
			is_attacking = true
			visual.play("attack_" + facing_direction)

		weapon_manager.attack(last_aim_direction)

# --- Aim indicator ---

func _create_aim_indicator() -> void:
	aim_indicator = Polygon2D.new()
	aim_indicator.name = "AimIndicator"
	aim_indicator.polygon = PackedVector2Array([
		Vector2(8, 0),
		Vector2(-4, -5),
		Vector2(-4, 5)
	])
	aim_indicator.color = Color(1, 1, 1, 0.6)
	aim_indicator.z_index = 1
	add_child(aim_indicator)

func _update_aim_indicator() -> void:
	if not aim_indicator or is_dead:
		if aim_indicator:
			aim_indicator.visible = false
		return
	var aim = _get_aim_direction()
	var indicator_distance = 40.0
	aim_indicator.position = aim * indicator_distance
	aim_indicator.rotation = aim.angle()
	aim_indicator.visible = true
