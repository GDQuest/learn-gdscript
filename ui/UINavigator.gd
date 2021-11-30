extends PanelContainer


signal transition_in_completed
signal transition_out_completed

export var scene_file: PackedScene

var screens_stack := []
# Can contain shortcuts to scenes. Match a string with a scene
# @type Dictionary[String, PackedScene Path]
var matches := {}
# Switch this off to remove transitions.
var use_transitions := false
var breadcrumbs: PoolStringArray setget _ready_only_setter, get_breadcrumbs

# Used for transition animations.
var _tween := Tween.new()
var _is_mobile_platform := OS.get_name() in ["Android", "HTML5", "iOS"]
var _path_regex := RegExpGroup.compile("^(?<prefix>user:\\/\\/|res:\\/\\/|\\.*?\\/+)(?<url>.*)")
var _current_url := ScreenUrl.new(_path_regex, "res://")

onready var _back_button := $VBoxContainer/Buttons/HBoxContainer/BackButton as Button
onready var _label := $VBoxContainer/Buttons/HBoxContainer/BreadCrumbs as Label
onready var _root_container := $VBoxContainer/PanelContainer as Container

onready var _scene_path := scene_file.resource_path


func _ready() -> void:
	Events.connect("lesson_end_popup_closed", self, "back")
	Events.connect("lesson_start_requested", self, "open_url")

	_back_button.connect("pressed", self, "back")

	connect("transition_in_completed", self, "_on_navigation_transition")
	connect("transition_out_completed", self, "_on_navigation_transition")

	open_url(_scene_path)
	if _is_mobile_platform:
		get_tree().set_auto_accept_quit(false)
	add_child(_tween)
	_on_ready_listen_to_browser_changes()


func _input(event: InputEvent) -> void:
	if event.is_action_released("ui_back"):
		back()


# Loads a scene and adds it to the stack.
#
# a url is of the form res://scene.tscn, user://scene.tscn, //scene.tscn,  or
# /scene.tscn ("res:" will be appended automatically)
func open_url(data: String) -> void:
	data = matches[data] if (data and data in matches) else data
	if not data:
		push_warning("no url provided")
		return
	var url = ScreenUrl.new(_path_regex, data)
	if not url.is_valid:
		return
	var scene: PackedScene = load(url.href)
	var screen: CanvasItem = scene.instance()
	set_current_url(url)
	_push_screen(screen)


# Pops the last screen from the stack
func back() -> void:
	if screens_stack.size() < 1:
		push_warning("No screen to pop")
		return

	var previous_node: Node = screens_stack.pop_back()

	var next_in_queue := _get_topmost_child()
	if next_in_queue:
		_add_child_to_root_container(next_in_queue)
	_set_current_url_from_scene(next_in_queue)

	_transition(previous_node, false)
	yield(self, "transition_out_completed")
	_root_container.call_deferred("remove_child", previous_node)
	previous_node.queue_free()


func set_current_url(url: ScreenUrl, is_back := false) -> void:
	_current_url = url
	if is_back:
		pass
	else:
		_push_javascript_state(url)


func get_breadcrumbs() -> PoolStringArray:
	var crumbs := PoolStringArray()
	var length := screens_stack.size()
	while length > 0:
		length -= 1
		var node: Node = screens_stack[length]
		crumbs.push_back(node.name)
	return crumbs


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


# Pushes a screen on top of the stack and transitions it in
func _push_screen(screen: Node) -> void:
	var previous_node := _get_topmost_child()
	screens_stack.push_back(screen)
	_add_child_to_root_container(screen)
	_transition(screen)
	if previous_node:
		yield(self, "transition_in_completed")

		_root_container.call_deferred("remove_child", previous_node)
	_connect_rich_texts_group()


# Transitions a screen in. This is there as a placeholder, we probably want
# something prettier.
#
# Anything can go in there, as long as "transition_in_completed" or
# "transition_out_completed" are emitted at the end.
#
# 'Screen' is assumed to be a CanvasItem, this method will have issues otherwise
# turn transitions off by setting `use_transitions` to false to skip transitions
func _transition(screen: CanvasItem, direction_in := true) -> void:
	var signal_name := "transition_in_completed" if direction_in else "transition_out_completed"
	if not use_transitions:
		yield(get_tree(), "idle_frame")
		emit_signal(signal_name)
		return
	var start = get_viewport().size.x
	var end = 0.0
	var property := (
		"position:x"
		if screen is Node2D
		else ("rect_position:x" if screen is Control else "")
	)
	if not property:
		return

	var trans := Tween.TRANS_CUBIC
	var easing := Tween.EASE_IN_OUT
	var duration := 0.8
	if direction_in:
		_tween.interpolate_property(screen, property, start, end, duration, trans, easing)
	else:
		_tween.interpolate_property(screen, property, end, start, duration, trans, easing)
	_tween.start()
	yield(_tween, "tween_all_completed")
	emit_signal(signal_name)


# If there are no more screens to pops, exits the application,
# otherwise, pops the last screen.
# Intended to be used in mobile environments
func _go_back_or_quit() -> void:
	if screens_stack.size() > 1:
		back()
	else:
		get_tree().quit()


func _set_current_url_from_scene(scene: Node = null, is_back := false) -> void:
	var path = scene.filename if scene and scene.filename else "res://"
	set_current_url(ScreenUrl.new(_path_regex, path))


# Appends a new child to the root container in deferred mode
func _add_child_to_root_container(child: Node) -> void:
	_root_container.call_deferred("add_child", child)


# Appends a new child to the root container in deferred mode
func _get_topmost_child() -> Node:
	if screens_stack.size() > 0:
		return screens_stack[0] as Node
	return null


# Handle back requests
func _notification(what: int) -> void:
	if not _is_mobile_platform:
		return

	if what in [MainLoop.NOTIFICATION_WM_QUIT_REQUEST, MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST]:
		_go_back_or_quit()


func _ready_only_setter(_unused_variable) -> void:
	push_error("this variable is read-only")


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


# Changes the browser's URL
func _push_javascript_state(url: ScreenUrl) -> void:
	if not _js_available:
		return
	_js_history.pushState(url.href, "", url.path)


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


# Registers the js listener
func _on_ready_listen_to_browser_changes() -> void:
	if not _js_available:
		return
	_js_window.addEventListener("popstate", _js_popstate_listener_ref)


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


func _on_navigation_transition():
	var is_root_screen = _current_url.path == _scene_path
	_back_button.disabled = is_root_screen
	_label.text = breadcrumbs.join("/")


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
