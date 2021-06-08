tool
extends HBoxContainer

enum STATUS{
	NONE,
	INVALID,
	VALID
}

const _script_base = """
extends Reference

func validate(script: String):
%s
"""


export var text := "Goal" setget set_text, get_text
export(STATUS) var status := 0 setget set_status
export var none_texture: Texture = preload("res://Resources/none.svg")
export var valid_texture: Texture = preload("res://Resources/valid.svg")
export var invalid_texture: Texture = preload("res://Resources/invalid.svg")
export(String, MULTILINE) var validation_script := "return true"
export var script_to_check:= ""

onready var _text_node: RichTextLabel = $RichTextLabel
onready var _texture: TextureRect = $Image
onready var _button: Button = $Button

var validation_script_instance: Reference

func _ready():
	if not Engine.editor_hint:
		_generate_validation_script()
		_button.connect("pressed", self, "validate_and_set")

func set_status(new_status: int) -> void:
	status = new_status
	if not is_inside_tree(): yield(self, "ready")
	match status:
		STATUS.VALID: 
			_texture.texture = valid_texture
		STATUS.INVALID:
			_texture.texture = invalid_texture
		_:
			_texture.texture = none_texture

func set_text(new_text: String) -> void:
	if not is_inside_tree(): yield(self, "ready")
	_text_node.bbcode_text = new_text

func get_text() -> String:
	return _text_node.bbcode_text

func _generate_validation_script() -> void:
	assert("return" in validation_script, "Your validation script does not return anything (%s)"%[get_path()])
	var script_array := validation_script.split("\n")
	for i in script_array.size():
		script_array[i] = "\t"+script_array[i]
	var source = _script_base%[script_array.join("\n")]
	print(source)
	var script = GDScript.new()
	script.source_code = source
	script.reload()
	validation_script_instance = script.new()

func validate(script_text: String) -> void:
	print(validation_script_instance.validate(script_text))

func validate_and_set(script_text: String = script_to_check) -> void:
	var result = validation_script_instance.validate(script_text)
	if result == true:
		set_status(STATUS.VALID)
	else:
		set_status(STATUS.INVALID)
