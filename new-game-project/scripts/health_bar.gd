extends ProgressBar

class_name HealthBar

@onready var label: Label = $Label

var target_value: float = 100.0

func _ready():
	show_percentage = false

func update_health(current: int, max_health: int) -> void:
	max_value = max_health
	target_value = float(current)
	value = target_value

	if label:
		label.text = "%d/%d" % [current, max_health]

	# Color based on health percentage
	var health_percent = float(current) / float(max_health)
	if health_percent > 0.6:
		modulate = Color(0.2, 0.8, 0.2, 1)  # Green
	elif health_percent > 0.3:
		modulate = Color(1, 0.8, 0.2, 1)    # Yellow
	else:
		modulate = Color(1, 0.2, 0.2, 1)    # Red

func _process(delta: float) -> void:
	# Smooth animation
	value = lerp(value, target_value, 10.0 * delta)
