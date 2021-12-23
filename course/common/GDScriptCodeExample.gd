tool
class_name GDScriptCodeExample
extends TextEdit

export var min_size := Vector2(600, 200) setget set_min_size


func _ready() -> void:
	context_menu_enabled = false
	shortcut_keys_enabled = false
	CodeEditorEnhancer.enhance(self)
	set("custom_styles/readonly", preload("res://ui/theme/textedit_stylebox.tres"))


func set_min_size(size: Vector2) -> void:
	min_size = size
	rect_min_size = size
