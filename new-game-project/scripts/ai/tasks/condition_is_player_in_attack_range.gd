class_name ConditionIsPlayerInAttackRange
extends BTTask

@export var attack_range: float = 200.0

func _init():
	name = "IsPlayerInAttackRange"

func tick(agent: Node, blackboard: Dictionary) -> Status:
	var target = blackboard.get("target_player")
	if target == null:
		return Status.FAILURE

	var distance = agent.global_position.distance_to(target.global_position)
	if distance <= attack_range:
		return Status.SUCCESS

	return Status.FAILURE
