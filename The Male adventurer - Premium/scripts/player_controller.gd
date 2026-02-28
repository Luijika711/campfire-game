extends CharacterBody2D

# Preload 8 player colors (adjust to your preference)
const PLAYER_COLORS = [
    Color.RED,              # Player 1
    Color.BLUE,             # Player 2
    Color.GREEN,            # Player 3
    Color.YELLOW,           # Player 4
    Color.MAGENTA,          # Player 5
    Color.CYAN,             # Player 6
    Color(1.0, 0.5, 0.0),   # Player 7 - Orange
    Color(0.5, 0.0, 1.0),   # Player 8 - Purple
]

@onready var sprite: Sprite2D = $Sprite2D
var current_player_id: int = 0
var shader_material: ShaderMaterial

func _ready() -> void:
    # Get the sprite's material
    if sprite.material == null:
        sprite.material = ShaderMaterial.new()
    
    shader_material = sprite.material as ShaderMaterial
    
    # Load the shader
    shader_material.shader = load("res://shaders/player_color.gdshader")
    
    # Set initial color (player 1 = red)
    set_player_color(0)

# Call this when assigning a player number or changing color
func set_player_color(player_id: int) -> void:
    if player_id < 0 or player_id >= PLAYER_COLORS.size():
        print("Invalid player ID: ", player_id)
        return
    
    current_player_id = player_id
    var color = PLAYER_COLORS[player_id]
    
    # Update the shader uniform
    shader_material.set_shader_parameter("hair_color", color)
    
    print("Player %d color set to: %s" % [player_id + 1, color])

# Useful for testing - cycle through colors
func _input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_C:
            # Press C to cycle to next color
            current_player_id = (current_player_id + 1) % PLAYER_COLORS.size()
            set_player_color(current_player_id)
        
        if event.keycode == KEY_S:
            # Press S to toggle color sensitivity
            var current_sensitivity = shader_material.get_shader_parameter("color_sensitivity") as float
            var new_sensitivity = current_sensitivity + 0.05
            if new_sensitivity > 1.0:
                new_sensitivity = 0.0
            shader_material.set_shader_parameter("color_sensitivity", new_sensitivity)
            print("Sensitivity: ", new_sensitivity)

# Optional: Set custom color (not from the preset list)
func set_custom_color(color: Color) -> void:
    shader_material.set_shader_parameter("hair_color", color)
    print("Custom color set to: ", color)

# Optional: Adjust sensitivity at runtime
func set_color_sensitivity(sensitivity: float) -> void:
    sensitivity = clamp(sensitivity, 0.0, 1.0)
    shader_material.set_shader_parameter("color_sensitivity", sensitivity)
