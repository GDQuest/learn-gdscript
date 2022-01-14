extends Node

enum LEVEL {
  TRACE = 10,
  DEBUG = 20,
  INFO = 30,
  WARN = 40,
  ERROR = 50,
  FATAL = 60,
};

var also_print_to_godot := false;
var _js_available := OS.has_feature("JavaScript")
var is_joypad = false
var joypad_index = -1
var GDQUEST: JavaScriptObject


func _init() -> void:
	var _err = Input.connect("joy_connection_changed", self, "_on_joy_connection_changed")
	if not _js_available:
		return
	GDQUEST = JavaScript.get_interface("GDQUEST")
	if not GDQUEST:
		_js_available = false
		return
	trim_if_over_limit()
	log_system_info_if_log_is_empty(get_info())


func write(level: int, properties: Dictionary, message: String) -> void:
	if also_print_to_godot and OS.is_debug_build():
		var level_index := LEVEL.values().find(level)
		var props := {
			"lvl": LEVEL.keys()[level_index] if level_index > -1 else "UNKNOWN",
			"msg": message,
			"prp": properties,
			"sep": "------------"
		}
		var object := "[%lvl]\n%msg\n%prp\n%sep".format(props, "%_")
		match(level):
			LEVEL.FATAL,LEVEL.ERROR:
				push_error(object);
			LEVEL.WARN:
				push_warning(object)
			_:
				print(object)
	if not _js_available:
		return
	var props = godot_dict_to_js_obj(properties)
	match(level):
		LEVEL.FATAL:
			# warning-ignore:unsafe_property_access
			GDQUEST.log.fatal(props, message)
		LEVEL.ERROR:
			# warning-ignore:unsafe_property_access
			GDQUEST.log.error(props, message)
		LEVEL.WARN:
			# warning-ignore:unsafe_property_access
			GDQUEST.log.warn(props, message)
		LEVEL.INFO:
			# warning-ignore:unsafe_property_access
			GDQUEST.log.info(props, message)
		LEVEL.DEBUG:
			# warning-ignore:unsafe_property_access
			GDQUEST.log.debug(props, message)
		_:
			# warning-ignore:unsafe_property_access
			GDQUEST.log.trace(props, message)


func trace(properties: Dictionary, message: String) -> void:
	write(LEVEL.TRACE, properties, message)


func debug(properties: Dictionary, message: String) -> void:
	write(LEVEL.DEBUG, properties, message)


func info(properties: Dictionary, message: String) -> void:
	write(LEVEL.INFO, properties, message)


func warn(properties: Dictionary, message: String) -> void:
	write(LEVEL.WARN, properties, message)


func error(properties: Dictionary, message: String) -> void:
	write(LEVEL.ERROR, properties, message)


func fatal(properties: Dictionary, message: String) -> void:
	write(LEVEL.FATAL, properties, message)


# Prompts a file download to the user in a web environment. Safe to call in all
# environments, will no-op when JS is not available.
func download() -> void:
	if not _js_available:
		return
	# warning-ignore:unsafe_property_access
	GDQUEST.log.download()


# Makes sure the log doesn't fill user's localStorage. Safe to call in all 
# environments, will no-op when JS is not available.
func trim_if_over_limit(max_kilo_bytes := 1000) -> bool:
	if not _js_available:
		return false
	# warning-ignore:unsafe_property_access
	return GDQUEST.log.trimIfOverLimit(max_kilo_bytes)


# Logs system info if the log is empty. Safe to call in all environments, will
# no-op when JS is not available.
func log_system_info_if_log_is_empty(additional_data := {}) -> void:
	if not _js_available:
		return
	if additional_data.size() > 0:
		var props = godot_dict_to_js_obj(additional_data)
		# warning-ignore:unsafe_property_access
		GDQUEST.log.logSystemInfoIfLogIsEmpty(props)
	else:
		# warning-ignore:unsafe_property_access
		GDQUEST.log.logSystemInfoIfLogIsEmpty()


func godot_dict_to_js_obj(properties: Dictionary):
	var props = JavaScript.create_object("Object", {})
	for key in properties:
		var value = properties[key]
		if value is Dictionary:
			value = godot_dict_to_js_obj(value)
		elif value is Vector2 or value is Vector3:
			value = "%s"%[value]
		props[key] = value
	return props


func get_info():
	var info = {
		"OS": OS.get_name(),
		"datetime": OS.get_datetime(),
		"video_driver": OS.get_video_driver_name(OS.get_current_video_driver()),
		"video_adapter": VisualServer.get_video_adapter_name(),
		"video_vendor": VisualServer.get_video_adapter_vendor(),
		"screen_size": OS.get_screen_size(),
		"screen_dpi": OS.get_screen_dpi(),
		"cores": OS.get_processor_count(),
		"locale": OS.get_locale(),
		"joypad": Input.get_joy_name(joypad_index) if is_joypad else "" 
	}
	return info


func _on_joy_connection_changed(device_id, connected):
	is_joypad = connected
	joypad_index = device_id