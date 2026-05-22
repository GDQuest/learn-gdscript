@tool
extends EditorTranslationParserPlugin


const SHARED := preload("Shared.gd")


func _parse_file(path: String) -> Array[PackedStringArray]:
	var parser := LessonBBCodeParser.new()
	
	var raw_lines := FileAccess.open(path, FileAccess.READ).get_as_text().split("\n")
	
	var result := parser.parse_file(path)
	if not result.is_success():
		push_error("Failed to parse BBCode for '%s':\n%s" % [path, result.get_all_messages()])
		return []
	var lesson_root := result.root
	
	# msgid, msgctxt, msgid_plural, comment, source_line
	var ret: Array[PackedStringArray]
	
	var current_paragraph := ""
	
	var stack := [lesson_root]
	var practice_idx := 0
	var quiz_idx := 0
	while not stack.is_empty():
		var current = stack.pop_front()
		if "children" in current:
			stack.append_array(current.children)
		if typeof(current) == TYPE_OBJECT and "tag" in current:
			match current.tag:
				BBCodeParserData.Tag.LESSON:
					ret.append(PackedStringArray([BBCodeUtils.get_lesson_title(current), "lesson.title", "", "", current.line_number]))
				BBCodeParserData.Tag.PARAGRAPH:
					var glossary_results := []
					var raw_string := BBCodeUtils.get_paragraph_text(current)
					var lines := _get_lines(raw_string)
					for i in lines.size():
						var line := lines[i]
						line = SHARED.fix_glossary_entries(line, glossary_results)
						ret.append(PackedStringArray([line, "text", "", ('The "term" in [glossary term="<term>"] should NOT be translated here') if glossary_results[0] else "", current.line_number + i]))
				BBCodeParserData.Tag.TITLE:
					ret.append(PackedStringArray([BBCodeUtils.get_paragraph_text(current), "heading", "", "", current.line_number]))
				BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT:
					var data := BBCodeUtils.get_quiz_data(current)
					ret.append(PackedStringArray([data.question, "quiz.%s.question" % [quiz_idx], "", "", current.line_number]))
					
					var lines := _get_lines(data.content)
					for line in lines:
						ret.append(PackedStringArray([line, "quiz.%s.content" % [quiz_idx], "", "", current.line_number]))
					
					lines = _get_lines(data.explanation)
					for line in lines:
						ret.append(PackedStringArray([line, "quiz.%s.explanation" % [quiz_idx], "", "", current.line_number]))
					
					for i in data.answers.size():
						ret.append(PackedStringArray([data.answers[i], "quiz.%s.answer%s" % [quiz_idx, ".valid" if data.valid_answers.has(data.answers[i]) else ""], "", "", current.line_number]))
					
					quiz_idx += 1
				BBCodeParserData.Tag.NOTE:
					var title := BBCodeUtils.get_note_title(current)
					ret.append(PackedStringArray([title, "note.title", "", "", current.line_number]))
					var contents := BBCodeUtils.get_note_contents(current)
					var lines := _get_lines(contents)
					for i in lines.size():
						var line := lines[i]
						ret.append(PackedStringArray([line, "note.text", "", "", current.line_number + i + 1]))
				BBCodeParserData.Tag.PRACTICE:
					var title := BBCodeUtils.get_practice_title(current)
					ret.append(PackedStringArray([title, "practice.%s.title" % [practice_idx], "", "", current.line_number]))
					
					var goal := BBCodeUtils.get_practice_goal(current)
					var lines := _get_lines(goal)
					for i in lines.size():
						ret.append(PackedStringArray([lines[i], "practice.%s.goal" % [practice_idx], "", "", current.line_number]))
					
					var description := BBCodeUtils.get_practice_description(current)
					lines = _get_lines(description)
					for i in lines.size():
						ret.append(PackedStringArray([lines[i], "practice.%s.description" % [practice_idx], "", "", current.line_number + i]))
					
					var hints := BBCodeUtils.get_practice_hints(current)
					for i in hints.size():
						ret.append(PackedStringArray([hints[i], "practice.%s.hint" % [practice_idx], "", "", current.line_number]))
						
					practice_idx += 1
	
	return ret


func _find_line_number(raw_lines: PackedStringArray, line: String) -> int:
	for i in raw_lines.size():
		if raw_lines[i] == line:
			return i
	return -1


func _get_lines(text_block: String) -> PackedStringArray:
	var raw_lines := text_block.split("\n", false)
	var ret := PackedStringArray()
	var current_line := ""
	var i := 0
	while i < raw_lines.size():
		if "[code]" in raw_lines[i] and not "[/code]" in raw_lines[i]:
			current_line = raw_lines[i]
			i += 1
			while not "[/code]" in raw_lines[i]:
				current_line += "\n" + raw_lines[i]
				i += 1
			current_line += "\n" + raw_lines[i]
			ret.push_back(current_line)
			i += 1
			continue
		if raw_lines[i].begins_with("- "):
			current_line = raw_lines[i]
			i += 1
			while i < raw_lines.size() and raw_lines[i].begins_with("- "):
				current_line += "\n" + raw_lines[i]
				i += 1
			ret.push_back(current_line)
			continue
		
		ret.push_back(raw_lines[i])
		i += 1
	return ret





func _get_recognized_extensions() -> PackedStringArray:
	return ["bbcode"]
