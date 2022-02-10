extends Panel

const TEXTURE_DISCONNECTED := preload("robot_tutor_no_connection.png")
const TEXTURE_CONNECTED := preload("robot_tutor_running_code.svg")

onready var _texture_rect := $Layout/TextureRect as TextureRect
onready var _server_down_label := $Layout/ServerDownLabel as Label


func _ready() -> void:
	ConnectionChecker.connect("has_connected", self, "_set_is_connected", [true])
	ConnectionChecker.connect("has_disconnected", self, "_set_is_connected", [false])
	connect("visibility_changed", self, "_on_visibility_changed")
	_server_down_label.text = tr("Can't reach the server. The tests will be less precise.")


func _set_is_connected(connected: bool) -> void:
	if connected:
		_texture_rect.texture = TEXTURE_CONNECTED
	else:
		_texture_rect.texture = TEXTURE_DISCONNECTED
	_server_down_label.visible = not connected


func _on_visibility_changed() -> void:
	if visible:
		_set_is_connected(ConnectionChecker.is_connected_to_server())
