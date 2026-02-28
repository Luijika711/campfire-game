class_name BTNode
extends RefCounted

enum Status {
	SUCCESS,
	FAILURE,
	RUNNING
}

var blackboard: Dictionary = {}
var name: String = "BTNode"

func tick(_agent: Node, _blackboard: Dictionary) -> Status:
	return Status.SUCCESS

func setup(p_blackboard: Dictionary) -> void:
	blackboard = p_blackboard
