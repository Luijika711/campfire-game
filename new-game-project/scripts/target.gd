class_name Target
extends StaticBody2D

@export var max_health: int = 50
@export var regen_rate: float = 0.0  # Health per second

@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	health_component.max_health = max_health
	health_component.health_depleted.connect(_on_death)
	health_component.damage_taken.connect(_on_damage_taken)

func _process(delta: float) -> void:
	if regen_rate > 0:
		health_component.heal(int(regen_rate * delta))

	# Visual feedback based on health
	var health_percent = health_component.get_health_percent()
	sprite.modulate = Color(1, health_percent, health_percent, 1)

func _on_damage_taken(_amount: int, _source: Node) -> void:
	# Visual hit effect
	var tween = create_tween()
	sprite.scale = Vector2(1.2, 1.2)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)

func _on_death() -> void:
	# Respawn after delay
	await get_tree().create_timer(2.0).timeout
	health_component.reset_health()
	visible = true
	collision_layer = 1
