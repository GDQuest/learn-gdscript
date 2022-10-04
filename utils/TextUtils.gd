extends Node

# Regex pattern to find [code][/code] tags
const REGEX_PATTERN_CODE = "\\[code\\](.+?)\\[\\/code\\]"
# Regex pattern to find the "func" literal
const REGEX_PATTERN_FUNC = "(?<func>func)"
# Regex pattern to find method calls (e.g. "draw(...)")
const REGEX_PATTERN_METHOD_CALL = "(?<method_name>\\w[\\w\\d]*)(?<method_args>\\(.*?\\))"
# Regex pattern for numbers (with no special characters on either side)
const REGEX_PATTERN_NUMBER = "(?<number>\\d+(\\.\\d+)?)"
const REGEX_SYMBOL = "(?<symbol>[a-zA-Z][a-zA-Z0-9_]+)"

# Maps type indices to their string representation.
const TYPE_MAP := {
	TYPE_BOOL: "boolean",
	TYPE_INT: "whole number",
	TYPE_REAL: "decimal number",
	TYPE_STRING: "text string",
	TYPE_VECTOR2: "2D vector",
	TYPE_RECT2: "2D rectangle",
	TYPE_VECTOR3: "3D vector",
	TYPE_TRANSFORM2D: "2D transform",
	TYPE_PLANE: "plane",
	TYPE_QUAT: "quaternion",
	TYPE_AABB: "axis-aligned bounding box",
	TYPE_BASIS: "basis",
	TYPE_TRANSFORM: "3D transform",
	TYPE_COLOR: "color",
	TYPE_NODE_PATH: "node path",
	TYPE_RID: "resource's unique ID",
	TYPE_OBJECT: "object",
	TYPE_DICTIONARY: "dictionary",
	TYPE_ARRAY: "array",
	TYPE_RAW_ARRAY: "PoolByteArray",
	TYPE_INT_ARRAY: "PoolIntArray",
	TYPE_REAL_ARRAY: "PoolRealArray",
	TYPE_STRING_ARRAY: "PoolStringArray",
	TYPE_VECTOR2_ARRAY: "PoolVector2Array",
	TYPE_VECTOR3_ARRAY: "PoolVector3Array",
	TYPE_COLOR_ARRAY: "PoolColorArray",
}

# Caches regexes to highlight code in text.
const _REGEX_CACHE := {}
# Intended to be used as a constant
var _REGEX_REPLACE_MAP := {}


func _init() -> void:
	_REGEX_CACHE["code"] = RegEx.new()
	_REGEX_CACHE["func"] = RegEx.new()
	_REGEX_CACHE["method_call"] = RegEx.new()
	_REGEX_CACHE["number"] = RegEx.new()
	_REGEX_CACHE["symbol"] = RegEx.new()

	_REGEX_CACHE["code"].compile(REGEX_PATTERN_CODE)
	_REGEX_CACHE["func"].compile(REGEX_PATTERN_FUNC)
	_REGEX_CACHE["method_call"].compile(REGEX_PATTERN_METHOD_CALL)
	_REGEX_CACHE["number"].compile(REGEX_PATTERN_NUMBER)
	_REGEX_CACHE["symbol"].compile(REGEX_SYMBOL)

	_REGEX_REPLACE_MAP = {
		"func": "[color=#%s]$func[/color]" % CodeEditorEnhancer.COLOR_KEYWORD.to_html(false),
		"method_call":
		(
			"[color=#%s]$method_name[/color]$method_args"
			% CodeEditorEnhancer.COLOR_MEMBER.to_html(false)
		),
		"number": "[color=#%s]$number[/color]" % CodeEditorEnhancer.COLOR_NUMBERS.to_html(false),
		"symbol": "[color=#%s]$symbol[/color]" % CodeEditorEnhancer.COLOR_MEMBER.to_html(false)
	}


func bbcode_add_code_color(bbcode_text := "") -> String:
	var regex_matches: Array = _REGEX_CACHE["code"].search_all(bbcode_text)
	var index_delta := 0

	for regex_match in regex_matches:
		var index_offset = regex_match.get_start() + index_delta
		var initial_length: int = regex_match.strings[0].length()
		var match_string: String = regex_match.strings[1]

		var current_index := 0
		var last_closing_bracket_index := 0
		var colored_string := ""
		for regex_type in [
			"func",
			"method_call",
			"number",
			"symbol",
		]:
			var before := match_string.substr(current_index)
			var replaced: String = _REGEX_CACHE[regex_type].sub(
				match_string, _REGEX_REPLACE_MAP[regex_type], false, current_index
			)
			if replaced != before:
				last_closing_bracket_index = match_string.rfind("]")
				colored_string += replaced.substr(current_index, last_closing_bracket_index)
				current_index = last_closing_bracket_index

		if colored_string == "":
			colored_string = match_string
		colored_string = "[code]" + colored_string + "[/code]"
		bbcode_text.erase(index_offset, initial_length)
		bbcode_text = bbcode_text.insert(index_offset, colored_string)
		index_delta += (colored_string.length() - initial_length)

	return bbcode_text


static func convert_input_action_to_tooltip(action: String) -> String:
	var events := InputMap.get_action_list(action)
	var count := events.size()
	var output := "Shortcut:" if count < 2 else "Shortcuts:"
	for index in count:
		if index > 0:
			output += ","
		output += " " + OS.get_scancode_string(events[index].get_scancode_with_modifiers())
	return output


func convert_type_index_to_text(type: int) -> String:
	if type in TYPE_MAP:
		return TYPE_MAP[type]
	else:
		printerr("Type value %s should be a member of the TYPE_* enum, but it is not.")
		return "[ERROR, nonexistent type value %s]" % type
