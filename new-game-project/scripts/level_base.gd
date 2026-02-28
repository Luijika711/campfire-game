extends Node2D
class_name LevelBase

@export var level_name: String = "Unnamed Level"
@export var description: String = ""
@export_range(0.0, 1.0) var background_hue_shift: float = 0.0
@export_range(0.0, 2.0) var background_saturation: float = 1.0
@export_range(0.0, 2.0) var background_brightness: float = 1.0

const HUE_SHIFT_SHADER_CODE := """
shader_type canvas_item;
uniform float hue_shift : hint_range(0.0, 1.0) = 0.0;
uniform float saturation_scale : hint_range(0.0, 2.0) = 1.0;
uniform float brightness_scale : hint_range(0.0, 2.0) = 1.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	vec3 hsv = rgb2hsv(color.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	hsv.y = clamp(hsv.y * saturation_scale, 0.0, 1.0);
	hsv.z = clamp(hsv.z * brightness_scale, 0.0, 1.0);
	COLOR = vec4(hsv2rgb(hsv), color.a);
}
"""

func _ready() -> void:
	_setup_parallax()
	_apply_hue_shift()

func _setup_parallax() -> void:
	var parallax_bg = find_child("ParallaxBackground")
	if not parallax_bg:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var min_zoom := 0.3
	var needed_height := viewport_size.y / min_zoom
	for layer in parallax_bg.get_children():
		if not layer is ParallaxLayer:
			continue
		layer.motion_scale.y = 0.0
		for sprite in layer.get_children():
			if sprite is Sprite2D and sprite.texture:
				var tex_size = sprite.texture.get_size()
				var scale_factor := maxf(needed_height / tex_size.y, 1.0)
				sprite.scale = Vector2(scale_factor, scale_factor)
				sprite.centered = true
				layer.motion_mirroring.x = tex_size.x * scale_factor

func _apply_hue_shift() -> void:
	if background_hue_shift == 0.0 and background_saturation == 1.0 and background_brightness == 1.0:
		return
	var shader := Shader.new()
	shader.code = HUE_SHIFT_SHADER_CODE
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("hue_shift", background_hue_shift)
	mat.set_shader_parameter("saturation_scale", background_saturation)
	mat.set_shader_parameter("brightness_scale", background_brightness)
	var parallax_bg = find_child("ParallaxBackground")
	if parallax_bg:
		for layer in parallax_bg.get_children():
			for sprite in layer.get_children():
				if sprite is Sprite2D:
					sprite.material = mat
		return
	var bg_sprite = find_child("Background")
	if bg_sprite and bg_sprite is Sprite2D:
		bg_sprite.material = mat
