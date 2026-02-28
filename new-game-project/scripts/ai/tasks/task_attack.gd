class_name TaskAttack
extends BTTask

func _init():
	name = "Attack"

func tick(agent: Node, blackboard: Dictionary) -> Status:
	if not agent.has_method("attack"):
		return Status.FAILURE

	var target = blackboard.get("target_player")
	if target == null:
		return Status.FAILURE

	var success = agent.attack(target)
	return Status.SUCCESS if success else Status.RUNNING
