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
const SERVER_URL := "http://localhost:3000"

const LanguageServerError := preload("./LanguageServerError.gd")
const http_request_name = "___HTTP_REQUEST___"

# Skip errors with a severity warning above this. The lower the number,
# the more dire the error. Defaults to `2`, which includes errors and
# warnings
var max_severity := 2

# A list of language server codes to ignore. You probably only want to skip
# "unused return value" (code 16), and "unsafe property access" (code 26)
var blacklist_codes := {16: true, 26: true}

var _node: Node
var _new_script_text: String
var _url: String


func _init(attached_node: Node, new_script_text: String, url := SERVER_URL) -> void:
	_node = attached_node
	_new_script_text = new_script_text
	_url = url


func append_http_request_node() -> HTTPRequest:
	var http_request = HTTPRequest.new()
	http_request.name = http_request_name
	http_request.connect("request_completed", self, "_on_http_request_completed")
	_node.add_child(http_request)
	return http_request


func remove_http_request_node() -> void:
	var previous_http_request = _node.get_node_or_null(http_request_name)
	if previous_http_request:
		previous_http_request.queue_free()


func _on_http_request_completed(
	result: int, _response_code: int, _headers: PoolStringArray, body: PoolByteArray
) -> void:
	var response = (
		parse_json(body.get_string_from_utf8())
		if result == HTTPRequest.RESULT_SUCCESS and _response_code == 200
		else []
	)
	remove_http_request_node()

	if result == HTTPRequest.RESULT_SUCCESS and not _response_code == 200:
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
	var query = "file=%s" % [_new_script_text.percent_encode()]
	var headers = PoolStringArray(["Content-Type: application/x-www-form-urlencoded"])
	http_request.request(_url, headers, false, HTTPClient.METHOD_POST, query)


# Tests a script to ensure it has no errors.
# Only works in exported projects. When running in the editor,
# this will stop the running application if there's an error
# in the script
static func test_file(current_file_name: String) -> bool:
	var test_file: Resource = load(current_file_name)
	var test_instance = test_file.new()
	return test_instance != null
