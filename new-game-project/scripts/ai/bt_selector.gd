class_name BTSelector
extends BTComposite

func _init():
	name = "Selector"

func tick(agent: Node, blackboard: Dictionary) -> Status:
	for child in children:
		var status = child.tick(agent, blackboard)

		if status == Status.SUCCESS:
			return Status.SUCCESS
		if status == Status.RUNNING:
			return Status.RUNNING

	return Status.FAILURE
