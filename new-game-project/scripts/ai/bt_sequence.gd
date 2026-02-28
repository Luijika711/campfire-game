class_name BTSequence
extends BTComposite

func _init():
	name = "Sequence"

func tick(agent: Node, blackboard: Dictionary) -> Status:
	for child in children:
		var status = child.tick(agent, blackboard)

		if status == Status.FAILURE:
			return Status.FAILURE
		if status == Status.RUNNING:
			return Status.RUNNING

	return Status.SUCCESS
