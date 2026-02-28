class_name HealthComponent
extends Node

signal health_changed(current_health: int, max_health: int)
signal health_depleted()
signal damage_taken(amount: int, source: Node)
signal healed(amount: int)

@export var max_health: int = 100:
	set(value):
		max_health = value
		current_health = min(current_health, max_health)
		emit_signal("health_changed", current_health, max_health)

@export var current_health: int = 100:
	set(value):
		var old_health = current_health
		current_health = clamp(value, 0, max_health)
		if current_health != old_health:
			health_changed.emit(current_health, max_health)
		if current_health <= 0 and old_health > 0:
			health_depleted.emit()

var is_dead: bool = false

func _ready() -> void:
	current_health = max_health
	health_depleted.connect(_on_health_depleted)

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead or amount <= 0:
		return

	current_health -= amount
	damage_taken.emit(amount, source)

func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	var old_health = current_health
	current_health += amount
	healed.emit(current_health - old_health)

func reset_health() -> void:
	is_dead = false
	current_health = max_health

func get_health_percent() -> float:
	return float(current_health) / float(max_health) if max_health > 0 else 0.0

func _on_health_depleted() -> void:
	is_dead = true
