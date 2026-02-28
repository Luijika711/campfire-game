extends Node2D
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var max_enemies: int = 5
@export var tile_map_path: NodePath = "../TileMap"

@onready var spawn_timer: Timer = $SpawnTimer

var spawned_enemies: Array[Node] = []
var tile_map: TileMap = null

func _ready() -> void:
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

	# Get TileMap reference
	if not tile_map_path.is_empty():
		tile_map = get_node_or_null(tile_map_path)
	else:
		# Try to find TileMap in parent
		tile_map = get_parent().get_node_or_null("TileMap")

	# Wait a frame for TileMap to be ready
	await get_tree().process_frame

	if tile_map == null:
		push_warning("EnemySpawner: TileMap not found!")

	spawn_timer.start(spawn_interval)

func _on_spawn_timer_timeout() -> void:
	# Remove dead enemies from list
	spawned_enemies = spawned_enemies.filter(func(e): return is_instance_valid(e) and not e.is_dead)

	# Spawn new enemy if under limit
	if spawned_enemies.size() < max_enemies:
		_spawn_enemy()

	spawn_timer.start(spawn_interval)

func _spawn_enemy() -> void:
	if enemy_scene == null:
		return

	if tile_map == null:
		push_warning("EnemySpawner: Cannot spawn - TileMap is null")
		return

	# Get all used cells from the TileMap
	var used_cells = tile_map.get_used_cells(0)

	if used_cells.is_empty():
		push_warning("EnemySpawner: No tiles found in TileMap")
		return

	# Pick a random tile
	var random_cell = used_cells[randi() % used_cells.size()]

	# Convert to world position
	var tile_world_pos = tile_map.map_to_local(random_cell)

	# Spawn enemy above the tile (tile is 32x32, so spawn 32 pixels above)
	var spawn_pos = tile_world_pos + Vector2(0, -32)

	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos

	get_tree().current_scene.add_child(enemy)
	spawned_enemies.append(enemy)

	print("Spawned enemy at: ", spawn_pos)
