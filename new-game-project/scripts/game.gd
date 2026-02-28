extends Node2D

const LEVELS_DIR := "res://scenes/levels/"
const PLAYER_SCENE := preload("res://scenes/player.tscn")

@export var current_map_id: String = "basic"

@onready var coin_label: Label = $CanvasLayer/UI/CoinLabel
@onready var player_count_label: Label = $CanvasLayer/UI/PlayerCountLabel
@onready var qr_display: Control = $CanvasLayer/QRDisplay
@onready var show_qr_button: Button = $CanvasLayer/UI/ShowQRButton
@onready var level_container: Node2D = $LevelContainer
@onready var coins: Node2D = $Coins
@onready var goal: Node2D = $Goal
@onready var game_camera: Camera2D = $GameCamera
@onready var health_bar: ProgressBar = $CanvasLayer/UI/HealthBar
@onready var health_label: Label = $CanvasLayer/UI/HealthLabel
@onready var weapon_1_label: Label = $CanvasLayer/UI/Weapon1Label
@onready var weapon_2_label: Label = $CanvasLayer/UI/Weapon2Label
@onready var weapon_3_label: Label = $CanvasLayer/UI/Weapon3Label
@onready var pause_menu: Control = $CanvasLayer/PauseMenu

var players: Dictionary = {}  # player_id -> player node
var spawn_points: Array[Vector2] = []
var current_player_index: int = 0  # For UI updates
var kill_counts: Dictionary = {}  # player_id -> kills
var player_names: Dictionary = {}  # player_id -> display name
var leaderboard_label: Label = null

func _ready() -> void:
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.reset_coins()
	_update_coin_label(0)

	# Connect QR button
	show_qr_button.pressed.connect(_on_show_qr_pressed)

	# Hide QR display initially
	qr_display.visible = false

	# Load the map
	var level_to_load = current_map_id
	if GameManager.selected_level != "":
		level_to_load = GameManager.selected_level
	_load_map(level_to_load)

	# Spawn all players from PartyManager
	_spawn_all_players()

	# Create death pit at the bottom of the level
	_create_death_pit()

	# Setup camera to follow first player
	if players.size() > 0:
		var first_player = players.values()[0]
		if game_camera and game_camera.has_method("setup"):
			game_camera.setup(first_player, self)

	# Update UI
	_update_player_count()
	_update_weapon_ui()
	_create_leaderboard()

	print("Game started with %d players!" % players.size())

func _load_map(map_id: String) -> void:
	# Clear any previous level
	for child in level_container.get_children():
		child.queue_free()

	# Auto-discover level scene from folder
	var scene_path := LEVELS_DIR + map_id + "/level.tscn"
	if not ResourceLoader.exists(scene_path):
		push_error("Level not found: %s" % scene_path)
		return

	var scene = load(scene_path)
	if scene == null:
		push_error("Failed to load level scene: %s" % scene_path)
		return

	var level = scene.instantiate()
	level_container.add_child(level)

	# Read spawn points from Marker2D nodes
	spawn_points.clear()
	var spawn_container = level.get_node_or_null("SpawnPoints")
	if spawn_container:
		for marker in spawn_container.get_children():
			if marker is Marker2D:
				spawn_points.append(marker.position)

	# Fallback spawn points if none defined
	if spawn_points.size() == 0:
		spawn_points = [Vector2(100, 400), Vector2(200, 400), Vector2(300, 400), Vector2(400, 400)]

	# Read coin positions from Marker2D nodes
	var coin_positions: Array[Vector2] = []
	var coin_container = level.get_node_or_null("CoinPositions")
	if coin_container:
		for marker in coin_container.get_children():
			if marker is Marker2D:
				coin_positions.append(marker.position)

	# Read goal position
	var goal_marker = level.get_node_or_null("GoalPosition")
	var goal_pos := Vector2(1050, 186)
	if goal_marker is Marker2D:
		goal_pos = goal_marker.position

	# Spawn coins
	_spawn_coins(coin_positions)

	# Position goal
	if goal != null:
		goal.position = goal_pos

	print("Level loaded: %s" % map_id)

func _create_death_pit() -> void:
	var death_pit = Area2D.new()
	death_pit.name = "DeathPit"
	death_pit.collision_layer = 0
	death_pit.collision_mask = 1  # Detect players
	death_pit.add_to_group("hazards")

	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(20000, 100)
	shape.shape = rect

	# Place far below the level (y=1200 is well below 1080p viewport)
	death_pit.position = Vector2(0, 1200)
	death_pit.add_child(shape)
	add_child(death_pit)

	death_pit.body_entered.connect(_on_death_pit_entered)

func _on_death_pit_entered(body: Node2D) -> void:
	if body.is_in_group("players") and body.has_method("take_damage"):
		body.take_damage(9999)

func _spawn_all_players() -> void:
	# Get all players from PartyManager
	var party_players = PartyManager.get_all_players()

	if party_players.size() == 0:
		# Fallback: spawn one keyboard player if none joined
		push_warning("No players in party! Spawning default keyboard player.")
		PartyManager.join_player("keyboard", -1)
		party_players = PartyManager.get_all_players()

	for i in range(party_players.size()):
		var player_data = party_players[i]
		_spawn_player(player_data, i)

func _spawn_player(player_data: PartyManager.PlayerData, spawn_index: int) -> void:
	var player = PLAYER_SCENE.instantiate()

	# Set position
	if spawn_index < spawn_points.size():
		player.position = spawn_points[spawn_index]
	else:
		player.position = spawn_points[spawn_index % spawn_points.size()]

	# Configure player based on party data
	player.name = "Player_" + str(player_data.player_id)

	# Apply player color to visual
	if player.has_node("AnimatedSprite2D"):
		var visual = player.get_node("AnimatedSprite2D")
		visual.modulate = player_data.player_color

	# Set up input device (for local multiplayer)
	# This would need to be handled in the player script based on device
	# For now, we just track it
	player.set_meta("input_device", player_data.input_device)
	player.set_meta("device_id", player_data.device_id)
	player.set_meta("player_id", player_data.player_id)
	player.set_meta("player_color", player_data.player_color)

	# Add to scene
	add_child(player)
	players[player_data.player_id] = player

	# Track for leaderboard
	var display_name = player_data.player_name
	player_names[player_data.player_id] = display_name
	kill_counts[player_data.player_id] = 0

	# Connect death signal for kill tracking
	player.player_died.connect(
		_on_player_killed.bind(player_data.player_id))

	# Connect signals for host player (first player) UI
	if players.size() == 1:
		player.health_changed.connect(_on_player_health_changed)
		player.weapon_changed.connect(_on_weapon_changed)
		if player.weapon_manager:
			player.weapon_manager.weapon_ammo_changed.connect(_on_weapon_ammo_changed)
		if player.health_component:
			var cur_health = player.health_component.current_health
			var max_health = player.health_component.max_health
			_on_player_health_changed(cur_health, max_health)

	print("Spawned %s at position %s" % [player_data.player_name, player.position])

func _spawn_coins(positions: Array[Vector2]) -> void:
	# Clear existing coins
	for child in coins.get_children():
		child.queue_free()

	# Spawn new coins
	const COIN_SCENE := preload("res://scenes/coin.tscn")
	for pos in positions:
		var coin = COIN_SCENE.instantiate()
		coin.position = pos
		coins.add_child(coin)

func _on_coins_changed(new_count: int) -> void:
	_update_coin_label(new_count)

func _update_coin_label(count: int) -> void:
	coin_label.text = "Coins: %d" % count

func _update_player_count() -> void:
	var count = players.size()
	player_count_label.text = "Players: %d/8" % count

func _on_show_qr_pressed() -> void:
	qr_display.visible = !qr_display.visible
	show_qr_button.text = "Hide QR Code" if qr_display.visible else "Show QR Code"

func _on_player_health_changed(current: int, max: int) -> void:
	if health_bar:
		health_bar.max_value = max
		health_bar.value = current
	if health_label:
		health_label.text = "Health: %d/%d" % [current, max]

func _on_weapon_changed(_weapon: Weapon) -> void:
	_update_weapon_ui()

func _on_weapon_ammo_changed(weapon_index: int, ammo_text: String) -> void:
	match weapon_index:
		0:
			if weapon_1_label:
				weapon_1_label.text = "[1] Sword"
		1:
			if weapon_2_label:
				weapon_2_label.text = "[2] Gun: " + ammo_text
		2:
			if weapon_3_label:
				weapon_3_label.text = "[3] Laser: " + ammo_text

func _update_weapon_ui() -> void:
	# Get the first player for UI
	if players.size() == 0:
		return

	var host_player = players.values()[0]
	if not host_player or not host_player.weapon_manager:
		return

	for i in range(3):
		var weapon = host_player.weapon_manager.get_weapon_at_slot(i)
		var label: Label = null

		match i:
			0: label = weapon_1_label
			1: label = weapon_2_label
			2: label = weapon_3_label

		if label and weapon:
			var prefix = "> " if host_player.weapon_manager.current_weapon_index == i else "  "
			match weapon.weapon_type:
				Weapon.WeaponType.MELEE_SWORD:
					label.text = prefix + "[%d] Sword" % (i + 1)
				Weapon.WeaponType.GUN:
					label.text = prefix + "[%d] Gun: %s" % [i + 1, weapon.get_ammo_text()]
				Weapon.WeaponType.LASER_GUN:
					label.text = prefix + "[%d] Laser: %s" % [i + 1, weapon.get_ammo_text()]

func get_player(player_id: int) -> Node:
	if players.has(player_id):
		return players[player_id]
	return null

func get_all_players() -> Dictionary:
	return players.duplicate()

func _create_leaderboard() -> void:
	leaderboard_label = Label.new()
	leaderboard_label.name = "Leaderboard"
	leaderboard_label.anchors_preset = Control.PRESET_TOP_LEFT
	leaderboard_label.position = Vector2(20, 10)
	leaderboard_label.size = Vector2(200, 200)
	leaderboard_label.add_theme_font_size_override("font_size", 16)
	leaderboard_label.add_theme_color_override(
		"font_color", Color(1, 1, 1, 0.9))
	leaderboard_label.add_theme_color_override(
		"font_shadow_color", Color(0, 0, 0, 0.7))
	leaderboard_label.add_theme_constant_override("shadow_offset_x", 1)
	leaderboard_label.add_theme_constant_override("shadow_offset_y", 1)
	$CanvasLayer/UI.add_child(leaderboard_label)
	_update_leaderboard()

func _on_player_killed(killer: Node, victim_id: int) -> void:
	if killer:
		# Find killer's player_id
		var killer_id = killer.get_meta("player_id", -1)
		if killer_id >= 0 and kill_counts.has(killer_id):
			# Don't count self-kills
			if killer_id != victim_id:
				kill_counts[killer_id] += 1
	_update_leaderboard()
	_check_game_over()

func _update_leaderboard() -> void:
	if not leaderboard_label:
		return

	var lines: Array[String] = ["-- Kills --"]
	# Sort by kills descending
	var sorted_ids = kill_counts.keys()
	sorted_ids.sort_custom(func(a, b):
		return kill_counts[a] > kill_counts[b])

	for pid in sorted_ids:
		var pname = player_names.get(pid, "P%d" % pid)
		var kills = kill_counts[pid]
		var dead_marker = ""
		if players.has(pid) and players[pid].is_dead:
			dead_marker = " [DEAD]"
		lines.append("%s: %d%s" % [pname, kills, dead_marker])

	leaderboard_label.text = "\n".join(lines)

func _check_game_over() -> void:
	var alive_count = 0
	var last_alive_id = -1
	for pid in players:
		if not players[pid].is_dead:
			alive_count += 1
			last_alive_id = pid

	if alive_count <= 1 and players.size() > 1:
		if alive_count == 1:
			var winner = player_names.get(last_alive_id, "???")
			_show_game_over("%s wins!" % winner)
		else:
			_show_game_over("Draw!")

func _show_game_over(message: String) -> void:
	var game_over = Label.new()
	game_over.name = "GameOverLabel"
	game_over.text = message
	game_over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over.anchors_preset = Control.PRESET_CENTER
	game_over.position = Vector2(-200, -50)
	game_over.size = Vector2(400, 100)
	game_over.add_theme_font_size_override("font_size", 48)
	game_over.add_theme_color_override(
		"font_color", Color(1, 0.9, 0.3, 1))
	game_over.add_theme_color_override(
		"font_shadow_color", Color(0, 0, 0, 0.8))
	game_over.add_theme_constant_override("shadow_offset_x", 2)
	game_over.add_theme_constant_override("shadow_offset_y", 2)
	$CanvasLayer/UI.add_child(game_over)
