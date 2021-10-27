# Represents a Language Server Protocol error.
#
# Mirrors the JSON structure, with the notable exception of `error_range`
# instead of `range` ("range" is a reserved word in GDScript).
#
# Use it like so:
#
# var error = LanguageServerError.new()
# error.from_JSON(json_error)
class_name LanguageServerError
extends Reference

var error_range := ErrorRange.new()
var message := ""
var severity := 0
var code := 0


func from_JSON(json: Dictionary) -> void:
	if "message" in json:
		message = String(json.message)
	if "range" in json:
		error_range.from_JSON(json.range)
	if "severity" in json:
		severity = int(json.severity)
	if "code" in json:
		code = int(json.code)


func _to_string() -> String:
	return "{ERR (%s:%s): %s}" % [code, error_range, message]


class ErrorRange:
	var start := ErrorPosition.new()
	var end := ErrorPosition.new()

	func from_JSON(json: Dictionary) -> void:
		if "start" in json:
			start.from_JSON(json.start)
		if "end" in json:
			end.from_JSON(json.end)

	func _to_string() -> String:
		return "[%s-%s]" % [start, end]


class ErrorPosition:
	var character := 0
	var line := 0

	func from_JSON(json: Dictionary) -> void:
		if "character" in json:
			character = int(json.character)
		if "line" in json:
			line = int(json.line)

	func _to_string() -> String:
		return "(%s:%s)" % [line, character]
