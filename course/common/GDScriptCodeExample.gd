@tool
class_name GDScriptCodeExample
extends CodeEdit

@export var min_size := Vector2(600, 200): set = set_min_size


func _ready() -> void:
	Events.font_size_scale_changed.connect(_update_size)
	context_menu_enabled = false
	shortcut_keys_enabled = false
	wrap_mode = TextEdit.LINE_WRAPPING_NONE
	CodeEditorEnhancer.enhance(self)
	CodeEditorEnhancer.prevent_editable(self)


func set_min_size(new_size: Vector2) -> void:
	min_size = new_size
	custom_minimum_size = new_size


func _update_size(_new_font_scale: int) -> void:
	# Forces the text wrapping to update. Without this, the code can overflow
	# the container when changing the font size.
	# TODO: There is some computation error in the TextEdit, it seems. Need to investigate it further.
	pass
