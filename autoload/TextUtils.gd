extends Node

var _regex_bbcode_code := RegEx.new()


func _ready() -> void:
	_regex_bbcode_code.compile("\\[code\\].+?\\[\\/code\\]")


func bbcode_add_code_color(bbcode_text := "") -> String:
	return _regex_bbcode_code.sub(bbcode_text, "[color=#c6c4e1]$0[/color]", true)


func convert_input_action_to_tooltip(action: String) -> String:
	var events := InputMap.get_action_list(action)
	var count := events.size()
	var output := "Shortcut:" if count < 2 else "Shortcuts:"
	for index in count:
		if index > 0:
			output += ","
		output += " " + OS.get_scancode_string(events[index].get_scancode_with_modifiers())
	return output
