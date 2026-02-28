extends Control

signal level_selected(map_id: String)

@onready var thumbnail: TextureRect = $VBoxContainer/Thumbnail
@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var select_button: Button = $VBoxContainer/SelectButton

var map_id: String = ""

func _ready():
	select_button.pressed.connect(_on_select_pressed)

func setup(p_map_id: String, map_data: MapData):
	map_id = p_map_id
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
