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

var tokens := []

var _code_lines := PoolStringArray()
var _line_index := 0

var _current_line := ""

var _current_scope := []
var _indent_regex := RegEx.new()


var _available_tokens := {
	TOKEN_FUNC_DECLARATION: "^func\\s+(?<func_name>[a-zA-Z_].*?)(?:\\(\\s*(?:(?<args>[^)]+)[,)])*|\\):)",
	TOKEN_FUNC_CALL: "\\t.*?\\s?(?<func_name>[a-zA-Z_][a-zA-Z0-9_]+)\\(\\s*(?<params>.*?)\\s*\\)",
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
	var parameters_list: PoolStringArray = token.get("args", "").split(",")
	var parameters := []
	for tuple_str in parameters_list:
		var tuple: PoolStringArray = tuple_str.split(":")
		var param := {
			"name": "",
			"type": "",
			"default": "",
			"required": true
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


func _test_regex(type: String, regex: RegEx, line: String) -> bool:
	var regex_match := regex.search(line)
	if regex_match == null or regex_match.names.size() == 0:
		return false

	var token := {
		"type": type
	}
	for group_name in regex_match.names:
		token[group_name] = regex_match.get_string(group_name)

	if type == TOKEN_FUNC_DECLARATION:
		_process_function_declaration(token)
	else:
		_current_scope.append(token)
		_line_index += 1
	return true


func _tokenize_line(line: String) -> bool:
	for token_type in _available_tokens:
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
