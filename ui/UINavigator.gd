extends PanelContainer

signal transition_in_completed
signal transition_out_completed

# If `true`, play transition animations.
var use_transitions := false

var _screens_stack := []
# Maps url strings to resource paths.
var _matches := {}
var _breadcrumbs: PoolStringArray
# Used for transition animations.
var _is_mobile_platform := OS.get_name() in ["Android", "HTML5", "iOS"]
var _path_regex := RegExpGroup.compile("^(?<prefix>user:\\/\\/|res:\\/\\/|\\.*?\\/+)(?<url>.*)")
var _current_url := ScreenUrl.new(_path_regex, "res://")

onready var _back_button := $VBoxContainer/Buttons/HBoxContainer/BackButton as Button
onready var _label := $VBoxContainer/Buttons/HBoxContainer/BreadCrumbs as Label
onready var _screen_container := $VBoxContainer/PanelContainer as Container
onready var _tween := $Tween as Tween


func _ready() -> void:
	Events.connect("lesson_end_popup_closed", self, "back")
	Events.connect("lesson_start_requested", self, "open_url")
	Events.connect("practice_start_requested", self, "_start_practice")

	_back_button.connect("pressed", self, "back")

	if _is_mobile_platform:
		get_tree().set_auto_accept_quit(false)

	# Registers the js listener
	if _js_available:
		_js_window.addEventListener("popstate", _js_popstate_listener_ref)


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_back"):
		back()


# Handle back requests
func _notification(what: int) -> void:
	if not _is_mobile_platform:
		return
	if what in [MainLoop.NOTIFICATION_WM_QUIT_REQUEST, MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST]:
		back()


# Pops the last screen from the stack
func back() -> void:
	if _screens_stack.size() < 1:
		push_warning("No screen to pop")
		return

	var previous_node: Node = _screens_stack.pop_back()

	var next_in_queue: Control = _screens_stack.pop_back()
	if next_in_queue:
		_screen_container.add_child(next_in_queue)

	_current_url = url
	if _js_available and not is_back:
		_js_history.pushState(url.href, "", url.path)

	_transition_to(previous_node, false)
	yield(self, "transition_out_completed")
	_screen_container.call_deferred("remove_child", previous_node)
	previous_node.queue_free()


# Pushes a screen on top of the stack and transitions it in
func _push_screen(screen: Control) -> void:
	var previous_node: Control = _screens_stack.back()
	_screens_stack.push_back(screen)
	_screen_container.add_child(screen)
	_transition_to(screen)
	if previous_node:
		yield(self, "transition_in_completed")
		_screen_container.call_deferred("remove_child", previous_node)
	_connect_rich_texts_group()


# when a screen loads, this is called, to connect all rich text's meta's links.
# the default group name is navigation_text. If you want to use this for other
# groups, then you can use it manually.
func _connect_rich_texts_group(group_name := "navigation_text") -> void:
	yield(get_tree(), "idle_frame")
	for child in get_tree().get_nodes_in_group(group_name):
		if child is RichTextLabel:
			var rich_text_label := child as RichTextLabel
			if rich_text_label.bbcode_enabled:
				# Connects links in a rich text so they open scenes.
				rich_text_label.connect("meta_clicked", self, "open_url")


# Transitions a screen in. This is there as a placeholder, we probably want
# something prettier.
#
# Anything can go in there, as long as "transition_in_completed" or
# "transition_out_completed" are emitted at the end.
func _transition_to(screen: Control, direction_in := true) -> void:
	var signal_name := "transition_in_completed" if direction_in else "transition_out_completed"

	_back_button.disabled = _current_url.path == filename
	_label.text = _breadcrumbs.join("/")

	if not use_transitions:
		yield(get_tree(), "idle_frame")
		emit_signal(signal_name)
		return

	_tween.stop_all()
	var start := get_viewport().size.x if direction_in else 0.0
	var end := 0.0 if direction_in else get_viewport().size.x
	_tween.interpolate_property(
		screen, "rect_position:x", start, end, 0.8, Tween.TRANS_CUBIC, Tween.EASE_OUT
	)
	_tween.start()
	yield(_tween, "tween_all_completed")
	emit_signal(signal_name)


func _start_practice(practice: Resource) -> void:
	var practice_ui: UIPractice = preload("UIPractice.tscn").instance()
	practice_ui.setup(practice)
	_screen_container.add_child(practice_ui)


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
	back()


# If a url is set on the page, uses that
func _load_current_browser_url() -> void:
	if not _js_available:
		return
	var state = _js_history.state
	if state:
		var url = state.url
		open_url(url)
	if _js_window.location.pathname:
		open_url(_js_window.location.pathname)
