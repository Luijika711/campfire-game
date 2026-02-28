extends Control

enum Tool {
	TILE_GROUND,
	TILE_PLATFORM,
	COIN,
	SPAWN_POINT,
	GOAL,
	ERASE
}

var current_tool: int = Tool.TILE_GROUND
var current_layer: int = 0

@onready var tile_map: TileMap = $ViewportContainer/SubViewport/TileMap
@onready var preview_sprite: Sprite2D = $PreviewSprite
@onready var tool_buttons: Dictionary = {}
@onready var layer_selector: OptionButton = $VBoxContainer/LayerSelector
@onready var save_button: Button = $VBoxContainer/SaveButton
@onready var load_button: Button = $VBoxContainer/LoadButton
@onready var clear_button: Button = $VBoxContainer/ClearButton
@onready var map_name_input: LineEdit = $VBoxContainer/MapNameInput
@onready var test_button: Button = $VBoxContainer/TestButton
@onready var back_button: Button = $VBoxContainer/BackButton

var is_mouse_down: bool = false

func _ready():
	# Setup tool buttons
	tool_buttons = {
		Tool.TILE_GROUND: $VBoxContainer/ToolButtons/GroundButton,
		Tool.TILE_PLATFORM: $VBoxContainer/ToolButtons/PlatformButton,
		Tool.COIN: $VBoxContainer/ToolButtons/CoinButton,
		Tool.SPAWN_POINT: $VBoxContainer/ToolButtons/SpawnButton,
		Tool.GOAL: $VBoxContainer/ToolButtons/GoalButton,
		Tool.ERASE: $VBoxContainer/ToolButtons/EraseButton
	}

	for tool in tool_buttons.keys():
		tool_buttons[tool].pressed.connect(_on_tool_selected.bind(tool))

	# Setup other buttons
	layer_selector.item_selected.connect(_on_layer_changed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	test_button.pressed.connect(_on_test_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Select ground tool by default
	_on_tool_selected(Tool.TILE_GROUND)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_mouse_down = event.pressed
			if is_mouse_down:
				_place_tile_at_mouse()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_erase_tile_at_mouse()

	elif event is InputEventMouseMotion:
		if is_mouse_down:
			_place_tile_at_mouse()

func _get_mouse_tile_pos() -> Vector2i:
	var mouse_pos = get_global_mouse_position()
	return tile_map.local_to_map(tile_map.to_local(mouse_pos))

func _place_tile_at_mouse() -> void:
	var tile_pos = _get_mouse_tile_pos()

	match current_tool:
		Tool.TILE_GROUND:
			tile_map.set_cell(current_layer, tile_pos, 0, Vector2i(0, 0))
		Tool.TILE_PLATFORM:
			tile_map.set_cell(current_layer, tile_pos, 0, Vector2i(1, 0))
		Tool.COIN:
			_place_coin(tile_pos)
		Tool.SPAWN_POINT:
			_place_spawn_point(tile_pos)
		Tool.GOAL:
			_place_goal(tile_pos)

func _erase_tile_at_mouse() -> void:
	var tile_pos = _get_mouse_tile_pos()
	tile_map.erase_cell(current_layer, tile_pos)

func _place_coin(pos: Vector2i) -> void:
	var world_pos = tile_map.map_to_local(pos)
	print("Placing coin at: ", world_pos)

func _place_spawn_point(pos: Vector2i) -> void:
	var world_pos = tile_map.map_to_local(pos)
	print("Placing spawn point at: ", world_pos)

func _place_goal(pos: Vector2i) -> void:
	var world_pos = tile_map.map_to_local(pos)
	print("Placing goal at: ", world_pos)

func _on_tool_selected(tool: int) -> void:
	current_tool = tool

	# Update button styles
	for t in tool_buttons.keys():
		var btn = tool_buttons[t]
		if t == tool:
			btn.modulate = Color(1.2, 1.2, 1.2, 1)
		else:
			btn.modulate = Color(1, 1, 1, 1)

func _on_layer_changed(index: int) -> void:
	current_layer = index

func _on_save_pressed() -> void:
	var map_name = map_name_input.text
	if map_name.is_empty():
		map_name = "custom_map"

	var map_data = _serialize_map()
	var json_data = JSON.stringify(map_data, "\t")

	var file = FileAccess.open("user://maps/%s.json" % map_name, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		file.close()
		print("Map saved: %s" % map_name)

func _on_load_pressed() -> void:
	var map_name = map_name_input.text
	if map_name.is_empty():
		return

	var path = "user://maps/%s.json" % map_name
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_data = file.get_as_text()
		file.close()

		var map_data = JSON.parse_string(json_data)
		if map_data:
			_deserialize_map(map_data)
			print("Map loaded: %s" % map_name)

func _on_clear_pressed() -> void:
	tile_map.clear()

func _on_test_pressed() -> void:
	# Save current map as temp and load it
	_on_save_pressed()
	GameManager.selected_level = "custom_" + map_name_input.text
	SceneManager.change_scene("res://scenes/game.tscn")

func _on_back_pressed() -> void:
	SceneManager.change_scene("res://scenes/main_menu.tscn")

func _serialize_map() -> Dictionary:
	var tiles = []
	var used_cells = tile_map.get_used_cells(0)

	for cell in used_cells:
		var atlas_coords = tile_map.get_cell_atlas_coords(0, cell)
		tiles.append({
			"x": cell.x,
			"y": cell.y,
			"layer": 0,
			"atlas_coords": [atlas_coords.x, atlas_coords.y]
		})

	return {
		"map_name": map_name_input.text,
		"tiles": tiles,
		"tile_size": 32
	}

func _deserialize_map(data: Dictionary) -> void:
	tile_map.clear()

	if data.has("tiles"):
		for tile in data.tiles:
			var x = tile.x
			var y = tile.y
			var layer = tile.get("layer", 0)
			var atlas = tile.atlas_coords
			tile_map.set_cell(layer, Vector2i(x, y), 0, Vector2i(atlas[0], atlas[1]))
