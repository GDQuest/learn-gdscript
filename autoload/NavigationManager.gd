extends Node

signal navigation_requested
signal back_navigation_requested
signal outliner_navigation_requested
signal welcome_screen_navigation_requested
signal last_screen_unload_requested
signal all_screens_unload_requested

enum UNLOAD_TYPE { BACK, OUTLINER }

const ERROR_WRONG_UNLOAD_TYPE := "Unsupported unload type in NavigationManager! Unload type: %s"

var history := PackedStringArray()
var current_url := "":
	get = get_current_url, set = set_current_url
var is_mobile_platform := OS.get_name() in ["Android", "Web", "iOS"]
var arguments := { }

var _current_unload_type := -1
var _url_normalization_regex := RegExpGroup.compile(
	r"^(?<prefix>user:\/\/|res:\/\/|\.*?\/+)#?(?<course>.*?)\/(?<lesson>.*)\.(?<extension>t?res|bbcode)(?<practice>#P[0-9]+)?",
)
var _practice_regex := RegEx.create_from_string("#P[0-9]+")
var _lesson_cache := { }


func _init() -> void:
	_parse_arguments()
	if _js_available:
		_on_init_setup_js()
	else:
		var initial_url: String = arguments.get("file", "")
		if initial_url != "":
			navigate_to(initial_url)


func _parse_arguments() -> void:
	arguments = { }
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
		return resource is BBCodeParser.ParseNode and resource.tag in [BBCodeParserData.Tag.LESSON, BBCodeParserData.Tag.PRACTICE]

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
	# prints("emptying history")
	history.resize(0)
	_js_to_outliner()

	emit_signal("outliner_navigation_requested")


func navigate_to_welcome_screen() -> void:
	emit_signal("welcome_screen_navigation_requested")


func navigate_to(metadata: String) -> void:
	var regex_result := _url_normalization_regex.search(metadata)
	if not regex_result:
		push_error("`%s` is not a valid resource or bbcode path" % [metadata])
		return
	
	var normalized := NormalizedUrl.new(regex_result)
	
	var course_index := CourseIndexPaths.get_course_index_instance(normalized.course_path)
	if not course_index:
		push_error("'%s' is not a valid course" % [normalized.course_path])
		return
	
	# legacy practices support
	var full_lesson_path := "%s.%s" % [normalized.lesson_path, normalized.extension]
	var alias := course_index.get_real_slug_from_slug(full_lesson_path)
	if alias != full_lesson_path:
		var new_path := "%s%s/%s" % [normalized.protocol, normalized.course_path, alias]
		regex_result = _url_normalization_regex.search(new_path)
		normalized = NormalizedUrl.new(regex_result)

	if not normalized.lesson_path:
		push_error("`%s` is not a valid path" % metadata)
		return

	var lesson_path := course_index.get_lesson_path_from_slug("%s.%s" % [normalized.lesson_path, normalized.extension])

	var lesson := get_navigation_resource(lesson_path)
	if not (lesson is BBCodeParser.ParseNode):
		push_error("`%s` is not a lesson" % lesson_path)
		return

	var effective_path := lesson_path
	if normalized.practice_index > -1:
		var practice := BBCodeUtils.get_lesson_practice(lesson, normalized.practice_index)
		if not practice is BBCodeParser.ParseNode:
			push_error("'%s' does not have a practice at index '%s'" % [lesson_path, normalized.practice_index])
			return
		effective_path += "#P%s" % [normalized.practice_index]

	history.push_back(effective_path)
	_push_javascript_state(normalized.get_web_url())

	emit_signal("navigation_requested")


func get_navigation_resource(resource_id: String) -> BBCodeParser.ParseNode:
	var practice_index_match := _practice_regex.search(resource_id)
	var is_practice := practice_index_match != null
	
	var bbcode_path := resource_id
	if is_practice:
		bbcode_path = bbcode_path.left(-practice_index_match.strings[0].length())

	var lesson_data: BBCodeParser.ParseNode = null
	if _lesson_cache.has(bbcode_path):
		lesson_data = _lesson_cache[bbcode_path]
	else:
		var _parser := LessonBBCodeParser.new()
		if not FileAccess.file_exists(bbcode_path):
			return null
		var result := _parser.parse_file(bbcode_path)

		if result.errors:
			push_error("NavigationManager.gd:get_navigation_resource(): Parse errors when loading lesson from bbcode file %s:" % bbcode_path)
			for error: BBCodeParser.ParseError in result.errors:
				push_error("  " + error.format())
			return null

		if result.warnings:
			print("NavigationManager.gd:get_navigation_resource(): Parse warnings when loading lesson from bbcode file %s:" % bbcode_path)
			for warning: BBCodeParser.ParseError in result.warnings:
				print("  ", warning.format())

		lesson_data = result.root.children[0]
		_lesson_cache[bbcode_path] = lesson_data

	if is_practice:
		var practice_idx := int(practice_index_match.strings[0].substr(2))
		return BBCodeUtils.get_lesson_practice(lesson_data, practice_idx)

	return lesson_data


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
	if not rich_text_node.bbcode_enabled:
		return
	if rich_text_node.meta_clicked.is_connected(_open_rich_text_node_meta):
		return
	rich_text_node.meta_clicked.connect(_open_rich_text_node_meta)


func set_current_url(_new_url: String) -> void:
	pass


func get_current_url() -> String:
	return get_history(1)

###############################################################################
#
# JAVASCRIPT INTERFACE
#

var _js_available := OS.has_feature("web")
var _js_history: JavaScriptObject
var _js_popstate_listener_ref: JavaScriptObject
var _js_window: JavaScriptObject
# We do not want to capture the JS state change when we control it ourselves
# We use this to stop listening on one frame
var _temporary_disable_back_listener := false


func _on_init_setup_js() -> void:
	if not _js_available:
		return
	_js_history = JavaScriptBridge.get_interface("history")

	# if the reference doesn't survive the method call, the callback will be dereferenced
	_js_popstate_listener_ref = JavaScriptBridge.create_callback(_on_js_popstate)

	_js_window = JavaScriptBridge.get_interface("window")
	@warning_ignore("unsafe_method_access")
	_js_window.addEventListener("popstate", _js_popstate_listener_ref)

	@warning_ignore("unsafe_method_access")
	@warning_ignore("unsafe_property_access")
	var url: String = (
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
	@warning_ignore("unsafe_method_access")
	_js_history.back()
	_restore_popstate_listener()


# Call this from GDScript to synchronize the browser. Safe to call in all environments, will no-op
# when JS is not available.
func _js_to_outliner() -> void:
	if not _js_available:
		return
	_disable_popstate_listener()
	@warning_ignore("unsafe_method_access")
	@warning_ignore("unsafe_property_access")
	_js_history.go(-_js_history.length)
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
	@warning_ignore("unsafe_method_access")
	_js_history.pushState(url, "", "#" + url)


class NormalizedUrl:
	var protocol := ""
	var course_path := ""
	var lesson_path := ""
	var practice_index := -1
	var extension := ""


	func _init(regex_result: RegExMatch) -> void:
		protocol = regex_result.get_string("prefix")
		course_path = regex_result.get_string("course")
		lesson_path = regex_result.get_string("lesson")
		extension = regex_result.get_string("extension")
		
		var practice_string := regex_result.get_string("practice")
		if practice_string:
			practice_index = int(practice_string.substr(2))
		if protocol in ["//", "/"]:
			protocol = "res://"


	func get_file_path() -> String:
		var file_path := "%s%s/%s.%s" % [protocol, course_path, lesson_path, extension]
		if practice_index > -1:
			file_path += "#P" % [practice_index]
		return file_path


	func get_web_url() -> String:
		var url := "%s/%s.%s" % [course_path, lesson_path, extension]
		if practice_index > -1:
			url += "#P%s" % [practice_index]
		return url


	func _to_string() -> String:
		var string := "%s%s/%s"
		if practice_index > -1:
			string += "#P%s" % [practice_index]
		return string
