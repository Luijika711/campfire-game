class_name BTPlayer
extends Node

var behavior_tree: BTNode = null
@export var update_interval: float = 0.1

var agent: Node = null
var blackboard: Dictionary = {}
var update_timer: float = 0.0

func _ready():
	agent = get_parent()

func _physics_process(delta: float) -> void:
	if behavior_tree == null or agent == null:
		return

	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		behavior_tree.tick(agent, blackboard)

func set_blackboard_var(key: String, value) -> void:
	blackboard[key] = value

func get_blackboard_var(key: String, default_value = null):
	return blackboard.get(key, default_value)
