extends Control

@export var nextjs_port: int = 3000
@export var websocket_port: int = 8080

@onready var url_label: Label = $Panel/URLLabel
@onready var status_label: Label = $Panel/StatusLabel
@onready var http_request: HTTPRequest = $HTTPRequest
@onready var qr_texture_rect: TextureRect = $Panel/QRPlaceholder/QRBackground/QRTextureRect

var wss_ip: String = ""
var http_ip: String = ""
var qr_url: String = ""

func _ready():
	wss_ip = _get_env_ip("WSS_IP", _get_local_ip())
	http_ip = _get_env_ip("HTTP_IP", _get_local_ip())

	var ws_url = "ws://%s:%d" % [wss_ip, websocket_port]
	var controller_url = "http://%s:%d/controller?ws=%s" % [http_ip, nextjs_port, ws_url]
	qr_url = controller_url

	if url_label:
		url_label.text = "Scan or visit:\n%s" % controller_url

	if status_label:
		status_label.text = "Waiting for players..."

	_fetch_qr_code(controller_url)

func _get_env_ip(env_var: String, fallback: String) -> String:
	var env_file_value = _read_env_file(env_var)
	if not env_file_value.is_empty():
		return env_file_value
	var env_value = OS.get_environment(env_var)
	if env_value.is_empty():
		return fallback
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
		if line.is_empty() or line.begins_with("#"):
			continue
		var equals_index = line.find("=")
		if equals_index > 0:
			var file_key = line.substr(0, equals_index).strip_edges()
			var value = line.substr(equals_index + 1).strip_edges()
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

func _fetch_qr_code(data: String) -> void:
	var encoded_data = data.uri_encode()
	var api_url = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&format=png&data=%s" % encoded_data

	http_request.request_completed.connect(_on_qr_request_completed, CONNECT_ONE_SHOT)
	var error = http_request.request(api_url)
	if error != OK:
		push_warning("QR API request failed, generating fallback")
		_generate_fallback_qr(data)

func _on_qr_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200 and body.size() > 0:
		var image = Image.new()
		var err = image.load_png_from_buffer(body)
		if err == OK:
			var texture = ImageTexture.create_from_image(image)
			if qr_texture_rect:
				qr_texture_rect.texture = texture
			return

	push_warning("QR API failed (code %d), using fallback" % response_code)
	_generate_fallback_qr(qr_url)

func _generate_fallback_qr(data: String) -> void:
	# Fallback: show URL prominently if API is unavailable
	if qr_texture_rect:
		var size = 300
		var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
		image.fill(Color(0.15, 0.12, 0.1))

		var texture = ImageTexture.create_from_image(image)
		qr_texture_rect.texture = texture

	if url_label:
		url_label.text = "Visit this URL on your phone:\n%s" % data

	if status_label:
		status_label.text = "QR unavailable - use URL above"

func _on_copy_url_pressed():
	DisplayServer.clipboard_set(qr_url)
	if status_label:
		status_label.text = "URL copied to clipboard!"
		await get_tree().create_timer(2.0).timeout
		status_label.text = "Waiting for players..."
