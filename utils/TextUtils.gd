class_name TextUtils
extends Reference

# It's a trick to have a static instance of RegEx.
# Bad bad hacks, but it does the job and static class > autoload helper.
const _cache := {}

# Regex pattern to find [code][/code] tags
const REGEX_PATTERN_CODE = "\\[code\\].+?\\[\\/code\\]"
# Regex pattern to find the "func" literal
const REGEX_PATTERN_FUNC = "(?<func>func)"
# Regex pattern to find method calls (e.g. "draw(...)")
const REGEX_PATTERN_METHOD_CALL = "(?<method_name>[^\\s\\[\\]]*)(?<method_args>\\(.*?\\))"
# Regex pattern for numbers (with no special characters on either side)
const REGEX_PATTERN_NUMBER = "(?<number>[^#\\[\\]\\(\\)]?[0-9]++\\.?[0-9][^#\\[\\]\\(\\)]?)"

static func bbcode_add_code_color(bbcode_text := "") -> String:
	_initialize_regex_cache()

	var regex_matches : Array = _cache["regex_bbcode_code"].search_all(bbcode_text)

	var index_delta := 0
	
	for regex_match in regex_matches:
		var index_offset = regex_match.get_start() + index_delta
		var match_string : String = regex_match.strings[0]
		var initial_length := match_string.length()
		
		match_string = _cache["regex_bbcode_func"].sub(match_string, "[color=#%s]$func[/color]" % CodeEditorEnhancer.COLOR_KEYWORD.to_html(false))
		match_string = _cache["regex_bbcode_method_call"].sub(match_string, "[color=#%s]$method_name[/color]$method_args" % CodeEditorEnhancer.COLOR_MEMBER.to_html(false))
		match_string = _cache["regex_bbcode_number"].sub(match_string, "[color=#%s]$number[/color]" % CodeEditorEnhancer.COLOR_NUMBERS.to_html(false))
		
		bbcode_text.erase(index_offset, initial_length)
		bbcode_text = bbcode_text.insert(index_offset, match_string)
		index_delta += (match_string.length() - initial_length)

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

static func _initialize_regex_cache():
	if not _cache.has("regex_bbcode_code"):
		_cache["regex_bbcode_code"] = RegEx.new()
		_cache["regex_bbcode_code"].compile(REGEX_PATTERN_CODE)
	if not _cache.has("regex_bbcode_func"):
		_cache["regex_bbcode_func"] = RegEx.new()
		_cache["regex_bbcode_func"].compile(REGEX_PATTERN_FUNC)
	if not _cache.has("regex_bbcode_method_call"):
		_cache["regex_bbcode_method_call"] = RegEx.new()
		_cache["regex_bbcode_method_call"].compile(REGEX_PATTERN_METHOD_CALL)
	if not _cache.has("regex_bbcode_number"):
		_cache["regex_bbcode_number"] = RegEx.new()
		_cache["regex_bbcode_number"].compile(REGEX_PATTERN_NUMBER)
