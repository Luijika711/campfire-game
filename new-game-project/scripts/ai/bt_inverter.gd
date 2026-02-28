class_name BTInverter
extends BTNode

var child: BTNode = null

func _init():
	name = "Inverter"

func set_child(p_child: BTNode) -> void:
	child = p_child
	child.setup(blackboard)

func tick(agent: Node, blackboard: Dictionary) -> Status:
	if child == null:
		return Status.FAILURE

	var status = child.tick(agent, blackboard)

	match status:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
		_:
			return status
