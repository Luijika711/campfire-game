class_name ConditionIsPlayerDead
extends BTTask

func _init():
	name = "IsPlayerDead"

func tick(_agent: Node, blackboard: Dictionary) -> Status:
	var target = blackboard.get("target_player")
	if target == null:
		return Status.SUCCESS  # No target = success (return to patrol)

	if target.is_dead:
		blackboard.erase("target_player")
		return Status.SUCCESS

	return Status.FAILURE
