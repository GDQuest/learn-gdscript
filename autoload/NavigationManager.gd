## Centralizes the navigation logic between the welcome screen, lessons, and
## practices.
##
## The input for navigation can be one of several types of strings:
## - A compact course location like L5.P1 (short for lesson 5, practice 1)
## - The URL slug of a lesson or practice like "your-first-function"
## - The full Godot path to a resource like "res://course/lesson-5-your-first-function/lesson.bbcode"
##
## Lessons are BBCode files parsed into data structures. This script resolves
## the input strings to a lesson or practice parsed node and emits a signal for
## the UI to display it.
##
## On desktop, you can use command line arguments like --go-to=...
## In a web browser, the URL hash might look like "#L5.P1" or be lesson and
## practice slugs like "your-first-function/a-function-to-draw-squares".
##
## We also use these slugs with a slash separator as our canonical
## lesson/practice URL. This is kept in history so the UI and browser can refer
## to the same location.
extends Node

signal navigation_requested
signal back_navigation_requested
signal outliner_navigation_requested
signal welcome_screen_navigation_requested
signal last_screen_unload_requested
signal all_screens_unload_requested

enum UNLOAD_TYPE {
	BACK,
	OUTLINER,
}

const ERROR_WRONG_UNLOAD_TYPE := "Unsupported unload type in NavigationManager! Unload type: %s"

var history := PackedStringArray()
var current_url := "":
	get = get_current_url, set = set_current_url
var is_mobile_platform := OS.get_name() in ["Android", "Web", "iOS"]
var arguments := { }

var _current_unload_type := -1
## This regex looks for patterns like L1.P2, L3P1 or L5, ignoring case. This is
## used to quickly access specific lessons and practices in the course.
var _regex_compact_course_location := RegExpGroup.compile(
	r"(?i)^l(?<lesson_number>\d+)(?:\.?p(?<practice_number>\d+))?$"
)
var _regex_url_normalization := RegExpGroup.compile(
	r"^(?<prefix>user:\/\/|res:\/\/|\.*?\/+)(?<course>[^\/]+)\/(?<lesson>[^\/]+)\/?(?<lesson_file>[^\.]+\.[^\/]+)?\/?(?<practice>.*)?",
)
var _regex_slug_normalization := RegExpGroup.compile(r"^(?<lesson>[^\/]+)\/?(?<practice>.*)?")
var _lesson_cache := { }


func _init() -> void:
	# Parse command line arguments
	arguments = { }
	for argument in OS.get_cmdline_user_args():
		if argument.find("=") > -1:
			var arg_tuple = argument.split("=")
			var key: String = arg_tuple[0].lstrip("--").to_lower()
			var value: String = arg_tuple[1]
			arguments[key] = value

	if _js_available:
		_on_init_setup_js.call_deferred()
	else:
		var initial_url: String = arguments.get("go-to", "")
		if initial_url != "":
			navigate_to.call_deferred(initial_url)


func _ready() -> void:
	TranslationManager.translation_changed.connect(_on_translation_changed)


# Checks if any resource with active user data is about to be closed.
#
# If the current screen is a Practice it might have code edited. If the current
# screen is a Lesson it might be shadowing a Practice.
func _is_unload_confirmation_required() -> bool:
	# For the home screen and outliner, get_current_url() returns "". We use
	# that to return false for those screens.
	if get_current_url():
		var resource = get_navigation_resource(get_current_url())
		return (
			resource is BBCodeParser.ParseNode
			and resource.tag in [BBCodeParserData.Tag.LESSON, BBCodeParserData.Tag.PRACTICE]
		)

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
		last_screen_unload_requested.emit()
		return

	_navigate_back()


func navigate_to_outliner() -> void:
	if _is_unload_confirmation_required():
		_current_unload_type = UNLOAD_TYPE.OUTLINER
		all_screens_unload_requested.emit()
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

	back_navigation_requested.emit()


func _navigate_to_outliner() -> void:
	history.resize(0)
	_js_to_outliner()

	outliner_navigation_requested.emit()


func navigate_to_welcome_screen() -> void:
	welcome_screen_navigation_requested.emit()


func navigate_to_lesson(lesson_slug: String) -> void:
	navigate_to("%s" % [lesson_slug])


func navigate_to_practice(lesson_slug: String, practice_id: String) -> void:
	navigate_to("%s/%s" % [lesson_slug, practice_id])


## Resolves an app location, records it, and asks the UI to display it.
## `location` is a compact label like L5.P1, `$lesson/$practice` slug, a browser
## URL or a godot resource file path (e.g. `res://path/to/...`) supplied by the
## UI.
func navigate_to(location: String) -> void:
	var normalized_url := _parse_navigation_request(location)
	if normalized_url == null:
		return

	var course_index := CourseIndexPaths.get_course_index_instance(
		CourseIndexPaths.DEFAULT_COURSE_INDEX
	)
	var target := _get_navigation_resource(normalized_url, course_index)
	if target == null:
		push_error("`%s` does not resolve to a lesson or practice." % location)
		return

	var lesson_path_for_navigation := _get_lesson_path(normalized_url, course_index)
	var lesson_slug_for_navigation := course_index.get_lesson_slug_from_path(
		lesson_path_for_navigation
	)
	if lesson_slug_for_navigation.is_empty():
		return
	# History uses the stable course slug, not the original compact label or a
	# resource path, so desktop and web navigation refer to the same URL.
	var canonical_navigation_path := lesson_slug_for_navigation
	if not normalized_url.practice_path.is_empty():
		canonical_navigation_path += "/%s" % normalized_url.practice_path

	history.push_back(canonical_navigation_path)
	_push_javascript_state(canonical_navigation_path)

	navigation_requested.emit()


## Resolves a location to its lesson or practice parse node without navigating.
## location can be the same compact label (e.g. L5.P1), slug, or resource URL
## accepted by [method navigate_to].
func get_navigation_resource(location: String) -> BBCodeParser.ParseNode:
	var normalized_url := _parse_navigation_request(location)
	if normalized_url == null:
		return null
	var course_index := CourseIndexPaths.get_course_index_instance(
		CourseIndexPaths.DEFAULT_COURSE_INDEX
	)
	return _get_navigation_resource(normalized_url, course_index)


## Parses a compact label, app slug, or resource URL into navigation parts.
## The returned object keeps the lesson and optional practice values separate so
## resource loading and history handling can use the same parsed request.
func _parse_navigation_request(location_raw: String) -> NormalizedUrl:
	var location := location_raw.strip_edges()
	var compact_course_location_match := _regex_compact_course_location.search(location)
	if compact_course_location_match != null:
		location = _resolve_compact_course_location(location)
		if location.is_empty():
			return null

	var regex_result := _regex_url_normalization.search(location)
	var is_slug := false
	if not regex_result:
		is_slug = true
		regex_result = _regex_slug_normalization.search(location)
	if not regex_result:
		push_error("`%s` is not a valid bbcode or slug path" % location_raw)
		return null

	var normalized_url := NormalizedUrl.new(regex_result)
	normalized_url.is_slug = is_slug
	return normalized_url


func _get_navigation_resource(normalized_url: NormalizedUrl, course_index: CourseIndex) -> BBCodeParser.ParseNode:
	var lesson_path := _get_lesson_path(normalized_url, course_index)
	if lesson_path.is_empty():
		return null

	var lesson_data := _load_lesson(lesson_path)
	if lesson_data == null:
		return null

	if normalized_url.practice_path.is_empty():
		return lesson_data

	for practice_index in BBCodeUtils.get_lesson_practice_count(lesson_data):
		var practice := BBCodeUtils.get_lesson_practice(lesson_data, practice_index)
		if BBCodeUtils.get_practice_id(practice) == normalized_url.practice_path:
			return practice
	push_error(
		"NavigationManager.gd:_get_navigation_resource(): Practice '%s' was not found in lesson '%s'."
		% [normalized_url.practice_path, lesson_path]
	)
	return null


func _get_lesson_path(normalized_url: NormalizedUrl, course_index: CourseIndex) -> String:
	if not normalized_url.is_slug:
		if (
			normalized_url.protocol.is_empty() or normalized_url.course.is_empty()
			or normalized_url.lesson.is_empty()
		):
			return ""
		var direct_path := "%s%s/%s" % [
			normalized_url.protocol,
			normalized_url.course,
			normalized_url.lesson,
		]
		if not normalized_url.lesson_file.is_empty():
			direct_path += "/%s" % normalized_url.lesson_file
		return direct_path

	var lesson_slug := course_index.get_real_slug_from_slug(normalized_url.lesson)
	return course_index.get_lesson_path_from_slug(lesson_slug)


func _load_lesson(lesson_path: String) -> BBCodeParser.ParseNode:
	if lesson_path.is_empty() or not FileAccess.file_exists(lesson_path):
		push_error("NavigationManager.gd:_load_lesson(): Lesson file does not exist: %s" % lesson_path)
		return null

	var effective_bbcode := lesson_path
	if TranslationManager.current_language != "en":
		effective_bbcode = "%s.%s.%s" % [
			lesson_path.get_basename(),
			TranslationManager.current_language,
			lesson_path.get_extension(),
		]
		if not FileAccess.file_exists(effective_bbcode):
			effective_bbcode = lesson_path

	if _lesson_cache.has(effective_bbcode):
		return _lesson_cache[effective_bbcode]

	var parser := LessonBBCodeParser.new()
	var result := parser.parse_file(effective_bbcode)
	if not result.is_success():
		push_error(
			"NavigationManager.gd:_load_lesson(): Failed to parse lesson file %s. Fix the reported BBCode errors before loading this lesson:"
			% effective_bbcode
		)
		for error: BBCodeParser.ParseError in result.errors:
			push_error("  " + error.format())
		return null

	if result.warnings:
		print(
			"NavigationManager.gd:_load_lesson(): Parse warnings when loading lesson from bbcode file %s:"
			% effective_bbcode
		)
		for warning: BBCodeParser.ParseError in result.warnings:
			print("  ", warning.format())

	if result.root == null or result.root.children.is_empty() or not result.root.children[0] is BBCodeParser.ParseNode:
		push_error(
			"NavigationManager.gd:_load_lesson(): Parsed lesson file %s has no [lesson] root."
			% effective_bbcode
		)
		return null

	var lesson_data: BBCodeParser.ParseNode = result.root.children[0]
	_lesson_cache[effective_bbcode] = lesson_data
	return lesson_data


## Converts a short label like L5.P1 or L3 or L12P4 into the canonical
## path to load the lesson or practice ($lesson_slug[/$practice_slug])
func _resolve_compact_course_location(location: String) -> String:
	var match := _regex_compact_course_location.search(location.strip_edges())
	if match == null:
		return ""

	var course_index := CourseIndexPaths.get_course_index_instance(
		CourseIndexPaths.DEFAULT_COURSE_INDEX
	)
	var lesson_number := match.get_string("lesson_number").to_int()
	var lesson_path := course_index.get_lesson_path_from_number(lesson_number)
	if lesson_path.is_empty():
		push_error("Lesson label 'L%d' is outside the course range." % lesson_number)
		return ""

	var lesson_slug := course_index.get_lesson_slug_from_path(lesson_path)
	var practice_number_text := match.get_string("practice_number")
	if practice_number_text.is_empty():
		return lesson_slug

	var practice_number := practice_number_text.to_int()
	var lesson := _load_lesson(lesson_path)
	if lesson == null:
		push_error("Could not load lesson label 'L%d'." % lesson_number)
		return ""
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
	if practice_number < 1 or practice_number > practice_count:
		push_error(
			"Practice label 'L%d.P%d' is outside the lesson range."
			% [lesson_number, practice_number]
		)
		return ""

	var practice := BBCodeUtils.get_lesson_practice(lesson, practice_number - 1)
	return "%s/%s" % [lesson_slug, BBCodeUtils.get_practice_id(practice)]


# Handle back requests
func _notification(what: int) -> void:
	if not is_mobile_platform:
		return
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST]:
		navigate_back()


func _open_rich_text_node_meta(metadata: String) -> void:
	if (
		metadata.begins_with("https://")
		or metadata.begins_with("http://") or metadata.begins_with("//")
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


func _on_translation_changed() -> void:
	_lesson_cache.clear()

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
	@warning_ignore("unsafe_property_access") var url: String = (
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
	# Keep app navigation in the hash so static hosts do not look for a page at
	# the lesson slug path.
	_js_history.pushState(url, "", "#%s" % url)


## The parsed parts of one navigation input. It is not itself a browser URL.
## `protocol`, `course`, and `lesson_file` identify resource paths; `lesson` and
## `practice_path` identify app slugs; `is_slug` tells which form was received.
class NormalizedUrl:
	var protocol := ""
	var course := ""
	var lesson := ""
	var practice_path := ""
	var lesson_file := ""
	var is_slug := false


	func _init(regex_result: RegExMatch) -> void:
		protocol = regex_result.get_string("prefix")
		course = regex_result.get_string("course")
		lesson = regex_result.get_string("lesson").trim_suffix("/")
		practice_path = regex_result.get_string("practice")
		lesson_file = regex_result.get_string("lesson_file")

		if protocol in ["//", "/"]:
			protocol = "res://"


	func _to_string() -> String:
		var string := "%s%s/%s" % [protocol, course, lesson]
		if lesson_file != "":
			string += "/%s" % [lesson_file]
		if practice_path != "":
			string += "/%s" % [practice_path]
		return string
