extends Node

# Player data structure
class PlayerData:
	var player_id: int
	var input_device: String  # "keyboard", "gamepad", "phone"
	var device_id: int  # For gamepads: 0, 1, 2, etc. For keyboard: -1
	var player_color: Color
	var player_name: String
	var is_ready: bool = false
	var team: int = 0  # 0=None, 1=Red, 2=Blue

	func _init(id: int, device: String, dev_id: int, color: Color, name: String):
		player_id = id
		input_device = device
		device_id = dev_id
		player_color = color
		player_name = name

# Signals
signal player_joined(player_data: PlayerData)
signal player_left(player_id: int)
signal player_changed_color(player_id: int, new_color: Color)
signal player_ready_changed(player_id: int, is_ready: bool)
signal player_changed_team(player_id: int, team: int)
signal all_players_ready

# Constants
const MAX_PLAYERS = 8
const DEFAULT_COLORS = [
	Color(0.85, 0.35, 0.35, 1.0),   # Red
	Color(0.35, 0.5, 0.85, 1.0),    # Blue
	Color(0.35, 0.8, 0.35, 1.0),    # Green
	Color(0.85, 0.85, 0.35, 1.0),   # Yellow
	Color(0.8, 0.4, 0.85, 1.0),     # Magenta
	Color(0.35, 0.8, 0.8, 1.0),     # Cyan
	Color(0.85, 0.6, 0.35, 1.0),    # Orange
	Color(0.65, 0.35, 0.85, 1.0),   # Purple
]

# State
var joined_players: Array[PlayerData] = []
var next_player_id: int = 1
var game_started: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

# Check if an input device is already taken
func is_device_joined(device_type: String, device_id: int) -> bool:
	for player in joined_players:
		if player.input_device == device_type and player.device_id == device_id:
			return true
	return false

# Get the next available color
func get_next_available_color() -> Color:
	var used_colors: Array[Color] = []
	for player in joined_players:
		used_colors.append(player.player_color)

	for color in DEFAULT_COLORS:
		if not color in used_colors:
			return color

	# If all default colors used, generate a random one
	return Color(randf(), randf(), randf(), 1.0)

# Join a player with specific input device
func join_player(device_type: String, device_id: int) -> PlayerData:
	if joined_players.size() >= MAX_PLAYERS:
		return null

	if is_device_joined(device_type, device_id):
		return null

	var player_name = "Player " + str(next_player_id)
	var player_color = get_next_available_color()

	var player_data = PlayerData.new(next_player_id, device_type, device_id, player_color, player_name)
	joined_players.append(player_data)
	next_player_id += 1

	player_joined.emit(player_data)

	return player_data

# Remove a player
func leave_player(player_id: int) -> void:
	for i in range(joined_players.size()):
		if joined_players[i].player_id == player_id:
			joined_players.remove_at(i)
			player_left.emit(player_id)
			return

# Change player color
func change_player_color(player_id: int, new_color: Color) -> void:
	for player in joined_players:
		if player.player_id == player_id:
			player.player_color = new_color
			player_changed_color.emit(player_id, new_color)
			return

# Change player team
func change_player_team(player_id: int, team: int) -> void:
	for player in joined_players:
		if player.player_id == player_id:
			player.team = team
			player_changed_team.emit(player_id, team)
			return

# Register a phone player from NetworkManager into the party
func register_phone_player(net_player_id: int, player_name: String, color_name: String, team: int) -> PlayerData:
	if joined_players.size() >= MAX_PLAYERS:
		return null

	var player_color = _color_name_to_color(color_name)
	var player_data = PlayerData.new(next_player_id, "phone", net_player_id, player_color, player_name)
	player_data.team = team
	player_data.is_ready = true
	joined_players.append(player_data)
	next_player_id += 1

	player_joined.emit(player_data)
	player_ready_changed.emit(player_data.player_id, true)
	check_all_ready()

	return player_data

# Remove a phone player by network ID
func remove_phone_player(net_player_id: int) -> void:
	for i in range(joined_players.size()):
		if joined_players[i].input_device == "phone" and joined_players[i].device_id == net_player_id:
			var pid = joined_players[i].player_id
			joined_players.remove_at(i)
			player_left.emit(pid)
			return

func _color_name_to_color(color_name: String) -> Color:
	match color_name.to_lower():
		"red": return DEFAULT_COLORS[0]
		"blue": return DEFAULT_COLORS[1]
		"green": return DEFAULT_COLORS[2]
		"yellow": return DEFAULT_COLORS[3]
		"magenta", "purple": return DEFAULT_COLORS[4]
		"cyan": return DEFAULT_COLORS[5]
		"orange": return DEFAULT_COLORS[6]
		"pink": return DEFAULT_COLORS[7]
		_: return get_next_available_color()

# Toggle player ready state
func toggle_player_ready(player_id: int) -> void:
	for player in joined_players:
		if player.player_id == player_id:
			player.is_ready = !player.is_ready
			player_ready_changed.emit(player_id, player.is_ready)
			check_all_ready()
			return

# Set player ready state
func set_player_ready(player_id: int, ready: bool) -> void:
	for player in joined_players:
		if player.player_id == player_id:
			player.is_ready = ready
			player_ready_changed.emit(player_id, ready)
			check_all_ready()
			return

# Check if all players are ready
func check_all_ready() -> void:
	if joined_players.size() == 0:
		return

	var all_ready = true
	for player in joined_players:
		if not player.is_ready:
			all_ready = false
			break

	if all_ready:
		all_players_ready.emit()

# Get player by ID
func get_player(player_id: int) -> PlayerData:
	for player in joined_players:
		if player.player_id == player_id:
			return player
	return null

# Get all joined players
func get_all_players() -> Array[PlayerData]:
	return joined_players.duplicate()

# Get number of joined players
func get_player_count() -> int:
	return joined_players.size()

# Clear all players (call when returning to menu)
func clear_players() -> void:
	joined_players.clear()
	next_player_id = 1
	game_started = false

# Get device display name
func get_device_display_name(device_type: String, device_id: int) -> String:
	match device_type:
		"keyboard":
			return "Keyboard/Mouse"
		"gamepad":
			return "Gamepad " + str(device_id + 1)
		"phone":
			return "Phone"
		_:
			return device_type

# Get input prefix for action names based on device
func get_input_prefix(device_type: String, device_id: int) -> String:
	match device_type:
		"keyboard":
			return "kb_"
		"gamepad":
			return "gp" + str(device_id) + "_"
		_:
			return ""
