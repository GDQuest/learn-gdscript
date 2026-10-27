extends Control

const COLOR_KEYWORD := CodeEditorEnhancer.COLOR_KEYWORD
const COLOR_KEYWORD_CONTROL_FLOW := CodeEditorEnhancer.COLOR_KEYWORD_CONTROL_FLOW
const COLOR_STRING := Color(1, 0.960784, 0.25098)
const COLOR_COMMENTS := Color(0.290196, 0.294118, 0.388235)

@export var _gdscript_code: CodeEdit
@export var _python_code: CodeEdit
@export var _js_code: CodeEdit


func _ready() -> void:
	CodeEditorEnhancer.enhance(_gdscript_code)
	CodeEditorEnhancer.prevent_editable(_gdscript_code)
	CodeEditorEnhancer.enhance(_python_code)
	CodeEditorEnhancer.prevent_editable(_python_code)
	CodeEditorEnhancer.enhance(_js_code)
	CodeEditorEnhancer.prevent_editable(_js_code)

	(_js_code.syntax_highlighter as CodeHighlighter).add_color_region("//", "", COLOR_COMMENTS, true)

	for key: String in ["function"]:
		(_js_code.syntax_highlighter as CodeHighlighter).add_keyword_color(key, COLOR_KEYWORD)
	for key: String in ["def"]:
		(_python_code.syntax_highlighter as CodeHighlighter).add_keyword_color(key, COLOR_KEYWORD)
