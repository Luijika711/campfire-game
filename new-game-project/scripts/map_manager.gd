extends Node

const LEVELS_DIR := "res://scenes/levels/"

# Discovered levels: map_id -> {name, description, scene_path}
var available_maps: Dictionary = {}

signal map_loaded()
signal map_unloaded()

func _ready():
	_discover_levels()

func _discover_levels() -> void:
	available_maps.clear()
	var dir = DirAccess.open(LEVELS_DIR)
	if dir == null:
		push_error("Cannot open levels directory: %s" % LEVELS_DIR)
		return

	dir.list_dir_begin()
	var folder_name = dir.get_next()
	while folder_name != "":
		if dir.current_is_dir() and not folder_name.begins_with("."):
			var scene_path = LEVELS_DIR + folder_name + "/level.tscn"
			if ResourceLoader.exists(scene_path):
				_register_level(folder_name, scene_path)
		folder_name = dir.get_next()
	dir.list_dir_end()
	print("Discovered %d levels" % available_maps.size())

func _register_level(map_id: String, scene_path: String) -> void:
	# Load scene to read metadata from the root node
	var scene = load(scene_path)
	if scene == null:
		return

	var level_name := map_id.capitalize()
	var description := ""

	# Instantiate briefly to read exported vars
	var instance = scene.instantiate()
	if instance.has_method("get") or "level_name" in instance:
		level_name = instance.get("level_name")
		description = instance.get("description")
	instance.queue_free()

	var map_data = MapData.new()
	map_data.map_name = level_name
	map_data.description = description
	available_maps[map_id] = map_data
	print("Registered level: %s (%s)" % [map_id, level_name])

func get_available_maps() -> Dictionary:
	return available_maps.duplicate()
