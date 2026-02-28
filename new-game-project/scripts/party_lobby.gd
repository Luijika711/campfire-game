extends Control

const PLAYER_SLOT_SCENE = preload("res://scenes/player_slot.tscn")

@onready var players_container: VBoxContainer = $Panel/VBoxContainer/PlayersContainer
@onready var instructions_label: Label = $Panel/VBoxContainer/InstructionsLabel
@onready var start_button: Button = $Panel/VBoxContainer/StartButton
@onready var back_button: Button = $Panel/VBoxContainer/BackButton

var player_slots: Dictionary = {}  # player_id -> PlayerSlot node

var ui_join_sound: AudioStream = null
var ui_leave_sound: AudioStream = null
var ui_ready_sound: AudioStream = null
var ui_color_sound: AudioStream = null
var ui_start_sound: AudioStream = null
var ui_back_sound: AudioStream = null

func _ready():
	# Load audio sounds if they exist
	if FileAccess.file_exists("res://assets/audio/ui_join.wav"):
		ui_join_sound = load("res://assets/audio/ui_join.wav")
	if FileAccess.file_exists("res://assets/audio/ui_leave.wav"):
		ui_leave_sound = load("res://assets/audio/ui_leave.wav")
	if FileAccess.file_exists("res://assets/audio/ui_ready.wav"):
		ui_ready_sound = load("res://assets/audio/ui_ready.wav")
	if FileAccess.file_exists("res://assets/audio/ui_color.wav"):
		ui_color_sound = load("res://assets/audio/ui_color.wav")
	if FileAccess.file_exists("res://assets/audio/ui_start.wav"):
		ui_start_sound = load("res://assets/audio/ui_start.wav")
	if FileAccess.file_exists("res://assets/audio/ui_back.wav"):
		ui_back_sound = load("res://assets/audio/ui_back.wav")

	# Connect signals
	PartyManager.player_joined.connect(_on_player_joined)
	PartyManager.player_left.connect(_on_player_left)
	PartyManager.player_changed_color.connect(_on_player_changed_color)
	PartyManager.player_ready_changed.connect(_on_player_ready_changed)
	PartyManager.all_players_ready.connect(_on_all_players_ready)

	# Connect buttons
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)

	# Update UI
	_update_start_button()

	# Check if PartyManager was already initialized (coming back from game)
	if PartyManager.get_player_count() > 0:
		_rebuild_player_slots()

func _input(event):
	# Keyboard player join
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			# Check if keyboard player already joined
			if not PartyManager.is_device_joined("keyboard", -1):
				PartyManager.join_player("keyboard", -1)
				AudioManager.play_sfx(ui_join_sound)
				get_viewport().set_input_as_handled()
				return

		# Leave with Escape
		if event.keycode == KEY_ESCAPE:
			for player in PartyManager.get_all_players():
				if player.input_device == "keyboard":
					PartyManager.leave_player(player.player_id)
					AudioManager.play_sfx(ui_leave_sound)
					get_viewport().set_input_as_handled()
					return

	# Gamepad player join
	if event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_A:
			var device_id = event.device
			if not PartyManager.is_device_joined("gamepad", device_id):
				PartyManager.join_player("gamepad", device_id)
				AudioManager.play_sfx(ui_join_sound)
				get_viewport().set_input_as_handled()
				return

		# Leave with B button
		if event.button_index == JOY_BUTTON_B:
			var device_id = event.device
			for player in PartyManager.get_all_players():
				if player.input_device == "gamepad" and player.device_id == device_id:
					PartyManager.leave_player(player.player_id)
					AudioManager.play_sfx(ui_leave_sound)
					get_viewport().set_input_as_handled()
					return

	# Color selection with shoulder buttons
	if event is InputEventJoypadButton and event.pressed:
		var device_id = event.device
		for player in PartyManager.get_all_players():
			if player.input_device == "gamepad" and player.device_id == device_id:
				if event.button_index == JOY_BUTTON_LEFT_SHOULDER:
					_cycle_player_color(player.player_id, -1)
					get_viewport().set_input_as_handled()
					return
				if event.button_index == JOY_BUTTON_RIGHT_SHOULDER:
					_cycle_player_color(player.player_id, 1)
					get_viewport().set_input_as_handled()
					return
				if event.button_index == JOY_BUTTON_X:
					PartyManager.toggle_player_ready(player.player_id)
					AudioManager.play_sfx(ui_ready_sound)
					get_viewport().set_input_as_handled()
					return

func _on_player_joined(player_data: PartyManager.PlayerData):
	_create_player_slot(player_data)
	_update_start_button()
	_update_instructions()

func _on_player_left(player_id: int):
	if player_slots.has(player_id):
		player_slots[player_id].queue_free()
		player_slots.erase(player_id)
	_update_start_button()
	_update_instructions()

func _on_player_changed_color(player_id: int, new_color: Color):
	if player_slots.has(player_id):
		player_slots[player_id].update_color(new_color)

func _on_player_ready_changed(player_id: int, is_ready: bool):
	if player_slots.has(player_id):
		player_slots[player_id].update_ready(is_ready)
	_update_start_button()

func _on_all_players_ready():
	# Auto-start when all ready (optional - can be disabled)
	pass

func _create_player_slot(player_data: PartyManager.PlayerData):
	var slot = PLAYER_SLOT_SCENE.instantiate()
	players_container.add_child(slot)
	slot.setup(player_data)
	player_slots[player_data.player_id] = slot

	# Connect slot signals
	slot.color_changed.connect(_on_slot_color_changed)
	slot.ready_toggled.connect(_on_slot_ready_toggled)
	slot.leave_pressed.connect(_on_slot_leave_pressed)

func _rebuild_player_slots():
	# Clear existing slots
	for slot in player_slots.values():
		slot.queue_free()
	player_slots.clear()

	# Rebuild from PartyManager
	for player_data in PartyManager.get_all_players():
		_create_player_slot(player_data)

	_update_start_button()
	_update_instructions()

func _on_slot_color_changed(player_id: int, new_color: Color):
	PartyManager.change_player_color(player_id, new_color)

func _on_slot_ready_toggled(player_id: int, is_ready: bool):
	PartyManager.set_player_ready(player_id, is_ready)
	AudioManager.play_sfx(ui_ready_sound)

func _on_slot_leave_pressed(player_id: int):
	PartyManager.leave_player(player_id)
	AudioManager.play_sfx(ui_leave_sound)

func _cycle_player_color(player_id: int, direction: int):
	var player = PartyManager.get_player(player_id)
	if player:
		var colors = PartyManager.DEFAULT_COLORS
		var current_idx = colors.find(player.player_color)
		var new_idx = (current_idx + direction) % colors.size()
		if new_idx < 0:
			new_idx = colors.size() - 1
		PartyManager.change_player_color(player_id, colors[new_idx])
		AudioManager.play_sfx(ui_color_sound)

func _update_start_button():
	var player_count = PartyManager.get_player_count()
	var all_ready = player_count > 0

	for player in PartyManager.get_all_players():
		if not player.is_ready:
			all_ready = false
			break

	start_button.disabled = not all_ready
	if player_count == 0:
		start_button.text = "WAITING FOR PLAYERS..."
	elif not all_ready:
		start_button.text = "WAITING FOR READY..."
	else:
		start_button.text = "START GAME!"

func _update_instructions():
	var player_count = PartyManager.get_player_count()
	if player_count == 0:
		instructions_label.text = "Press ENTER (Keyboard) or A Button (Gamepad) to Join!"
	else:
		instructions_label.text = "Use Shoulder Buttons to Change Color, X Button to Ready Up"

func _on_start_pressed():
	AudioManager.play_sfx(ui_start_sound)
	SceneManager.change_scene("res://scenes/level_select.tscn")

func _on_back_pressed():
	AudioManager.play_sfx(ui_back_sound)
	PartyManager.clear_players()
	SceneManager.change_scene("res://scenes/main_menu.tscn")
