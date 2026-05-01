## Database of GDScript error and warning codes (as well as custom GDQuest
## codes as necessary), supplemented with descriptions and explanations
## for learners. An object representation of a CSV file.
class_name GDScriptErrorDatabase extends RefCounted

const ERROR_DATABASE_SOURCE := "res://script_checking/error_database.csv"

const CSV_DELIMITER := ","
const CSV_IDENTIFIER_FIELD := "error_code"
const CSV_EXPLANATION_FIELD := "error_explanation"
const CSV_SUGGESTION_FIELD := "error_suggestion"

class ErrorRecord:
	var code: String = ""
	var explanation: String = ""
	var suggestion: String = ""

static var _errors: Dictionary[int, ErrorRecord] = {}


static func _static_init():
	_load_errors(ERROR_DATABASE_SOURCE)


static func get_message(error_code: int) -> ErrorRecord:
	if error_code == -1 or not _errors.has(error_code):
		return null

	return _errors[error_code]


static func _load_errors(file_path: String) -> void:
	_errors.clear()

	# Load the file at the specified path.

	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		push_error(
			"Failed to open the error database source at '%s': File does not exist." % [file_path],
		)
		return

	var database_file := FileAccess.open(file_path, FileAccess.READ)
	if not database_file:
		push_error(
			"Failed to open the error database source at '%s': Error code %d" % [file_path, FileAccess.get_open_error()],
		)
		return

	# Reset the cursor.

	database_file.seek(0)

	# Read the header and extract column indices.

	var header := database_file.get_csv_line(CSV_DELIMITER)
	if header.is_empty():
		push_warning("Loaded the error database source, but it's empty.")
		return # File is empty.

	var identifier_index := header.find(CSV_IDENTIFIER_FIELD)
	var explanation_index := header.find(CSV_EXPLANATION_FIELD)
	var suggestion_index := header.find(CSV_SUGGESTION_FIELD)
	if identifier_index == -1 or explanation_index == -1 or suggestion_index == -1:
		push_error("Bad error database header: one of the expected headers is missing.")
		return

	# Loop through lines in the file until the end and extract error data.

	while database_file.get_position() < database_file.get_length():
		var line := database_file.get_csv_line(CSV_DELIMITER)
		# Empty or invalid line, ignore it.
		if line.is_empty() or line.size() < header.size():
			continue

		var error_code := line[identifier_index]
		var error_value := -1
		if GDScriptCodes.WarningCode.has(error_code):
			error_value = GDScriptCodes.WarningCode[error_code]
		elif GDScriptCodes.ErrorCode.has(error_code):
			error_value = GDScriptCodes.ErrorCode[error_code]
		elif GDQuestCodes.ErrorCode.has(error_code):
			error_value = GDQuestCodes.ErrorCode[error_code]

		# Unknown error name, report it and continue.
		if error_value == -1:
			printerr(
				"Bad error database record '%s': No such error or warning code." % [error_code],
			)
			continue

		var record := ErrorRecord.new()
		record.code = error_code
		record.explanation = line[explanation_index]
		record.suggestion = line[suggestion_index]
		_errors[error_value] = record

	# Reset the cursor again, us being neat.

	database_file.seek(0)
