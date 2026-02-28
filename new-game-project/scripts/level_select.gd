extends Control

var click_sound: AudioStream = null
const LEVEL_CARD_SCENE = preload("res://scenes/level_card.tscn")

@onready var grid_container: GridContainer = $ScrollContainer/GridContainer
@onready var back_button: Button = $BackButton

func _ready():
	# Load click sound if it exists
	if FileAccess.file_exists("res://assets/audio/click.wav"):
		click_sound = load("res://assets/audio/click.wav")

	back_button.pressed.connect(_on_back_pressed)

	# Load available maps
	var maps = MapManager.get_available_maps()

	for map_id in maps.keys():
		var map_data = maps[map_id]
		var card = LEVEL_CARD_SCENE.instantiate()
		card.setup(map_id, map_data)
		card.level_selected.connect(_on_level_selected)
		grid_container.add_child(card)

func _on_level_selected(map_id: String):
	AudioManager.play_sfx(click_sound)
	GameManager.selected_level = map_id
	SceneManager.change_scene("res://scenes/game.tscn")

func _on_back_pressed():
	AudioManager.play_sfx(click_sound)
	SceneManager.change_scene("res://scenes/main_menu.tscn")
