extends Node

signal settings_loaded
signal settings_saved

# Graphics settings
var fullscreen: bool = false:
	set(value):
		fullscreen = value
		_apply_graphics_settings()

var vsync: bool = true:
	set(value):
		vsync = value
		var vsync_mode = DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
		DisplayServer.window_set_vsync_mode(vsync_mode)

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0

# Game settings
var player_name: String = "Player"
var show_fps: bool = false

const SETTINGS_PATH = "user://settings.cfg"

func _ready():
	load_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)

	if err == OK:
		fullscreen = config.get_value("graphics", "fullscreen", false)
		vsync = config.get_value("graphics", "vsync", true)
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 0.8)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		player_name = config.get_value("game", "player_name", "Player")
		show_fps = config.get_value("game", "show_fps", false)

		_apply_graphics_settings()
		_apply_audio_settings()

	emit_signal("settings_loaded")

func save_settings() -> void:
	var config = ConfigFile.new()

	config.set_value("graphics", "fullscreen", fullscreen)
	config.set_value("graphics", "vsync", vsync)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("game", "player_name", player_name)
	config.set_value("game", "show_fps", show_fps)

	config.save(SETTINGS_PATH)
	emit_signal("settings_saved")

func _apply_graphics_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_audio_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))

func set_bus_volume(bus_name: String, volume: float) -> void:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))
