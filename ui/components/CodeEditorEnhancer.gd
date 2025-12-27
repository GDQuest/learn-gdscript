# Sets options on a TextEdit for it to be more suitable as
# a text editor.
class_name CodeEditorEnhancer
extends Node

const COLOR_CLASS := Color(0.666667, 0, 0.729412)
const COLOR_MEMBER := Color(0.14902, 0.776471, 0.968627)
const COLOR_KEYWORD := Color(1, 0.094118, 0.321569)
const COLOR_QUOTES := Color(1, 0.960784, 0.25098)
const COLOR_COMMENTS := Color(0.290196, 0.294118, 0.388235)
const COLOR_NUMBERS := Color(0.922, 0.580, 0.200)

const KEYWORDS := [
	
	# Basic keywords.
	"var",
	"const",
	"func",
	"signal",
	"enum",
	"class",
	"static",
	"extends",
	"self",
	
	# Control flow keywords.
	"if",
	"elif",
	"else",
	"not",
	"and",
	"or",
	"in",
	"for",
	"do",
	"while",
	"match",
	"switch",
	"case",
	"break",
	"continue",
	"pass",
	"return",
	"is",
	
	# Godot-specific keywords.
	"onready",
	"export",
	"tool",
	"setget",
	"breakpoint",
	"remote", "sync",
	"master", "puppet", "slave",
	"remotesync", "mastersync", "puppetsync",
	
	# Primitive data types.
	"bool",
	"int",
	"float",
	"null",
	"true", "false",
	
	# Global GDScript namespace.
	"Color8",
	"ColorN",
	"abs",
	"acos",
	"asin",
	"assert",
	"atan",
	"atan2",
	"bytes2var",
	"cartesian2polar",
	"ceil",
	"char",
	"clamp",
	"convert",
	"cos",
	"cosh",
	"db2linear",
	"decials",
	"dectime",
	"deg2rad",
	"dict2inst",
	"ease",
	"expo",
	"floor",
	"fmod",
	"fposmod",
	"funcref",
	"hash",
	"inst2dict",
	"instance_from_id",
	"inverse_lerp",
	"is_inf",
	"is_nan",
	"len",
	"lerp",
	"linear2db",
	"load",
	"log",
	"max",
	"min",
	"nearest_po2",
	"parse_json",
	"polar2cartesian",
	"pow",
	"preload",
	"print",
	"print_stack",
	"printerr",
	"printraw",
	"prints",
	"printt",
	"rad2deg",
	"rand_range",
	"rand_seed",
	"randf",
	"randi",
	"randomize",
	"range",
	"range_lerp",
	"round",
	"seed",
	"sign",
	"sin",
	"sinh",
	"sqrt",
	"stepify",
	"str",
	"str2var",
	"tan",
	"tanh",
	"to_json",
	"type_exists",
	"typeof",
	"validate_json",
	"var2bytes",
	"var2str",
	"weakref",
	"wrapf",
	"wrapi",
	"yield",
	
	"PI", "TAU", "INF", "NAN",
	
]

# Enhances a TextEdit to better highlight GDScript code.
static func enhance(text_edit: TextEdit) -> void:
	text_edit.draw_tabs = true
	text_edit.draw_spaces = true
	text_edit.scroll_smooth = true
	text_edit.caret_blink = true
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE

	if text_edit is CodeEdit:
		text_edit.set("line_numbers_draw_column", true)
		text_edit.set("gutters_draw_line_numbers", true)

	var highlighter := CodeHighlighter.new()
	highlighter.number_color = COLOR_NUMBERS
	highlighter.add_color_region('"', '"', COLOR_QUOTES)
	highlighter.add_color_region("'", "'", COLOR_QUOTES)
	highlighter.add_color_region("#", "", COLOR_COMMENTS, true)

	for class_name_str: String in ClassDB.get_class_list():
		highlighter.add_keyword_color(class_name_str, COLOR_CLASS)
		
		for property_info: Dictionary in ClassDB.class_get_property_list(class_name_str):
			var property_name: String = property_info.get("name", "")
			if not property_name.is_empty():
				highlighter.add_keyword_color(property_name, COLOR_MEMBER)

	for keyword: String in KEYWORDS:
		highlighter.add_keyword_color(keyword, COLOR_KEYWORD)

	text_edit.syntax_highlighter = highlighter
