extends Node

var _regex_bbcode_code := RegEx.new()


func _ready() -> void:
	_regex_bbcode_code.compile("\\[code\\].+?\\[\\/code\\]")


func bbcode_add_code_color(bbcode_text := "") -> String:
	return _regex_bbcode_code.sub(bbcode_text, "[color=#c6c4e1]$0[/color]", true)
