# Autoload that allows us to check if the client is connected to the server
# using websockets.
#
# Use signals and is_connected_to_server() to check for an active connection.
extends Node

signal has_connected
signal has_disconnected
signal cant_connect
signal pong
signal connected

var _client := WebSocketClient.new()
var _is_connecting := false

var is_connected_to_server := false setget _set_read_only
var print_debug_strings := false

var server_url := "ws://localhost:3000"
var reconnect_delay_seconds := 3
var _reconnect_timer := Timer.new()
var ping_delay_seconds := 5
var _ping_timer := Timer.new()
var _ping_message: String
var _pong_was_received := false


func _ready() -> void:
	add_child(_reconnect_timer)
	_reconnect_timer.connect("timeout", self, "_connect_to_server")
	add_child(_ping_timer)
	_ping_timer.connect("timeout", self, "_ping")

	if ProjectSettings.has_setting("global/lsp_url"):
		var url: String = ProjectSettings.get_setting("global/lsp_url")
		if url != "":
			server_url = get_hostname_from_url(url)
	#server_url = "ws://localhost:3000/socket"

	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("server_disconnected", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	_retry_connect(true)


# This method is intended to be called with a yield:
# ```gdscript
# var is_connected: bool = yield(ConnectionChecker.connect_to_server(), "connected")
# ```
func connect_to_server() -> bool:
	if not is_connected_to_server:
		_retry_connect(true)
		yield(self, "has_connected")
	if is_connected_to_server:
		emit_signal("connected")
		return true
	return false


func _connect_to_server() -> void:
	_is_connecting = true
	_print_debug("attempting to connect to", server_url)
	var err := _client.connect_to_url(server_url)
	if err != OK:
		emit_signal("cant_connect")
		_retry_connect()


func _closed(was_clean := false) -> void:
	_print_debug("Connection closed, clean:", was_clean)
	emit_signal("has_disconnected")
	_retry_connect()


func _retry_connect(immediately := false) -> void:
	if _reconnect_timer.is_stopped():
		is_connected_to_server = false
		_is_connecting = false
		_pong_was_received = false
		if immediately:
			_connect_to_server()
		else:
			_print_debug(
				"Unable to connect, will try again in %ss seconds" % [reconnect_delay_seconds]
			)
		_reconnect_timer.start(reconnect_delay_seconds)


func _connected(protocol := "") -> void:
	_print_debug("connected with protocol", protocol)
	_ping_message = "ping from %s" % [UserProfiles.uuid]
	is_connected_to_server = true
	_pong_was_received = true
	_reconnect_timer.stop()
	_ping()
	emit_signal("has_connected")


var _is_probably_offline := false


func _ping():
	_print_debug("Sending: ping")
	if not _pong_was_received:
		is_connected_to_server = false
		_is_probably_offline = true
		_print_debug("we're probably offline")
		emit_signal("has_disconnected")
	elif _is_probably_offline:
		# this means we were virtually disconnected
		_is_probably_offline = false
		is_connected_to_server = true
		_print_debug("we're back online!")
		emit_signal("has_connected")
	if is_connected_to_server:
		_pong_was_received = false
		_client.get_peer(1).put_packet(_ping_message.to_utf8())
		_ping_timer.start(ping_delay_seconds)


func _on_data() -> void:
	# You MUST always use get_peer(1).get_packet to receive data from server, and
	# not get_packet directly when not using the MultiplayerAPI.
	var data := _client.get_peer(1).get_packet().get_string_from_utf8()
	_print_debug("Received:", data)
	if data == "pong":
		_pong_was_received = true
		emit_signal("pong")


# Data transfer and signals emission will only happen when calling this function.
func _process(_delta: float) -> void:
	_client.poll()


# Poor man's read only property
func _set_read_only(_bogus_var) -> void:
	push_error("setting a read only property")


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
		"host": result.get_string("server_url"),
		"port": result.get_string("port"),
		"path": "/socket",  #result.get_string("path"),
		"protocol": "wss" if tls else "ws"
	}
	if props.port:
		props.port = ":" + props.port
	return "{protocol}://{host}{path}{port}".format(props)
