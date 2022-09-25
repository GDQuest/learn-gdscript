class_name TextUtils
extends Reference

# It's a trick to have a static instance of RegEx.
# Bad bad hacks, but it does the job and static class > autoload helper.
const _REGEX_CACHE := {}

# Regex pattern to find [code][/code] tags
const REGEX_PATTERN_CODE = "\\[code\\](.+?)\\[\\/code\\]"
# Regex pattern to find the "func" literal
const REGEX_PATTERN_FUNC = "(?<func>func)"
# Regex pattern to find method calls (e.g. "draw(...)")
const REGEX_PATTERN_METHOD_CALL = "(?<method_name>\\w[\\w\\d]*)(?<method_args>\\(.*?\\))"
# Regex pattern for numbers (with no special characters on either side)
const REGEX_PATTERN_NUMBER = "(?<number>[^#\\[\\]\\(\\)]?[0-9]++\\.?[0-9][^#\\[\\]\\(\\)]?)"
const REGEX_SYMBOL = "(?<symbol>[a-zA-Z][a-zA-Z0-9_]+)"


static func bbcode_add_code_color(bbcode_text := "") -> String:
	if not _REGEX_CACHE:
		_REGEX_CACHE["regex_code"] = RegEx.new()
		_REGEX_CACHE["regex_func"] = RegEx.new()
		_REGEX_CACHE["regex_method_call"] = RegEx.new()
		_REGEX_CACHE["regex_number"] = RegEx.new()
		_REGEX_CACHE["regex_symbol"] = RegEx.new()

		_REGEX_CACHE["regex_code"].compile(REGEX_PATTERN_CODE)
		_REGEX_CACHE["regex_func"].compile(REGEX_PATTERN_FUNC)
		_REGEX_CACHE["regex_method_call"].compile(REGEX_PATTERN_METHOD_CALL)
		_REGEX_CACHE["regex_number"].compile(REGEX_PATTERN_NUMBER)
		_REGEX_CACHE["regex_symbol"].compile(REGEX_SYMBOL)

	var regex_matches: Array = _REGEX_CACHE["regex_code"].search_all(bbcode_text)
	var index_delta := 0
	
	var REGEX_REPLACE_MAP := {
		"regex_func": "[color=#%s]$func[/color]" % CodeEditorEnhancer.COLOR_KEYWORD.to_html(false),
		"regex_method_call":
		"[color=#%s]$method_name[/color]$method_args" % CodeEditorEnhancer.COLOR_MEMBER.to_html(false),
		"regex_number": "[color=#%s]$number[/color]" % CodeEditorEnhancer.COLOR_NUMBERS.to_html(false),
		"regex_symbol": "[color=#%s]$symbol[/color]" % CodeEditorEnhancer.COLOR_MEMBER.to_html(false)
	}

	for regex_match in regex_matches:
		var index_offset = regex_match.get_start() + index_delta
		var initial_length: int = regex_match.strings[0].length()
		var match_string: String = regex_match.strings[1]

		var current_index := 0
		var last_closing_bracket_index := 0
		var colored_string := ""
		for regex_type in [
			"regex_func",
			"regex_method_call",
			"regex_number",
			"regex_symbol",
		]:
			var before := match_string.substr(current_index)
			var replaced: String = _REGEX_CACHE[regex_type].sub(match_string, REGEX_REPLACE_MAP[regex_type], false, current_index)
			if replaced != before:
				last_closing_bracket_index = match_string.rfind("]")
				colored_string += replaced.substr(current_index, last_closing_bracket_index)
				current_index = last_closing_bracket_index

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


static func convert_type_index_to_text(type: int) -> String:
	match type:
		TYPE_BOOL:
			return "boolean"
		TYPE_INT:
			return "whole number"
		TYPE_REAL:
			return "decimal number"
		TYPE_STRING:
			return "text string"
		TYPE_VECTOR2:
			return "2D vector"
		TYPE_RECT2:
			return "2D rectangle"
		TYPE_VECTOR3:
			return "3D vector"
		TYPE_TRANSFORM2D:
			return "2D transform"
		TYPE_PLANE:
			return "plane"
		TYPE_QUAT:
			return "quaternion"
		TYPE_AABB:
			return "axis-aligned bounding box"
		TYPE_BASIS:
			return "basis"
		TYPE_TRANSFORM:
			return "3D transform"
		TYPE_COLOR:
			return "color"
		TYPE_NODE_PATH:
			return "node path"
		TYPE_RID:
			return "resource's unique ID"
		TYPE_OBJECT:
			return "object"
		TYPE_DICTIONARY:
			return "dictionary"
		TYPE_ARRAY:
			return "array"
		TYPE_RAW_ARRAY:
			return "PoolByteArray"
		TYPE_INT_ARRAY:
			return "PoolIntArray"
		TYPE_REAL_ARRAY:
			return "PoolRealArray"
		TYPE_STRING_ARRAY:
			return "PoolStringArray"
		TYPE_VECTOR2_ARRAY:
			return "PoolVector2Array"
		TYPE_VECTOR3_ARRAY:
			return "PoolVector3Array"
		TYPE_COLOR_ARRAY:
			return "PoolColorArray"
		_:
			printerr("Type value %s should be a member of the TYPE_* enum, but it is not.")
	return "[ERROR, nonexistent type value %s]" % type
