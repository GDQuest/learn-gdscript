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

const PARSE_WRAPPER_CLASS := "GDScriptParserWrap"

# Array[ScriptError]
var errors := []


func _init(new_script_text: String).(new_script_text) -> void:
	pass


func test() -> void:
	if ClassDB.class_exists(PARSE_WRAPPER_CLASS):
		var wrap: Reference = ClassDB.instance(PARSE_WRAPPER_CLASS)
		wrap.parse_script(_new_script_text)
		if wrap.has_error():
			var error_line: int = wrap.get_error_line() - 1
			var line_text := _new_script_text.split("\n")[error_line]
			var error_data := make_error_from_data(
				1,
				wrap.get_error(),
				"gdscript",
				-1,
				error_line,
				line_text.length() - line_text.strip_edges(true, false).length(),
				line_text.strip_edges(false).length()
			)
			errors = [error_data]
		else:
			errors = []
	else:
		push_error("Script Parser Wrapper class is missing!")
		var error := make_error_no_parser_wrapper_class()
		errors = [error]
		return


static func make_error_no_parser_wrapper_class() -> ScriptError:
	var err = ScriptVerifier.ScriptError.new()
	err.message = "No Script Parser class in exported app. There will be no error checking possible"
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
		character_end: int
) -> ScriptError:
	
	var error_block := {
		"severity": severity,
		"message": message,
		"source": source,
		"code": -1,
		"range": {
			"start": {
				"line": line,
				"character": character_start
			},
			"end": {
				"line": line,
				"character": character_end
			}
		}
	}
	
	var error = ScriptVerifier.ScriptError.new()
	error.from_JSON(error_block)
	return error


static func check_error_is_missing_parser_error(error: ScriptError) -> bool:
	return error.code == GDQuestCodes.ErrorCode.NO_PARSER_CLASS
