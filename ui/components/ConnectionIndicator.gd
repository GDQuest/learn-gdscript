extends TextureRect


const TEXTURE_DISCONNECTED := preload("connectionIndicator_OFF.png")
const TEXTURE_CONNECTED := preload("connectionIndicator_ON.png")


func _ready() -> void:
	ConnectionChecker.connect("has_connected", self, "_set_is_connected", [true])
	ConnectionChecker.connect("has_disconnected", self, "_set_is_connected", [false])
	_set_is_connected(ConnectionChecker.is_connected_to_server())


func _set_is_connected(connected: bool) -> void:
	if connected:
		texture = TEXTURE_CONNECTED
		hint_tooltip = tr("Connected to the server.")
	else:
		texture = TEXTURE_DISCONNECTED
		hint_tooltip = tr("Can't reach the server. The server might be down, or your internet may be down.")
