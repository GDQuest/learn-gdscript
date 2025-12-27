# This script turns the result from the parser into a data structure that the
# app can use to build and display a lesson's content.
#
# This is a compatibility layer that we use temporarily for an upgrade path to
# this new lesson authoring format.
#
# Later I'd like to directly build the node structure of the lesson UI from the
# parsed data instead of adding this conversion step. It'd be good also to get
# rid of the lesson content block scene and directly build the layout from code
# and only include actually required nodes. Because the number of nodes we
# manipulate right now leads to edge cases in the UI layout we have to consider.
class_name BBCodeResourceBuilder
extends Reference

var _parser_data := BBCodeParserData.new()
var _base_path := ""


func build_lesson(root: BBCodeParser.ParseNode, base_path: String = "") -> Lesson:
	_base_path = base_path
	# The expected structure for a lesson right now is there is a wrapping lesson tag and practices
	# are wrapped in practice tags. We validate that here.
	var lesson_node: BBCodeParser.ParseNode = null
	for child in root.children:
		if child is BBCodeParser.ParseNode and child.tag == _parser_data.Tag.LESSON:
			lesson_node = child
			break

	if not lesson_node:
		return null

	var lesson := Lesson.new()
	lesson.title = lesson_node.attributes.get("title", "Untitled")

	var current_title := ""
	var text_accumulator := ""

	for child in lesson_node.children:
		if child is String:
			text_accumulator += child
			continue

		if not child is BBCodeParser.ParseNode:
			continue

		var child_node: BBCodeParser.ParseNode = child

		if child_node.tag in _parser_data.CONTENT_PRODUCING_TAGS:
			if text_accumulator.strip_edges() != "":
				var block := _create_content_block(text_accumulator, current_title)
				lesson.content_blocks.append(block)
				text_accumulator = ""
				current_title = ""

		if child_node.tag == _parser_data.Tag.TITLE:
			current_title = _get_node_text_content(child_node).strip_edges()

		elif child_node.tag == _parser_data.Tag.CODEBLOCK:
			lesson.content_blocks.append(_create_codeblock(child_node))

		elif child_node.tag == _parser_data.Tag.VISUAL:
			lesson.content_blocks.append(_create_visual_block(child_node))

		elif child_node.tag == _parser_data.Tag.SEPARATOR:
			var separator_block := ContentBlock.new()
			separator_block.has_separator = true
			lesson.content_blocks.append(separator_block)

		elif child_node.tag == _parser_data.Tag.NOTE:
			lesson.content_blocks.append(_create_note_block(child_node))

		elif child_node.tag == _parser_data.Tag.QUIZ_CHOICE:
			lesson.content_blocks.append(_create_quiz_choice(child_node))

		elif child_node.tag == _parser_data.Tag.QUIZ_INPUT:
			lesson.content_blocks.append(_create_quiz_input(child_node))

		elif child_node.tag == _parser_data.Tag.PRACTICE:
			lesson.practices.append(_create_practice(child_node))

	if text_accumulator.strip_edges() != "":
		var block := _create_content_block(text_accumulator, current_title)
		lesson.content_blocks.append(block)

	return lesson


func _create_content_block(text: String, title: String) -> ContentBlock:
	var block := ContentBlock.new()
	block.title = title
	block.text = _clean_text_content(text)
	block.type = ContentBlock.Type.PLAIN
	return block


func _create_codeblock(node: BBCodeParser.ParseNode) -> CodeBlock:
	var code := _strip_leading_trailing_newlines(_get_node_text_content(node))

	var block := CodeBlock.new()
	block.is_runnable = _get_bool_attributes(node.attributes, "runnable", false)
	if block.is_runnable:
		block.content_id = "_generated_codeblock_runnable"
	else:
		block.content_id = "_generated_codeblock_static"
	block.code = code
	return block


func _create_visual_block(node: BBCodeParser.ParseNode) -> ContentBlock:
	var block := ContentBlock.new()
	block.type = ContentBlock.Type.PLAIN
	var path = node.attributes.get("path", "")

	if path != "" and path.is_rel_path() and _base_path != "":
		path = _base_path.plus_file(path)

	block.visual_element_path = path
	return block


func _create_note_block(node: BBCodeParser.ParseNode) -> ContentBlock:
	var block := ContentBlock.new()
	block.type = ContentBlock.Type.NOTE
	block.title = node.attributes.get("title", "")
	block.text = _clean_text_content(_get_node_text_content(node))
	return block


func _create_quiz_choice(node: BBCodeParser.ParseNode) -> QuizChoice:
	var quiz := QuizChoice.new()
	quiz.question = node.attributes.get("question", "")
	quiz.is_multiple_choice = _get_bool_attributes(node.attributes, "multiple", false)
	quiz.do_shuffle_answers = _get_bool_attributes(node.attributes, "shuffle", true)

	for child in node.children:
		if not child is BBCodeParser.ParseNode:
			continue

		var child_node: BBCodeParser.ParseNode = child

		if child_node.tag == _parser_data.Tag.OPTION:
			var option_text := _clean_text_content(_get_node_text_content(child_node))
			quiz.answer_options.append(option_text)
			if child_node.attributes.get("correct", false):
				quiz.valid_answers.append(option_text)

		elif child_node.tag == _parser_data.Tag.HINT:
			quiz.hint = _clean_text_content(_get_node_text_content(child_node))

		elif child_node.tag == _parser_data.Tag.EXPLANATION:
			quiz.explanation_bbcode = _clean_text_content(_get_node_text_content(child_node))

	return quiz


func _create_quiz_input(node: BBCodeParser.ParseNode) -> QuizInputField:
	var quiz := QuizInputField.new()
	quiz.question = node.attributes.get("question", "")
	quiz.valid_answer = node.attributes.get("answer", "")

	for child in node.children:
		if not child is BBCodeParser.ParseNode:
			continue

		var child_node: BBCodeParser.ParseNode = child
		if child_node.tag == _parser_data.Tag.HINT:
			quiz.hint = _clean_text_content(_get_node_text_content(child_node))
		elif child_node.tag == _parser_data.Tag.EXPLANATION:
			quiz.explanation_bbcode = _clean_text_content(_get_node_text_content(child_node))

	return quiz


func _create_practice(node: BBCodeParser.ParseNode) -> Practice:
	var practice := Practice.new()
	practice.practice_id = node.attributes.get("id", "")
	practice.title = node.attributes.get("title", "")

	var hints := []
	var doc_refs := []

	for child in node.children:
		if not child is BBCodeParser.ParseNode:
			continue

		var child_node: BBCodeParser.ParseNode = child

		if child_node.tag == _parser_data.Tag.DESCRIPTION:
			practice.description = _clean_text_content(_get_node_text_content(child_node))
		elif child_node.tag == _parser_data.Tag.GOAL:
			practice.goal = _clean_text_content(_get_node_text_content(child_node))
		elif child_node.tag == _parser_data.Tag.STARTING_CODE:
			practice.starting_code = _strip_leading_trailing_newlines(_get_node_text_content(child_node))
		elif child_node.tag == _parser_data.Tag.CURSOR:
			var line_number_string: String = child_node.attributes.get("line", "0")
			var column_string: String = child_node.attributes.get("column", "0")
			practice.cursor_line = int(line_number_string)
			practice.cursor_column = int(column_string)
		elif child_node.tag == _parser_data.Tag.VALIDATOR:
			var path = child_node.attributes.get("path", "")
			if path != "" and path.is_rel_path() and _base_path != "":
				path = _base_path.plus_file(path)
			practice.validator_script_path = path
		elif child_node.tag == _parser_data.Tag.SCRIPT_SLICE:
			var path = child_node.attributes.get("path", "")
			if path != "" and path.is_rel_path() and _base_path != "":
				path = _base_path.plus_file(path)
			practice.script_slice_path = path
			practice.slice_name = child_node.attributes.get("name", "")
		elif child_node.tag == _parser_data.Tag.HINT:
			hints.append(_clean_text_content(_get_node_text_content(child_node)))
		elif child_node.tag == _parser_data.Tag.DOCS:
			var docs_text := _get_node_text_content(child_node).strip_edges()
			if docs_text != "":
				var refs := docs_text.split(",")
				for ref in refs:
					doc_refs.append(ref.strip_edges())

	practice.hints = PoolStringArray(hints)
	practice.documentation_references = PoolStringArray(doc_refs)
	if practice.cursor_line == 0 and practice.cursor_column == 0 and practice.starting_code != "":
		var lines := practice.starting_code.split("\n")
		practice.cursor_line = lines.size()
		if lines.size() > 0:
			practice.cursor_column = lines[lines.size() - 1].length()

	return practice


func _get_node_text_content(node: BBCodeParser.ParseNode) -> String:
	var text := ""
	for child in node.children:
		if child is String:
			text += child
		elif child is BBCodeParser.ParseNode:
			text += _get_node_text_content(child)
	return text


# Cleans up text content by stripping whitespace and removing consecutive blank
# lines.
func _clean_text_content(text: String) -> String:
	text = text.strip_edges()
	var lines := text.split("\n")
	var cleaned_lines := []
	var is_previous_line_blank := false
	for line in lines:
		var is_blank: bool = line.strip_edges() == ""
		if is_blank and is_previous_line_blank:
			continue
		cleaned_lines.append(line)
		is_previous_line_blank = is_blank
	return PoolStringArray(cleaned_lines).join("\n")


func _get_bool_attributes(attrs: Dictionary, name: String, default: bool) -> bool:
	var value = attrs.get(name, default)
	if value is bool:
		return value
	return value == "true"


func _strip_leading_trailing_newlines(text: String) -> String:
	var start := 0
	while start < text.length() and text[start] == "\n":
		start += 1
	var end := text.length() - 1
	while end >= 0 and text[end] == "\n":
		end -= 1
	if start != 0 or end != text.length() - 1:
		return text.substr(start, end - start + 1)
	return text
