extends Resource
const RegExp := preload("../utils/RegExp.gd")

export var leading_spaces := 0
export var keyword := "EXPORT"
export var closing := false
export var name := ""
export var global := false
export var start := 0
export var end := 0
export var before := []
export var after := []
export var text := []
var main_text: Array setget set_main_text, get_main_text

func _init(result: RegExMatch):
	leading_spaces = result.get_string("leading_spaces").length()
	keyword = result.get_string("keyword")
	closing = result.get_string("closing") != ""
	name = result.get_string("name")
	global = name == ""

func set_main_text(lines: Array) -> void:
	before = lines.slice(0, start - 1)
	after = lines.slice(end + 1, lines.size())
	text = lines.slice(start + 1, end - 1)
	if leading_spaces:
		for idx in text.size():
			var line: String = text[idx]
			line = line.substr(leading_spaces)
			text[idx] = line
	
func get_main_text() -> Array:
	var _text = text
	if leading_spaces:
		_text = []
		var indent = "\\t".repeat(leading_spaces)
		for idx in text.size():
			var line: String = text[idx]
			_text.append(indent + line)
	return before + _text + after


func _to_json() -> Dictionary:
	return {
		"leading_spaces": leading_spaces,
		"keyword" : keyword,
		"closing" : closing,
		"name" : name,
		"global" : global,
		"start" : start,
		"end" : end,
		"text" : text,
		"before": before,
		"after": after
	}


func _to_string() -> String:
	return JSON.print(_to_json(), "\t")
