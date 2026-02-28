extends Control

var click_sound: AudioStream = null

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var play_button: Button = $Panel/VBoxContainer/PlayButton
@onready var level_select_button: Button = $Panel/VBoxContainer/LevelSelectButton
@onready var settings_button: Button = $Panel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

func _ready():
	# Load click sound if it exists
	if FileAccess.file_exists("res://assets/audio/click.wav"):
		click_sound = load("res://assets/audio/click.wav")

	# Connect buttons
	play_button.pressed.connect(_on_play_pressed)
	level_select_button.pressed.connect(_on_level_select_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Animation
	_title_animation()

	# Focus play button
	play_button.grab_focus()

func _title_animation():
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.5).from(Vector2(0.0, 0.0))

func _on_play_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.change_scene("res://scenes/party_lobby.tscn")

func _on_level_select_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.change_scene("res://scenes/level_select.tscn")

func _on_settings_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.change_scene("res://scenes/settings_menu.tscn")

func _on_quit_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.quit_game()
