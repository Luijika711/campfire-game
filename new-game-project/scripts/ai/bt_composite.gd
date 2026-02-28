class_name BTComposite
extends BTNode

var children: Array[BTNode] = []

func add_child(child: BTNode) -> void:
	children.append(child)
	child.setup(blackboard)

func clear_children() -> void:
	children.clear()
