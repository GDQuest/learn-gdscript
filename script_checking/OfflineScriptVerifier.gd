# Verifies a GDScript file using a custom build of Godot
#
# Usage:
#
# var verifier = OfflineScriptVerifier.new(node, script_text)
# verifier.test()
# var errors: Array = verifier.errors
#
# Where `errors` is an array of ScriptErrors
#
class_name OfflineScriptVerifier
extends ScriptVerifier

const PARSE_WRAPPER_CLASS := "GDScriptErrorChecker"

# Array[ScriptError]
var errors := []


func _init(new_script_text: String) -> void:
	super(new_script_text)
	pass


func test() -> void:
	if ClassDB.class_exists(PARSE_WRAPPER_CLASS):
		var wrap_instance: RefCounted = ClassDB.instantiate(PARSE_WRAPPER_CLASS)
		@warning_ignore("unsafe_method_access")
		wrap_instance.set_source(_new_script_text)
		@warning_ignore("unsafe_method_access")
		if wrap_instance.has_errors():
			errors = []
			var lines := _new_script_text.split("\n")
			@warning_ignore("unsafe_method_access")
			for i: int in wrap_instance.get_error_count():
				@warning_ignore("unsafe_method_access")
				var error_line: int = wrap_instance.get_error_line(i)
				@warning_ignore("unsafe_method_access")
				error_line = clampi(error_line - 1, 0, lines.size()-1)
				var line_text := lines[error_line]
				@warning_ignore("unsafe_method_access")
				var error_data := make_error_from_data(
					1,
					wrap_instance.get_error(i) as String,
					"gdscript",
					-1,
					error_line,
					line_text.length() - line_text.strip_edges(true, false).length(),
					line_text.strip_edges(false).length(),
				)
				errors.push_back(error_data)
		else:
			errors = []
	else:
		push_error("Script Error Checker class is missing!")
		var error := make_error_no_parser_wrapper_class()
		errors = [error]
		return


static func make_error_no_parser_wrapper_class() -> ScriptError:
	var err = ScriptError.new()
	err.message = "No Script Error Checker class in exported app. There will be no error checking possible"
	err.severity = 1
	err.code = ScriptVerifier.GDQuestErrorCode.NO_PARSER_CLASS
	return err


static func make_error_from_data(
		severity: int,
		message: String,
		source: String,
		code: int,
		line: int,
		character_start: int,
		character_end: int,
) -> ScriptError:
	var error_block := {
		"severity": severity,
		"message": message,
		"source": source,
		"code": code,
		"range": {
			"start": {
				"line": line,
				"character": character_start,
			},
			"end": {
				"line": line,
				"character": character_end,
			},
		},
	}

	var error = ScriptError.new()
	error.from_JSON(error_block)
	return error


static func check_error_is_missing_parser_error(error: ScriptError) -> bool:
	return error.code == GDQuestCodes.ErrorCode.NO_PARSER_CLASS
