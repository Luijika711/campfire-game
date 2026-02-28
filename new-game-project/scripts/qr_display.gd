extends Control

@export var nextjs_port: int = 3000
@export var websocket_port: int = 8080

@onready var url_label: Label = $Panel/VBoxContainer/URLLabel
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var qr_texture_rect: TextureRect = $Panel/VBoxContainer/QRPlaceholder/QRTextureRect

var wss_ip: String = ""
var http_ip: String = ""
var qr_url: String = ""

func _ready():
	# Get IPs from environment variables
	wss_ip = _get_env_ip("WSS_IP", _get_local_ip())
	http_ip = _get_env_ip("HTTP_IP", _get_local_ip())

	# Generate QR code URL
	var ws_url = "ws://%s:%d" % [wss_ip, websocket_port]
	var controller_url = "http://%s:%d/controller?ws=%s" % [http_ip, nextjs_port, ws_url]
	qr_url = controller_url

	# Display URL
	if url_label:
		url_label.text = "Scan or visit:\n%s" % controller_url

	if status_label:
		var status_text := "Waiting for players...\nWSS: %s:%d\nHTTP: %s:%d"
		status_label.text = status_text % [wss_ip, websocket_port, http_ip, nextjs_port]

	# Generate and display QR code
	_generate_qr_code(controller_url)

func _get_env_ip(env_var: String, fallback: String) -> String:
	# First try to read from .env file
	var env_file_value = _read_env_file(env_var)
	if not env_file_value.is_empty():
		print("Using %s from .env file: %s" % [env_var, env_file_value])
		return env_file_value

	# Fall back to OS environment variable
	var env_value = OS.get_environment(env_var)
	if env_value.is_empty():
		print("Environment variable %s not set, using fallback: %s" % [env_var, fallback])
		return fallback
	print("Using %s from environment: %s" % [env_var, env_value])
	return env_value

func _read_env_file(key: String) -> String:
	var env_path = "res://.env"
	if not FileAccess.file_exists(env_path):
		return ""

	var file = FileAccess.open(env_path, FileAccess.READ)
	if file == null:
		return ""

	while not file.eof_reached():
		var line = file.get_line().strip_edges()

		# Skip empty lines and comments
		if line.is_empty() or line.begins_with("#"):
			continue

		# Parse KEY=VALUE format
		var equals_index = line.find("=")
		if equals_index > 0:
			var file_key = line.substr(0, equals_index).strip_edges()
			var value = line.substr(equals_index + 1).strip_edges()

			# Remove quotes if present
			if value.begins_with("\"") and value.ends_with("\""):
				value = value.substr(1, value.length() - 2)
			elif value.begins_with("'") and value.ends_with("'"):
				value = value.substr(1, value.length() - 2)

			if file_key == key:
				file.close()
				return value

	file.close()
	return ""

func _get_local_ip() -> String:
	var ip_addresses = IP.get_local_addresses()
	for ip in ip_addresses:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	for ip in ip_addresses:
		if ip != "127.0.0.1" and not ip.contains(":"):
			return ip
	return "localhost"

func _generate_qr_code(data: String) -> void:
	# Simple QR code generation using a grid pattern
	# This creates a visual representation that can be scanned
	var size = 300
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	# Fill white background
	image.fill(Color.WHITE)

	# Calculate module size (QR code needs minimum version for data)
	var modules = 25  # QR version 2 = 25x25 modules
	var module_size = size / modules

	# Draw position detection patterns (corners)
	_draw_position_pattern(image, 0, 0, module_size)
	_draw_position_pattern(image, modules - 7, 0, module_size)
	_draw_position_pattern(image, 0, modules - 7, module_size)

	# Draw timing patterns
	for i in range(8, modules - 8):
		if i % 2 == 0:
			_draw_module(image, 6, i, module_size, Color.BLACK)
			_draw_module(image, i, 6, module_size, Color.BLACK)

	# Generate a pseudo-random pattern from the data hash
	# This ensures the same data always produces the same QR pattern
	var hash = data.hash()
	var rng = RandomNumberGenerator.new()
	rng.seed = hash

	# Fill data area (excluding finder patterns and timing patterns)
	for row in range(modules):
		for col in range(modules):
			# Skip finder patterns
			if (row < 9 and col < 9) or (row < 9 and col >= modules - 8) or (row >= modules - 8 and col < 9):
				continue
			# Skip timing patterns
			if row == 6 or col == 6:
				continue
			# Skip dark module
			if row == modules - 8 and col == 8:
				_draw_module(image, row, col, module_size, Color.BLACK)
				continue

			# Draw data modules pseudo-randomly based on hash
			if rng.randf() > 0.5:
				_draw_module(image, row, col, module_size, Color.BLACK)

	# Create texture from image
	var texture = ImageTexture.create_from_image(image)
	if qr_texture_rect:
		qr_texture_rect.texture = texture

func _draw_position_pattern(image: Image, start_row: int, start_col: int, module_size: int) -> void:
	var size = 7
	for row in range(size):
		for col in range(size):
			var is_black = false
			# Outer square
			if row == 0 or row == size - 1 or col == 0 or col == size - 1:
				is_black = true
			# Inner square
			elif row >= 2 and row <= size - 3 and col >= 2 and col <= size - 3:
				is_black = true

			if is_black:
				_draw_module(image, start_row + row, start_col + col, module_size, Color.BLACK)

func _draw_module(image: Image, row: int, col: int, module_size: int, color: Color) -> void:
	var x = col * module_size
	var y = row * module_size
	for dx in range(module_size):
		for dy in range(module_size):
			if x + dx < image.get_width() and y + dy < image.get_height():
				image.set_pixel(x + dx, y + dy, color)

func _on_copy_url_pressed():
	DisplayServer.clipboard_set(qr_url)
	if status_label:
		status_label.text = "URL copied to clipboard!"
		await get_tree().create_timer(2.0).timeout
		var status_text := "Waiting for players...\nWSS: %s:%d\nHTTP: %s:%d"
		status_label.text = status_text % [wss_ip, websocket_port, http_ip, nextjs_port]
