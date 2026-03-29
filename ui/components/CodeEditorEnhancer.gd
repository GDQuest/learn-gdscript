# Sets options on a TextEdit for it to be more suitable as
# a text editor.
#
# Sets some colors, and adds keywords used GDScript to the
# highlight list, as well as strings and comments.
class_name CodeEditorEnhancer
extends Node

const GDSCRIPT_SYNTAX_HIGHLIGHTER_PATH := "res://ui/theme/gdscript_syntax_highlighter.tres"

const COLOR_CLASS := Color(0.666667, 0, 0.729412)
const COLOR_MEMBER := Color(0.32, 0.82, 0.97)
const COLOR_KEYWORD := Color(1, 0.094118, 0.321569)
const COLOR_QUOTES := Color(1, 0.960784, 0.25098)
const COLOR_COMMENTS := Color(0.290196, 0.294118, 0.388235)
const COLOR_NUMBERS := Color(0.922, 0.580, 0.200)
const COLOR_SYMBOLS := Color(0.407, 0.587, 1.0)
const COLOR_FUNCTIONS := Color(0.34, 0.69, 1.0)
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
	"super",

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
	"setget",
	"breakpoint",

	# Primitive data types.
	"bool",
	"int",
	"float",
	"null",
	"true",
	"false",
	"void",

	# Global GDScript namespace.
	"await",
	"Color8",
	"ColorN",
	"abs",
	"acos",
	"asin",
	"assert",
	"atan",
	"atan2",
	"bytes_to_var",
	"cartesian2polar",
	"ceil",
	"char",
	"clamp",
	"convert",
	"cos",
	"cosh",
	"db_to_linear",
	"decials",
	"move_toward",
	"deg_to_rad",
	"dict_to_inst",
	"ease",
	"expo",
	"floor",
	"fmod",
	"fposmod",
	"funcref",
	"hash",
	"inst_to_dict",
	"instance_from_id",
	"inverse_lerp",
	"is_inf",
	"is_nan",
	"len",
	"lerp",
	"linear_to_db",
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
	"rad_to_deg",
	"randf_range",
	"rand_seed",
	"randf",
	"randi",
	"randomize",
	"range",
	"remap",
	"round",
	"seed",
	"sign",
	"sin",
	"sinh",
	"sqrt",
	"snapped",
	"str",
	"str_to_var",
	"tan",
	"tanh",
	"JSON.new().stringify",
	"type_exists",
	"typeof",
	"validate_json",
	"var_to_bytes",
	"var_to_str",
	"weakref",
	"wrapf",
	"wrapi",
	"PI",
	"TAU",
	"INF",
	"NAN",
	"Variant",
]

const ANNOTATIONS := [
	"onready",
	"icon",
	"abstract",
	"export",
	"export_range",
	"export_category",
	"export_color_no_alpha",
	"export_custom",
	"export_dir",
	"export_enum",
	"export_exp_easing",
	"export_file",
	"export_file_path",
	"export_flags",
	"export_flags_2d_navigation",
	"export_flags_2d_physics",
	"export_flags_2d_render",
	"export_flags_3d_navigation",
	"export_flags_3d_physics",
	"export_flags_3d_render",
	"export_flags_avoidance",
	"export_global_dir",
	"export_global_file",
	"export_group",
	"export_multiline",
	"export_node_path",
	"export_placeholder",
	"export_range",
	"export_storage",
	"export_subgroup",
	"export_tool_button",
	"rpc",
	"static_unload",
	"tool",
	"warning_ignore",
	"warning_ignore_restore",
	"warning_ignore_start",
]


# Enhances a TextEdit to better highlight GDScript code.
static func enhance(text_edit: CodeEdit) -> void:
	if not text_edit.syntax_highlighter or text_edit.syntax_highlighter.resource_path != GDSCRIPT_SYNTAX_HIGHLIGHTER_PATH:
		text_edit.syntax_highlighter = load(GDSCRIPT_SYNTAX_HIGHLIGHTER_PATH)
	if not Engine.is_editor_hint():
		text_edit.syntax_highlighter = text_edit.syntax_highlighter.duplicate()
	text_edit.gutters_draw_line_numbers = true
	text_edit.draw_tabs = true
	text_edit.draw_spaces = true
	text_edit.scroll_smooth = true
	text_edit.caret_blink = true
	text_edit.wrap_mode = TextEdit.LINE_WRAPPING_NONE


static func _input_event_bypass(event: InputEvent, target: Control) -> void:
	if event is InputEventKey:
		target.accept_event()


static func prevent_editable(text_edit: CodeEdit) -> void:
	text_edit.gui_input.connect(_input_event_bypass.bind(text_edit))


static func enhance_highlighter(highlighter: CodeHighlighter) -> void:
	highlighter.number_color = COLOR_NUMBERS
	highlighter.member_variable_color = COLOR_MEMBER
	highlighter.function_color = COLOR_FUNCTIONS
	highlighter.symbol_color = COLOR_SYMBOLS

	highlighter.clear_color_regions()
	highlighter.clear_keyword_colors()
	highlighter.clear_member_keyword_colors()
	highlighter.clear_highlighting_cache()

	highlighter.add_color_region("'", "'", COLOR_QUOTES)
	highlighter.add_color_region('"', '"', COLOR_QUOTES)
	highlighter.add_color_region("#", "", COLOR_COMMENTS, true)

	for classname in ClassDB.get_class_list():
		highlighter.add_keyword_color(classname, COLOR_CLASS)
		for member: Dictionary in ClassDB.class_get_property_list(classname):
			var member_name: String = member.name
			highlighter.add_member_keyword_color(member_name, COLOR_MEMBER)

	for keyword: String in KEYWORDS:
		highlighter.add_keyword_color(keyword, COLOR_KEYWORD)

	for annotation: String in ANNOTATIONS:
		highlighter.add_keyword_color("@%s" % annotation, COLOR_NUMBERS)
