# Limited GDScript tokenizer. We use it to prevent crashes in students' code:
#
# - Stack overflows due to recursive functions.
# - Infinite loops.
#
# It works like so:
#
# 1. Read each line of code.
# 2. Put each line through a bunch of regexes.
# 3. If a regex regex_match, extract a dict of values from the group, then
# 4. Check if there is a custom parser method.
#    - If so, send the dict there
#    - If not, append the dict to the current token list
#
# Current token list is by default the top level, but can be changed. For
# example, when a function is found_token, it sets its "body" variable as
# `_current_scope`, which makes it so every subsequent line gets appended to its
# body
class_name MiniGDScriptTokenizer

const TOKEN_FUNC_DECLARATION := "function_declaration"
const TOKEN_FUNC_CALL := "function_call"
const TOKEN_WHILE_LOOP := "while_loop"
const TOKEN_BREAK := "break_statement"
const TOKEN_ASSIGNMENT := "assignment"

var tokens := []

var _code_lines := PackedStringArray()
var _line_index := 0

var _current_line := ""

var _current_scope := []
var _indent_regex := RegEx.new()

# Order matters! While loop must be checked before function call to avoid matching "while(...)" as a function
var _token_order := [
	TOKEN_FUNC_DECLARATION,
	TOKEN_WHILE_LOOP,
	TOKEN_BREAK,
	TOKEN_ASSIGNMENT,
	TOKEN_FUNC_CALL,
]

var _available_tokens := {
	TOKEN_FUNC_DECLARATION: "^func\\s+(?<func_name>[a-zA-Z_].*?)(?:\\(\\s*(?:(?<args>[^)]+)[,)])*|\\):)",
	TOKEN_FUNC_CALL: "\\t.*?\\s?(?<func_name>[a-zA-Z_][a-zA-Z0-9_]+)\\(\\s*(?<params>.*?)\\s*\\)",
	TOKEN_WHILE_LOOP: "^\\s*while\\s*\\(?\\s*(?<condition>.+?)\\s*\\)?\\s*:",
	TOKEN_BREAK: "^\\s*(?<keyword>break)\\s*$",
	TOKEN_ASSIGNMENT: "^\\s*(?<var_name>[a-zA-Z_][a-zA-Z0-9_]*)(?:\\.[a-zA-Z_][a-zA-Z0-9_]*)*\\s*[+\\-*/]?=",
}


func _init(text: String) -> void:
	_code_lines = text.split("\n")
	_indent_regex.compile('^(\\s|\\t)')
	for token_type in _available_tokens:
		var pattern: String = _available_tokens[token_type]
		var regex := RegEx.new()
		regex.compile(pattern)
		_available_tokens[token_type] = regex

	_current_scope = tokens
	tokenize()


func tokenize():
	_line_index = 0
	var size := _code_lines.size()
	while _line_index < size:
		_current_line = _code_lines[_line_index]

		# Skip comments, we don't care
		if _current_line.strip_edges().begins_with("#"):
			_line_index += 1
			continue

		var is_indented := _indent_regex.search(_current_line)
		# Any line at the root level, apart for a comment, resets the context
		if is_indented == null and _current_line.strip_edges() != "":
			_current_scope = tokens

		var found_token := _tokenize_line(_current_line)
		if not found_token:
			_line_index += 1


func _process_function_declaration(token: Dictionary):
	var parameters_list: PackedStringArray = token.get("args", "").split(",")
	var parameters := []
	for tuple_str in parameters_list:
		var tuple: PackedStringArray = tuple_str.split(":")
		var param := {
			"name": "",
			"type": "",
			"default": "",
			"required": true,
		}
		param.name = tuple[0].strip_edges()
		if tuple.size() > 1:
			var type := tuple[1].strip_edges().split("=")
			param.type = type[0].strip_edges()
			if type.size() > 1:
				param.default = type[1].strip_edges()
				param.required = false
		if param.name != "":
			parameters.append(param)
	token["args"] = parameters
	var body := []
	token["body"] = body
	_current_scope = body
	tokens.append(token)
	_line_index += 1


func _process_while_loop(token: Dictionary):
	var body := []
	token["body"] = body
	var previous_scope := _current_scope
	_current_scope.append(token)
	_current_scope = body
	_line_index += 1

	var while_indent := _get_indentation_level(_code_lines[_line_index - 1])

	# Continue parsing the body until we reach a statement with equal or less indentation
	while _line_index < _code_lines.size():
		var current_line := _code_lines[_line_index]

		if current_line.strip_edges() == "" or current_line.strip_edges().begins_with("#"):
			_line_index += 1
			continue

		var current_indent := _get_indentation_level(current_line)

		# If we've dedented, the while body is done. Otherwise, tokenize this
		# line as part of the while body
		if current_indent <= while_indent:
			_current_scope = previous_scope
			return

		var found_token := _tokenize_line(current_line)
		if not found_token:
			_line_index += 1

	_current_scope = previous_scope


func _test_regex(type: String, regex: RegEx, line: String) -> bool:
	var regex_match := regex.search(line)
	if regex_match == null:
		return false

	var token := {
		"type": type,
	}
	for group_name in regex_match.names:
		token[group_name] = regex_match.get_string(group_name)

	if type == TOKEN_FUNC_DECLARATION:
		_process_function_declaration(token)
	elif type == TOKEN_WHILE_LOOP:
		_process_while_loop(token)
	else:
		_current_scope.append(token)
		_line_index += 1
	return true


func _tokenize_line(line: String) -> bool:
	for token_type in _token_order:
		var regex := _available_tokens[token_type] as RegEx
		var found_token := _test_regex(token_type, regex, line)
		if found_token:
			return true
	return false


###############################################################################
#
# Analysis Utilities
#
# If there is one recursive function, this function returns its name
func find_any_recursive_function() -> String:
	for token in tokens:
		if token.type == TOKEN_FUNC_DECLARATION:
			for sub_token in token.body:
				if sub_token.type == TOKEN_FUNC_CALL and sub_token.func_name == token.func_name:
					return token.func_name
	return ""


# Returns true if there is an infinite while loop in the code
func has_infinite_while_loop() -> bool:
	return _check_infinite_while_in_tokens(tokens)


# Recursively checks tokens for infinite while loops
func _check_infinite_while_in_tokens(token_list: Array) -> bool:
	for token in token_list:
		if token.type == TOKEN_WHILE_LOOP:
			if _is_while_loop_infinite(token):
				return true
		elif token.has("body"):
			if _check_infinite_while_in_tokens(token.body):
				return true
	return false


func _is_while_loop_infinite(while_token: Dictionary) -> bool:
	var condition: String = while_token.get("condition", "")

	if _has_break_statement(while_token.body):
		return false

	var stripped := condition.strip_edges()
	if stripped in ["true", "1"] or stripped in ["not false", "!false"]:
		return true

	return false


# Checks if a token body contains a break statement
func _has_break_statement(body: Array) -> bool:
	for token in body:
		if token.type == TOKEN_BREAK:
			return true
		if token.has("body"):
			if _has_break_statement(token.body):
				return true
	return false


# Gets the indentation level of a line, counting tabs as equivalent to 4 spaces
# This helps normalize mixed indentation for comparison purposes
func _get_indentation_level(line: String) -> int:
	var indent := 0
	for i in range(line.length()):
		var character := line[i]
		if character == '\t':
			indent += 4
		elif character == ' ':
			indent += 1
		else:
			break
	return indent / 4
