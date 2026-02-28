class_name ConditionCanSeePlayer
extends BTTask

@export var detection_range: float = 400.0
@export var field_of_view: float = 120.0  # degrees

func _init():
	name = "CanSeePlayer"

func tick(agent: Node, blackboard: Dictionary) -> Status:
	var players = agent.get_tree().get_nodes_in_group("players")
	var nearest_player = null
	var nearest_distance = detection_range

	for player in players:
		var distance = agent.global_position.distance_to(player.global_position)
		if distance < nearest_distance:
			# Check field of view
			var direction_to_player = (player.global_position - agent.global_position).normalized()
			var facing_direction = Vector2.RIGHT if not agent.visual.flip_h else Vector2.LEFT
			var angle = rad_to_deg(facing_direction.angle_to(direction_to_player))

			if abs(angle) <= field_of_view / 2:
				nearest_player = player
				nearest_distance = distance

	if nearest_player != null:
		blackboard["target_player"] = nearest_player
		blackboard["target_distance"] = nearest_distance
		return Status.SUCCESS

	return Status.FAILURE
