extends Control

signal level_selected(map_id: String)

@onready var thumbnail: TextureRect = $Panel/VBoxContainer/Thumbnail
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var description_label: Label = $Panel/VBoxContainer/DescriptionLabel
@onready var select_button: Button = $Panel/VBoxContainer/SelectButton

var map_id: String = ""
var pending_setup: Dictionary = {}

func _ready():
	select_button.pressed.connect(_on_select_pressed)

	# If setup was called before _ready, apply it now
	if pending_setup:
		_apply_setup(pending_setup.map_id, pending_setup.map_data)
		pending_setup.clear()

func setup(p_map_id: String, map_data: MapData):
	map_id = p_map_id

	# If _ready hasn't finished yet, store for later
	if not is_node_ready():
		pending_setup = {"map_id": p_map_id, "map_data": map_data}
	else:
		_apply_setup(p_map_id, map_data)

func _apply_setup(_p_map_id: String, map_data: MapData):
	title_label.text = map_data.map_name
	description_label.text = map_data.description

	# Generate thumbnail color based on map name hash
	var hash_val = map_data.map_name.hash()
	var color = Color(
		float(hash_val & 0xFF) / 255.0,
		float((hash_val >> 8) & 0xFF) / 255.0,
		float((hash_val >> 16) & 0xFF) / 255.0,
		1.0
	)
	thumbnail.modulate = color

func _on_select_pressed():
	emit_signal("level_selected", map_id)
