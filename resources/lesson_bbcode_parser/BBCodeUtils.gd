class_name BBCodeUtils
extends RefCounted

static var snake_case_regex := RegEx.create_from_string("(?<=[a-z])(?=[A-Z])|[^a-zA-Z]")


static func get_lesson_block_count(lesson: BBCodeParser.ParseNode) -> int:
	var child_count := 0
	for child in lesson.children:
		if child is String or (child is BBCodeParser.ParseNode and child.tag in BBCodeParserData.CONTENT_PRODUCING_TAGS):
			child_count += 1
	return child_count


static func get_lesson_block_type(lesson: BBCodeParser.ParseNode, block_index: int) -> int:
	var child = lesson.children[block_index]
	if child is String:
		return BBCodeParserData.Tag.STRING
	if child is BBCodeParser.ParseNode and child.tag in BBCodeParserData.CONTENT_PRODUCING_TAGS:
		return child.tag
	return BBCodeParserData.Tag.UNKNOWN


static func get_lesson_text_block(lesson: BBCodeParser.ParseNode, block_index: int) -> String:
	var child = lesson.children[block_index]
	if child is String:
		return child
	return ""


static func get_lesson_title_for_index(lesson: BBCodeParser.ParseNode, block_index: int) -> String:
	# Work backwards from the content index to find the nearest title above the block
	for i: int in range(block_index, -1, -1):
		var child: Variant = lesson.children[i]
		if child is BBCodeParser.ParseNode:
			var child_node: BBCodeParser.ParseNode = lesson.children[i]
			if child_node.tag == BBCodeParserData.Tag.TITLE:
				return clean_text_content(_get_text_content(child_node, true))
			# If a visual, quiz, separator or other block is encountered first, have no titles
			if child.tag in BBCodeParserData.CONTENT_PRODUCING_TAGS:
				break

	return ""


static func get_note_title(note: BBCodeParser.ParseNode) -> String:
	return note.attributes.get("title", "")


static func get_note_contents(note: BBCodeParser.ParseNode) -> String:
	return clean_text_content(_get_text_content(note, true))


static func get_visual_path(visual: BBCodeParser.ParseNode) -> String:
	return visual.attributes.get("path", "")


static func get_block_type(block: Variant) -> int:
	return BBCodeParserData.Tag.STRING if block is String else block.tag if block is BBCodeParser.ParseNode else BBCodeParserData.Tag.UNKNOWN


static func get_lesson_title(lesson: BBCodeParser.ParseNode) -> String:
	return lesson.attributes.get("title", "")


static func get_lesson_practice_count(lesson: BBCodeParser.ParseNode) -> int:
	var practice_count := 0
	for child in lesson.children:
		if child is BBCodeParser.ParseNode and child.tag == BBCodeParserData.Tag.PRACTICE:
			practice_count += 1
	return practice_count


static func get_lesson_practice(lesson: BBCodeParser.ParseNode, practice_index: int) -> BBCodeParser.ParseNode:
	assert(practice_index >= 0 and practice_index < get_lesson_practice_count(lesson), "Invalid practice index")
	var practice_count := 0
	for child in lesson.children:
		if child is BBCodeParser.ParseNode and child.tag == BBCodeParserData.Tag.PRACTICE:
			if practice_index == practice_count:
				return child
			practice_count += 1
	return null


static func get_practice_index(lesson: BBCodeParser.ParseNode, practice: BBCodeParser.ParseNode) -> int:
	var practice_id := get_practice_id(practice)
	var count := 0
	for child in lesson.children:
		if child is BBCodeParser.ParseNode and child.tag == BBCodeParserData.Tag.PRACTICE:
			if get_practice_id(child) == practice_id:
				return count
			count += 1
	return -1


static func get_lesson_quiz_count(lesson: BBCodeParser.ParseNode) -> int:
	var quiz_count := 0
	for child in lesson.children:
		if child is BBCodeParser.ParseNode and child.tag in [BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT]:
			quiz_count += 1
	return quiz_count


static func get_lesson_quiz(lesson: BBCodeParser.ParseNode, quiz_index: int) -> BBCodeParser.ParseNode:
	assert(quiz_index >= 0 and quiz_index < get_lesson_quiz_count(lesson), "Invalid quiz index")
	var quiz_count := 0
	for child in lesson.children:
		if child is BBCodeParser.ParseNode and child.tag in [BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT]:
			if quiz_index == quiz_count:
				return child
			quiz_count += 1
	return null


static func get_practice_title(practice: BBCodeParser.ParseNode) -> String:
	return practice.attributes.get("title", "")


static func get_practice_description(practice: BBCodeParser.ParseNode) -> String:
	for child: BBCodeParser.ParseNode in practice.children:
		if child is BBCodeParser.ParseNode and child.tag == BBCodeParserData.Tag.DESCRIPTION:
			return clean_text_content(_get_text_content(child, true))
	return ""


static func get_practice_script_slice_path(practice: BBCodeParser.ParseNode) -> String:
	for child: BBCodeParser.ParseNode in practice.children:
		if child.tag == BBCodeParserData.Tag.SCRIPT_SLICE:
			return child.attributes.get("path", "")
	return ""


static func get_practice_script_slice_name(practice: BBCodeParser.ParseNode) -> String:
	for child: BBCodeParser.ParseNode in practice.children:
		if child.tag == BBCodeParserData.Tag.SCRIPT_SLICE:
			return child.attributes.get("name", "")
	return ""


static func get_practice_validator_path(practice: BBCodeParser.ParseNode) -> String:
	for child: BBCodeParser.ParseNode in practice.children:
		if child.tag == BBCodeParserData.Tag.VALIDATOR:
			return child.attributes.get("path", "")
	return ""


static func get_practice_documentation(practice: BBCodeParser.ParseNode) -> PackedStringArray:
	var docs := PackedStringArray()
	for child: BBCodeParser.ParseNode in practice.children:
		if child.tag == BBCodeParserData.Tag.DOCS:
			docs.push_back(_get_text_content(child, true))
	return docs


static func get_practice_goal(practice: BBCodeParser.ParseNode) -> String:
	for child: BBCodeParser.ParseNode in practice.children:
		if child.tag == BBCodeParserData.Tag.GOAL:
			return clean_text_content(_get_text_content(child, true))
	return ""


static func get_practice_starting_code(practice: BBCodeParser.ParseNode) -> String:
	for child: BBCodeParser.ParseNode in practice.children:
		if child.tag == BBCodeParserData.Tag.STARTING_CODE:
			return clean_text_content(_get_text_content(child, true))
	return ""


static func get_practice_cursor(practice: BBCodeParser.ParseNode) -> Vector2i:
	for child: BBCodeParser.ParseNode in practice.children:
		if child.tag == BBCodeParserData.Tag.CURSOR:
			var child_attributes_line: int = int(child.attributes.get("line", 0) as String)
			var child_attributes_column: int = int(child.attributes.get("column", 0) as String)
			return Vector2i(child_attributes_line, child_attributes_column)
	return Vector2i.ZERO


static func get_practice_hints(practice: BBCodeParser.ParseNode) -> PackedStringArray:
	var hints := PackedStringArray()
	for child: BBCodeParser.ParseNode in practice.children:
		if child.tag == BBCodeParserData.Tag.HINT:
			hints.push_back(clean_text_content(_get_text_content(child, true)))
	return hints


static func get_practice_id(practice: BBCodeParser.ParseNode) -> String:
	return practice.attributes.get("id", "")


class QuizData:
	var tag: int = BBCodeParserData.Tag.UNKNOWN
	var question := ""
	var content := ""
	var explanation := ""
	var answers := []
	var valid_answers := []
	var shuffle := false
	var multiple := false


	func get_answer_count() -> int:
		return valid_answers.size()


	func get_correct_answer_string() -> String:
		match valid_answers.size():
			0:
				return ""
			1:
				return str(valid_answers[0])
			2:
				return "%s and %s" % [valid_answers[0], valid_answers[1]]
			_:
				var answer_list := valid_answers.duplicate()
				var last_answer = answer_list.pop_back()
				return "%s, and %s" % [", ".join(PackedStringArray(answer_list)), last_answer]


static func get_quiz_id(quiz: BBCodeParser.ParseNode) -> String:
	var quiz_attributes_question: String = quiz.attributes.get("question", "")
	return _to_snake_case(quiz_attributes_question)


static func get_quiz_data(quiz: BBCodeParser.ParseNode) -> QuizData:
	var data := QuizData.new()
	data.tag = quiz.tag
	data.question = quiz.attributes.get("question", "")
	data.shuffle = quiz.attributes.get("shuffle", "false") == "true"
	data.multiple = quiz.attributes.get("multiple", "false") == "true"
	data.content = clean_text_content(_get_text_content(quiz, false))

	if quiz.tag == BBCodeParserData.Tag.QUIZ_INPUT:
		var quiz_attributes_answer: String = quiz.attributes.get("answer", "")
		data.valid_answers = [quiz_attributes_answer.strip_edges()]

	for child in quiz.children:
		if child is BBCodeParser.ParseNode:
			var child_node: BBCodeParser.ParseNode = child
			match child.tag:
				BBCodeParserData.Tag.EXPLANATION:
					data.explanation = clean_text_content(_get_text_content(child_node, true))
				BBCodeParserData.Tag.OPTION:
					var answer: String = clean_text_content(_get_text_content(child_node, true))
					data.answers.push_back(answer)
					var child_attributes_correct: bool = child_node.attributes.get("correct", false)
					if child_attributes_correct:
						data.valid_answers.push_back(answer)
				_:
					pass

	return data


static func clean_text_content(text: String) -> String:
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
	return "\n".join(PackedStringArray(cleaned_lines))


static func _get_text_content(node: BBCodeParser.ParseNode, recurse: bool) -> String:
	var text := ""
	for child in node.children:
		if child is String:
			text += child
		elif child is BBCodeParser.ParseNode and recurse:
			var child_node: BBCodeParser.ParseNode = child
			text += _get_text_content(child_node, recurse)
	return text


static func _to_snake_case(input_string: String, separator := "_") -> String:
	return snake_case_regex.sub(input_string, " ", true).strip_edges().replace(" ", separator).to_lower()


static func _to_kebab_case(input_string: String) -> String:
	return _to_snake_case(input_string, "-")


static func _strip_leading_trailing_newlines(text: String) -> String:
	var start := 0
	while start < text.length() and text[start] == "\n":
		start += 1
	var end := text.length() - 1
	while end >= 0 and text[end] == "\n":
		end -= 1
	if start != 0 or end != text.length() - 1:
		return text.substr(start, end - start + 1)
	return text
