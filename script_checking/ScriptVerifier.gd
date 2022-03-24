# Virtual class to verify a GDScript script
#
# Usage: override the test() function.
class_name ScriptVerifier
extends Reference

const ScriptError := preload("./ScriptError.gd")
const WarningCode := GDScriptCodes.WarningCode
const ErrorCode := GDScriptCodes.ErrorCode
const GDQuestErrorCode := GDQuestCodes.ErrorCode
# Skip errors with a severity warning above this. The lower the number,
# the more dire the error. Defaults to `2`, which includes errors and
# warnings
var max_severity := 2


# A list of error codes to ignore. All warnings are added automatically
# (see _ready). This is similar to setting _max_severity to 1, but left here in
# case we want more granularity
var blacklist_codes := {
	ErrorCode.INVALID_CLASS_DECLARATION: true
}

var _new_script_text: String

func _init(new_script_text: String) -> void:
	for warning in WarningCode:
		blacklist_codes[WarningCode[warning]] = true

	_new_script_text = new_script_text


# Virtual function to override to test the _new_script_text source code
func test() -> void:
	pass


# Tests a script to ensure it has no errors.
# Only works in exported projects. When running in the editor,
# this will stop the running application if there's an error
# in the script
static func test_file(current_file_name: String) -> bool:
	var test_file := load(current_file_name) as GDScript
	var test_instance = test_file.new()
	return test_instance != null
