extends Camera2D

## Camera that follows the host player and zooms out to fit all players.

@export var min_zoom: float = 0.3
@export var max_zoom: float = 1.0
@export var zoom_margin: float = 200.0
@export var smooth_speed: float = 5.0
@export var camera_offset: Vector2 = Vector2.ZERO
@export var enable_zoom: bool = true

var _host_player: CharacterBody2D
var _player_manager: Node2D
var _viewport_size: Vector2

func _ready() -> void:
	_viewport_size = get_viewport_rect().size

func setup(host: CharacterBody2D, player_mgr: Node2D) -> void:
	_host_player = host
	_player_manager = player_mgr

func _process(delta: float) -> void:
	if _host_player == null:
		return

	var all_positions: Array[Vector2] = [_host_player.global_position]

	if _player_manager:
		for p in _player_manager.get_all_players():
			if p is Node2D:
				all_positions.append(p.global_position)

	if all_positions.size() == 1:
		# Single player — just follow them
		global_position = global_position.lerp(
			all_positions[0], smooth_speed * delta
		)
		zoom = zoom.lerp(Vector2(max_zoom, max_zoom), smooth_speed * delta)
		return

	# Multiple players — find bounding box
	var rect := Rect2(all_positions[0], Vector2.ZERO)
	for pos in all_positions:
		rect = rect.expand(pos)

	# Center on midpoint of all players
	var target_pos := rect.get_center() + camera_offset
	global_position = global_position.lerp(target_pos, smooth_speed * delta)

	# Zoom to fit everyone with margin
	if enable_zoom:
		var needed_width := rect.size.x + zoom_margin * 2.0
		var needed_height := rect.size.y + zoom_margin * 2.0
		var zoom_x := _viewport_size.x / needed_width
		var zoom_y := _viewport_size.y / needed_height
		var target_zoom := clampf(min(zoom_x, zoom_y), min_zoom, max_zoom)
		zoom = zoom.lerp(
			Vector2(target_zoom, target_zoom), smooth_speed * delta
		)
