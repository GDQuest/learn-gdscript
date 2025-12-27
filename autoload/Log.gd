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
var is_joypad := false
var joypad_index := -1

# Godot 4: keep JS interfaces typed as Object to avoid "unsafe Variant" warnings.
var GDQUEST: Object
var _log_lines: Array = []


func _init() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

	if not _js_available:
		log_system_info_if_log_is_empty(get_info())
		return

	GDQUEST = JavaScriptBridge.get_interface("GDQUEST") as Object
	if GDQUEST == null:
		_js_available = false
		log_system_info_if_log_is_empty(get_info())
		return

	trim_if_over_limit()
	log_system_info_if_log_is_empty(get_info())


func _get_js_log_obj() -> Object:
	if not _js_available or GDQUEST == null:
		return null
	return GDQUEST.get("log") as Object


func _js_call(obj: Object, method: String, args: Array = []):
	if obj == null:
		return null
	return obj.callv(method, args)


func write(level: int, properties: Dictionary, message: String) -> void:
	# Optional local printing in debug builds.
	if also_print_to_godot and OS.is_debug_build():
		var level_index := LEVEL.values().find(level)
		var props := {
			"lvl": LEVEL.keys()[level_index] if level_index > -1 else "UNKNOWN",
			"msg": message,
			"prp": properties,
			"sep": "------------"
		}
		var object := "[%lvl]\n%msg\n%prp\n%sep".format(props, "%_")
		match level:
			LEVEL.FATAL, LEVEL.ERROR:
				push_error(object)
			LEVEL.WARN:
				push_warning(object)
			_:
				print(object)

	# Non-web: store lines locally for later file export.
	if not _js_available:
		var line := { "time": "", "level": level, "msg": message }
		for prop_name in properties:
			line[prop_name] = properties[prop_name]
		_log_lines.append(line)
		return

	# Web: forward to GDQUEST logger if available.
	var log_obj := _get_js_log_obj()
	if log_obj == null:
		_js_available = false
		# Fallback to local store so we don't lose logs.
		var line2 := { "time": "", "level": level, "msg": message }
		for prop_name2 in properties:
			line2[prop_name2] = properties[prop_name2]
		_log_lines.append(line2)
		return

	var props_js = godot_dict_to_js_obj(properties)

	var method := "trace"
	match level:
		LEVEL.FATAL: method = "fatal"
		LEVEL.ERROR: method = "error"
		LEVEL.WARN:  method = "warn"
		LEVEL.INFO:  method = "info"
		LEVEL.DEBUG: method = "debug"
		_:           method = "trace"

	_js_call(log_obj, method, [props_js, message])


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


# Prompts a file download to the user in a web environment.
# Safe to call in all environments.
func download() -> void:
	if not _js_available:
		var json_string := ""
		for line in _log_lines:
			json_string += JSON.stringify(line) + "\n"

		var time := Time.get_datetime_dict_from_system()
		var dir_name := "error_logs"
		var file_name := "%d-%02d-%02d-%02d-%02d" % [time.year, time.month, time.day, time.hour, time.minute]

		var dir_path := "user://%s" % dir_name
		DirAccess.make_dir_recursive_absolute(dir_path)

		var full_file_path := "%s/%s.log" % [dir_path, file_name]
		var f := FileAccess.open(full_file_path, FileAccess.WRITE)
		if f == null:
			push_error("could not write log file: %s" % full_file_path)
			return
		f.store_string(json_string)
		f.close()

		var dir_absolute_path := OS.get_user_data_dir().path_join(dir_name) + "/"
		OS.shell_open(dir_absolute_path)
		return

	var log_obj := _get_js_log_obj()
	if log_obj == null:
		return
	_js_call(log_obj, "download")


# Makes sure the log doesn't fill user's localStorage. Safe to call in all environments.
func trim_if_over_limit(max_kilo_bytes := 1000) -> bool:
	if not _js_available:
		return false

	var log_obj := _get_js_log_obj()
	if log_obj == null:
		return false

	var result = log_obj.call("trimIfOverLimit", max_kilo_bytes)

	if result is bool:
		return result
	if result is int:
		return result != 0
	if result is float:
		return result != 0.0
	if result is String:
		var s := result as String
		return s != "0" and s.to_lower() != "false" and not s.is_empty()

	return false


# Logs system info if the log is empty. Safe to call in all environments.
func log_system_info_if_log_is_empty(additional_data := {}) -> void:
	if not _js_available:
		if additional_data.size() > 0:
			trace(additional_data, "INIT")
		return

	var log_obj := _get_js_log_obj()
	if log_obj == null:
		return

	if additional_data.size() > 0:
		var props_js = godot_dict_to_js_obj(additional_data)
		_js_call(log_obj, "logSystemInfoIfLogIsEmpty", [props_js])
	else:
		_js_call(log_obj, "logSystemInfoIfLogIsEmpty")


func godot_dict_to_js_obj(properties: Dictionary):
	var props = JavaScriptBridge.create_object("Object", {})
	for key in properties:
		var value = properties[key]
		if value is Dictionary:
			value = godot_dict_to_js_obj(value as Dictionary)
		elif value is Vector2 or value is Vector3:
			value = "%s" % [value]
		props[key] = value
	return props


func get_info() -> Dictionary:
	var sys_info := {
		"OS": OS.get_name(),
		"datetime": Time.get_datetime_dict_from_system(),
		"screen_size": DisplayServer.screen_get_size(),
		"screen_dpi": DisplayServer.screen_get_dpi(),
		"cores": OS.get_processor_count(),
		"locale": OS.get_locale(),
		"joypad": Input.get_joy_name(joypad_index) if is_joypad else ""
	}

	sys_info["video_adapter"] = RenderingServer.get_video_adapter_name()
	sys_info["video_vendor"] = RenderingServer.get_video_adapter_vendor()

	return sys_info


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	is_joypad = connected
	joypad_index = device_id
