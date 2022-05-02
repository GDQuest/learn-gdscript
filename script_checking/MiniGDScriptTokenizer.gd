# Simple and brutish tokenizer
# We only use it to test for recursive calls (at the moment)
# the way it works:
# 1. walk line by line
# 2. put each line through a bunch of regexes
# 3. if a regex match, extract a dict of values from the group, then
# 4. check if there is a custom parser method.
#    - If yes, send the dict there
#    - If no, append the dict to the current token list
# current token list is by default the top level, but can be changed. For example,
# when a function is found, it sets its "body" variable as `_current_scope`, which
# makes it so every subsequent line gets appended to its body 
class_name MiniGDScriptTokenizer

const TOKEN_FUNC_DECLARATION := "function_declaration"
const TOKEN_FUNC_CALL := "function_call"

var _lines := PoolStringArray()
var _index := 0
var _current_line := ""
var tokens := []
var _current_scope := []
var indent_regex := RegEx.new()


var _available_tokens := {
	TOKEN_FUNC_DECLARATION: "^func\\s+(?<func_name>[a-zA-Z_].*?)(?:\\(\\s*(?:(?<args>[^)]+)[,)])*|\\):)",
	TOKEN_FUNC_CALL: "\\t.*?\\s?(?<func_name>[a-zA-Z_][a-zA-Z0-9_]+)\\(\\s*(?<params>.*?)\\s*\\)"
}


func _init(text: String) -> void:
	_lines = text.split("\n")
	indent_regex.compile('^(\\s|\\t)')
	for token_type in _available_tokens:
		var pattern: String = _available_tokens[token_type]
		var regex := RegEx.new()
		regex.compile(pattern)
		_available_tokens[token_type] = regex
	_current_scope = tokens
	tokenize()


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
	_index += 1


func _test_regex(type: String, regex: RegEx, line: String) -> bool:
	var m := regex.search(line)
	if m == null or m.names.size() == 0:
		return false
	var token := {
		"type": type
	}
	for group_name in m.names:
		token[group_name] = m.get_string(group_name)
	var further_process_method_name := "_process_%s"%[type]
	if has_method(further_process_method_name):
		call(further_process_method_name, token)
	else:
		_current_scope.append(token)
		_index += 1
	return true


func _tokenize_line(line: String) -> bool:
	for token_type in _available_tokens:
		var regex := _available_tokens[token_type] as RegEx
		var found := _test_regex(token_type, regex, line)
		if found:
			return true
	return false


func tokenize():
	_index = 0
	var size := _lines.size()
	while _index < size:
		_current_line = _lines[_index]
		# skip comments early, we don't care
		if _current_line.begins_with("#"):
			_index += 1
			continue
		var is_indented := indent_regex.search(_current_line)
		# any line at the root level, apart for a comment, resets the context
		if is_indented == null:
			_current_scope = tokens
		var found := _tokenize_line(_current_line)
		if not found:
			# couldn't find any token, increment _index
			_index += 1


###############################################################################
#
# Analysis Utilities
#

# If there is one recursive function, this function returns its name
func find_any_recursive_function() -> String:
	for token in tokens:
		if token.type == TOKEN_FUNC_DECLARATION:
			for sub_token in token.body:
				if sub_token.type == TOKEN_FUNC_CALL:
					if sub_token.func_name == token.func_name:
						return token.func_name
	return ""


func _to_string():
	return JSON.print(tokens, "  ")
