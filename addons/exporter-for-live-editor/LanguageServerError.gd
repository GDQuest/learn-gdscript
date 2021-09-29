extends Reference

var error_range := LanguageServerRange.new()
var message := ""


func fromJSON(json:Dictionary) -> void:
	if "message" in json:
		message = String(json.message)
	if "range" in json:
		error_range.fromJSON(json.range)


class LanguageServerRange:
	var start := LanguageServerPosition.new()
	var end := LanguageServerPosition.new()

	func fromJSON(json:Dictionary) -> void:
		if "start" in json:
			start.fromJSON(json.start)
		if "end" in json:
			end.fromJSON(json.end)


class LanguageServerPosition:
	var character := 0
	var line := 0

	func fromJSON(json:Dictionary) -> void:
		if "character" in json:
			character = int(json.character)
		if "line" in json:
			line = int(json.line)
