extends Node2D

@export var current_map_id: String = "basic"

@onready var coin_label: Label = $CanvasLayer/UI/CoinLabel
@onready var player_count_label: Label = $CanvasLayer/UI/PlayerCountLabel
@onready var qr_display: Control = $CanvasLayer/QRDisplay
@onready var show_qr_button: Button = $CanvasLayer/UI/ShowQRButton
@onready var tile_map: TileMap = $TileMap
@onready var platforms: Node2D = $Platforms
@onready var coins: Node2D = $Coins
@onready var goal: Node2D = $Goal
@onready var host_player: CharacterBody2D = $HostPlayer
@onready var background: Sprite2D = $Background

# UI Elements for health and weapons
@onready var health_bar: ProgressBar = $CanvasLayer/UI/HealthBar
@onready var health_label: Label = $CanvasLayer/UI/HealthLabel
@onready var weapon_1_label: Label = $CanvasLayer/UI/Weapon1Label
@onready var weapon_2_label: Label = $CanvasLayer/UI/Weapon2Label
@onready var weapon_3_label: Label = $CanvasLayer/UI/Weapon3Label

func _ready() -> void:
	# DEBUG: Check background setup
	print("=== BACKGROUND DEBUG ===")
	if background != null:
		print("Background node found")
		print("  - Position: " + str(background.position))
		print("  - Scale: " + str(background.scale))
		print("  - Modulate: " + str(background.modulate))
		print("  - Texture: " + str(background.texture))
		print("  - Visible: " + str(background.visible))
		if background.texture != null:
			print("  - Texture size: " + str(background.texture.get_size()))
	else:
		print("ERROR: Background node not found!")
	print("=== END BACKGROUND DEBUG ===")
	
	GameManager.coins_changed.connect(_on_coins_changed)
	_update_coin_label(0)

	# Connect to NetworkManager for player join/leave events
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)

	# Connect QR button
	show_qr_button.pressed.connect(_on_show_qr_pressed)

	# Hide QR display initially
	qr_display.visible = false

	# Load the map
	_load_map(current_map_id)

	# Initial player count (just host)
	_update_player_count()

	# Connect to host player health and weapon signals
	if host_player:
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

	print("Game started! Press 'Show QR Code' to let players join.")

func _load_map(map_id: String) -> void:
	print("Loading map: " + map_id)
	# Load map using MapManager
	if MapManager.load_map(map_id, tile_map):
		var map_data = MapManager.get_current_map()

		# Background wallpaper displays at full color (no tint)
		# DEBUG: Check background after map load
		print("=== POST-LOAD BACKGROUND DEBUG ===")
		if background != null:
			print("Background after load:")
			print("  - Position: " + str(background.position))
			print("  - Scale: " + str(background.scale))
			print("  - Modulate: " + str(background.modulate))
			print("  - Texture: " + str(background.texture))
		else:
			print("ERROR: Background node not found after load!")
		print("=== END POST-LOAD DEBUG ===")

		# Position host player at first spawn point
		if host_player != null:
			host_player.position = map_data.get_spawn_point(0)

		# Spawn coins
		_spawn_coins(map_data.coin_positions)

		# Position goal
		if goal != null:
			goal.position = map_data.goal_position

		# Setup player manager spawn points
		if $PlayerManager:
			$PlayerManager.spawn_points = map_data.spawn_points

		print("Map loaded: %s" % map_data.map_name)
	else:
		push_error("Failed to load map: %s" % map_id)

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

func _on_player_connected(_player_id: int, player_name: String, _color: String) -> void:
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

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

	# Toggle QR display with Tab key
	if event.is_action_pressed("toggle_qr"):
		_on_show_qr_pressed()

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
