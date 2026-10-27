@tool
extends Node

# Maps type indices to their string representation.
const TYPE_MAP := {
	TYPE_BOOL: "boolean",
	TYPE_INT: "whole number",
	TYPE_FLOAT: "decimal number",
	TYPE_STRING: "text string",
	TYPE_VECTOR2: "2D vector",
	TYPE_RECT2: "2D rectangle",
	TYPE_VECTOR3: "3D vector",
	TYPE_TRANSFORM2D: "2D transform",
	TYPE_PLANE: "plane",
	TYPE_QUATERNION: "quaternion",
	TYPE_AABB: "axis-aligned bounding box",
	TYPE_BASIS: "basis",
	TYPE_TRANSFORM3D: "3D transform",
	TYPE_COLOR: "color",
	TYPE_NODE_PATH: "node path",
	TYPE_RID: "resource's unique ID",
	TYPE_OBJECT: "object",
	TYPE_DICTIONARY: "dictionary",
	TYPE_ARRAY: "array",
	TYPE_PACKED_BYTE_ARRAY: "PackedByteArray",
	TYPE_PACKED_INT32_ARRAY: "PackedInt32Array",
	TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array",
	TYPE_PACKED_STRING_ARRAY: "PackedStringArray",
	TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array",
	TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array",
	TYPE_PACKED_COLOR_ARRAY: "PackedColorArray",
}

# Caches regexes and color tags used to highlight code inside [code] spans.
var _regex_code: RegEx = null
# Tokens: numbers, quoted strings, function calls (an identifier followed by
# an opening parenthesis), plain identifiers, and parentheses.
var _regex_format: RegEx = null

# Opening bbcode color tags, using the same colors as the code editor.
var _tag_string := ""
var _tag_number := ""
var _tag_function := ""
var _tag_parenthesis := ""
var _tag_keyword := ""
var _tag_base_type := ""
var _tag_global_function := ""
var _tag_class := ""
var _tag_control_flow_keyword := ""

# Cache of global function names from CodeEditorEnhancer.GLOBAL_FUNCTIONS, for
# lookups during code highlighting. The list is fairly long so I'm using this as
# a "set"
var _cache_gdscript_global_functions := { }

var _glossary: Glossary = null


func _ready() -> void:
	get_glossary()


func _init() -> void:
	_regex_code = RegEx.create_from_string(r"\[code\](.+?)\[\/code\]")
	_regex_format = RegEx.create_from_string(
		"-?\\d+(\\.\\d+)?|[\"'].+[\"']|[a-zA-Z_]\\w*\\s*\\(|[a-zA-Z0-9_]+|[()]"
	)

	_tag_string = "[color=#%s]" % CodeEditorEnhancer.COLOR_STRING.to_html(false)
	_tag_number = "[color=#%s]" % CodeEditorEnhancer.COLOR_NUMBER.to_html(false)
	_tag_function = "[color=#%s]" % CodeEditorEnhancer.COLOR_FUNCTIONS.to_html(false)
	_tag_parenthesis = "[color=#%s]" % CodeEditorEnhancer.COLOR_MEMBER.to_html(false)
	_tag_keyword = "[color=#%s]" % CodeEditorEnhancer.COLOR_KEYWORD.to_html(false)
	_tag_base_type = "[color=#%s]" % CodeEditorEnhancer.COLOR_BASE_TYPE.to_html(false)
	_tag_global_function = "[color=#%s]" % CodeEditorEnhancer.COLOR_GLOBAL_FUNCTION.to_html(false)
	_tag_class = "[color=#%s]" % CodeEditorEnhancer.COLOR_CLASS.to_html(false)
	_tag_control_flow_keyword = "[color=#%s]" % CodeEditorEnhancer \
			.COLOR_KEYWORD_CONTROL_FLOW \
			.to_html(false)
	for function_name in CodeEditorEnhancer.GLOBAL_FUNCTIONS:
		_cache_gdscript_global_functions[function_name] = true


## Use this function to get the Glossary singleton. It gives access to glossary
## terms.
func get_glossary() -> Glossary:
	if _glossary == null:
		_glossary = Glossary.new()
	return _glossary


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		get_glossary().reload()


## Prepares lesson text to display in a RichTextLabel with bbcode enabled:
##
## - Splits paragraphs on \n\n
## - Escapes literal square brackets in code as [lb]/[rb].
## - Adds syntax highlighting inside [code] spans.
##
## Use it on all markup to display on RichTextLabels in the UI, after
## translation (We can't apply transformations like syntax highlighting before
## translation because it wouldn't match the input text).
func preprocess_bbcode_for_rich_text_label(text := "") -> String:
	return bbcode_add_code_color(paragraph(text))


func bbcode_add_code_color(text := "") -> String:
	var regex_matches: Array = _regex_code.search_all(text)
	if regex_matches.is_empty():
		return text

	# Matches are found from left to right, so we can rebuild the text in a
	# single pass, copying the parts between [code] spans unchanged.
	var output := ""
	var last_match_end := 0
	for regex_match: RegExMatch in regex_matches:
		output += text.substr(last_match_end, regex_match.get_start() - last_match_end)
		output += "[code]" + _highlight_code(regex_match.strings[1]) + "[/code]"
		last_match_end = regex_match.get_end()
	output += text.substr(last_match_end)
	return output


# Colors numbers, strings, and function calls in a [code] span's contents.
# The algorithm tokenizes the code with _regex_format, colors each token based
# on its first character, and leaves the text in between uncolored.
#
# Note this only does a subset of the syntax highlighting in the code
# editor, just enough for lesson text to look good.
func _highlight_code(code: String) -> String:
	var output := ""
	var last_match_end := 0
	for regex_match: RegExMatch in _regex_format.search_all(code):
		var part := regex_match.get_string()
		var formatted := ""
		var first_character := part[0]
		# For strings, parentheses, and numbers, we can determine the token type
		# based on the first character.
		if first_character == "\"" or first_character == "'":
			formatted = _tag_string + part + "[/color]"
		elif first_character == "(" or first_character == ")":
			formatted = _tag_parenthesis + part + "[/color]"
		elif first_character == "-" or (first_character >= "0" and first_character <= "9"):
			formatted = _tag_number + part + "[/color]"
		# We found a function call and highlight it like a member call in Godot. It
		# highlights any pattern that's like name(...). Global functions like
		# print() use the editor's purple global function color instead.
		elif part.ends_with("("):
			var name_part := part.substr(0, part.length() - 1)
			var function_name := name_part.rstrip(" \t")
			var whitespace := name_part.substr(function_name.length())
			var function_tag := _tag_function
			if function_name in _cache_gdscript_global_functions:
				function_tag = _tag_global_function
			# This is for base type constructors like calling int().
			elif function_name in CodeEditorEnhancer.BASE_TYPES:
				function_tag = _tag_base_type
			# This is for class constructors like calling Vector2().
			elif function_name in CodeEditorEnhancer.EXTRA_CLASS_NAMES:
				function_tag = _tag_class
			elif function_name in CodeEditorEnhancer.KEYWORDS:
				# Keywords followed by a parenthesis, like "if (...)", are
				# matched as function calls by the tokenizer.
				function_tag = _tag_keyword
			elif function_name in CodeEditorEnhancer.CONTROL_FLOW_KEYWORDS:
				function_tag = _tag_control_flow_keyword
			formatted = function_tag + function_name + "[/color]" + whitespace + _tag_parenthesis + "([/color]"
		elif part in CodeEditorEnhancer.KEYWORDS:
			formatted = _tag_keyword + part + "[/color]"
		elif part in CodeEditorEnhancer.CONTROL_FLOW_KEYWORDS:
			formatted = _tag_control_flow_keyword + part + "[/color]"
		elif part in CodeEditorEnhancer.BASE_TYPES:
			formatted = _tag_base_type + part + "[/color]"
		elif part in CodeEditorEnhancer.EXTRA_CLASS_NAMES:
			formatted = _tag_class + part + "[/color]"
		if formatted.is_empty():
			continue
		output += _bbcode_escape_square_brackets(
			code.substr(last_match_end, regex_match.get_start() - last_match_end)
		)
		output += formatted
		last_match_end = regex_match.get_end()
	output += _bbcode_escape_square_brackets(code.substr(last_match_end))
	return output


func convert_input_action_to_tooltip(action: String) -> String:
	var events := InputMap.action_get_events(action)
	var count := events.size()
	var output := "Shortcut:" if count < 2 else "Shortcuts:"
	for index in count:
		if index > 0:
			output += ","
		output += " " + OS.get_keycode_string(
			(events[index] as InputEventKey).get_keycode_with_modifiers()
		)
	return output


func convert_type_index_to_text(type: int) -> String:
	if type in TYPE_MAP:
		return TYPE_MAP[type]
	else:
		printerr("Type value %s should be a member of the TYPE_* enum, but it is not.")
		return "[ERROR, nonexistent type value %s]" % type


# Translates multi-paragraph text by splitting on double newlines.
#
# We split strings on paragraph breaks in the build system to make translations
# more fine-grained and easier to update.
#
# we split each paragraph individually, then we join the result. This allows PO
# files to store translations at the paragraph level rather than as large
# multi-paragraph blocks.
func tr_paragraph(text: String) -> String:
	if text.is_empty():
		return text

	var normalized_line_endings := text.replace("\r\n", "\n")
	var paragraphs := _paragraphs_split_and_normalize(normalized_line_endings)
	if paragraphs.size() <= 1:
		return tr(normalized_line_endings)

	var translated_paragraphs := PackedStringArray()
	for paragraph_text in paragraphs:
		translated_paragraphs.append(tr(paragraph_text))

	return "\n\n".join(translated_paragraphs)


func paragraph(text: String) -> String:
	if text.is_empty():
		return text

	var normalized := text.replace("\r\n", "\n")
	var paragraphs := _paragraphs_split_and_normalize(normalized)
	if paragraphs.size() <= 1:
		return normalized

	return "\n\n".join(paragraphs)


# This function splits strings into paragraphs and strips each line. This
# normalizes paragraphs and we can then translate each one individually.
func _paragraphs_split_and_normalize(text: String) -> PackedStringArray:
	var paragraphs := text.split("\n\n")
	for index in paragraphs.size():
		paragraphs[index] = paragraphs[index].strip_edges()
	return paragraphs


## Replaces raw square brackets with the literal bracket tags [lb] and [rb].
func _bbcode_escape_square_brackets(text: String) -> String:
	# Scanning and manipulating the string would be slower in GDScript, so we
	# use these search and replace instead (; - ;).
	return (
		text
		.replace("[", "\u0001")
		.replace("]", "\u0002")
		.replace("\u0001", "[lb]")
		.replace("\u0002", "[rb]")
	)


# Call this function to ensure that changes to the formatter don't change color highlighting.
# TODO: move this to a test runner and to the program's test suite.
func _test_formatting() -> void:
	var color_number := CodeEditorEnhancer.COLOR_NUMBER.to_html(false)
	var color_string := CodeEditorEnhancer.COLOR_STRING.to_html(false)
	var color_function := CodeEditorEnhancer.COLOR_FUNCTIONS.to_html(false)
	var color_parenthesis := CodeEditorEnhancer.COLOR_MEMBER.to_html(false)
	var color_keyword := CodeEditorEnhancer.COLOR_KEYWORD.to_html(false)
	var tag_test_function := "[color=#" + color_function + "]"
	var tag_test_parenthesis := "[color=#" + color_parenthesis + "]"
	var tag_test_number := "[color=#" + color_number + "]"
	var tag_test_global_function := "[color=#" + CodeEditorEnhancer.COLOR_GLOBAL_FUNCTION.to_html(
		false
	) + "]"
	var tag_test_base_type := "[color=#" + CodeEditorEnhancer.COLOR_BASE_TYPE.to_html(false) + "]"
	var tag_test_class := "[color=#" + CodeEditorEnhancer.COLOR_CLASS.to_html(false) + "]"
	var tag_test_control_flow_keyword := "[color=#" + CodeEditorEnhancer \
			.COLOR_KEYWORD_CONTROL_FLOW \
			.to_html(false) + "]"
	# Pairs of strings that would be inside of [code] bbcode tags and their formatted output.
	# We omit the [code] tags in the dictionary for readability, they get added in the tests.
	var test_pairs := {
		"[0, 1, 2]": "[lb]" + tag_test_number + "0[/color], " + tag_test_number
		+ "1[/color], " + tag_test_number + "2[/color][rb]",
		"-10": tag_test_number + "-10[/color]",
		"\"Some string.\"": "[color=#" + color_string + "]\"Some string.\"[/color]",
		"add_order()": tag_test_function + "add_order[/color]" + tag_test_parenthesis
		+ "([/color]" + tag_test_parenthesis + ")[/color]",
		"Vector2(2, 0)": tag_test_class + "Vector2[/color]" + tag_test_parenthesis
		+ "([/color]" + tag_test_number + "2[/color], " + tag_test_number
		+ "0[/color]" + tag_test_parenthesis + ")[/color]",
		"Vector2": tag_test_class + "Vector2[/color]",
		"int(5)": tag_test_base_type + "int[/color]" + tag_test_parenthesis + "([/color]"
		+ tag_test_number + "5[/color]" + tag_test_parenthesis + ")[/color]",
		"if x > 0": tag_test_control_flow_keyword + "if[/color] x > "
		+ tag_test_number + "0[/color]",
		"use_item(item)": tag_test_function + "use_item[/color]" + tag_test_parenthesis
		+ "([/color]item" + tag_test_parenthesis + ")[/color]",
		"lerp(a, clamp(x, 0, 1))": tag_test_global_function + "lerp[/color]" + tag_test_parenthesis
		+ "([/color]a, " + tag_test_global_function + "clamp[/color]" + tag_test_parenthesis
		+ "([/color]x, " + tag_test_number + "0[/color], " + tag_test_number + "1[/color]"
		+ tag_test_parenthesis + ")[/color]" + tag_test_parenthesis + ")[/color]",
		"print(\"(\")": tag_test_global_function + "print[/color]" + tag_test_parenthesis
		+ "([/color][color=#" + color_string + "]\"(\"[/color]" + tag_test_parenthesis + ")[/color]",
		"var score: int = 5": "[color=#" + color_keyword + "]var[/color] score: "
		+ tag_test_base_type + "int[/color] = " + tag_test_number + "5[/color]",
		"if (x > 0):": tag_test_control_flow_keyword + "if[/color] " + tag_test_parenthesis
		+ "([/color]x > " + tag_test_number + "0[/color]" + tag_test_parenthesis + ")[/color]:",
		"func _ready():": "[color=#" + color_keyword + "]func[/color] "
		+ tag_test_function + "_ready[/color]" + tag_test_parenthesis
		+ "([/color]" + tag_test_parenthesis + ")[/color]:",
		"units[cell]": "units[lb]cell[rb]",
		"=": "=",
		">": ">",
	}

	for input_text: String in test_pairs:
		var expected_output: String = "[code]" + test_pairs[input_text] + "[/code]"
		var output := bbcode_add_code_color("[code]" + input_text + "[/code]")
		assert(
			output == expected_output,
			"Expected output '%s' but got '%s' instead." % [expected_output, output],
		)
