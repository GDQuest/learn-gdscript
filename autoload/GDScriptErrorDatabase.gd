extends Node

const DATABASE_SOURCE := "res://script_checking/error_database.csv"

const CSV_DELIMITER := ","
const CSV_IDENTIFIER_FIELD := "error_code"
const CSV_EXPLANATION_FIELD := "error_explanation"
const CSV_SUGGESTION_FIELD := "error_suggestion"

var _main_table := {}
var _translated_table := {}


func _init():
	_main_table = _load_csv_file(DATABASE_SOURCE)


func get_message(error_code: int) -> Dictionary:
	var message := {
		"explanation": "",
		"suggestion": "",
	}

	if error_code == -1:
		return message

	if not _main_table.empty() and _main_table.has(error_code):
		var record = _main_table[error_code] as DatabaseRecord
		if record:
			message.explanation = record.explanation
			message.suggestion = record.suggestion

	return message


func _load_csv_file(file_path: String) -> Dictionary:
	var database_file = File.new()
	if file_path.empty() or not database_file.file_exists(file_path):
		printerr(
			"Failed to open the error database source at '%s': File does not exist." % [file_path]
		)
		return {}

	var error = database_file.open(file_path, File.READ)
	if error != OK:
		printerr(
			"Failed to open the error database source at '%s': Error code %d" % [file_path, error]
		)
		return {}

	var table = _parse_csv_file(database_file)
	database_file.close()
	return table


func _parse_csv_file(file: File) -> Dictionary:
	var parsed := {}
	if not file.is_open():
		return parsed

	# Reset the cursor.
	file.seek(0)
	var header := Array(file.get_csv_line(CSV_DELIMITER))
	if header.size() == 0:
		return parsed

	var identifier_index := header.find(CSV_IDENTIFIER_FIELD)
	var explanation_index := header.find(CSV_EXPLANATION_FIELD)
	var suggestion_index := header.find(CSV_SUGGESTION_FIELD)
	if identifier_index == -1 or explanation_index == -1 or suggestion_index == -1:
		return parsed

	# Loop while there is content in the file left.
	while file.get_position() < file.get_len():
		var line = file.get_csv_line(CSV_DELIMITER)
		# Empty or invalid line, ignore it.
		if line.size() == 0 or line.size() != header.size():
			continue

		var error_code = line[identifier_index]
		var error_value := -1
		if GDScriptCodes.WarningCode.has(error_code):
			error_value = GDScriptCodes.WarningCode[error_code]
		elif GDScriptCodes.ErrorCode.has(error_code):
			error_value = GDScriptCodes.ErrorCode[error_code]
		elif GDQuestCodes.ErrorCode.has(error_code):
			error_value = GDQuestCodes.ErrorCode[error_code]
		
		# It seems that the name of the error in the CSV file is invalid, reporting and skipping.
		if error_value == -1:
			printerr(
				"Bad error database record '%s': No such error or warning code." % [error_code]
			)
			continue

		var record := DatabaseRecord.new()
		record.code = error_code
		record.explanation = line[explanation_index]
		record.suggestion = line[suggestion_index]
		parsed[error_value] = record

	# Reset the cursor again.
	file.seek(0)

	return parsed


class DatabaseRecord:
	var code := -1
	var explanation := ""
	var suggestion := ""
