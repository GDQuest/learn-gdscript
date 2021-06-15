tool
extends VBoxContainer

export var title := "Expand" setget set_title
export var collapsed := false setget set_collapsed

onready var _button: Button = $Title
onready var _container: Control = _button
onready var _chevron: TextureRect = $Title/Chevron
onready var _tween: Tween = $Title/Tween


func _ready() -> void:
	_button.pressed = not collapsed
	_button.connect("toggled", self, "_on__button_toggled")
	set_collapsed(collapsed)


func _on__button_toggled(_toggled: bool) -> void:
	toggle()


func toggle() -> void:
	set_collapsed(not collapsed)


func set_collapsed(new_collapsed: bool) -> void:
	collapsed = new_collapsed
	if not is_inside_tree():
		yield(self, "ready")
	_tween.stop_all()
	if collapsed:
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
