extends Node2D

@export var player_scene: PackedScene
@export var spawn_points: Array[Vector2] = [
	Vector2(100, 400),
	Vector2(1052, 400),
	Vector2(300, 300),
	Vector2(852, 300),
	Vector2(200, 500),
	Vector2(952, 500),
	Vector2(400, 400),
	Vector2(752, 400),
]

var players: Dictionary = {}
var available_colors: Array[String] = [
	"Red", "Blue", "Green", "Yellow",
	"Purple", "Orange", "Cyan", "Pink"
]
var used_colors: Array[String] = []

func _ready():
	if NetworkManager:
		NetworkManager.player_connected.connect(_on_player_connected)
		NetworkManager.player_disconnected.connect(_on_player_disconnected)
		NetworkManager.player_input.connect(_on_player_input)

func _on_player_connected(player_id: int, player_name: String, color: String, team: int = 0):
	# Assign a random available color if the chosen one is taken
	var assigned_color = color
	if used_colors.has(color):
		var available = available_colors.filter(func(c): return not used_colors.has(c))
		if available.size() > 0:
			assigned_color = available[0]

	used_colors.append(assigned_color)

	# Spawn player
	var spawn_index = players.size()
	var spawn_pos = spawn_points[spawn_index % spawn_points.size()]

	var player = player_scene.instantiate()
	player.name = "Player_%d" % player_id
	player.position = spawn_pos
	player.setup_player(player_id, player_name, assigned_color, team)

	add_child(player)
	players[player_id] = player

	print("Spawned player %d: %s at %s" % [player_id, player_name, str(spawn_pos)])

func _on_player_disconnected(player_id: int):
	if players.has(player_id):
		var player = players[player_id]
		used_colors.erase(player.player_color)
		player.queue_free()
		players.erase(player_id)
		print("Removed player %d" % player_id)

func _on_player_input(
	player_id: int, move_x: float, move_y: float, aim_x: float,
	aim_y: float, fire: bool, jump: bool, weapon: int
):
	if players.has(player_id):
		players[player_id].handle_input(move_x, move_y, aim_x, aim_y, fire, jump, weapon)

func get_player_count() -> int:
	return players.size()

func get_all_players() -> Array:
	return players.values()
