extends Panel

signal color_changed(player_id: int, new_color: Color)
signal ready_toggled(player_id: int, is_ready: bool)
signal leave_pressed(player_id: int)

@onready var color_preview: TextureRect = $HBoxContainer/ColorPreview
@onready var name_label: Label = $HBoxContainer/VBoxContainer/NameLabel
@onready var device_label: Label = $HBoxContainer/VBoxContainer/DeviceLabel
@onready var ready_check_box: CheckBox = $HBoxContainer/ReadyCheckBox
@onready var leave_button: Button = $HBoxContainer/LeaveButton

var player_id: int = -1
var current_color: Color = Color.WHITE

func _ready():
	ready_check_box.toggled.connect(_on_ready_toggled)
	leave_button.pressed.connect(_on_leave_pressed)

func setup(player_data: PartyManager.PlayerData):
	player_id = player_data.player_id

	name_label.text = player_data.player_name
	var dev_type = player_data.input_device
	var dev_id = player_data.device_id
	var device_name = PartyManager.get_device_display_name(dev_type, dev_id)
	device_label.text = device_name
	update_color(player_data.player_color)
	update_ready(player_data.is_ready)

func update_color(new_color: Color):
	current_color = new_color
	color_preview.modulate = new_color

	# Create a new gradient texture with the color
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([new_color, new_color])
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 40
	texture.height = 40
	color_preview.texture = texture

func update_ready(is_ready: bool):
	ready_check_box.button_pressed = is_ready
	if is_ready:
		modulate = Color(1.2, 1.2, 1.2, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_ready_toggled(button_pressed: bool):
	ready_toggled.emit(player_id, button_pressed)

func _on_leave_pressed():
	leave_pressed.emit(player_id)
