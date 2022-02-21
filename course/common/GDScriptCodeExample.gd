tool
class_name GDScriptCodeExample
extends TextEdit

export var min_size := Vector2(600, 200) setget set_min_size


func _ready() -> void:
	Events.connect("font_size_scale_changed", self, "_update_size")
	context_menu_enabled = false
	shortcut_keys_enabled = false
	readonly = true
	CodeEditorEnhancer.enhance(self)


func set_min_size(size: Vector2) -> void:
	min_size = size
	rect_min_size = size


func _update_size(_new_font_scale: int) -> void:
	# Forces the text wrapping to update. Without this, the code can overflow
	# the container when changing the font size.
	# TODO: There is some computation error in the TextEdit, it seems. Need to investigate it further.
	pass
