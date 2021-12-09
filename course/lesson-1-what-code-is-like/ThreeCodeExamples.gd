extends Control

const COLOR_KEYWORD := Color(1, 0.094118, 0.321569)
const COLOR_QUOTES := Color(1, 0.960784, 0.25098)
const COLOR_COMMENTS := Color(0.290196, 0.294118, 0.388235)

onready var _python_code := $PythonCodeExample as TextEdit
onready var _js_code := $JavascriptCodeExample as TextEdit


func _ready() -> void:
	_python_code.add_color_region("#", "\n", COLOR_COMMENTS, true)
	_js_code.add_color_region("//", "\n", COLOR_COMMENTS, true)

	for key in ["if", "function"]:
		_js_code.add_keyword_color(key, COLOR_KEYWORD)
	for key in ["if", "def"]:
		_python_code.add_keyword_color(key, COLOR_KEYWORD)
