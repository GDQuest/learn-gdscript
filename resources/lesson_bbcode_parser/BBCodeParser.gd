# This script tokenizes and parses BBCode-formatted text into a parse tree.
# Note: It's built to be simple and constrained: tags need to be on one line. I've
# used regex for parsing the tags and attributes because this offloads work to
# the engine, but regex parsing is always a bit limiting. We can later rewrite
# it as a scanner parser if we need to make it more lenient.
class_name BBCodeParser
extends Reference

# When we tokenize the BBCode, we only consider opening and closing tags and
# accumulate all the text in between. The goal of these tokens are to delineate
# just these big chunks.
enum TokenTypes {
	TEXT,
	TAG_OPEN,
	TAG_CLOSE,
}

var _parser_data := BBCodeParserData.new()

var _regex_tag_open: RegEx = null
var _regex_tag_close: RegEx = null
var _regex_attribute: RegEx = null

var _result: ParseResult = null


func _init() -> void:
	# TODO: consider moving to a scanner parser, at least using string.find()
	# and peeking ahead/behind instead of regex. We just need to be careful with
	# escaped brackets or things like ignoring code/capturing it as plain text.
	# For now I'm just sticking to regex cause the parser works okay, and it's
	# not going to change much to scan linearly in GDScript.

	_regex_tag_open = RegEx.new()
	# Detects opening tags like [tag_name a="value" b] with optional attributes.
	# This also handles escaped quotes in attribute values.
	_regex_tag_open.compile("\\[([a-z_]+)((?:\\s+[a-z_]+(?:=\"(?:[^\\\\\"]|\\\\.)*\")?)*)\\]")

	_regex_tag_close = RegEx.new()
	# Detects closing tags like [/tag_name].
	_regex_tag_close.compile("\\[/([a-z_]+)\\]")

	_regex_attribute = RegEx.new()
	# Detects attributes like name="value" or single flags like name.
	# This also handles escaped quotes in attribute values.
	_regex_attribute.compile("([a-z_]+)(?:=\"((?:[^\\\\\"]|\\\\.)*)\")?")


func parse(source: String, result: ParseResult) -> ParseNode:
	_result = result
	var tokens := _tokenize(source)
	if not result.errors.empty():
		return null
	var root := _parse_tokens(tokens)
	return root


func _tokenize(source: String) -> Array:
	var tokens := []
	var lines := source.split("\n")
	var line_number := 0

	for line in lines:
		line_number += 1
		var line_tokens := _tokenize_line(line, line_number)
		tokens.append_array(line_tokens)

	return tokens


func _tokenize_line(line: String, line_number: int) -> Array:
	var tokens := []
	var position_current := 0

	while position_current < line.length():
		var close_match := _regex_tag_close.search(line, position_current)
		if close_match and close_match.get_start() == position_current:
			var tag_name := close_match.get_string(1)
			var tag_id := _parser_data.get_tag_enum(tag_name)

			if tag_id == _parser_data.Tag.UNKNOWN:
				# Treat unknown tags (including ignored formatting tags like b,
				# code, etc.) as literal text to insert into the content
				var token := Token.new()
				token.type = TokenTypes.TEXT
				token.text = close_match.get_string()
				token.line_number = line_number
				tokens.append(token)
				position_current = close_match.get_end()
				continue
			else:
				var token := Token.new()
				token.type = TokenTypes.TAG_CLOSE
				token.tag = tag_id
				token.line_number = line_number
				tokens.append(token)

			position_current = close_match.get_end()
			continue

		var open_match := _regex_tag_open.search(line, position_current)
		if open_match and open_match.get_start() == position_current:
			var tag_name := open_match.get_string(1)
			var attributes_string := open_match.get_string(2)
			var tag_id := _parser_data.get_tag_enum(tag_name)

			if tag_id == _parser_data.Tag.UNKNOWN:
				# Same as above, we turn unknown tags into literal text content
				var token := Token.new()
				token.type = TokenTypes.TEXT
				token.text = open_match.get_string()
				token.line_number = line_number
				tokens.append(token)
				position_current = open_match.get_end()
				continue
			else:
				var token := Token.new()
				token.type = TokenTypes.TAG_OPEN
				token.tag = tag_id
				token.attributes = _parse_attributes(attributes_string)
				token.line_number = line_number
				tokens.append(token)

			position_current = open_match.get_end()
			continue

		var next_open_tag_index := _regex_tag_open.search(line, position_current)
		var next_closed_tag_index := _regex_tag_close.search(line, position_current)

		var position_next_tag := line.length()
		if next_open_tag_index:
			position_next_tag = min(position_next_tag, next_open_tag_index.get_start())
		if next_closed_tag_index:
			position_next_tag = min(position_next_tag, next_closed_tag_index.get_start())

		if position_next_tag > position_current:
			var text_content := line.substr(position_current, position_next_tag - position_current)
			var token := Token.new()
			token.type = TokenTypes.TEXT
			token.text = text_content
			token.line_number = line_number
			tokens.append(token)
			position_current = position_next_tag
		elif position_next_tag == position_current and not next_open_tag_index and not next_closed_tag_index:
			var text_content := line.substr(position_current)
			if text_content.length() > 0:
				var token := Token.new()
				token.type = TokenTypes.TEXT
				token.text = text_content
				token.line_number = line_number
				tokens.append(token)
			break

	var token_newline := Token.new()
	token_newline.type = TokenTypes.TEXT
	token_newline.text = "\n"
	token_newline.line_number = line_number
	tokens.append(token_newline)

	return tokens


func _parse_attributes(attributes_string: String) -> Dictionary:
	var attributes := {}
	var matches := _regex_attribute.search_all(attributes_string)

	for match_result in matches:
		var attribute_name: String = match_result.get_string(1)
		var attribute_value: String = match_result.get_string(2)
		# This makes it so an attribute flag like [tag flag] is treated as a boolean set to true
		if attribute_value == "":
			attributes[attribute_name] = true
		else:
			attributes[attribute_name] = _unescape_attribute_value(attribute_value)

	return attributes


# Replaces escaped quotes and backslashes to turn them back into literal text.
func _unescape_attribute_value(value: String) -> String:
	return value.replace("\\\"", "\"").replace("\\\\", "\\")


func _parse_tokens(tokens: Array) -> ParseNode:
	var root := ParseNode.new()
	root.tag = _parser_data.Tag.UNKNOWN
	root.line_number = 0

	var stack := [root]
	var accumulated_text := ""

	for token in tokens:
		var current: ParseNode = stack.back()

		if token.type == TokenTypes.TAG_OPEN:
			if accumulated_text.strip_edges() != "":
				current.children.append(accumulated_text)
			accumulated_text = ""

			var tag_definition := _parser_data.get_tag_definition(token.tag)
			if tag_definition == null:
				_result.add_error(
					"No tag definition found for tag enum %d" % token.tag,
					token.line_number
				)
				continue

			var valid_parents: Array = tag_definition.valid_parents
			if not valid_parents.empty() and not current.tag in valid_parents:
				var parent_names := []
				for parent_current in valid_parents:
					parent_names.append("[%s]" % _parser_data.get_tag_name(parent_current))
				_result.add_error(
					"Tag [%s] cannot appear inside [%s]. Valid parents: %s" % [
						_parser_data.get_tag_name(token.tag),
						_parser_data.get_tag_name(current.tag) if current.tag != _parser_data.Tag.UNKNOWN else "_root",
						", ".join(parent_names)
					],
					token.line_number
				)

			var node := ParseNode.new()
			node.tag = token.tag
			node.attributes = token.attributes
			node.line_number = token.line_number
			current.children.append(node)

			if _parser_data.is_container_tag(token.tag):
				stack.push_back(node)

		elif token.type == TokenTypes.TAG_CLOSE:
			if accumulated_text.strip_edges() != "":
				current.children.append(accumulated_text)
			elif accumulated_text != "":
				if current.tag == _parser_data.Tag.CODEBLOCK or current.tag == _parser_data.Tag.STARTING_CODE:
					current.children.append(accumulated_text)
			accumulated_text = ""

			var current_name := _parser_data.get_tag_name(current.tag) if current.tag != _parser_data.Tag.UNKNOWN else "_root"
			var closing_name := _parser_data.get_tag_name(token.tag)

			if current.tag == _parser_data.Tag.UNKNOWN:
				_result.add_error(
					"Unexpected closing tag [/%s] with no matching opening tag" % closing_name,
					token.line_number
				)
			elif current.tag != token.tag:
				_result.add_error(
					"Mismatched closing tag: expected [/%s] but found [/%s]" % [
						current_name,
						closing_name
					],
					token.line_number
				)
			else:
				stack.pop_back()

		elif token.type == TokenTypes.TEXT:
			accumulated_text += token.text

	if stack.size() > 1:
		for current_index in range(1, stack.size()):
			var unclosed: ParseNode = stack[current_index]
			_result.add_error(
				"Unclosed tag [%s] opened at line %d" % [
					_parser_data.get_tag_name(unclosed.tag),
					unclosed.line_number
				],
				unclosed.line_number
			)

	return root


# This represents one token of type TokenTypes.
class Token:
	var type: int = TokenTypes.TEXT
	# We store the tag as we tokenize to avoid going back through it again later.
	var tag: int = BBCodeParserData.Tag.UNKNOWN
	var attributes := {}
	var text := ""
	var line_number := -1


# Parse tree node class
class ParseNode:
	var tag: int = BBCodeParserData.Tag.UNKNOWN
	var attributes := {}
	var children := []
	var line_number := -1



class ParseError:
	var message: String
	var line_number: int
	var is_warning: bool


	func _init(p_message: String, p_line: int, p_warning: bool = false) -> void:
		message = p_message
		line_number = p_line
		is_warning = p_warning


	func format() -> String:
		var prefix := "WARNING" if is_warning else "ERROR"
		return "[%s] Line %d: %s" % [prefix, line_number, message]


# This is the result object produced by the parser that is passed back to the caller.
# The parser aims to directly produce a lesson data structure that can be drawn by the app.
class ParseResult:
	var lesson: Lesson
	var errors: Array
	var warnings: Array


	func _init() -> void:
		lesson = null
		errors = []
		warnings = []


	func is_success() -> bool:
		return errors.empty() and lesson != null


	func add_error(message: String, line: int) -> void:
		errors.append(ParseError.new(message, line, false))


	func add_warning(message: String, line: int) -> void:
		warnings.append(ParseError.new(message, line, true))


	func get_all_messages() -> Array:
		var messages := []
		for error in errors:
			messages.append(error.format())
		for warning in warnings:
			messages.append(warning.format())
		return messages
