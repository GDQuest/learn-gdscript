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

const GROUP_NAME = "validator_checks"

# Sends a request to the ValidationManager to run children validators
signal request_validation

enum STATUS { NONE, INVALID, VALID }

export var text := "Goal" setget set_text
export (STATUS) var status := 0 setget set_status

# adds or removes a goal from the checks group.
# ValidationManager expects all checks to be in the group at `_ready()`, so if
# you activate a goal later, you'll have to rerun the ValidationManager's
# `connect_checks()`
export var is_active := true setget set_active, get_active

# Texture used when the goal has not been checked yet
export var none_texture: Texture = preload("../resources/none.svg")

# Texture used when the goal is passed
export var valid_texture: Texture = preload("../resources/valid.svg")

# Texture used when the goal is not passed
export var invalid_texture: Texture = preload("../resources/invalid.svg")

var _text_node := Label.new()
var _texture := TextureRect.new()
var _button := Button.new()


func _init() -> void:
	_texture.rect_min_size = Vector2(32, 32)
	_texture.rect_size = Vector2(32, 32)
	_texture.expand = true
	_texture.texture = none_texture

	_text_node.valign = Label.VALIGN_CENTER
	_text_node.rect_min_size = Vector2(100, 32)
	_text_node.size_flags_horizontal = SIZE_EXPAND_FILL

	_button.text = "test"

	add_child(_texture)
	add_child(_text_node)
	add_child(_button)


func _ready() -> void:
	set_status(status)
	set_active(is_active)
	if Engine.editor_hint:
		return
	_button.connect("pressed", self, "request_validation")


func request_validation() -> void:
	emit_signal("request_validation")


func set_status(new_status: int) -> void:
	status = new_status
	match status:
		STATUS.VALID:
			_texture.texture = valid_texture
		STATUS.INVALID:
			_texture.texture = invalid_texture
		_:
			_texture.texture = none_texture


func set_text(new_text: String) -> void:
	text = new_text
	_text_node.text = text


func set_active(new_is_active: bool) -> void:
	is_active = new_is_active
	var _is_in_group = is_in_group(GROUP_NAME)
	if is_active:
		if not _is_in_group:
			add_to_group(GROUP_NAME)
	else:
		if _is_in_group:
			remove_from_group(GROUP_NAME)


func get_active() -> bool:
	return is_in_group(GROUP_NAME)


func _get_configuration_warning() -> String:
	for child in get_children():
		if child is Validator:
			return ""
	return "Goal requires at least one Validator"
