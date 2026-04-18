extends Node

enum LEVEL {
	TRACE = 10,
	DEBUG = 20,
	INFO = 30,
	WARN = 40,
	ERROR = 50,
	FATAL = 60,
}

var also_print_to_godot := false
var _js_available := OS.has_feature("web")
var is_joypad = false
var joypad_index := -1
var GDQUEST: JavaScriptObject
var _log_lines := []


func _init() -> void:
	var _err = Input.joy_connection_changed.connect(_on_joy_connection_changed)
	if not _js_available:
		log_system_info_if_log_is_empty(get_info())

	GDQUEST = JavaScriptBridge.get_interface("GDQUEST")
	if not GDQUEST:
		_js_available = false
		return
	trim_if_over_limit()
	log_system_info_if_log_is_empty(get_info())


func write(level: int, properties: Dictionary, message: String) -> void:
	if also_print_to_godot and OS.is_debug_build():
		var level_index := LEVEL.values().find(level)
		var print_props := {
			"lvl": LEVEL.keys()[level_index] if level_index > -1 else "UNKNOWN",
			"msg": message,
			"prp": properties,
			"sep": "------------",
		}
		var object := "[%lvl]\n%msg\n%prp\n%sep".format(print_props, "%_")
		match (level):
			LEVEL.FATAL, LEVEL.ERROR:
				push_error(object)
			LEVEL.WARN:
				push_warning(object)
			_:
				print(object)
	if not _js_available:
		var line := { "time": "", "level": level, "msg": message }
		for propName in properties:
			line[propName] = properties[propName]
		_log_lines.append(line)
		return
	var props = godot_dict_to_js_obj(properties)
	@warning_ignore_start("unsafe_property_access")
	@warning_ignore_start("unsafe_method_access")
	match (level):
		LEVEL.FATAL:
			GDQUEST.log.fatal(props, message)
		LEVEL.ERROR:
			GDQUEST.log.error(props, message)
		LEVEL.WARN:
			GDQUEST.log.warn(props, message)
		LEVEL.INFO:
			GDQUEST.log.info(props, message)
		LEVEL.DEBUG:
			GDQUEST.log.debug(props, message)
		_:
			GDQUEST.log.trace(props, message)
	@warning_ignore_restore("unsafe_property_access")
	@warning_ignore_restore("unsafe_method_access")


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
# environments
func download() -> void:
	if not _js_available:
		var json_string := ""
		for line in _log_lines:
			json_string += JSON.stringify(line) + "\n"
		var time := Time.get_datetime_dict_from_system()
		var dir_name := "error_logs"
		var file_name := "%d-%02d-%02d-%02d-%02d" % [time.year, time.month, time.day, time.hour, time.minute]
		var ok := DirAccess.make_dir_recursive_absolute("user://%s/" % [dir_name])
		if ok != OK:
			push_error("could not create %s" % [dir_name])
		var file := FileAccess.open("user://%s/%s.log" % [dir_name, file_name], FileAccess.WRITE)
		file.store_string(json_string)
		file.close()
		var dir_absolute_path := OS.get_user_data_dir().path_join("error_logs") + "/"
		OS.shell_open(dir_absolute_path)
		return
	@warning_ignore("unsafe_method_access")
	@warning_ignore("unsafe_property_access")
	GDQUEST.log.download()


# Makes sure the log doesn't fill user's localStorage. Safe to call in all
# environments, will no-op when JS is not available.
func trim_if_over_limit(max_kilo_bytes := 1000) -> bool:
	if not _js_available:
		return false
	# warning-ignore:unsafe_property_access
	@warning_ignore("unsafe_method_access")
	@warning_ignore("unsafe_property_access")
	return GDQUEST.log.trimIfOverLimit(max_kilo_bytes)


# Logs system info if the log is empty. Safe to call in all environments
func log_system_info_if_log_is_empty(additional_data := { }) -> void:
	@warning_ignore_start("unsafe_method_access")
	@warning_ignore_start("unsafe_property_access")
	if not _js_available:
		if additional_data.size() > 0:
			trace(additional_data, 'INIT')
	elif additional_data.size() > 0:
		var props = godot_dict_to_js_obj(additional_data)
		GDQUEST.log.logSystemInfoIfLogIsEmpty(props)
	else:
		GDQUEST.log.logSystemInfoIfLogIsEmpty()
	@warning_ignore_restore("unsafe_method_access")
	@warning_ignore_restore("unsafe_property_access")


func godot_dict_to_js_obj(properties: Dictionary):
	var props = JavaScriptBridge.create_object("Object", { })
	for key in properties:
		var value = properties[key]
		if value is Dictionary:
			value = godot_dict_to_js_obj(value as Dictionary)
		elif value is Vector2 or value is Vector3:
			value = "%s" % [value]
		props[key] = value
	return props


func get_info() -> Dictionary:
	var local_info := {
		"OS": OS.get_name(),
		"datetime": Time.get_datetime_dict_from_system(),
		"video_driver": RenderingServer.get_current_rendering_driver_name(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"video_vendor": RenderingServer.get_video_adapter_vendor(),
		"screen_size": DisplayServer.screen_get_size(),
		"screen_dpi": DisplayServer.screen_get_dpi(),
		"locale": OS.get_locale(),
		"joypad": Input.get_joy_name(joypad_index) if is_joypad else "",
	}
	return local_info


func _on_joy_connection_changed(device_id, connected):
	is_joypad = connected
	joypad_index = device_id
