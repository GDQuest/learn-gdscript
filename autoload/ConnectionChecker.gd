# Autoload that allows us to check if the client is connected to the server
# using sockets.
#
# Use signals and is_connected_to_server() to check for an active connection.
extends Node

signal has_connected
signal has_disconnected
signal cant_connect
signal connected

var _client := WebSocketClient.new()
var _is_connecting := false

var is_connected_to_server := false setget _set_read_only
var print_debug_strings := true

var server_url := "ws://localhost:3000"
var reconnect_delay_seconds := 3
var timer := Timer.new()


func _init() -> void:
	add_child(timer)
	timer.connect("timeout", self, "_connect_to_server")

	if ProjectSettings.has_setting("global/lsp_url"):
		var url: String = ProjectSettings.get_setting("global/lsp_url")
		if url != "":
			server_url = get_hostname_from_url(url)

	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	_connect_to_server()


# This method is intended to be called with a yield:
# ```gdscript
# var is_connected: bool = yield(ConnectionChecker.connect_to_server(), "connected")
# ```
func connect_to_server() -> bool:
	if not is_connected_to_server:
		_connect_to_server()
		yield(self, "has_connected")
	if is_connected_to_server:
		emit_signal("connected")
		return true
	return false


func _connect_to_server() -> void:
	if _is_connecting:
		_print_debug("request to connect, but already connecting")
		return
	_is_connecting = true
	timer.stop()
	_print_debug("attempting to connect to", server_url)
	var err := _client.connect_to_url(server_url)
	if err != OK:
		emit_signal("cant_connect")
		_retry_connect()


func _closed(was_clean := false) -> void:
	_print_debug("Connection closed, clean:", was_clean)
	emit_signal("has_disconnected")
	_retry_connect()

func _retry_connect() -> void:
	if timer.is_stopped():
		is_connected_to_server = false
		_is_connecting = false
		push_error("Unable to connect, will try again in %ss seconds" % [reconnect_delay_seconds])
		timer.start(reconnect_delay_seconds)	

func _connected(protocol := "") -> void:
	_print_debug("connected with protocol", protocol)
	var message = "ping from %s"%[UserProfiles.uuid]
	_client.get_peer(1).put_packet(message.to_utf8())
	emit_signal("has_connected")


func _on_data() -> void:
	# You MUST always use get_peer(1).get_packet to receive data from server, and
	# not get_packet directly when not using the MultiplayerAPI.
	_print_debug("Got data from server: ", _client.get_peer(1).get_packet().get_string_from_utf8())


# Data transfer and signals emission will only happen when calling this function.
func _process(_delta: float) -> void:
	_client.poll()


# Poor man's read only property
func _set_read_only(_bogus_var) -> void:
	pass


# Used internally to track socket client state
func _print_debug(message: String, object = "") -> void:
	if print_debug_strings:
		prints(message, object)


# Extracts server url ad port from a string
func get_hostname_from_url(url: String, tls := true) -> String:
	var urlRegex := RegEx.new()
	urlRegex.compile("(?<protocol>https?:\/\/)(?<server_url>.*?)(?<path>\/.*?)?(?<port>:\\d+)?$")
	var result := urlRegex.search(url)
	if result == null:
		return ""
	var props := {
		"host" : result.get_string("server_url"),
		"port" : result.get_string("port"),
		"path" : '/socket',#result.get_string("path"),
		"protocol" : "wss" if tls else "ws"
	}
	if props.port:
		props.port = ":"+props.port
	return "{protocol}://{host}{path}{port}".format(props)
