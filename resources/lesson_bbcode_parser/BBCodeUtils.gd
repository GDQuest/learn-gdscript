class_name BBCodeUtils
extends Reference


static func get_node_type(node: BBCodeParser.ParseNode) -> int:
	return node.tag


static func get_codeblock_id(codeblock: BBCodeParser.ParseNode) -> String:
	if codeblock.attributes.get("runnable", false):
		return "_generated_codeblock_runnable_%s" % codeblock.line_number
	else:
		return "_generated_codeblock_static_%s" % codeblock.line_number


static func get_codeblock_code(codeblock: BBCodeParser.ParseNode) -> String:
	return _strip_leading_trailing_newlines(_get_text_content(codeblock, true))


static func get_lesson_block_count(lesson: BBCodeParser.ParseNode) -> int:
	var child_count := 0
	for child in lesson.children:
		if child is String or (child is BBCodeParser.ParseNode and child.tag in BBCodeParserData.CONTENT_PRODUCING_TAGS):
			child_count += 1
	return child_count


static func get_lesson_block_type(lesson: BBCodeParser.ParseNode, block_index: int) -> int:
	assert(block_index >= 0 and block_index < get_lesson_block_count(lesson), "Invalid block index")
	var child_count := 0
	for child in lesson.children:
		if child is String:
			if block_index == child_count:
				return BBCodeParserData.Tag.STRING
		if child is BBCodeParser.ParseNode and child.tag in BBCodeParserData.CONTENT_PRODUCING_TAGS:
			if block_index == child_count:
				return child.tag
		child_count += 1
	return BBCodeParserData.Tag.UNKNOWN


static func get_lesson_text_block(lesson: BBCodeParser.ParseNode, block_index: int) -> String:
	assert(block_index >= 0 and block_index < get_lesson_block_count(lesson), "Invalid block index")
	var child_count := 0
	for child in lesson.children:
		if child is String and block_index == child_count:
			return child
		child_count += 1
	return ""


static func get_lesson_title_for_index(lesson: BBCodeParser.ParseNode, block_index: int) -> String:
	assert(block_index >= 0 and block_index < get_lesson_block_count(lesson), "Invalid block index")
	var child_count := 0
	var last_title := ""
	for child in lesson.children:
		if child is BBCodeParser.ParseNode and child.tag == BBCodeParserData.Tag.TITLE:
			last_title = clean_text_content(_get_text_content(child, true))
		elif child is BBCodeParser.ParseNode and child.tag in BBCodeParserData.CONTENT_PRODUCING_TAGS:
			last_title = ""
		if child_count == block_index:
			break
		child_count += 1
	return last_title


static func get_note_title(note: BBCodeParser.ParseNode) -> String:
	return note.attributes.get("title", "")


static func get_note_contents(note: BBCodeParser.ParseNode) -> String:
	return clean_text_content(_get_text_content(note, true))


static func get_visual_path(visual: BBCodeParser.ParseNode) -> String:
	return visual.attributes.get("path", "")


static func get_block_type(block) -> int:
	return block.tag if block is BBCodeParser.ParseNode else BBCodeParserData.Tag.STRING


static func get_lesson_block_id(block: BBCodeParser.ParseNode) -> String:
	return "_generated_content_block_plain_%s" % block.line_number


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
	for child in practice.children:
		if child is BBCodeParser.ParseNode and child.tag == BBCodeParserData.Tag.DESCRIPTION:
			return clean_text_content(_get_text_content(child, true))
	return ""


static func get_practice_script_slice_path(practice: BBCodeParser.ParseNode) -> String:
	for child in practice.children:
		if child.tag == BBCodeParserData.Tag.SCRIPT_SLICE:
			return child.attributes.get("path", "")
	return ""


static func get_practice_script_slice_name(practice: BBCodeParser.ParseNode) -> String:
	for child in practice.children:
		if child.tag == BBCodeParserData.Tag.SCRIPT_SLICE:
			return child.attributes.get("name", "")
	return ""


static func get_practice_validator_path(practice: BBCodeParser.ParseNode) -> String:
	for child in practice.children:
		if child.tag == BBCodeParserData.Tag.VALIDATOR:
			return child.attributes.get("path", "")
	return ""


static func get_practice_documentation(practice: BBCodeParser.ParseNode) -> PoolStringArray:
	var docs := PoolStringArray()
	for child in practice.children:
		if child.tag == BBCodeParserData.Tag.DOCS:
			docs.push_back(_get_text_content(child, true))
	return docs


static func get_practice_goal(practice: BBCodeParser.ParseNode) -> String:
	for child in practice.children:
		if child.tag == BBCodeParserData.Tag.GOAL:
			return clean_text_content(_get_text_content(child, true))
	return ""


static func get_practice_starting_code(practice: BBCodeParser.ParseNode) -> String:
	for child in practice.children:
		if child.tag == BBCodeParserData.Tag.STARTING_CODE:
			return clean_text_content(_get_text_content(child, true))
	return ""


static func get_practice_cursor(practice: BBCodeParser.ParseNode) -> Vector2:
	for child in practice.children:
		if child.tag == BBCodeParserData.Tag.CURSOR:
			return Vector2(child.attributes.get("line", 0), child.attributes.get("column", 0))
	return Vector2.ZERO


static func get_practice_hints(practice: BBCodeParser.ParseNode) -> PoolStringArray:
	var hints := PoolStringArray()
	for child in practice.children:
		if child.tag == BBCodeParserData.Tag.HINT:
			hints.push_back(clean_text_content(_get_text_content(child, true)))
	return hints


static func get_practice_id(practice: BBCodeParser.ParseNode) -> String:
	return practice.attributes.get("id", "")


static func get_quiz_id(quiz: BBCodeParser.ParseNode) -> String:
	return _to_snake_case(get_quiz_question(quiz))


static func get_quiz_question(quiz: BBCodeParser.ParseNode) -> String:
	return quiz.attributes.get("question", "")


static func get_quiz_content(quiz: BBCodeParser.ParseNode) -> String:
	return clean_text_content(_get_text_content(quiz, false))


static func get_quiz_explanation(quiz: BBCodeParser.ParseNode) -> String:
	for child in quiz.children:
		if child is BBCodeParser.ParseNode:
			if child.tag == BBCodeParserData.Tag.EXPLANATION:
				return clean_text_content(_get_text_content(child, true))
	return ""


static func get_quiz_type(quiz: BBCodeParser.ParseNode) -> int:
	return quiz.tag


static func get_quiz_choices(quiz: BBCodeParser.ParseNode) -> Dictionary:
	var answers := []
	var valid_answers := []
	for child in quiz.children:
		if child is BBCodeParser.ParseNode:
			if child.tag == BBCodeParserData.Tag.OPTION:
				var text: String = clean_text_content(_get_text_content(child, true))
				answers.push_back(text)
				if child.attributes.get("correct", false):
					valid_answers.push_back(text)
	return {"answers": answers, "valid_answers": valid_answers}


static func get_quiz_shuffle(quiz: BBCodeParser.ParseNode) -> bool:
	return quiz.attributes.get("shuffle", "false") == "true"


static func get_quiz_multiple_answers(quiz: BBCodeParser.ParseNode) -> bool:
	return quiz.attributes.get("multiple", "false") == "true"


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
	return PoolStringArray(cleaned_lines).join("\n")


static func _get_text_content(node: BBCodeParser.ParseNode, recurse: bool) -> String:
	var text := ""
	for child in node.children:
		if child is String:
			text += child
		elif child is BBCodeParser.ParseNode and recurse:
			text += _get_text_content(child, recurse)
	return text


static func _to_snake_case(input_string: String) -> String:
	var regex := RegEx.new()
	regex.compile("(?<=[a-z])(?=[A-Z])|[^a-zA-Z]")
	return regex.sub(input_string, " ", true).strip_edges().replace(" ", "_").to_lower()


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
