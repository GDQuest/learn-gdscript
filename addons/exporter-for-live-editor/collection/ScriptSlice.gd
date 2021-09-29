extends Resource
const RegExp := preload("../utils/RegExp.gd")


export var leading_spaces := 0
export var keyword := "EXPORT"
export var closing := false
export var name := ""
export var global := false
export var start := 0
export var end := 0
export var lines_before := []
export var lines_after := []
export var lines_editable := []
var slice_text: String setget _read_only, get_slice_text
var full_text: String setget _read_only, get_full_text
var current_text: String setget set_current_text, get_current_text
var current_full_text: String setget _read_only, get_current_full_text
var start_offset: int setget _read_only, get_start_offset
var end_offset: int setget _read_only, get_end_offset

func _init() -> void:
	lines_before = []
	lines_after = []
	lines_editable = []


static func indent_text(indent_amount: int, lines: PoolStringArray) -> PoolStringArray:
	var _text = PoolStringArray()
	var indent = "\t".repeat(indent_amount)
	for idx in lines.size():
		var line: String = lines[idx]
		_text.append(indent + line)
	return _text


func from_regex_match(result: RegExMatch):
	leading_spaces = result.get_string("leading_spaces").length()
	keyword = result.get_string("keyword")
	closing = result.get_string("closing") != ""
	name = result.get_string("name")
	global = name == ""


func set_main_lines(lines: Array) -> void:
	lines_before = lines.slice(0, start - 1)
	lines_after = lines.slice(end + 1, lines.size())
	lines_editable = lines.slice(start + 1, end - 1)
	if leading_spaces:
		for idx in lines_editable.size():
			var line: String = lines_editable[idx]
			line = line.substr(leading_spaces)
			lines_editable[idx] = line


func get_main_lines() -> Array:
	var middle_text := Array(indent_text(leading_spaces, lines_editable)) \
		if leading_spaces \
		else lines_editable
	return lines_before + middle_text + lines_after


func _read_only(new_text) -> void:
	push_error("Don't try to set this value")
	return


func get_slice_text() -> String:
	return PoolStringArray(lines_editable).join("\n")


func get_full_text() -> String:
	return PoolStringArray(get_main_lines()).join("\n")


func get_current_full_text() -> String:
	var lines = current_text.split("\n")
	var middle_text := Array(indent_text(leading_spaces, lines)) \
		if leading_spaces \
		else lines
	return PoolStringArray(lines_before + middle_text + lines_after).join("\n")


func set_current_text(new_current_text: String) -> void:
	current_text = new_current_text


func get_current_text() -> String:
	if current_text == "":
		return get_slice_text()
	return current_text


func get_start_offset() -> int:
	return lines_before.size()


func get_end_offset() -> int:
	return lines_before.size() + lines_editable.size()


func _to_json() -> Dictionary:
	return {
		"leading_spaces": leading_spaces,
		"keyword" : keyword,
		"closing" : closing,
		"name" : name,
		"global" : global,
		"start" : start,
		"end" : end,
		"lines_editable" : lines_editable,
		"lines_before": lines_before,
		"lines_after": lines_after
	}


func _to_string() -> String:
	return JSON.print(_to_json(), "\t")
