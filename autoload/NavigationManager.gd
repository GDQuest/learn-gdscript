extends Node

signal navigation_requested
signal back_navigation_requested
signal outliner_navigation_requested
signal welcome_screen_navigation_requested
signal last_screen_unload_requested
signal all_screens_unload_requested

enum UNLOAD_TYPE { BACK, OUTLINER }

const ERROR_WRONG_UNLOAD_TYPE := "Unsupported unload type in NavigationManager! Unload type: %s"

var history: PackedStringArray = PackedStringArray()

# Godot 4: replace setget with property setter/getter.
var _current_url: String = ""
var current_url: String:
	get:
		return get_current_url()
	set(value):
		set_current_url(value)

var is_mobile_platform := OS.get_name() in ["Android", "Web", "iOS"]
var arguments := {}

var _current_unload_type := -1
var _url_normalization_regex := RegExpGroup.compile(
	"^(?<prefix>user:\\/\\/|res:\\/\\/|\\.*?\\/+)(?<url>.*)\\.(?<extension>t?res)"
)

func _init() -> void:
	_parse_arguments()
	if _js_available:
		_on_init_setup_js()
	else:
		var initial_url: String = arguments.get("file", "")
		if initial_url != "":
			navigate_to(initial_url)


func _parse_arguments() -> void:
	arguments = {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var arg_tuple = argument.split("=")
			var key: String = arg_tuple[0].lstrip("--").to_lower()
			var value: String = arg_tuple[1]
			arguments[key] = value


# Checks if any resource with active user data is about to be closed.
#
# If the current screen is a Practice it might have code edited. If the current
# screen is a Lesson it might be shadowing a Practice.
func _is_unload_confirmation_required() -> bool:
	# For the home screen and outliner, get_current_url() returns "". We use
	# that to return false for those screens.
	if get_current_url() != "":
		var resource = get_navigation_resource(get_current_url())
		return resource is Practice or resource is Lesson

	return false


func get_history(n := 1) -> String:
	if n > history.size():
		return ""
	return history[history.size() - n]


# Called by any screen that is to be unloaded (but it is not safe/user denied)
func deny_unload() -> void:
	_current_unload_type = -1


# Called by any screen that is to be unloaded
func confirm_unload() -> void:
	match _current_unload_type:
		UNLOAD_TYPE.BACK:
			_navigate_back()
		UNLOAD_TYPE.OUTLINER:
			_navigate_to_outliner()
		_:
			printerr(ERROR_WRONG_UNLOAD_TYPE % _current_unload_type)

	_current_unload_type = -1


# Call to navigate back from within the app. If the user is about to lose data,
# they'll get a popup window preventing them from navigating back until they
# confirm they want to leave the screen.
#
# For browser-only navigation, use _navigate_back() instead.
func navigate_back() -> void:
	if _is_unload_confirmation_required():
		_current_unload_type = UNLOAD_TYPE.BACK
		emit_signal("last_screen_unload_requested")
		return

	_navigate_back()


func navigate_to_outliner() -> void:
	if _is_unload_confirmation_required():
		_current_unload_type = UNLOAD_TYPE.OUTLINER
		emit_signal("all_screens_unload_requested")
		return

	_navigate_to_outliner()


# Navigates back instantly, without confirmation popups. Use this for browser
# navigation.
func _navigate_back() -> void:
	# Nothing to go back to, open the outliner.
	if history.size() < 2:
		navigate_to_outliner()
		return

	history.remove_at(history.size() - 1)
	_js_back()

	emit_signal("back_navigation_requested")


func _navigate_to_outliner() -> void:
	history.resize(0)
	_js_to_outliner()

	emit_signal("outliner_navigation_requested")


func navigate_to_welcome_screen() -> void:
	emit_signal("welcome_screen_navigation_requested")


func navigate_to(metadata: String) -> void:
	var regex_result := _url_normalization_regex.search(metadata)
	if not regex_result:
		push_error("`%s` is not a valid resource path" % [metadata])
		return
	var normalized := NormalizedUrl.new(regex_result)

	if normalized.path == "":
		push_error("`%s` is not a valid path" % metadata)
		return

	var file_path := normalized.get_file_path()

	var resource := get_navigation_resource(file_path)
	if not (resource is Resource):
		push_error("`%s` is not a resource" % file_path)
		return

	history.push_back(file_path)
	_push_javascript_state(normalized.get_web_url())

	emit_signal("navigation_requested")


func get_navigation_resource(resource_id: String) -> Resource:
	var is_lesson := resource_id.ends_with("lesson.tres")

	if is_lesson:
		return load(resource_id) as Resource

	var lesson_path := resource_id.get_base_dir().path_join("lesson.tres")
	var lesson_data := load(lesson_path) as Lesson
	if lesson_data == null:
		return null

	# If it's not a lesson, it's a practice. May support some other types in future.
	for practice_res in lesson_data.practices:
		if practice_res.practice_id == resource_id:
			return practice_res

	return null


# Handle back requests
func _notification(what: int) -> void:
	if not is_mobile_platform:
		return
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		navigate_back()


func _open_rich_text_node_meta(metadata: String) -> void:
	if (
		metadata.begins_with("https://")
		or metadata.begins_with("http://")
		or metadata.begins_with("//")
	):
		OS.shell_open(metadata)
		return


func connect_rich_text_node(rich_text_node: RichTextLabel) -> void:
	# Godot 4: RichTextLabel still supports BBCode, but property is `bbcode_enabled`.
	if not rich_text_node.bbcode_enabled:
		return

	var cb := Callable(self, "_open_rich_text_node_meta")
	if rich_text_node.meta_clicked.is_connected(cb):
		return
	rich_text_node.meta_clicked.connect(cb)


func set_current_url(new_url: String) -> void:
	_current_url = new_url


func get_current_url() -> String:
	# Historical behavior: current url is the last entry.
	return get_history(1)


###############################################################################
#
# JAVASCRIPT INTERFACE
#

var _js_available := OS.has_feature("web")
var _js_history: Object
var _js_popstate_listener_ref
var _js_window: Object

# We do not want to capture the JS state change when we control it ourselves.
# We use this to stop listening on one frame.
var _temporary_disable_back_listener := false


func _on_init_setup_js() -> void:
	if not _js_available:
		return

	_js_history = JavaScriptBridge.get_interface("history") as Object
	_js_window = JavaScriptBridge.get_interface("window") as Object
	if _js_history == null or _js_window == null:
		_js_available = false
		return

	# Keep a reference so the callback isn't GC'd.
	_js_popstate_listener_ref = JavaScriptBridge.create_callback(Callable(self, "_on_js_popstate"))
	_js_window.call("addEventListener", "popstate", _js_popstate_listener_ref)

	var location_obj := _js_window.get("location") as Object
	var url := ""
	if location_obj != null:
		var hash_val = location_obj.get("hash")
		if hash_val is String:
			var h := hash_val as String
			url = h.trim_prefix("#").trim_prefix("/")

	if url != "":
		navigate_to("res://%s" % [url])


# Handles user changing the url manually or pressing back
func _on_js_popstate(_args: Array) -> void:
	# We have set this to true either in _js_to_outliner or _js_back; we can restore listening now.
	if _temporary_disable_back_listener:
		return
	_navigate_back()


# Call this from GDScript to synchronize the browser. Safe to call in all environments, will no-op
# when JS is not available.
func _js_back() -> void:
	if not _js_available:
		return
	_disable_popstate_listener()
	_js_history.call("back")
	_restore_popstate_listener()


# Call this from GDScript to synchronize the browser. Safe to call in all environments, will no-op
# when JS is not available.
func _js_to_outliner() -> void:
	if not _js_available:
		return
	_disable_popstate_listener()

	var len_val = _js_history.get("length")
	var length_i := 0

	if len_val is int:
		length_i = len_val
	elif len_val is float:
		length_i = len_val as int

	_js_history.call("go", -length_i)
	_restore_popstate_listener()


func _disable_popstate_listener() -> void:
	_temporary_disable_back_listener = true


func _restore_popstate_listener() -> void:
	await get_tree().create_timer(0.3).timeout
	_temporary_disable_back_listener = false


# Call this from GDScript to synchronize the browser. Safe to call in all environments, will no-op
# when JS is not available.
func _push_javascript_state(url: String) -> void:
	if not _js_available:
		return
	_js_history.call("pushState", url, "", "#" + url)


class NormalizedUrl:
	var protocol := ""
	var path := ""
	var extension := ""

	func _init(regex_result: RegExMatch) -> void:
		protocol = regex_result.get_string("prefix")
		path = regex_result.get_string("url")
		extension = regex_result.get_string("extension")
		if protocol in ["//", "/"]:
			protocol = "res://"

	func get_file_path() -> String:
		return "%s%s.%s" % [protocol, path, extension]

	func get_web_url() -> String:
		return "%s.%s" % [path, extension]

	func _to_string() -> String:
		return protocol + path
