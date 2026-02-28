class_name LaserGun
extends Weapon

@export var laser_range: float = 10000.0  # Practically infinite
@export var laser_width: float = 6.0
@export var beam_duration: float = 0.2
@export var max_ammo: int = 100
@export var ammo_per_shot: int = 1

var current_ammo: int
var is_firing: bool = false

@onready var laser_beam: Line2D
@onready var glow_beam: Line2D
@onready var hit_effect: Polygon2D

func _ready() -> void:
	super._ready()
	weapon_name = "Laser Gun"
	weapon_type = WeaponType.LASER_GUN
	current_ammo = max_ammo

	# Create laser beam
	laser_beam = Line2D.new()
	laser_beam.name = "LaserBeam"
	laser_beam.width = laser_width
	laser_beam.default_color = Color(0, 1, 1, 0.9)
	laser_beam.gradient = create_laser_gradient()
	laser_beam.visible = false
	# Enable glow effect
	laser_beam.modulate = Color(1, 1, 1, 1)
	add_child(laser_beam)

	# Create glow effect for laser
	_create_glow_beam()

	# Create hit effect
	hit_effect = Polygon2D.new()
	hit_effect.name = "HitEffect"
	setup_hit_effect()
	hit_effect.visible = false
	add_child(hit_effect)

func create_laser_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 1),     # White core
		Color(0, 1, 1, 0.9),   # Cyan
		Color(0, 0.8, 1, 0.6), # Blue
		Color(0, 0.5, 1, 0.3)  # Fade
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.5, 1.0])
	return gradient

func setup_hit_effect() -> void:
	var points = PackedVector2Array()
	var segments = 12
	for i in range(segments):
		var angle = i * TAU / segments
		var radius = 20.0
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	hit_effect.polygon = points
	hit_effect.color = Color(0, 1, 1, 0.9)

func perform_attack(direction: Vector2) -> void:
	if is_firing or current_ammo < ammo_per_shot:
		return

	_fire_laser(direction)

func _fire_laser(direction: Vector2) -> void:
	is_firing = true
	current_ammo -= ammo_per_shot

	var start_pos = global_position
	var end_pos = start_pos + direction * laser_range

	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	query.collision_mask = 4 | 1 | 2  # Hit enemies, players, and walls
	if player:
		query.exclude = [player.get_rid()]
	query.hit_from_inside = false

	# Draw laser beam
	laser_beam.points = PackedVector2Array([to_local(start_pos), to_local(end_pos)])
	laser_beam.visible = true
	if glow_beam:
		glow_beam.points = laser_beam.points
		glow_beam.visible = true

	# Deal damage to targets along the beam, stop at walls
	var max_penetrations = 3
	var hits = 0

	while hits < max_penetrations:
		query.from = start_pos
		query.to = end_pos
		var result = space_state.intersect_ray(query)

		if not result:
			break

		var collider = result.collider
		var hit_pos = result.position

		query.exclude.append(collider.get_rid())

		# Stop at walls
		if collider.is_in_group("walls") or collider is TileMapLayer or collider is StaticBody2D:
			# Shorten laser visual to wall hit point
			laser_beam.points = PackedVector2Array([to_local(start_pos), to_local(hit_pos)])
			if glow_beam:
				glow_beam.points = laser_beam.points
			_show_hit_at(hit_pos)
			break

		if collider.is_in_group("enemies"):
			if collider.has_method("take_damage"):
				collider.take_damage(damage, player)
			_show_hit_at(hit_pos)
			hits += 1
		elif collider.is_in_group("players"):
			if TeamManager and TeamManager.are_enemies(player, collider):
				if collider.has_method("take_damage"):
					collider.take_damage(damage, player)
				_show_hit_at(hit_pos)
			hits += 1
		else:
			# Unknown collider, stop beam
			laser_beam.points = PackedVector2Array([to_local(start_pos), to_local(hit_pos)])
			if glow_beam:
				glow_beam.points = laser_beam.points
			break

	# Recoil
	if player:
		player.velocity -= direction * 50

	# Hide laser after beam duration
	await get_tree().create_timer(beam_duration).timeout
	laser_beam.visible = false
	if glow_beam:
		glow_beam.visible = false
	is_firing = false

func _show_hit_at(pos: Vector2) -> void:
	var effect = Polygon2D.new()
	effect.polygon = hit_effect.polygon
	effect.color = Color(0, 1, 1, 0.8)
	effect.global_position = pos
	get_tree().current_scene.add_child(effect)

	var tween = create_tween()
	tween.tween_property(effect, "scale", Vector2(2.0, 2.0), 0.1)
	tween.parallel().tween_property(effect, "modulate:a", 0.0, 0.1)
	tween.finished.connect(func(): effect.queue_free())

func _create_glow_beam() -> void:
	# Create a wider glow beam behind the main laser
	glow_beam = Line2D.new()
	glow_beam.name = "GlowBeam"
	glow_beam.width = laser_width * 2.5
	glow_beam.default_color = Color(0, 0.8, 1, 0.3)
	glow_beam.gradient = create_glow_gradient()
	glow_beam.visible = false
	glow_beam.z_index = -1  # Render behind main beam
	add_child(glow_beam)

func create_glow_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(0, 1, 1, 0.5),   # Cyan center
		Color(0, 0.5, 1, 0.2), # Blue outer
		Color(0, 0.2, 1, 0)    # Fade
	])
	gradient.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	return gradient

func reload() -> void:
	current_ammo = max_ammo

func get_ammo_text() -> String:
	return "%d/%d" % [current_ammo, max_ammo]
