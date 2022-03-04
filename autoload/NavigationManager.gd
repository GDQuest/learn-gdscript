extends Node

signal navigation_requested
signal back_navigation_requested
signal outliner_navigation_requested
signal welcome_screen_navigation_requested
signal last_screen_unload_requested
signal all_screens_unload_requested

enum UNLOAD_TYPE { BACK, OUTLINER }

const ERROR_WRONG_UNLOAD_TYPE := "Unsupported unload type in NavigationManager! Unload type: %s"

var history := PoolStringArray()
var current_url := "" setget set_current_url, get_current_url
var is_mobile_platform := OS.get_name() in ["Android", "HTML5", "iOS"]
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
	if get_current_url():
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

	history.remove(history.size() - 1)
	_js_back()

	emit_signal("back_navigation_requested")


func _navigate_to_outliner() -> void:
	# prints("emptying history")
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

	if not normalized.path:
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

	var lesson_path := resource_id.get_base_dir().plus_file("lesson.tres")
	var lesson_data := load(lesson_path) as Lesson

	# If it's not a lesson, it's a practice. May support some other types in future.
	for practice_res in lesson_data.practices:
		if practice_res.practice_id == resource_id:
			return practice_res

	return null


# Handle back requests
func _notification(what: int) -> void:
	if not is_mobile_platform:
		return
	if what in [MainLoop.NOTIFICATION_WM_QUIT_REQUEST, MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST]:
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
	if not rich_text_node.bbcode_enabled:
		return
	if rich_text_node.is_connected("meta_clicked", self, "_open_rich_text_node_meta"):
		return
	rich_text_node.connect("meta_clicked", self, "_open_rich_text_node_meta")


func set_current_url(_new_url: String) -> void:
	pass


func get_current_url():
	return get_history(1)


###############################################################################
#
# JAVASCRIPT INTERFACE
#

var _js_available := OS.has_feature("JavaScript")
var _js_history: JavaScriptObject
var _js_popstate_listener_ref: JavaScriptObject
var _js_window: JavaScriptObject
# We do not want to capture the JS state change when we control it ourselves
# We use this to stop listening on one frame
var _temporary_disable_back_listener := false


func _on_init_setup_js() -> void:
	if not _js_available:
		return
	_js_history = JavaScript.get_interface("history")

	# if the reference doesn't survive the method call, the callback will be dereferenced
	_js_popstate_listener_ref = JavaScript.create_callback(self, "_on_js_popstate")

	_js_window = JavaScript.get_interface("window")
	# warning-ignore:unsafe_method_access
	_js_window.addEventListener("popstate", _js_popstate_listener_ref)

	# warning-ignore:unsafe_property_access
	var url: String = (
		# warning-ignore:unsafe_property_access
		# warning-ignore:unsafe_property_access
		_js_window.location.hash.trim_prefix("#").trim_prefix("/")
		if _js_window.location.hash
		else ""
	)
	if url:
		navigate_to("res://%s" % [url])


# Handles user changing the url manually or pressing back
func _on_js_popstate(_args: Array) -> void:
	# we have set this to `false` either in _js_to_outliner or _js_back, we can set it back to true now
	if _temporary_disable_back_listener:
		return
	_navigate_back()


# Call this from GDScript to synchronize the browser. Safe to call in all environments, will no-op
# when JS is not available.
func _js_back() -> void:
	if not _js_available:
		return
	_disable_popstate_listener()
	# warning-ignore:unsafe_method_access
	_js_history.back()
	_restore_popstate_listener()


# Call this from GDScript to synchronize the browser. Safe to call in all environments, will no-op
# when JS is not available.
func _js_to_outliner() -> void:
	if not _js_available:
		return
	_disable_popstate_listener()
	# warning-ignore:unsafe_method_access
	# warning-ignore:unsafe_method_access
	# warning-ignore:unsafe_property_access
	_js_history.go(-_js_history.length)
	_restore_popstate_listener()


func _disable_popstate_listener() -> void:
	_temporary_disable_back_listener = true


func _restore_popstate_listener() -> void:
	yield(get_tree().create_timer(0.3), "timeout")
	_temporary_disable_back_listener = false


# Call this from GDScript to synchronize the browser. Safe to call in all environments, will no-op
# when JS is not available.
func _push_javascript_state(url: String) -> void:
	if not _js_available:
		return
	# warning-ignore:unsafe_method_access
	_js_history.pushState(url, "", "#" + url)


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
