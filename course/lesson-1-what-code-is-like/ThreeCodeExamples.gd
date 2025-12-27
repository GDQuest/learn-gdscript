extends Control

const COLOR_KEYWORD := Color(1, 0.094118, 0.321569)
const COLOR_QUOTES := Color(1, 0.960784, 0.25098)
const COLOR_COMMENTS := Color(0.290196, 0.294118, 0.388235)

# If these nodes are meant for code, consider changing their type 
# in the scene tree to "CodeEdit" for even better features.
@onready var _python_code := $PythonCodeExample as CodeEdit
@onready var _js_code := $JavascriptCodeExample as CodeEdit

func _ready() -> void:
	_python_code.line_folding = true
	_python_code.gutters_draw_line_numbers = true
	_js_code.line_folding = true
	_js_code.gutters_draw_line_numbers = true
	
	var py_highlighter := CodeHighlighter.new()
	py_highlighter.add_color_region("#", "", COLOR_COMMENTS, true)
	
	for key: String in ["if", "def"]:
		py_highlighter.add_keyword_color(key, COLOR_KEYWORD)
	
	_python_code.syntax_highlighter = py_highlighter

	var js_highlighter := CodeHighlighter.new()
	js_highlighter.add_color_region("//", "", COLOR_COMMENTS, true)
	
	for key: String in ["if", "function"]:
		js_highlighter.add_keyword_color(key, COLOR_KEYWORD)
	
	_js_code.syntax_highlighter = js_highlighter
