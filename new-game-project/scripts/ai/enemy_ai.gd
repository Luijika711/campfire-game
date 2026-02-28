extends Node
class_name EnemyAI

@export var enemy: Enemy = null
@export var enable_ai: bool = true

var bt_player: BTPlayer = null

func _ready() -> void:
	if not enable_ai:
		return

	# Get BTPlayer node
	bt_player = get_parent().get_node_or_null("BTPlayer")
	if bt_player == null:
		push_error("BTPlayer node not found!")
		return

	# Build behavior tree
	var behavior_tree = _build_behavior_tree()
	bt_player.behavior_tree = behavior_tree

func _build_behavior_tree() -> BTNode:
	# Root selector - chooses between combat and patrol modes
	var root = BTSelector.new()

	# Combat mode sequence
	var combat_sequence = BTSequence.new()

	# Check if player is visible
	var can_see_player = ConditionCanSeePlayer.new()
	can_see_player.detection_range = enemy.detection_range if enemy else 400.0
	combat_sequence.add_child(can_see_player)

	# Check if player is in attack range
	var in_attack_range = ConditionIsPlayerInAttackRange.new()
	in_attack_range.attack_range = enemy.attack_range if enemy else 200.0

	# Attack or chase selector
	var attack_or_chase = BTSelector.new()

	# Attack sequence
	var attack_sequence = BTSequence.new()
	attack_sequence.add_child(in_attack_range)
	attack_sequence.add_child(TaskAttack.new())

	# Chase task (if not in attack range)
	var chase_task = TaskChasePlayer.new()

	attack_or_chase.add_child(attack_sequence)
	attack_or_chase.add_child(chase_task)

	combat_sequence.add_child(attack_or_chase)

	# Patrol mode (default when no player seen)
	var patrol_task = TaskPatrol.new()

	root.add_child(combat_sequence)
	root.add_child(patrol_task)

	return root
