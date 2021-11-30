# Exemple of a Goal. A goal represents a separate validation for an exercise
#
# A goal doesn't need to subclass a specific class. A goal:
#
# 1. adds itself to the group `"validator_checks"`
# 2. has one or more validator children
# 3. emits a signal called "request_validation" that takes no arguments
# 4. has a method called set_status(status) which takes an int, 0 for no errors,
#    1 for errors, 2 for valid
#
tool
extends HBoxContainer

const CheckmarkIcon := preload("./CheckmarkIcon.gd")

var _text_node := Label.new()
var _texture := CheckmarkIcon.new()

export var text := "Goal" setget set_text
export (CheckmarkIcon.STATUS) var status := 0 setget set_status

# Texture used when the goal has not been checked yet
export var none_texture: Texture = _texture.none_texture setget set_none_texture

# Texture used when the goal is passed
export var valid_texture: Texture = _texture.valid_texture setget set_valid_texture

# Texture used when the goal is not passed
export var invalid_texture: Texture = _texture.invalid_texture setget set_invalid_texture


func _init() -> void:
	_texture.rect_min_size = Vector2(32, 32)
	_texture.rect_size = Vector2(32, 32)
	_texture.expand = true
	_texture.texture = none_texture

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


func set_none_texture(texture: Texture) -> void:
	none_texture = texture
	if not is_inside_tree():
		yield(self, "ready")
	_texture.none_texture = texture


func set_valid_texture(texture: Texture) -> void:
	valid_texture = texture
	if not is_inside_tree():
		yield(self, "ready")
	_texture.valid_texture = texture


func set_invalid_texture(texture: Texture) -> void:
	invalid_texture = texture
	if not is_inside_tree():
		yield(self, "ready")
	_texture.invalid_texture = texture
