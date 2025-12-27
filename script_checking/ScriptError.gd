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
	if json.has("message"):
		var msg := json["message"] as String
		if msg != null:
			message = msg
		else:
			message = str(json["message"])

	if json.has("range"):
		var r := json["range"] as Dictionary
		if r != null:
			error_range.from_JSON(r)

	if json.has("severity"):
		var sev := json["severity"] as int
		severity = sev

	if json.has("code"):
		var c := json["code"] as int
		code = _improve_error_code(c, message)


func _improve_error_code(raw_code: int, raw_message: String) -> int:
	# If the code has a valid value, just use it.
	if not raw_code == -1:
		return raw_code

	# But if it's -1, try to remap the message to a new code using the GDScript codes database.
	var remapped_code := -1
	# Iterate through every record to find the one that has a matching pattern.
	for rec_v in GDScriptCodes.MESSAGE_DATABASE:
		var record := rec_v as Dictionary
		# First check if the record has a valid structure, just in case.
		if record.is_empty():
			continue
		if not record.has("patterns") or not record.has("code"):
			continue
		if not typeof(record.patterns) == TYPE_ARRAY or not typeof(record.code) == TYPE_INT:
			continue

		# Iterate through an array of match patterns to see if any of them matches our message
		# completely.
		var matched = false
		var patterns: Array = record["patterns"] as Array
		
		for pattern_v in patterns:
			var pattern: Array = pattern_v as Array
			# Pattern must be an array of strings.
			if pattern.is_empty():
				continue

			# We'll be modifying the message here, so copy it.
			var curr_message: String = raw_message
			# Pattern's substrings must match the target message in order.
			for i in range(pattern.size()):
				# If the substring does not match, exit early, this is not our match.
				var substring: String = pattern[i] as String
				var found: int = curr_message.find(substring)
				if found == -1:
					break

				# substr() needs ints; found is now int.
				curr_message = curr_message.substr(found)
				i += 1
				# If we reached the last element and never broke, it's a match.
				if i == pattern.size() - 1:
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
		if json.has("start") and json["start"] is Dictionary:
			start.from_JSON(json["start"] as Dictionary)

		if json.has("end") and json["end"] is Dictionary:
			end.from_JSON(json["end"] as Dictionary)

	func _to_string() -> String:
		return "[%s-%s]" % [start, end]


class ErrorPosition:
	var character := 0
	var line := 0

	func from_JSON(json: Dictionary) -> void:
		if json.has("character"):
			var v: Variant = json["character"]
			if v is int:
				character = v as int
			elif v is float:
				character = int(v as float)
			elif v is bool:
				character = int(v as bool)
			elif v is String:
				character = int((v as String).to_float())

		if json.has("line"):
			var v2: Variant = json["line"]
			if v2 is int:
				line = v2 as int
			elif v2 is float:
				line = int(v2 as float)
			elif v2 is bool:
				line = int(v2 as bool)
			elif v2 is String:
				line = int((v2 as String).to_float())


	func _to_string() -> String:
		return "(%s:%s)" % [line, character]
