extends Area2D

@export var speed: float = 800.0
@export var lifetime: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var damage: int = 1
var shooter: Node = null
var shooter_team: int = 0  # TeamManager.Team.NONE

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	# Connect collision signals first
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func setup(
	dir: Vector2, start_pos: Vector2,
	bullet_damage: int = 1, bullet_shooter: Node = null
) -> void:
	direction = dir.normalized()
	position = start_pos
	damage = bullet_damage
	shooter = bullet_shooter
	if shooter and TeamManager:
		shooter_team = TeamManager.get_team(shooter)

	# Rotate sprite to face direction
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	# Don't hit the shooter
	if body == shooter:
		return

	# Team-aware player damage
	if body.is_in_group("players"):
		if TeamManager and shooter:
			if TeamManager.are_enemies(shooter, body):
				if body.has_method("take_damage"):
					body.take_damage(damage, self)
				_destroy_with_effect()
			# Allies: bullet passes through (no destroy)
		return

	# Deal damage to enemies
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage, self)
		_destroy_with_effect()
		return

	# Hit walls/platforms/ground - destroy bullet
	_destroy_with_effect()

func _on_area_entered(_area: Area2D) -> void:
	# Handle area collisions if needed
	pass

func _destroy_with_effect() -> void:
	# Could add particle effect here
	queue_free()
