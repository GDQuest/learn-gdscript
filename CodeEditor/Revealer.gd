tool
extends VBoxContainer

export var title := "Expand" setget set_title
export var is_collapsed := false setget set_collapsed

onready var _button: Button = $Title
onready var _container: Control = _button
onready var _chevron: TextureRect = $Title/Chevron
onready var _tween: Tween = $Title/Tween


func _ready() -> void:
	_button.pressed = not is_collapsed
	_button.connect("toggled", self, "set_collapsed")
	set_collapsed(is_collapsed)


func set_collapsed(new_collapsed: bool) -> void:
	is_collapsed = new_collapsed
	if not is_inside_tree():
		yield(self, "ready")
	_tween.stop_all()
	if is_collapsed:
		_tween.interpolate_property(_chevron, "rect_rotation", _chevron.rect_rotation, 0, .2)
		for child in get_children():
			if child != _container:
				child.hide()
	else:
		_tween.interpolate_property(_chevron, "rect_rotation", _chevron.rect_rotation, 90, .2)
		for child in get_children():
			child.show()
	_tween.start()


func set_title(new_title: String) -> void:
	title = new_title
	if not is_inside_tree():
		yield(self, "ready")
	_button.text = new_title
