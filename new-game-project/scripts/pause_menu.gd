extends Control

var click_sound: AudioStream = null
var pause_sound: AudioStream = null
var unpause_sound: AudioStream = null

@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready():
	visible = false

	# Load sounds if they exist
	if FileAccess.file_exists("res://assets/audio/click.wav"):
		click_sound = load("res://assets/audio/click.wav")
	if FileAccess.file_exists("res://assets/audio/pause.wav"):
		pause_sound = load("res://assets/audio/pause.wav")
	if FileAccess.file_exists("res://assets/audio/unpause.wav"):
		unpause_sound = load("res://assets/audio/unpause.wav")

	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	visible = !visible
	SceneManager.toggle_pause()

	if visible:
		resume_button.grab_focus()
		AudioManager.play_sfx(pause_sound)
	else:
		AudioManager.play_sfx(unpause_sound)

func _on_resume_pressed():
	AudioManager.play_sfx(click_sound)
	toggle_pause()

func _on_restart_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.resume_game()
	SceneManager.restart_current_level()

func _on_settings_pressed():
	AudioManager.play_sfx(click_sound)
	# TODO: Show settings overlay

func _on_main_menu_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.resume_game()
	SceneManager.change_scene("res://scenes/main_menu.tscn")

func _on_quit_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.quit_game()
