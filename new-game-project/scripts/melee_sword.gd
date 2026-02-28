class_name MeleeSword
extends Weapon

@export var swing_range: float = 60.0
@export var swing_angle: float = 120.0
@export var swing_duration: float = 0.15
@export var knockback_force: float = 300.0

@onready var hitbox: Area2D
@onready var sword_visual: Polygon2D

var is_swinging: bool = false

func _ready() -> void:
	super._ready()
	weapon_name = "Melee Sword"
	weapon_type = WeaponType.MELEE_SWORD
	damage = 30
	cooldown = 0.4

	# Create hitbox
	hitbox = Area2D.new()
	hitbox.name = "SwordHitbox"
	hitbox.collision_layer = 0
	hitbox.collision_mask = 6 | 1  # Hit enemies, platforms, and players
	hitbox.monitoring = false
	add_child(hitbox)

	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = swing_range
	collision_shape.shape = circle_shape
	hitbox.add_child(collision_shape)

	# Create sword visual
	sword_visual = Polygon2D.new()
	sword_visual.name = "SwordVisual"
	sword_visual.color = Color(0.8, 0.8, 0.9, 1)
	setup_sword_shape()
	sword_visible = false
	add_child(sword_visual)

	hitbox.body_entered.connect(_on_hitbox_body_entered)

var sword_visible: bool = false:
	set(value):
		sword_visible = value
		if sword_visual:
			sword_visual.visible = value

func setup_sword_shape() -> void:
	# Create a wedge shape for the sword
	var points = PackedVector2Array()
	var segments = 10
	var half_angle = deg_to_rad(swing_angle / 2)

	# Start from center
	points.append(Vector2.ZERO)

	# Arc for the sword blade
	for i in range(segments + 1):
		var angle = -half_angle + (half_angle * 2 * i / segments)
		var point = Vector2(cos(angle), sin(angle)) * swing_range
		points.append(point)

	# Close the shape
	points.append(Vector2.ZERO)
	sword_visual.polygon = points

func perform_attack(direction: Vector2) -> void:
	if is_swinging:
		return

	is_swinging = true
	sword_visible = true

	# Rotate sword to face direction
	rotation = direction.angle()

	# Animate swing
	var tween = create_tween()
	var half_angle = deg_to_rad(swing_angle / 2)
	sword_visual.rotation = -half_angle
	tween.tween_property(sword_visual, "rotation", half_angle, swing_duration)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Enable hitbox during swing
	hitbox.monitoring = true

	# End swing after duration
	tween.finished.connect(func():
		sword_visible = false
		hitbox.monitoring = false
		is_swinging = false
	)

	weapon_fired.emit()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == player:
		return

	# FFA: damage any player that isn't the wielder
	if body.is_in_group("players"):
		pass  # Allow damage below

	# Apply damage
	if body.has_node("HealthComponent"):
		var health = body.get_node("HealthComponent")
		health.take_damage(damage, player)

	# Apply knockback
	if body is CharacterBody2D:
		var knockback_dir = (body.global_position - global_position).normalized()
		body.velocity += knockback_dir * knockback_force
