extends Node

signal scene_changed(scene_name: String)
signal game_paused
signal game_resumed

var current_scene: Node = null
var paused: bool = false:
	set(value):
		paused = value
		get_tree().paused = paused
		if paused:
			emit_signal("game_paused")
		else:
			emit_signal("game_resumed")

func _ready():
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func change_scene(scene_path: String) -> void:
	call_deferred("_deferred_change_scene", scene_path)

func _deferred_change_scene(scene_path: String) -> void:
	current_scene.free()

	var scene = load(scene_path)
	if scene:
		current_scene = scene.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene

		var scene_name = scene_path.get_file().get_basename()
		emit_signal("scene_changed", scene_name)

func toggle_pause() -> void:
	paused = !paused

func pause_game() -> void:
	paused = true

func resume_game() -> void:
	paused = false

func quit_game() -> void:
	get_tree().quit()

func restart_current_level() -> void:
	var current_path = current_scene.scene_file_path
	change_scene(current_path)
