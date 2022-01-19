extends Node


signal cant_connect
signal has_connected
signal has_disconnected
signal packet_error(message)
signal packet_received(message)

var _client := StreamPeerTCP.new()
var _packet_peer_stream := PacketPeerStream.new()
var _is_connected := false setget _read_only, get_is_connected
var _will_connect := false setget _read_only, get_is_connected
var _print_debug_strings := true

var allow_object_decoding := false
var host = "localhost"
var port = 8124


func _init() -> void:
	if ProjectSettings.has_setting("global/lsp_url"):
		var url: String = ProjectSettings.get_setting("global/lsp_url")
		var urlRegex = RegEx.new()
		urlRegex.compile("(?<protocol>https?:\/\/)(?<host>.*?)(?<path>\/.*?)?(?<port>:\\d+)?$")
		host = urlRegex.search(url).get_string("host")
	connect_to_host()


func _process(_delta: float) -> void:
	if _will_connect and not _is_connected:
		return
	if _is_connected and not _client.is_connected_to_host():
		_is_connected = false
		emit_signal("has_disconnected")
		_debug("emit:has_disconnected")
		return
	if _client.is_connected_to_host():
		_poll_server()


# Initiates a connection. Make sure you set `host` and `port` prior
func connect_to_host() -> void:
	_will_connect = true
	var error := _client.connect_to_host(host, port)
	if error != OK:
		push_error("could not connect to host `%s:%s`"%[ host, port ])
		emit_signal("cant_connect")
		return
	if _client.is_connected_to_host():
		_is_connected = true
		_will_connect = false
		_packet_peer_stream.set_stream_peer(_client)
		emit_signal("has_connected")
		put_var(UserProfiles.uuid)
		_debug("emit:has_connected")


# Sends a packet to the server
func put_var(variant,  full_objects := false) -> bool:
	if not _client.is_connected_to_host():
		push_error("client is not connected")
	_packet_peer_stream.put_var(variant, full_objects)
	var error = _packet_peer_stream.get_packet_error()
	if error != OK:
		push_error("could not send packet")
		return false
	return true


# Disconnects from the server
func disconnect_from_host() -> void:
	_client.disconnect_from_host()


func get_is_connected() -> bool:
	return _is_connected


func _read_only(_bogus_var) -> void:
	pass


# Runs on each process tick to check if any new data is available
func _poll_server() -> void:
	while _packet_peer_stream.get_available_packet_count() > 0:
		var variant = _packet_peer_stream.get_var(allow_object_decoding)
		var error := _packet_peer_stream.get_packet_error()
		if error != OK:
			emit_signal("packet_error", variant)
		if variant == null:
			_debug("empty message")
			continue
		emit_signal("packet_received", variant)
		_debug("message", variant)


# Used internally to track socket client state
func _debug(message: String, object = "") -> void:
	if _print_debug_strings:
		prints(message, object)
