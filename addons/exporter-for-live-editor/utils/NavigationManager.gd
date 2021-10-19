extends Node

const RegExp = preload("./RegExp.gd")

signal transition_in_completed
signal transition_out_completed


var _is_path_regex := RegExp.compile("^(?<prefix>user:\\/\\/|res:\\/\\/|\\.*?\\/+)(?<url>.*)")
var _screens_stack := []
var _next := []
var _tween := Tween.new()

var root_container: Node

# Can contain shortcuts to scenes. Match a string with a scene
# @type Dictionary[String, PackedScene Path]
export var matches := {}


func _ready() -> void:
	add_child(_tween)
	get_tree().set_auto_accept_quit(false)
	_on_ready_listen_to_browser_changes()


func connect_rich_text_links(rich_text: RichTextLabel) -> void:
	rich_text.connect("meta_clicked", self, "open_url")


func open_url(data: String) -> void:
	print(data)
	data = matches[data] if (data and data in matches) else data
	if not data:
		push_warning("no url provided")
		return
	var regex_result := _is_path_regex.search(data)
	var prefix := regex_result.get_string("prefix")
	var url := regex_result.get_string("url")
	if regex_result:
		if prefix == "//" or prefix == "/":
			prefix = "res://"
	var path = prefix + url 
	var scene: PackedScene = load(path)
	var screen: CanvasItem = scene.instance()
	_push_screen(screen)
	_push_javascript_state(url)


func _transition(screen: CanvasItem, direction_in := true) -> void:
	var start = get_viewport().size.x
	var end = 0.0
	var property = "position:x" if screen is Node2D else (
		"rect_position:x" if screen is Control else ""
	)
	if not property:
		return
	var trans := Tween.TRANS_ELASTIC
	var eas := Tween.EASE_OUT
	var duration := 0.5
	if direction_in:
		_tween.interpolate_property(screen, property, start, end, duration, trans, eas)
	else:
		_tween.interpolate_property(screen, property, end, start, duration, trans, eas)
	_tween.start()
	yield(_tween, "tween_all_completed")
	if direction_in:
		emit_signal("transition_in_completed")
	else:
		emit_signal("transition_out_completed")


func back() -> void:
	_pop_screen()


func _notification(what: int) -> void:
	if \
		what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST \
		or \
		what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST \
	:
		if _screens_stack.size() > 1:
			_pop_screen()
		else:
			get_tree().quit()


func _push_screen(screen: Node) -> void:
	var previous_node := _get_topmost_child()
	_screens_stack.push_front(screen)
	_add_child_to_root_container(screen)
	_transition(screen)
	if previous_node:
		yield(self, "transition_in_completed")
		remove_child_from_root_container(previous_node)


func _pop_screen():
	if _screens_stack.size() < 2:
		push_warning("No screen to pop")
		return
	
	var previous_node: Node = _screens_stack.pop_front()
	_add_child_to_root_container(_get_topmost_child())

	_transition(previous_node, false)
	yield(self, "transition_out_completed")
	remove_child_from_root_container(previous_node)
	previous_node.queue_free()
	


func get_root_container() -> Node:
	if root_container:
		return root_container
	return get_tree().root


func _add_child_to_root_container(child: Node) -> void:
	get_root_container().call_deferred("add_child", child)


func remove_child_from_root_container(child: Node) -> void:
	get_root_container().call_deferred("remove_child", child)


func _get_topmost_child() -> Node:
	if _screens_stack.size() > 0:
		return _screens_stack[0] as Node
	return null


################################################################################
#
# UNTESTED, EXPERIMENTAL JS SUPPORT
# 

var _js_available := OS.has_feature('JavaScript')
var _js_window := JavaScript.get_interface("window") if _js_available else null
var _js_history := JavaScript.get_interface("history") if _js_available else null
var _js_popstate_listener_ref := JavaScript.create_callback(self, "_js_popstate_listener") if _js_available else null


func _push_javascript_state(url: String) -> void:
	if not _js_available:
		return
	_js_history.pushState(url, '', url)
	#JavaScript.eval("history && 'pushState' in history && history.pushState(\"%s\", '', \"%s\")"%[url], true)


func _js_popstate_listener(args) -> void:
	var event = args[0]
	var url = event.state
	prints("js asks to go back to:", url)
	_pop_screen()


func _on_ready_listen_to_browser_changes() -> void:
	if not _js_available:
		return
	_js_window.addEventListener('popstate', _js_popstate_listener_ref)
