# Verifies a GDScript file against an HTTP language server
#
# Usage:
#
# var verifier = ScriptVerifier.new(node, script_text)
# verifier.test()
# var errors: Array = yield(verifier, "errors")
#
# Where `errors` is an array of LanguageServerErrors
class_name ScriptVerifier
extends Reference

# Emits error messages as an Array[LanguageServerError]
signal errors(errors)

# The URL of the HTTP Language Server
const SERVER_URL := "https://lsp.gdquest.com"
# const SERVER_URL := "http://localhost:3000"

# https://docs.godotengine.org/en/stable/classes/class_httprequest.html#enumerations
const HTTP_RESULT_ERRORS := {
	0: "RESULT_SUCCESS",
	1: "RESULT_CHUNKED_BODY_SIZE_MISMATCH",
	2: "RESULT_CANT_CONNECT",
	3: "RESULT_CANT_RESOLVE",
	4: "RESULT_CONNECTION_ERROR",
	5: "RESULT_SSL_HANDSHAKE_ERROR",
	6: "RESULT_NO_RESPONSE",
	7: "RESULT_BODY_SIZE_LIMIT_EXCEEDED",
	8: "RESULT_REQUEST_FAILED",
	9: "RESULT_DOWNLOAD_FILE_CANT_OPEN",
	10: "RESULT_DOWNLOAD_FILE_WRITE_ERROR0",
	11: "RESULT_REDIRECT_LIMIT_REACHED1",
	12: "RESULT_TIMEOUT",
}

const LanguageServerError := preload("./LanguageServerError.gd")
const http_request_name = "___HTTP_REQUEST___"
const WarningCode := GDScriptCodes.WarningCode
const ErrorCode := GDScriptCodes.ErrorCode
# Skip errors with a severity warning above this. The lower the number,
# the more dire the error. Defaults to `2`, which includes errors and
# warnings
var max_severity := 2


# A list of language server codes to ignore. All warnings are added automatically
# (see _ready). This is similar to setting _max_severity to 1, but left here in
# case we want more granularity
var blacklist_codes := {
	ErrorCode.INVALID_CLASS_DECLARATION: true
}

var _node: Node
var _new_script_text: String
var _url: String
var _new_script_filename: String
var _start_time := OS.get_unix_time()

func _init(attached_node: Node, new_script_filename: String, new_script_text: String, url := SERVER_URL) -> void:
	
	for warning in WarningCode:
		blacklist_codes[WarningCode[warning]] = true

	_node = attached_node
	_new_script_text = new_script_text
	_new_script_filename = new_script_filename
	_url = url


func append_http_request_node() -> HTTPRequest:
	var http_request = HTTPRequest.new()
	http_request.name = http_request_name
	http_request.timeout = 10
	http_request.connect("request_completed", self, "_on_http_request_completed")
	_node.add_child(http_request)
	return http_request


func remove_http_request_node() -> void:
	var previous_http_request = _node.get_node_or_null(http_request_name)
	if previous_http_request:
		previous_http_request.queue_free()


func _on_http_request_completed(
	result: int, response_code: int, _headers: PoolStringArray, body: PoolByteArray
) -> void:

	var end := OS.get_unix_time()
	var elapsed := end - _start_time
	
	Log.info({
		"end": end,
		"elapsed": elapsed,
		"id": UserProfiles.uuid,
		"filename": _new_script_filename,
		"response": response_code,
		"result": result,
	}, "finished request")
	
	if result != HTTPRequest.RESULT_SUCCESS:
		var error_name: String = HTTP_RESULT_ERRORS[result]
		printerr("http error connecting to %s: [%s]"%[_url, error_name])
		emit_signal("errors", [])
		return
		
	var response = (
		parse_json(body.get_string_from_utf8())
		if response_code == 200
		else []
	)
	remove_http_request_node()

	if not response_code == 200:
		printerr(
			"Failed to verify the script using the language server: " + body.get_string_from_utf8()
		)

	# @type Array<LanguageServerError>
	var errors = []

	if not response.size():
		emit_signal("errors", errors)
		return

	for index in response.size():
		var dict: Dictionary = response[index]
		# unused return value.
		var error = LanguageServerError.new()
		error.from_JSON(dict)
		if error.code in blacklist_codes or error.severity > max_severity:
			continue
		errors.append(error)

	emit_signal("errors", errors)


# This requests the LSP server for checking the provided file
func test() -> void:
	remove_http_request_node()
	var http_request := append_http_request_node()
	var request_props := {
		"file": _new_script_text,
		"filename": _new_script_filename,
		"id": UserProfiles.uuid
	}
	var query := HTTPClient.new().query_string_from_dict(request_props)
	var headers := PoolStringArray(["Content-Type: application/x-www-form-urlencoded"])
	var validate := _url.begins_with("https")
	Log.info({
		"start": _start_time,
		"id": UserProfiles.uuid,
		"filename": _new_script_filename,
		"elapsed": 0,
	}, "initiated request")
	var success := http_request.request(_url, headers, validate, HTTPClient.METHOD_POST, query)
	if success != OK:
		push_error("could not connect")
		remove_http_request_node()
		var error := LanguageServerError.new()
		error.message = "Could not initiate an http connection"
		error.code = -1
		var errors := [error]
		emit_signal("errors", errors)

# Tests a script to ensure it has no errors.
# Only works in exported projects. When running in the editor,
# this will stop the running application if there's an error
# in the script
static func test_file(current_file_name: String) -> bool:
	var test_file := load(current_file_name) as GDScript
	var test_instance = test_file.new()
	return test_instance != null
