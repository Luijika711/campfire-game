extends Node

@export var port: int = 8080
@export var max_players: int = 8

var tcp_server: TCPServer
var peers: Dictionary = {}
var players: Dictionary = {}
var next_player_id: int = 1

signal player_connected(player_id: int, name: String, color: String)
signal player_disconnected(player_id: int)
signal player_input(
	player_id: int, move_x: float, move_y: float, aim_x: float,
	aim_y: float, fire: bool, jump: bool, weapon: int
)

func _ready():
	tcp_server = TCPServer.new()
	var err = tcp_server.listen(port)
	if err != OK:
		push_error("Failed to start TCP server on port %d: %d" % [port, err])
		return

	print("WebSocket server started on port %d" % port)
	print("Connect phones to: ws://%s:%d" % [get_local_ip(), port])

func _process(_delta):
	# Accept new connections
	if tcp_server.is_connection_available():
		var conn = tcp_server.take_connection()
		if conn:
			_create_peer(conn)

	# Poll all peers
	for peer_id in peers.keys():
		var peer = peers[peer_id]
		peer.poll()

		var state = peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count() > 0:
				var packet = peer.get_packet()
				var message = packet.get_string_from_utf8()
				_on_message_received(peer_id, message)
		elif state == WebSocketPeer.STATE_CLOSING:
			pass  # Closing
		elif state == WebSocketPeer.STATE_CLOSED:
			_on_client_disconnected(peer_id)

func _create_peer(conn):
	var peer = WebSocketPeer.new()
	var err = peer.accept_stream(conn)
	if err != OK:
		push_error("Failed to create WebSocket peer")
		conn.disconnect_from_host()
		return

	var peer_id = conn.get_instance_id()
	peers[peer_id] = peer
	print("Client connecting: %d" % peer_id)

func _on_client_disconnected(peer_id: int):
	if not peers.has(peer_id):
		return

	print("Client disconnected: %d" % peer_id)
	peers.erase(peer_id)

	if players.has(peer_id):
		var player_id = players[peer_id].id
		players.erase(peer_id)
		player_disconnected.emit(player_id)

func _on_message_received(peer_id: int, message: String):
	var data = JSON.parse_string(message)
	if data == null:
		push_error("Failed to parse message: %s" % message)
		return

	match data.get("type", ""):
		"join":
			_handle_join(peer_id, data)
		"input":
			_handle_input(peer_id, data)
		"ping":
			_handle_ping(peer_id)

func _handle_join(peer_id: int, data: Dictionary):
	if players.size() >= max_players:
		_send_error(peer_id, "Lobby full (max %d players)" % max_players)
		return

	var player_name = data.get("name", "Player %d" % next_player_id)
	var color = data.get("color", "Red")
	var player_id = next_player_id
	next_player_id += 1

	players[peer_id] = {
		"id": player_id,
		"name": player_name,
		"color": color
	}

	_send_message(peer_id, {
		"type": "connected",
		"player_id": player_id,
		"color": color
	})

	player_connected.emit(player_id, player_name, color)
	print("Player %d joined: %s (%s)" % [player_id, player_name, color])

func _handle_input(peer_id: int, data: Dictionary):
	if not players.has(peer_id):
		return

	var player_id = players[peer_id].id

	# Get analog stick values (0.0 to 1.0)
	var move_x = float(data.get("move_x", 0.0))
	var move_y = float(data.get("move_y", 0.0))
	var aim_x = float(data.get("aim_x", 0.0))
	var aim_y = float(data.get("aim_y", 0.0))

	# Get button states
	var fire = bool(data.get("fire", false))
	var jump = bool(data.get("jump", false))

	# Get weapon selection
	var weapon = int(data.get("weapon", -1))

	player_input.emit(player_id, move_x, move_y, aim_x, aim_y, fire, jump, weapon)

func _handle_ping(peer_id: int):
	_send_message(peer_id, {"type": "pong"})

func _send_message(peer_id: int, data: Dictionary):
	if not peers.has(peer_id):
		return

	var message = JSON.stringify(data)
	var peer = peers[peer_id]
	if peer.get_ready_state() == WebSocketPeer.STATE_OPEN:
		peer.send_text(message)

func _send_error(peer_id: int, error_message: String):
	_send_message(peer_id, {
		"type": "error",
		"message": error_message
	})

	# Close connection after error
	if peers.has(peer_id):
		peers[peer_id].close()

func get_player_info(player_id: int) -> Dictionary:
	for peer_id in players.keys():
		if players[peer_id].id == player_id:
			return players[peer_id]
	return {}

func get_local_ip() -> String:
	var ip_addresses = IP.get_local_addresses()
	for ip in ip_addresses:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	for ip in ip_addresses:
		if ip != "127.0.0.1" and not ip.contains(":"):
			return ip
	return "localhost"
