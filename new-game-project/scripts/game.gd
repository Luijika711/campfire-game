extends Node2D

const LEVELS_DIR := "res://scenes/levels/"

@export var current_map_id: String = "basic"

@onready var coin_label: Label = $CanvasLayer/UI/CoinLabel
@onready var player_count_label: Label = $CanvasLayer/UI/PlayerCountLabel
@onready var qr_display: Control = $CanvasLayer/QRDisplay
@onready var show_qr_button: Button = $CanvasLayer/UI/ShowQRButton
@onready var level_container: Node2D = $LevelContainer
@onready var coins: Node2D = $Coins
@onready var goal: Node2D = $Goal
@onready var host_player: CharacterBody2D = $HostPlayer
@onready var game_camera: Camera2D = $GameCamera
@onready var health_bar: ProgressBar = $CanvasLayer/UI/HealthBar
@onready var health_label: Label = $CanvasLayer/UI/HealthLabel
@onready var weapon_1_label: Label = $CanvasLayer/UI/Weapon1Label
@onready var weapon_2_label: Label = $CanvasLayer/UI/Weapon2Label
@onready var weapon_3_label: Label = $CanvasLayer/UI/Weapon3Label
@onready var pause_menu: Control = $CanvasLayer/PauseMenu
@onready var team_label: Label

func _ready() -> void:
	# Setup camera
	if game_camera:
		game_camera.setup(host_player, $PlayerManager)

	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.reset_coins()
	_update_coin_label(0)

	# Connect to NetworkManager for player join/leave events
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

	# Connect QR button
	show_qr_button.pressed.connect(_on_show_qr_pressed)

	# Hide QR display initially
	qr_display.visible = false

	# Load the map
	var level_to_load = current_map_id
	if GameManager.selected_level != "":
		level_to_load = GameManager.selected_level
	_load_map(level_to_load)

	# Connect to host player health and weapon signals
	if host_player:
		# Assign host to Team Red by default
		host_player.set_team(TeamManager.Team.TEAM_RED)

		host_player.health_changed.connect(_on_player_health_changed)
		host_player.weapon_changed.connect(_on_weapon_changed)

		# Connect to weapon manager for ammo updates
		if host_player.weapon_manager:
			host_player.weapon_manager.weapon_ammo_changed.connect(_on_weapon_ammo_changed)

		# Initialize health display
		if host_player.health_component:
			var health = host_player.health_component
			_on_player_health_changed(health.current_health, health.max_health)

	# Update weapon UI
	_update_weapon_ui()

	# Create team label dynamically
	_create_team_label()

	# Initial player count (just host)
	_update_player_count()

	print("Game started! Press 'Show QR Code' to let players join.")

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
	var spawn_points: Array[Vector2] = []
	var spawn_container = level.get_node_or_null("SpawnPoints")
	if spawn_container:
		for marker in spawn_container.get_children():
			if marker is Marker2D:
				spawn_points.append(marker.position)

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

	# Position host player at first spawn point
	if host_player != null and spawn_points.size() > 0:
		host_player.position = spawn_points[0]

	# Spawn coins
	_spawn_coins(coin_positions)

	# Position goal
	if goal != null:
		goal.position = goal_pos

	# Setup player manager spawn points
	if $PlayerManager and spawn_points.size() > 0:
		$PlayerManager.spawn_points = spawn_points

	print("Level loaded: %s" % map_id)

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

func _on_player_connected(
	_player_id: int, player_name: String,
	_color: String, _team: int = 0
) -> void:
	_update_player_count()
	print("Player joined: %s" % player_name)

func _on_player_disconnected(_player_id: int) -> void:
	_update_player_count()

func _update_player_count() -> void:
	if $PlayerManager:
		var count = $PlayerManager.get_player_count() + 1  # +1 for host
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

func _create_team_label() -> void:
	team_label = Label.new()
	team_label.name = "TeamLabel"
	team_label.anchors_preset = 1  # Top-right
	team_label.anchor_left = 1.0
	team_label.anchor_right = 1.0
	team_label.offset_left = -200.0
	team_label.offset_top = 135.0
	team_label.offset_right = -20.0
	team_label.offset_bottom = 160.0
	team_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	team_label.add_theme_font_size_override("font_size", 18)
	team_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	var ui = $CanvasLayer/UI
	if ui:
		ui.add_child(team_label)

	_update_team_label()

func _update_team_label() -> void:
	if not team_label or not host_player or not TeamManager:
		return
	var team = TeamManager.get_team(host_player)
	var team_name = TeamManager.get_team_name(team)
	var team_color = TeamManager.get_team_color(team)
	team_label.text = "Team: %s" % team_name
	team_label.add_theme_color_override("font_color", team_color)
