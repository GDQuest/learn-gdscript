extends PanelContainer

signal transition_completed

export (Resource) var course = preload("res://course/course-learn-gdscript.tres")

# If `true`, play transition animations.
var use_transitions := true

var _screens_stack := []
# Maps url strings to resource paths.
var _matches := {}
var _breadcrumbs: PoolStringArray
# Used for transition animations.
var _is_mobile_platform := OS.get_name() in ["Android", "HTML5", "iOS"]
var _path_regex := RegExpGroup.compile("^(?<prefix>user:\\/\\/|res:\\/\\/|\\.*?\\/+)(?<url>.*)")
var _current_url := ScreenUrl.new(_path_regex, "res://")
var _lesson_index := 0 setget _set_lesson_index
var _lesson_count: int = course.lessons.size()

onready var _back_button := $VBoxContainer/Buttons/HBoxContainer/BackButton as Button
onready var _label := $VBoxContainer/Buttons/HBoxContainer/BreadCrumbs as Label
onready var _screen_container := $VBoxContainer/PanelContainer as Container
onready var _tween := $Tween as Tween


func _ready() -> void:
	Events.connect("lesson_end_popup_closed", self, "_back")
	Events.connect("lesson_start_requested", self, "_navigate_to")
	Events.connect("practice_start_requested", self, "_navigate_to")
	Events.connect("practice_completed", self, "_on_Events_practice_completed")

	_back_button.connect("pressed", self, "_back")

	if _is_mobile_platform:
		get_tree().set_auto_accept_quit(false)

	# Registers the js listener
	if _js_available:
		_js_window.addEventListener("popstate", _js_popstate_listener_ref)
	_navigate_to(course.lessons[0])


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_back"):
		_back()


# Handle back requests
func _notification(what: int) -> void:
	if not _is_mobile_platform:
		return
	if what in [MainLoop.NOTIFICATION_WM_QUIT_REQUEST, MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST]:
		_back()


# Pops the last screen from the stack
func _back() -> void:
	if _screens_stack.size() < 2:
		return

	_breadcrumbs.remove(_breadcrumbs.size() - 1)

	var current_screen: Control = _screens_stack.pop_back()
	var next_screen: Control = _screens_stack.back()
	_transition_to(next_screen, current_screen, false)
	yield(self, "transition_completed")
	current_screen.queue_free()


# Instantates a screen based on the `target` resource and transitions to it.
func _navigate_to(target: Resource, clear_history := false) -> void:
	var screen: Control
	if target is Practice:
		screen = preload("UIPractice.tscn").instance()
	elif target is Lesson:
		screen = preload("UILesson.tscn").instance()
	else:
		printerr("Trying to navigate to unsupported resource type: %s" % target.get_class())
		return

	if clear_history:
		for child in _screen_container.get_children():
			child.queue_free()
		_screens_stack.clear()
		_breadcrumbs = PoolStringArray()

	screen.setup(target)

	_breadcrumbs.push_back(target.title)
	_label.text = _breadcrumbs.join("/")

	var has_previous_screen = not _screens_stack.empty()
	_screens_stack.push_back(screen)
	_screen_container.add_child(screen)
	if has_previous_screen:
		var previous_screen: Control = _screens_stack[-2]
		_transition_to(screen, previous_screen)
		yield(self, "transition_completed")

	# Connect to RichTextLabel meta links to navigate to different scenes.
	for node in get_tree().get_nodes_in_group("rich_text_label"):
		assert(node is RichTextLabel)
		if (
			node.bbcode_enabled
			and not node.is_connected("meta_clicked", self, "_on_RichTextLabel_meta_clicked")
		):
			node.connect("meta_clicked", self, "_on_RichTextLabel_meta_clicked")


func _on_RichTextLabel_meta_clicked(metadata: String) -> void:
	if (
		metadata.begins_with("https://")
		or metadata.begins_with("http://")
		or metadata.begins_with("//")
	):
		OS.shell_open(metadata)
	else:
		var resource := load(metadata)
		assert(
			resource is Resource, "Attempting to load invalid resource from path '%s'" % metadata
		)
		_navigate_to(resource)


# Transitions a screen in. This is there as a placeholder, we probably want
# something prettier.
#
# Anything can go in there, as long as "transition_in_completed" or
# "transition_out_completed" are emitted at the end.
func _transition_to(screen: Control, previous_screen: Control = null, direction_in := true) -> void:
	if not use_transitions:
		previous_screen.hide()
		screen.show()
		yield(get_tree(), "idle_frame")
		emit_signal("transition_completed")
		return

	screen.show()
	previous_screen.show()
	var viewport_width := get_viewport().size.x
	var direction := 1.0 if direction_in else -1.0
	screen.rect_position.x = viewport_width * direction
	_tween.interpolate_property(
		screen,
		"rect_position:x",
		screen.rect_position.x,
		0.0,
		1.2,
		Tween.TRANS_CUBIC,
		Tween.EASE_OUT
	)
	if previous_screen:
		_tween.interpolate_property(
			previous_screen,
			"rect_position:x",
			previous_screen.rect_position.x,
			-viewport_width * direction,
			1.2,
			Tween.TRANS_CUBIC,
			Tween.EASE_OUT
		)
	_tween.start()
	yield(_tween, "tween_all_completed")
	emit_signal("transition_completed")


func _on_Events_practice_completed(practice: Practice) -> void:
	var practices: Array = course.lessons[_lesson_index].practices
	var index := practices.find(practice)
	var is_last_practice := practices.size() - 1 <= index
	if is_last_practice:
		_set_lesson_index(_lesson_index + 1)
	else:
		_navigate_to(practices[index + 1])


func _set_lesson_index(index: int) -> void:
	_lesson_index = index
	if _lesson_index == _lesson_count:
		# TODO: figure out some screen at the end of the course
		print("You reached the end of the course!")
	else:
		_navigate_to(course.lessons[index], true)


class ScreenUrl:
	var path: String
	var protocol: String
	var href: String setget , _to_string
	var is_valid := true

	func _init(_path_regex: RegEx, data: String) -> void:
		var regex_result := _path_regex.search(data)
		protocol = regex_result.get_string("prefix")
		path = regex_result.get_string("url")
		if regex_result:
			if protocol in ["//", "/"]:
				protocol = "res://"
		else:
			is_valid = false
		if not path:
			path = "/"

	func _to_string() -> String:
		return protocol + path


################################################################################
#
# UNTESTED, EXPERIMENTAL JS SUPPORT
#

var _js_available := OS.has_feature("JavaScript")
var _js_window := JavaScript.get_interface("window") if _js_available else null
var _js_history := JavaScript.get_interface("history") if _js_available else null
var _js_popstate_listener_ref := (
	JavaScript.create_callback(self, "_js_popstate_listener")
	if _js_available
	else null
)
var _temporary_disable_listener := false


func _pop_javascript_state() -> void:
	if not _js_available:
		return
	_temporary_disable_listener = true
	_js_history.back()
	yield(get_tree(), "idle_frame")
	_temporary_disable_listener = false


# Handles user pressing back button in browser
func _js_popstate_listener(args) -> void:
	if _temporary_disable_listener:
		return
	var event = args[0]
	var url = event.state
	_back()

# If a url is set on the page, uses that
# TODO: we removed the open_url function, gotta restore it first if needed or delete this.
#func _load_current_browser_url() -> void:
#	if not _js_available:
#		return
#	var state = _js_history.state
#	if state:
#		var url = state.url
#		open_url(url)
#	if _js_window.location.pathname:
#		open_url(_js_window.location.pathname)
