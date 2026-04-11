class_name BBCodeTreeValidator
extends RefCounted

var _parser_data := BBCodeParserData.new()
var _result: BBCodeParser.ParseResult


func validate_tree(root: BBCodeParser.ParseNode, result: BBCodeParser.ParseResult) -> void:
	_result = result

	var lesson_count := 0
	var lesson_node: BBCodeParser.ParseNode = null

	for child: Variant in root.children:
		if child is BBCodeParser.ParseNode:
			if child.tag == _parser_data.Tag.LESSON:
				lesson_count += 1
				lesson_node = child
			else:
				var child_tag: int = child.tag
				var child_line_number: int = child.line_number
				_result.add_error(
					"Tag [%s] must be inside a [lesson] tag" % _parser_data.get_tag_name(child_tag),
					child_line_number,
				)
		elif child is String and (child as String).strip_edges() != "":
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

	if not required_children.is_empty():
		var found_tags := { }
		for child in node.children:
			if child is BBCodeParser.ParseNode:
				found_tags[child.tag] = true

		for required_tag: int in required_children:
			if not found_tags.has(required_tag):
				_result.add_error(
					"[%s] is missing required [%s] tag" % [_parser_data.get_tag_name(node.tag), _parser_data.get_tag_name(required_tag)],
					node.line_number,
				)

	if node.tag == _parser_data.Tag.QUIZ_CHOICE:
		var has_correct_option := false
		for child: Variant in node.children:
			if child is BBCodeParser.ParseNode and child.tag == _parser_data.Tag.OPTION:
				var child_attributes_correct: bool = (child as BBCodeParser.ParseNode).attributes.get("correct", false)
				if child_attributes_correct:
					has_correct_option = true
					break
		if not has_correct_option:
			_result.add_error(
				"[quiz_choice] must have at least one [option correct] marking the correct answer",
				node.line_number,
			)

	for child in node.children:
		if child is BBCodeParser.ParseNode:
			_validate_node_children(child as BBCodeParser.ParseNode)
