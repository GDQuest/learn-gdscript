@tool
class_name GDScriptCodeExample
extends CodeEdit

const CODE_FONT := "res://ui/theme/fonts/font_code.tres"

func _ready() -> void:
	if get_theme_font("font").resource_path != CODE_FONT:
		add_theme_font_override("font", load(CODE_FONT) as FontVariation)
	context_menu_enabled = false
	shortcut_keys_enabled = false
	wrap_mode = TextEdit.LINE_WRAPPING_NONE
	CodeEditorEnhancer.enhance(self)
	CodeEditorEnhancer.prevent_editable(self)
	scroll_fit_content_height = true
