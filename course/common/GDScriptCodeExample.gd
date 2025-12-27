@tool
class_name GDScriptCodeExample
extends TextEdit

var _min_size: Vector2 = Vector2(600, 200)

@export var min_size: Vector2 = Vector2(600, 200):
	set(value):
		_set_min_size(value)
	get:
		return _min_size


func _ready() -> void:
	Events.font_size_scale_changed.connect(_update_size)
	context_menu_enabled = false
	shortcut_keys_enabled = false

	editable = false # Godot 4 replacement for readonly
	wrap_mode = TextEdit.LINE_WRAPPING_NONE # Godot 4 replacement for wrap_enabled

	CodeEditorEnhancer.enhance(self)


func _set_min_size(new_size: Vector2) -> void:
	_min_size = new_size
	custom_minimum_size = new_size


func _update_size(_new_font_scale: int) -> void:
	# Forces the text wrapping to update. Without this, the code can overflow
	# the container when changing the font size.
	# TODO: There is some computation error in the TextEdit, it seems. Need to investigate it further.
	#
	# Practical Godot 4 equivalent: re-apply wrap and/or minimum size next frame
	# to force a relayout. Keep as a no-op for now if you don't need it.
	pass
