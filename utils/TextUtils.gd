class_name TextUtils
extends Reference

# It's a trick to have a static instance of RegEx.
# Bad bad hacks, but it does the job and static class > autoload helper.
const _cache := {}


static func bbcode_add_code_color(bbcode_text := "") -> String:
	if not _cache.has("regex_bbcode_code"):
		_cache["regex_bbcode_code"] = RegEx.new()
		_cache["regex_bbcode_code"].compile("\\[code\\].+?\\[\\/code\\]")

	return _cache["regex_bbcode_code"].sub(bbcode_text, "[color=#c6c4e1]$0[/color]", true)


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
