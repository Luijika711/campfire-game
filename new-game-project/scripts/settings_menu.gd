extends Control

var click_sound: AudioStream = null

@onready var master_slider: HSlider = $Panel/VBoxContainer/AudioSection/MasterSlider
@onready var music_slider: HSlider = $Panel/VBoxContainer/AudioSection/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/AudioSection/SFXSlider
@onready var fullscreen_check: CheckBox = $Panel/VBoxContainer/GraphicsSection/FullscreenCheck
@onready var vsync_check: CheckBox = $Panel/VBoxContainer/GraphicsSection/VSyncCheck
@onready var show_fps_check: CheckBox = $Panel/VBoxContainer/GraphicsSection/ShowFPSCheck
@onready var player_name_input: LineEdit = $Panel/VBoxContainer/GameSection/PlayerNameInput
@onready var save_button: Button = $Panel/VBoxContainer/SaveButton
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

func _ready():
	# Load click sound if it exists
	if FileAccess.file_exists("res://assets/audio/click.wav"):
		click_sound = load("res://assets/audio/click.wav")

	# Load current settings
	master_slider.value = GameSettings.master_volume * 100
	music_slider.value = GameSettings.music_volume * 100
	sfx_slider.value = GameSettings.sfx_volume * 100
	fullscreen_check.button_pressed = GameSettings.fullscreen
	vsync_check.button_pressed = GameSettings.vsync
	show_fps_check.button_pressed = GameSettings.show_fps
	player_name_input.text = GameSettings.player_name

	# Connect signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	show_fps_check.toggled.connect(_on_show_fps_toggled)
	player_name_input.text_changed.connect(_on_player_name_changed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_master_volume_changed(value: float):
	GameSettings.master_volume = value / 100.0
	GameSettings.set_bus_volume("Master", GameSettings.master_volume)

func _on_music_volume_changed(value: float):
	GameSettings.music_volume = value / 100.0
	GameSettings.set_bus_volume("Music", GameSettings.music_volume)

func _on_sfx_volume_changed(value: float):
	GameSettings.sfx_volume = value / 100.0
	GameSettings.set_bus_volume("SFX", GameSettings.sfx_volume)

func _on_fullscreen_toggled(pressed: bool):
	GameSettings.fullscreen = pressed

func _on_vsync_toggled(pressed: bool):
	GameSettings.vsync = pressed

func _on_show_fps_toggled(pressed: bool):
	GameSettings.show_fps = pressed

func _on_player_name_changed(text: String):
	GameSettings.player_name = text

func _on_save_pressed():
	AudioManager.play_sfx(click_sound)
	GameSettings.save_settings()

func _on_back_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.change_scene("res://scenes/main_menu.tscn")
