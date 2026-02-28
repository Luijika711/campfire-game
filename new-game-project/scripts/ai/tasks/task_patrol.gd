class_name TaskPatrol
extends BTTask

func _init():
	name = "Patrol"

func tick(agent: Node, _blackboard: Dictionary) -> Status:
	if not agent.has_method("patrol"):
		return Status.FAILURE

	var success = agent.patrol()
	return Status.SUCCESS if success else Status.FAILURE
