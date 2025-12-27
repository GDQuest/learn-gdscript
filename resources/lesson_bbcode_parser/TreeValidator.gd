class_name BBCodeTreeValidator
extends Reference

var _parser_data := BBCodeParserData.new()
var _result: BBCodeParser.ParseResult


func validate_tree(root: BBCodeParser.ParseNode, result: BBCodeParser.ParseResult) -> void:
	_result = result

	var lesson_count := 0
	var lesson_node: BBCodeParser.ParseNode = null

	for child in root.children:
		if child is BBCodeParser.ParseNode:
			if child.tag == _parser_data.Tag.LESSON:
				lesson_count += 1
				lesson_node = child
			else:
				_result.add_error(
					"Tag [%s] must be inside a [lesson] tag" % _parser_data.get_tag_name(child.tag),
					child.line_number
				)
		elif child is String and child.strip_edges() != "":
			_result.add_error("Content found outside of [lesson] tag", 1)

	if lesson_count == 0:
		_result.add_error("No [lesson] tag found in document", 1)
		return
	elif lesson_count > 1:
		_result.add_error("Multiple [lesson] tags found. Only one is allowed per file", 1)

	if lesson_node:
		_validate_node_children(lesson_node)


func _validate_node_children(node: BBCodeParser.ParseNode) -> void:
	var tag_definition := _parser_data.get_tag_definition(node.tag)
	if tag_definition == null:
		return
	var required_children: Array = tag_definition.required_children

	if not required_children.empty():
		var found_tags := {}
		for child in node.children:
			if child is BBCodeParser.ParseNode:
				found_tags[child.tag] = true

		for required_tag in required_children:
			if not found_tags.has(required_tag):
				_result.add_error(
					"[%s] is missing required [%s] tag" % [_parser_data.get_tag_name(node.tag), _parser_data.get_tag_name(required_tag)],
					node.line_number
				)

	if node.tag == _parser_data.Tag.QUIZ_CHOICE:
		var has_correct_option := false
		for child in node.children:
			if child is BBCodeParser.ParseNode and child.tag == _parser_data.Tag.OPTION:
				if child.attributes.get("correct", false):
					has_correct_option = true
					break
		if not has_correct_option:
			_result.add_error(
				"[quiz_choice] must have at least one [option correct] marking the correct answer",
				node.line_number
			)

	for child in node.children:
		if child is BBCodeParser.ParseNode:
			_validate_node_children(child)
