class_name TaskRetreat
extends BTTask

func _init():
	name = "Retreat"

func tick(agent: Node, _blackboard: Dictionary) -> Status:
	if not agent.has_method("retreat"):
		return Status.FAILURE

	var success = agent.retreat()
	return Status.SUCCESS if success else Status.FAILURE
