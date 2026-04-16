@tool
extends CodeEdit


func _ready() -> void:
	CodeEditorEnhancer.enhance(self)
	CodeEditorEnhancer.prevent_editable(self)
