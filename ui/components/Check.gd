# Exemple of a Goal. A goal represents a separate validation for an exercise
#
# A goal doesn't need to subclass a specific class. A goal:
#
# 1. adds itself to the group `"validator_checks"`
# 2. has one or more validator children
# 3. emits a signal called "request_validation" that takes no arguments
# 4. has a method called set_status(status) which takes an int, 0 for no errors,
#    1 for errors, 2 for valid
tool
extends HBoxContainer

var _text_node := Label.new()
var _texture := CheckmarkIcon.new()

var text := "Goal" setget set_text
var status := 0 setget set_status


func _init() -> void:
	_texture.rect_min_size = Vector2(32, 32)
	_texture.rect_size = Vector2(32, 32)
	_texture.expand = true

	_text_node.valign = Label.VALIGN_CENTER
	_text_node.rect_min_size = Vector2(100, 32)
	_text_node.size_flags_horizontal = SIZE_EXPAND_FILL

	add_child(_texture)
	add_child(_text_node)


func _ready() -> void:
	set_status(status)


func set_status(new_status: int) -> void:
	status = new_status
	if not is_inside_tree():
		yield(self, "ready")
	_texture.status = status


func set_text(new_text: String) -> void:
	text = new_text
	_text_node.text = text
