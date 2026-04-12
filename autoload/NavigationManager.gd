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
	r"^(?<prefix>user:\/\/|res:\/\/|\.*?\/+)#?(?<course>[^\/]+)\/(?<lesson>[^\/]+)\/?(?<lesson_file>[^\.]+\.[^\/]+)?\/?(?<practice>\$.*)?",
)
var _slug_normalization_regex := RegExpGroup.compile(
	r"^#?(?<course>[^\/]+)\/(?<lesson>[^\$]+)\/?(?<practice>\$.*)?",
)
var _lesson_cache := { }


func _init() -> void:
	CourseIndexPaths.build_all_practice_slugs.call_deferred()

	_parse_arguments()
	if _js_available:
		_on_init_setup_js.call_deferred()
	else:
		var initial_url: String = arguments.get("file", "")
		if initial_url != "":
			navigate_to.call_deferred(initial_url)


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


func navigate_to_lesson(course_id: String, lesson_slug: String) -> void:
	navigate_to("%s/%s" % [course_id, lesson_slug])


func navigate_to_practice(course_id: String, lesson_slug: String, practice_id: String) -> void:
	navigate_to("#%s/%s/$%s" % [course_id, lesson_slug, practice_id])


func navigate_to(metadata: String) -> void:
	var regex_result := _url_normalization_regex.search(metadata)
	if not regex_result:
		regex_result = _slug_normalization_regex.search(metadata)

	if not regex_result:
		push_error("`%s` is not a valid bbcode or slug path" % [metadata])
		return

	var normalized := NormalizedUrl.new(regex_result)

	var course_index := CourseIndexPaths.get_course_index_instance(normalized.course_path)
	if not course_index:
		push_error("'%s' is not a valid course" % [normalized.course_path])
		return

	# legacy slugs support
	var legacy_path := normalized.lesson_path
	var lesson_slug := course_index.get_real_slug_from_slug(legacy_path)
	if lesson_slug != legacy_path:
		regex_result = _slug_normalization_regex.search("%s/%s" % [course_index.get_course_id(), lesson_slug])
		normalized = NormalizedUrl.new(regex_result)

	var lesson_path := course_index.get_lesson_path_from_slug(normalized.lesson_path)

	var lesson := get_navigation_resource(lesson_path)
	if not (lesson is BBCodeParser.ParseNode):
		push_error("`%s` is not a lesson" % lesson_path)
		return

	var effective_path := "%s/%s" % [course_index.get_course_id(), normalized.lesson_path]
	if normalized.practice_path != "":
		var practice := course_index.get_practice_from_slug("%s/$%s" % [normalized.lesson_path, normalized.practice_path])
		if not practice is BBCodeParser.ParseNode:
			push_error("'%s' does not have a practice at slug '%s'" % [lesson_path, normalized.practice_path])
			return
		effective_path += "/$%s" % [normalized.practice_path]

	history.push_back(effective_path)
	_push_javascript_state(effective_path)

	navigation_requested.emit()


func get_navigation_resource(resource_id: String) -> BBCodeParser.ParseNode:
	var normalized_url_groups := _url_normalization_regex.search(resource_id)
	var is_slug := false
	if not normalized_url_groups:
		is_slug = true
		normalized_url_groups = _slug_normalization_regex.search(resource_id)
	var is_practice := not normalized_url_groups.get_string("practice").is_empty()

	var bbcode_path := resource_id
	if is_practice:
		bbcode_path = bbcode_path.left(-(normalized_url_groups.get_end("practice")-normalized_url_groups.get_start("practice")+1))
	if is_slug:
		var course_index := CourseIndexPaths.get_course_index_instance(normalized_url_groups.get_string("course"))
		bbcode_path = course_index.get_lesson_path_from_slug(normalized_url_groups.get_string("lesson").trim_suffix("/"))

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
		var course_index := CourseIndexPaths.get_course_index_instance(normalized_url_groups.get_string("course"))
		var lesson_slug := course_index.get_lesson_slug_from_path(bbcode_path)
		return course_index.get_practice_from_slug("%s/%s" % [lesson_slug, normalized_url_groups.get_string("practice")])
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
		navigate_to(url)


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
	var practice_path := ""
	var lesson_file := ""


	func _init(regex_result: RegExMatch) -> void:
		protocol = regex_result.get_string("prefix")
		course_path = regex_result.get_string("course")
		lesson_path = regex_result.get_string("lesson").trim_suffix("/")
		practice_path = regex_result.get_string("practice").substr(1)
		lesson_file = regex_result.get_string("lesson_file")

		if protocol in ["//", "/"]:
			protocol = "res://"


	func get_file_path(with_practices: bool = false) -> String:
		var file_path := "%s%s/%s" % [protocol, course_path, lesson_path]
		if lesson_file != "":
			file_path += "/%s" % [lesson_file]
		if with_practices and practice_path != "":
			file_path += "/$%s" % [practice_path]
		return file_path


	func get_web_url() -> String:
		var url := "%s/%s" % [course_path, lesson_path]
		if lesson_file != "":
			url += "/%s" % [lesson_file]
		if practice_path != "":
			url += "/$%s" % [practice_path]
		return url


	func _to_string() -> String:
		var string := "%s%s/%s" % [protocol, course_path, lesson_path]
		if lesson_file != "":
			string += "/%s" % [lesson_file]
		if practice_path != "":
			string += "/$%s" % [practice_path]
		return string
