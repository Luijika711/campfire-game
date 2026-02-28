extends Node

enum Team {
	NONE,
	TEAM_RED,
	TEAM_BLUE
}

signal team_changed(node: Node, team: int)

# Maps node instance IDs to teams
var _teams: Dictionary = {}

const TEAM_COLORS = {
	Team.NONE: Color(1, 1, 1, 1),
	Team.TEAM_RED: Color(1, 0.3, 0.3, 1),
	Team.TEAM_BLUE: Color(0.3, 0.3, 1, 1),
}

const TEAM_NAMES = {
	Team.NONE: "None",
	Team.TEAM_RED: "Red Team",
	Team.TEAM_BLUE: "Blue Team",
}

func set_team(node: Node, team: int) -> void:
	var old_team = get_team(node)
	_teams[node.get_instance_id()] = team

	# Update groups
	for t in [Team.TEAM_RED, Team.TEAM_BLUE]:
		var group_name = _team_group(t)
		if node.is_in_group(group_name):
			node.remove_from_group(group_name)
	if team != Team.NONE:
		node.add_to_group(_team_group(team))

	if old_team != team:
		team_changed.emit(node, team)

func get_team(node: Node) -> int:
	if node == null:
		return Team.NONE
	var id = node.get_instance_id()
	if _teams.has(id):
		return _teams[id]
	return Team.NONE

func are_enemies(a: Node, b: Node) -> bool:
	var team_a = get_team(a)
	var team_b = get_team(b)
	# NONE team players are hostile to everyone
	if team_a == Team.NONE or team_b == Team.NONE:
		return true
	return team_a != team_b

func are_allies(a: Node, b: Node) -> bool:
	var team_a = get_team(a)
	var team_b = get_team(b)
	if team_a == Team.NONE or team_b == Team.NONE:
		return false
	return team_a == team_b

func get_team_color(team: int) -> Color:
	return TEAM_COLORS.get(team, Color(1, 1, 1, 1))

func get_team_name(team: int) -> String:
	return TEAM_NAMES.get(team, "None")

func remove_player(node: Node) -> void:
	var id = node.get_instance_id()
	_teams.erase(id)

func _team_group(team: int) -> String:
	match team:
		Team.TEAM_RED: return "team_red"
		Team.TEAM_BLUE: return "team_blue"
		_: return "team_none"
