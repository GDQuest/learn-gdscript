extends Node

onready var is_fullscreen := OS.window_fullscreen setget set_is_fullscreen, get_is_fullscreen


var _js_on_fullscreen_ref: JavaScriptObject

func _init() -> void:
	if not OS.has_feature('JavaScript'):
		return
	# full screen does not work in the browser, remove the action entirely
	InputMap.erase_action("toggle_full_screen")
	_js_on_fullscreen_ref = JavaScript.create_callback(self, "_on_js_fullscreen")
	var GDQUEST := JavaScript.get_interface("GDQUEST")
	# warning-ignore:unsafe_property_access
	GDQUEST.events.onFullScreen.connect(_js_on_fullscreen_ref)


func _on_js_fullscreen(_args: Array) -> void:
	var _is_it: bool = _args[0]; # full screen state
	var _was_it_ours: bool = _args[1]; #triggered through button or F11
	Events.emit_signal("fullscreen_toggled")


func set_is_fullscreen(value: bool) -> void:
	if OS.has_feature('JavaScript'):
		push_error("browsers do not support setting full screen from a webgl context")
		return
	is_fullscreen = value
	OS.window_fullscreen = is_fullscreen
	Events.emit_signal("fullscreen_toggled")


func get_is_fullscreen() -> bool:
	if not OS.has_feature('JavaScript'):
		return is_fullscreen
	var GDQUEST := JavaScript.get_interface("GDQUEST")
	# warning-ignore:unsafe_property_access
	return GDQUEST.fullScreen.isIt()
