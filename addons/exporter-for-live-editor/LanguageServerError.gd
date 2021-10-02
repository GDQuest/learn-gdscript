extends Reference

var error_range := LanguageServerRange.new()
var message := ""
var severity := 0
var code := 0


func fromJSON(json: Dictionary) -> void:
	if "message" in json:
		message = String(json.message)
	if "range" in json:
		error_range.fromJSON(json.range)
	if "severity" in json:
		severity = int(json.severity)
	if "code" in json:
		code = int(json.code)


func _to_string() -> String:
	return "{ERR (%s:%s): %s}" % [code, error_range, message]


class LanguageServerRange:
	var start := LanguageServerPosition.new()
	var end := LanguageServerPosition.new()

	func fromJSON(json: Dictionary) -> void:
		if "start" in json:
			start.fromJSON(json.start)
		if "end" in json:
			end.fromJSON(json.end)

	func _to_string() -> String:
		return "[%s-%s]" % [start, end]


class LanguageServerPosition:
	var character := 0
	var line := 0

	func fromJSON(json: Dictionary) -> void:
		if "character" in json:
			character = int(json.character)
		if "line" in json:
			line = int(json.line)

	func _to_string() -> String:
		return "(%s:%s)" % [line, character]
