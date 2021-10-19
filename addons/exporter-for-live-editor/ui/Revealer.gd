tool
class_name Revealer, "./Revealer.svg"
extends Container

export var title := "Expand" setget set_title
export var is_expanded := false setget set_is_expanded
export var revealer_height := 32.0 setget set_revealer_height
export var chevron_size := 16.0
export var padding := 24.0
export var first_margin := 5.0
export var children_margin := 2.0

var _height := 0.0
var _contents := []

onready var _button: Button = $Button
onready var _chevron: TextureRect = $Button/Chevron
onready var _tween: Tween = $Tween


func _ready() -> void:
	_button.pressed = is_expanded
	_button.connect("toggled", self, "set_is_expanded")
	update_min_size()
	for child in get_children():
		if child == _button or not child is Control:
			continue
		_contents.append(child)
	# Through the constructor setter call, the _contents variable will be empty, so we need to call this again. 
	set_is_expanded(is_expanded)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		sort_children()


func set_is_expanded(new_is_expanded: bool) -> void:
	is_expanded = new_is_expanded

	if not is_inside_tree():
		yield(self, "ready")

	if is_expanded:
		_rotate_chevron(90, _height)
	else:
		_rotate_chevron(0, _button.rect_size.y)

	for node in _contents:
		node.visible = is_expanded


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	_button.text = new_title


func set_revealer_height(new_revealer_height: float) -> void:
	revealer_height = new_revealer_height
	if not is_inside_tree():
		yield(self, "ready")
	rect_min_size.y = revealer_height
	_button.rect_size.y = revealer_height


func update_min_size() -> void:
	rect_min_size.x = max(_button.rect_size.x, rect_size.x)
	rect_min_size.y = revealer_height
	_button.rect_size.y = revealer_height
	if is_expanded:
		for node in _contents:
			rect_min_size.y += node.rect_min_size.y



func sort_children() -> void:
	var top := 0.0
	update_min_size()
	_height = _button.rect_size.y
	for index in get_child_count():
		var child: Node = get_child(index)
		if not child is Control or not child.visible:
			continue
		var node_padding := 0.0 if index == 0 else padding
		var margin := 0.0 if index == 0 else first_margin if index == 1 else children_margin
		top = _fit_child(child, top + margin, node_padding)
	_height = top


func _rotate_chevron(to: float, height: float, time := .2) -> void:
	if not _tween.is_inside_tree():
		_chevron.rect_rotation = to
		rect_size.y = height
		return
	_tween.stop_all()
	_tween.interpolate_property(_chevron, "rect_rotation", _chevron.rect_rotation, to, time)
	_tween.interpolate_property(self, "rect_min_size:y", rect_min_size.y, to, time)
	_tween.start()


func _fit_child(control: Control, top := 0.0, node_padding := 0.0) -> float:
	var position := Vector2(node_padding, top)
	var height := control.rect_size.y
	var size := Vector2(rect_size.x - node_padding, height)
	var rect := Rect2(position, size)
	fit_child_in_rect(control, rect)
	return top + height
