extends Node

const DATABASE_SOURCE := "res://script_checking/error_database.csv"

const CSV_DELIMITER := ","
const CSV_IDENTIFIER_FIELD := "error_code"
const CSV_EXPLANATION_FIELD := "error_explanation"
const CSV_SUGGESTION_FIELD := "error_suggestion"

var _main_table := {}
@warning_ignore("unused_private_class_variable")
var _translated_table := {}

func _init() -> void:
	_main_table = _load_csv_file(DATABASE_SOURCE)


func get_message(error_code: int) -> Dictionary:
	var message := {
		"explanation": "",
		"suggestion": "",
	}

	if error_code == -1:
		return message

	if not _main_table.is_empty() and _main_table.has(error_code):
		var record := _main_table[error_code] as DatabaseRecord
		if record != null:
			message["explanation"] = record.explanation
			message["suggestion"] = record.suggestion

	return message


func _load_csv_file(file_path: String) -> Dictionary:
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		printerr("Failed to open the error database source at '%s': File does not exist." % file_path)
		return {}

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		printerr("Failed to open the error database source at '%s'." % file_path)
		return {}

	return _parse_csv_file(file)


func _parse_csv_file(file: FileAccess) -> Dictionary:
	var parsed := {}
	if file == null:
		return parsed

	# Read header
	var header := file.get_csv_line(CSV_DELIMITER)
	if header.is_empty():
		return parsed

	var identifier_index := header.find(CSV_IDENTIFIER_FIELD)
	var explanation_index := header.find(CSV_EXPLANATION_FIELD)
	var suggestion_index := header.find(CSV_SUGGESTION_FIELD)
	if identifier_index == -1 or explanation_index == -1 or suggestion_index == -1:
		return parsed

	# Read remaining lines
	while not file.eof_reached():
		var line := file.get_csv_line(CSV_DELIMITER)

		# Empty or invalid line, ignore it.
		if line.is_empty() or line.size() != header.size():
			continue

		var error_code := String(line[identifier_index])
		var error_value := -1

		if GDScriptCodes.WarningCode.has(error_code):
			error_value = GDScriptCodes.WarningCode[error_code]
		elif GDScriptCodes.ErrorCode.has(error_code):
			error_value = GDScriptCodes.ErrorCode[error_code]
		elif GDQuestCodes.ErrorCode.has(error_code):
			error_value = GDQuestCodes.ErrorCode[error_code]

		# Invalid code in CSV, report and skip.
		if error_value == -1:
			printerr("Bad error database record '%s': No such error or warning code." % error_code)
			continue

		var record := DatabaseRecord.new()
		record.code = error_value
		record.explanation = String(line[explanation_index])
		record.suggestion = String(line[suggestion_index])
		parsed[error_value] = record

	return parsed


class DatabaseRecord:
	var code := -1
	var explanation := ""
	var suggestion := ""
