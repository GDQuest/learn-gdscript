tool
extends HBoxContainer

signal validation_completed(errors)

enum STATUS { NONE, INVALID, VALID }

export var text := "Goal" setget set_text
export (STATUS) var status := 0 setget set_status
export var none_texture: Texture = preload("res://Resources/none.svg")
export var valid_texture: Texture = preload("res://Resources/valid.svg")
export var invalid_texture: Texture = preload("res://Resources/invalid.svg")
export (String, MULTILINE) var validation_script := "return true"
export var script_to_check := ""

onready var _text_node: RichTextLabel = $RichTextLabel
onready var _texture: TextureRect = $Image
onready var _button: Button = $Button


func _ready():
	add_to_group("goals")
	if not Engine.editor_hint:
		_button.connect("pressed", self, "validate_and_set")
		if _get_validators().size() == 0:
			push_warning("Goal has no validators and will always return true (%s)" % get_path())


func set_status(new_status: int) -> void:
	status = new_status
	if not is_inside_tree():
		yield(self, "ready")
	match status:
		STATUS.VALID:
			_texture.texture = valid_texture
		STATUS.INVALID:
			_texture.texture = invalid_texture
		_:
			_texture.texture = none_texture


func set_text(new_text: String) -> void:
	text = new_text
	if not is_inside_tree():
		yield(self, "ready")
	_text_node.bbcode_text = new_text


func validate(scene: Node, script_text: String):
	var validators := _get_validators()
	var errors = []
	for index in validators.size():
		var validator: Validator = validators[index]
		validator.validate(scene, script_text)
		errors += yield(validator, "validation_completed")
	emit_signal("validation_completed", errors)


func validate_and_set(scene: Node, script_text: String) -> void:
	validate(scene, script_text)
	var errors: Array = yield(self, "validation_completed")
	if errors.size() == 0:
		set_status(STATUS.VALID)
	else:
		set_status(STATUS.INVALID)


func _get_configuration_warning():
	for child in get_children():
		if child is Validator:
			return ''
	return 'Goal requires at least one Validator'


func _get_validators() -> Array:
	var validators = []
	for child in get_children():
		if child is Validator:
			validators.append(child)
	return validators
