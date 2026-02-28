class_name TaskChasePlayer
extends BTTask

func _init():
	name = "ChasePlayer"

func tick(agent: Node, blackboard: Dictionary) -> Status:
	if not agent.has_method("chase_player"):
		return Status.FAILURE

	var target = blackboard.get("target_player")
	if target == null:
		return Status.FAILURE

	var success = agent.chase_player(target)
	return Status.SUCCESS if success else Status.FAILURE
