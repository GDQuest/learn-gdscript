extends Node

# Maps type indices to their string representation.
# Godot 4: Variant.Type constants changed names (TYPE_REAL -> TYPE_FLOAT, etc.)
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

	# Godot 4 packed arrays
	TYPE_PACKED_BYTE_ARRAY: "PackedByteArray",
	TYPE_PACKED_INT32_ARRAY: "PackedInt32Array",
	TYPE_PACKED_FLOAT32_ARRAY: "PackedFloat32Array",
	TYPE_PACKED_STRING_ARRAY: "PackedStringArray",
	TYPE_PACKED_VECTOR2_ARRAY: "PackedVector2Array",
	TYPE_PACKED_VECTOR3_ARRAY: "PackedVector3Array",
	TYPE_PACKED_COLOR_ARRAY: "PackedColorArray",
}

# Caches regexes to highlight code in text.
# Godot 4: these must be vars (you mutate them in _init()).
var _regexes: Dictionary = {}
var _regex_replace_map: Dictionary = {}

func _init() -> void:
	_regexes = {
		"code": RegEx.new(),
		"func": RegEx.new(),
		"number": RegEx.new(),
		"string": RegEx.new(),
		"symbol": RegEx.new(),
		"format": RegEx.new(),
	}

	(_regexes["code"] as RegEx).compile("\\[code\\](.+?)\\[\\/code\\]")
	(_regexes["func"] as RegEx).compile("(?<func>\\bfunc\\b)")
	(_regexes["number"] as RegEx).compile("(?<number>-?\\d+(\\.\\d+)?)")
	(_regexes["string"] as RegEx).compile("(?<string>[\"'].+[\"'])")
	(_regexes["symbol"] as RegEx).compile("(?<symbol>[a-zA-Z][a-zA-Z0-9_]+|[a-zA-Z])")
	(_regexes["format"] as RegEx).compile("[\"\\-']?\\d+(\\.\\d+)?[\"']?|[\"'].+[\"']|[a-zA-Z0-9_]+")

	_regex_replace_map = {
		"func": "[color=#%s]$func[/color]" % CodeEditorEnhancer.COLOR_KEYWORD.to_html(false),
		"number": "[color=#%s]$number[/color]" % CodeEditorEnhancer.COLOR_NUMBERS.to_html(false),
		"symbol": "[color=#%s]$symbol[/color]" % CodeEditorEnhancer.COLOR_MEMBER.to_html(false),
		"string": "[color=#%s]$string[/color]" % CodeEditorEnhancer.COLOR_QUOTES.to_html(false),
	}


func bbcode_add_code_color(bbcode_text: String = "") -> String:
	if _regexes.is_empty():
		return bbcode_text

	var code_re := _regexes.get("code") as RegEx
	if code_re == null:
		return bbcode_text

	var regex_matches: Array[RegExMatch] = code_re.search_all(bbcode_text)
	var index_delta := 0

	for rm in regex_matches:
		var index_offset: int = rm.get_start() + index_delta
		var initial_length: int = rm.strings[0].length()
		var match_string: String = rm.strings[1]

		var colored_string := ""
		var fmt_re := _regexes.get("format") as RegEx
		if fmt_re == null:
			continue

		# Find all chunks to format
		var to_format: Array[RegExMatch] = fmt_re.search_all(match_string)
		var last_match_end := -1

		for mf in to_format:
			var match_start: int = mf.get_start()

			if last_match_end == -1 and match_start > 0:
				colored_string += match_string.substr(0, match_start)
			elif last_match_end != -1:
				colored_string += match_string.substr(last_match_end, match_start - last_match_end)

			var part: String = mf.get_string()

			for regex_type in ["string", "func", "symbol", "number"]:
				var r := _regexes.get(regex_type) as RegEx
				var repl := _regex_replace_map.get(regex_type, "") as String
				if r == null or repl == "":
					continue

				var replaced: String = r.sub(part, repl, false)
				if part != replaced:
					colored_string += replaced
					last_match_end = mf.get_end()
					break

		colored_string += match_string.substr(last_match_end)
		if colored_string == "":
			colored_string = match_string

		colored_string = "[code]" + colored_string + "[/code]"
		bbcode_text = bbcode_text.erase(index_offset, initial_length)
		bbcode_text = bbcode_text.insert(index_offset, colored_string)
		index_delta += (colored_string.length() - initial_length)

	return bbcode_text


static func convert_input_action_to_tooltip(action: String) -> String:
	var events: Array[InputEvent] = InputMap.action_get_events(action)
	var count := events.size()
	var output := "Shortcut:" if count < 2 else "Shortcuts:"

	for i in range(count):
		if i > 0:
			output += ","
		output += " " + _event_to_shortcut_string(events[i])

	return output


static func _event_to_shortcut_string(ev: InputEvent) -> String:
	# Keyboard
	if ev is InputEventKey:
		var key_ev := ev as InputEventKey
		return OS.get_keycode_string(key_ev.get_keycode_with_modifiers())

	# Mouse buttons
	if ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		return "Mouse %d" % mb.button_index

	# Joypad buttons
	if ev is InputEventJoypadButton:
		var jb := ev as InputEventJoypadButton
		return "Joy %d" % jb.button_index

	# Joypad axes
	if ev is InputEventJoypadMotion:
		var jm := ev as InputEventJoypadMotion
		return "Joy Axis %d" % jm.axis

	return ev.as_text()


func convert_type_index_to_text(type: int) -> String:
	if TYPE_MAP.has(type):
		return TYPE_MAP[type]
	printerr("Type value %s should be a member of the TYPE_* enum, but it is not." % type)
	return "[ERROR, nonexistent type value %s]" % type


# Translates multi-paragraph text by splitting on double newlines.
func tr_paragraph(text: String) -> String:
	if text.is_empty():
		return text

	# Normalize line endings first (Windows CRLF to LF)
	var normalized := text.replace("\r\n", "\n")
	var paragraphs := normalized.split("\n\n")
	if paragraphs.size() <= 1:
		return tr(normalized)

	var translated := PackedStringArray()
	for paragraph in paragraphs:
		var trimmed := paragraph.strip_edges()
		if trimmed.is_empty():
			translated.append("")
		else:
			translated.append(tr(trimmed))

	# Godot 4.5: use String.join for best compatibility
	return "\n\n".join(translated)


# Call this function to ensure that changes to the formatter don't change color highlighting.
func _test_formatting() -> void:
	var _color_keyword := CodeEditorEnhancer.COLOR_KEYWORD.to_html(false)
	var color_number := CodeEditorEnhancer.COLOR_NUMBERS.to_html(false)
	var color_symbol := CodeEditorEnhancer.COLOR_MEMBER.to_html(false)
	var color_string := CodeEditorEnhancer.COLOR_QUOTES.to_html(false)

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

	for input_text in test_pairs.keys():
		var key := str(input_text)
		var expected_output: String = "[code]" + str(test_pairs[input_text]) + "[/code]"
		var output := bbcode_add_code_color("[code]" + key + "[/code]")
		assert(output == expected_output, "Expected output '%s' but got '%s' instead." % [expected_output, output])
