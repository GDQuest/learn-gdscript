extends Node

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
const _REGEXES := {}
# Intended to be used as a constant
var _REGEX_REPLACE_MAP := {}


func _init() -> void:
	_REGEXES["code"] = RegEx.new()
	_REGEXES["func"] = RegEx.new()
	_REGEXES["number"] = RegEx.new()
	_REGEXES["string"] = RegEx.new()
	_REGEXES["symbol"] = RegEx.new()
	_REGEXES["format"] = RegEx.new()
	

	_REGEXES["code"].compile("\\[code\\](.+?)\\[\\/code\\]")
	_REGEXES["func"].compile("(?<func>func)")
	_REGEXES["number"].compile("(?<number>-?\\d+(\\.\\d+)?)")
	_REGEXES["string"].compile("(?<string>[\"'].+[\"'])")
	_REGEXES["symbol"].compile("(?<symbol>[a-zA-Z][a-zA-Z0-9_]+|[a-zA-Z])")
	_REGEXES["format"].compile("[\"\\-']?\\d+(\\.\\d+)?[\"']?|[\"'].+[\"']|[a-zA-Z0-9_]+")

	_REGEX_REPLACE_MAP = {
		"func": "[color=#%s]$func[/color]" % CodeEditorEnhancer.COLOR_KEYWORD.to_html(false),
		"number": "[color=#%s]$number[/color]" % CodeEditorEnhancer.COLOR_NUMBERS.to_html(false),
		"symbol": "[color=#%s]$symbol[/color]" % CodeEditorEnhancer.COLOR_MEMBER.to_html(false),
		"string": "[color=#%s]$string[/color]" % CodeEditorEnhancer.COLOR_QUOTES.to_html(false),
	}


func bbcode_add_code_color(bbcode_text := "") -> String:
	var regex_matches: Array = _REGEXES["code"].search_all(bbcode_text)
	var index_delta := 0

	for regex_match in regex_matches:
		var index_offset = regex_match.get_start() + index_delta
		var initial_length: int = regex_match.strings[0].length()
		var match_string: String = regex_match.strings[1]

		var colored_string := ""
		# The algorithm consists of finding all regex matches of a-zA-Z0-9_ and \d.\d
		# Then formatting these regex matches, and adding the parts in-between 
		# matches to the formatted string.
		var to_format: Array = _REGEXES["format"].search_all(match_string)
		var last_match_end := -1
		for match_to_format in to_format:
			var match_start: int = match_to_format.get_start()
			if last_match_end == -1 and match_start > 0:
				colored_string += match_string.substr(0, match_start)
			if last_match_end != -1:
				colored_string += match_string.substr(last_match_end, match_start - last_match_end)
			var part: String = match_to_format.get_string()
			for regex_type in [
				"string",
				"func",
				"symbol",
				"number",
			]:
				var replaced: String = _REGEXES[regex_type].sub(
					part, _REGEX_REPLACE_MAP[regex_type], false
				)
				if part != replaced:
					colored_string += replaced
					last_match_end = match_to_format.get_end()
					break

		colored_string += match_string.substr(last_match_end)
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


# Call this function to ensure that changes to the formatter don't change color highlighting.
func _test_formatting() -> void:
	var color_keyword := CodeEditorEnhancer.COLOR_KEYWORD.to_html(false)
	var color_number := CodeEditorEnhancer.COLOR_NUMBERS.to_html(false)
	var color_symbol := CodeEditorEnhancer.COLOR_MEMBER.to_html(false)
	var color_string := CodeEditorEnhancer.COLOR_QUOTES.to_html(false)
	# Pairs of strings that would be inside of [code] bbcode tags and their formatted output.
	# We omit the [code] tags in the dictionary for readability, they get added in the tests.
	var test_pairs := {
		"[0, 1, 2]": "[[color=#eb9433]0[/color], [color=#eb9433]1[/color], [color=#eb9433]2[/color]]",
		"-10": "[color=#" + color_number + "]-10[/color]",
		"\"Some string.\"": "[color=#" + color_string + "]\"Some string.\"[/color]",
		"add_order()": "[color=#" + color_symbol + "]add_order[/color]()",
		"Vector2(2, 0)": "[color=#" + color_symbol + "]Vector2[/color]([color=#" + color_number + "]2[/color], [color=#" + color_number + "]0[/color])",
		"use_item(item)": "[color=#" + color_symbol + "]use_item[/color]([color=#" + color_symbol + "]item[/color])",
		"=": "=",
		">": ">",
	}
	
	for input_text in test_pairs:
		var expected_output: String = "[code]" + test_pairs[input_text] + "[/code]"
		var output := bbcode_add_code_color("[code]" + input_text + "[/code]")
		assert(output == expected_output, "Expected output '%s' but got '%s' instead." % [expected_output, output])

