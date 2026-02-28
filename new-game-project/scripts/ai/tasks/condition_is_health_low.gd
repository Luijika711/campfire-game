class_name ConditionIsHealthLow
extends BTTask

@export var health_threshold: float = 0.3  # 30% health

func _init():
	name = "IsHealthLow"

func tick(agent: Node, _blackboard: Dictionary) -> Status:
	if not agent.has_node("HealthComponent"):
		return Status.FAILURE

	var health = agent.get_node("HealthComponent")
	var health_percent = float(health.current_health) / float(health.max_health)

	if health_percent <= health_threshold:
		return Status.SUCCESS

	return Status.FAILURE
