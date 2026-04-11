# Represents a Script error.
#
# Mirrors the JSON structure of the language server, with the notable exception
# of `error_range` instead of `range` ("range" is a reserved word in GDScript).
#
# Use it like so:
#
# var error = ScriptError.new()
# error.from_JSON(json_error)
class_name ScriptError
extends RefCounted

var error_range := ErrorRange.new()
var message := ""
var severity := 0
var code := 0


func from_JSON(json: Dictionary) -> void:
	if "message" in json:
		var json_message: String = json.message
		message = str(json_message)
	if "range" in json:
		var json_range: Dictionary = json.range
		error_range.from_JSON(json_range)
	if "severity" in json:
		var json_severity: int = json.severity
		severity = int(json_severity)
	if "code" in json:
		var json_code: int = json.code
		code = _improve_error_code(json_code, message)


func _improve_error_code(raw_code: int, raw_message: String) -> int:
	# If the code has a valid value, just use it.
	if not raw_code == -1:
		return raw_code

	# But if it's -1, try to remap the message to a new code using the GDScript codes database.
	var remapped_code := -1
	# Iterate through every record to find the one that has a matching pattern.
	for record: Dictionary in GDScriptCodes.MESSAGE_DATABASE:
		# First check if the record has a valid structure, just in case.
		if not typeof(record) == TYPE_DICTIONARY:
			continue
		if not record.has("patterns") or not record.has("code"):
			continue
		if not typeof(record.patterns) == TYPE_ARRAY or not typeof(record.code) == TYPE_INT:
			continue

		# Iterate through an array of match patterns to see if any of them matches our message
		# completely.
		var matched = false
		for pattern: Array in record.patterns:
			# Pattern must be an array of strings.
			if not typeof(pattern) == TYPE_ARRAY:
				continue

			# We'll be modifying the message here, so copy it.
			var curr_message = raw_message
			# Pattern's substrings must match the target message in order.
			for i in pattern.size():
				# If the substring does not match, exit early, this is not our match.
				var substring := pattern[i] as String
				var found := curr_message.find(substring)
				if found == -1:
					break

				# Cut a part of the message that we have already matched to exclude it from
				# further checks.
				curr_message = curr_message.substr(found)
				i += 1
				# We reached the end of the pattern without errors, so this is our match.
				if i >= pattern.size():
					matched = true
					break

			if matched:
				break

		if matched:
			remapped_code = record.code
			break

	return remapped_code


func _to_string() -> String:
	return "{ERR (%s:%s): %s}" % [code, error_range, message]


class ErrorRange:
	var start := ErrorPosition.new()
	var end := ErrorPosition.new()


	func from_JSON(json: Dictionary) -> void:
		if "start" in json:
			var json_start: Dictionary = json.start
			start.from_JSON(json_start)
		if "end" in json:
			var json_end: Dictionary = json.end
			end.from_JSON(json_end)


	func _to_string() -> String:
		return "[%s-%s]" % [start, end]


class ErrorPosition:
	var character := 0
	var line := 0


	func from_JSON(json: Dictionary) -> void:
		if "character" in json:
			var json_character: int = json.character
			character = int(json_character)
		if "line" in json:
			var json_line: int = json.line
			line = int(json_line)


	func _to_string() -> String:
		return "(%s:%s)" % [line, character]
