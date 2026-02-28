extends Node

signal coins_changed(new_count: int)
signal level_completed
signal player_joined(player_id: int, player_name: String)
signal player_left(player_id: int)

var coin_count: int = 0
var total_coins: int = 0
var selected_level: String = "basic"
var game_state: int = GameState.MAIN_MENU

enum GameState {
	MAIN_MENU,
	PLAYING,
	PAUSED,
	LEVEL_SELECT,
	SETTINGS
}

func _ready() -> void:
	# Count total coins in level
	await get_tree().process_frame
	total_coins = get_tree().get_nodes_in_group("coins").size()

func add_coin() -> void:
	coin_count += 1
	coins_changed.emit(coin_count)

func complete_level() -> void:
	level_completed.emit()
	print("Level Complete! Coins collected: ", coin_count, "/", total_coins)

func reset_coins() -> void:
	coin_count = 0
	coins_changed.emit(0)

func set_game_state(state: int) -> void:
	game_state = state

func is_playing() -> bool:
	return game_state == GameState.PLAYING
