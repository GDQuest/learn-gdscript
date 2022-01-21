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
