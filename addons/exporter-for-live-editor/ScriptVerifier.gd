const LanguageServerError := preload("./LanguageServerError.gd")
const http_request_name = "___HTTP_REQUEST___"

signal errors(errors)

var _node: Node
var _new_script_text: String
var max_severity := 2
var blacklist_codes := {16: true}  # unused return value.


func _init(attached_node: Node, new_script_text: String) -> void:
	_node = attached_node
	_new_script_text = new_script_text


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
		if result == HTTPRequest.RESULT_SUCCESS
		else []
	)
	remove_http_request_node()
	var errors = []

	if not response.size():
		emit_signal("errors", errors)

	for index in response.size():
		var dict: Dictionary = response[index]
		# unused return value.
		if dict.code in blacklist_codes or dict.severity > max_severity:
			continue
		var error = LanguageServerError.new()
		error.fromJSON(dict)
		errors.append(error)

	emit_signal("errors", errors)


func test() -> void:
	remove_http_request_node()
	var http_request := append_http_request_node()
	var url = "http://localhost:3000"
	var query = "file=%s" % [_new_script_text.percent_encode()]
	var headers = PoolStringArray(["Content-Type: application/x-www-form-urlencoded"])
	http_request.request(url, headers, false, HTTPClient.METHOD_POST, query)
