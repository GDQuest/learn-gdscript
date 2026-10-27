# Sets options on a TextEdit for it to be more suitable as
# a text editor.
#
# Sets some colors, and adds keywords used GDScript to the
# highlight list, as well as strings and comments.
class_name CodeEditorEnhancer
extends Node

const GDSCRIPT_SYNTAX_HIGHLIGHTER_PATH := "res://ui/theme/gdscript_syntax_highlighter.tres"

# These colors come from the default Godot theme in version 4.7.
# In Godot: text_color: variables and other plain identifiers.
const COLOR_TEXT := Color(1.0, 1.0, 1.0, 0.75)
# In Godot: engine_type_color: Classes like Node, Sprite2D.
const COLOR_CLASS := Color(0.56, 1.0, 0.86)
# In Godot: base_type_color: bool, int, float, void, Variant.
const COLOR_BASE_TYPE := Color(0.26, 1.0, 0.76)
# In Godot: member_variable_color: property access after a dot.
const COLOR_MEMBER := Color(0.736, 0.88, 1.0)
# In Godot: keyword_color: keywords like func, var...
const COLOR_KEYWORD := Color(1.0, 0.44, 0.52)
# In Godot: control_flow_keyword_color: pink used for control flow keywords like
# if, else.
const COLOR_KEYWORD_CONTROL_FLOW := Color(1.0, 0.55, 0.8)
# In Godot: gdscript/global_function_color: for global functions like print, lerp...
const COLOR_GLOBAL_FUNCTION := Color(0.64, 0.64, 0.96)
# In Godot: function_color: general function calls.
const COLOR_FUNCTIONS := Color(0.34, 0.7, 1.0)
# In Godot: string_color: strings
const COLOR_STRING := Color(1.0, 0.93, 0.63)
# In Godot: comment_color: comments
const COLOR_COMMENTS := Color(1.0, 1.0, 1.0, 0.5)
# In Godot: number_color: numbers
const COLOR_NUMBER := Color(0.63, 1.0, 0.88)
# In Godot: symbol_color: color used for dots, parentheses, attribute accesses
const COLOR_SYMBOLS := Color(0.67, 0.79, 1.0)
# In Godot: gdscript/annotation_color: @export, @onready...
const COLOR_ANNOTATIONS := Color(1.0, 0.7, 0.45)

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

	# Boolean operators.
	"not",
	"and",
	"or",
	"in",
	"is",

	# Godot-specific keywords.
	"breakpoint",
	"await",

	# Bools and null.
	"null",
	"true",
	"false",
]

# This copies the official editor that now uses a pink color for control flow
# keywords in version 4.X.
# Ref: GDScriptLanguage::is_control_flow_keyword().
const CONTROL_FLOW_KEYWORDS := [
	"break",
	"continue",
	"elif",
	"else",
	"for",
	"if",
	"match",
	"pass",
	"return",
	"when",
	"while",
]

const BASE_TYPES := [
	"bool",
	"int",
	"float",
	"void",
	"Variant",
]

# Covers extra classes like Vector2 that are not derived from Object but that
# also get highlighted in green.
#
# I've only included the class names we use in the course right now;
# extend it if the course mentions new ones (or consider getting through reflection later)
const EXTRA_CLASS_NAMES := [
	"Array",
	"String",
	"Vector2",
]

const GLOBAL_FUNCTIONS := [
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
	"clampf",
	"clampi",
	"convert",
	"cos",
	"cosh",
	"db_to_linear",
	"deg_to_rad",
	"ease",
	"error_string",
	"exp",
	"floor",
	"floorf",
	"floori",
	"fmod",
	"fposmod",
	"hash",
	"instance_from_id",
	"inverse_lerp",
	"is_equal_approx",
	"is_inf",
	"is_instance_valid",
	"is_nan",
	"is_zero_approx",
	"lerp",
	"lerpf",
	"linear_to_db",
	"load",
	"log",
	"max",
	"maxf",
	"maxi",
	"min",
	"minf",
	"mini",
	"move_toward",
	"nearest_po2",
	"pow",
	"preload",
	"print",
	"print_stack",
	"printerr",
	"printraw",
	"prints",
	"printt",
	"push_error",
	"push_warning",
	"rad_to_deg",
	"randf",
	"randf_range",
	"randi",
	"randi_range",
	"randomize",
	"range",
	"remap",
	"round",
	"roundf",
	"roundi",
	"seed",
	"sign",
	"signf",
	"signi",
	"sin",
	"sinh",
	"smoothstep",
	"sqrt",
	"step_decimals",
	"str",
	"str_to_var",
	"snapped",
	"snappedf",
	"tan",
	"tanh",
	"type_exists",
	"type_string",
	"typeof",
	"var_to_bytes",
	"var_to_str",
	"weakref",
	"wrapf",
	"wrapi",

	# Built-in constants.
	"PI",
	"TAU",
	"INF",
	"NAN",
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
		# Note that we can't share the same highlighter resource across multiple
		# CodeEdits, it breaks highlighting otherwise. It's a resource that must
		# be unique to each code listing.
		text_edit.syntax_highlighter = text_edit.syntax_highlighter.duplicate(true)
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


# This function is only used in the editor, we bake as much as possible in a
# .tres file to avoid running these costly operations when instantiating every
# code listing.
static func enhance_highlighter(highlighter: CodeHighlighter) -> void:
	highlighter.number_color = COLOR_NUMBER
	highlighter.member_variable_color = COLOR_MEMBER
	highlighter.function_color = COLOR_FUNCTIONS
	highlighter.symbol_color = COLOR_SYMBOLS

	highlighter.clear_color_regions()
	highlighter.clear_keyword_colors()
	highlighter.clear_member_keyword_colors()
	highlighter.clear_highlighting_cache()

	highlighter.add_color_region("'", "'", COLOR_STRING)
	highlighter.add_color_region('"', '"', COLOR_STRING)
	highlighter.add_color_region("#", "", COLOR_COMMENTS, true)

	for classname: String in ClassDB.get_class_list():
		highlighter.add_keyword_color(classname, COLOR_CLASS)
	for classname: String in EXTRA_CLASS_NAMES:
		highlighter.add_keyword_color(classname, COLOR_CLASS)

	for base_type: String in BASE_TYPES:
		highlighter.add_keyword_color(base_type, COLOR_BASE_TYPE)

	for keyword: String in KEYWORDS:
		highlighter.add_keyword_color(keyword, COLOR_KEYWORD)

	for keyword: String in CONTROL_FLOW_KEYWORDS:
		highlighter.add_keyword_color(keyword, COLOR_KEYWORD_CONTROL_FLOW)

	for global_function: String in GLOBAL_FUNCTIONS:
		highlighter.add_keyword_color(global_function, COLOR_GLOBAL_FUNCTION)

	for annotation: String in ANNOTATIONS:
		highlighter.add_keyword_color("@%s" % annotation, COLOR_ANNOTATIONS)
