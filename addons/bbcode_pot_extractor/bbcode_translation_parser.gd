@tool
extends EditorTranslationParserPlugin


static var GLOSSARY_RE := RegEx.create_from_string(r"\[url=(?!http)[^\]]+\]([^\[]+)\[\/url\]")


func _parse_file(path: String) -> Array[PackedStringArray]:
	var parser := LessonBBCodeParser.new()
	
	var result := parser.parse_file(path)
	if not result.is_success():
		push_error("Failed to parse BBCode for '%s':\n%s" % [path, result.get_all_messages()])
		return []
	var lesson_root := result.root
	
	# msgid, msgctxt, msgid_plural, comment, source_line
	var ret: Array[PackedStringArray]
	
	var current_paragraph := ""
	
	var stack := [lesson_root]
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
					var raw_string := _fix_glossary_entries(BBCodeUtils.get_paragraph_text(current), glossary_results)
					ret.append(PackedStringArray([raw_string, "", "", ('The "term" in [glossary term="<term>"] should be translated') if glossary_results[0] else "", current.line_number]))
				BBCodeParserData.Tag.TITLE:
					ret.append(PackedStringArray([BBCodeUtils.get_paragraph_text(current), "lesson.heading", "", "", current.line_number]))
				BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT:
					var data := BBCodeUtils.get_quiz_data(current)
					ret.append(PackedStringArray([data.question, "quiz.question", "", "", current.line_number]))
					for i in data.answers.size():
						ret.append(PackedStringArray([data.answers[i], "quiz.answer.%s%s" % [i, ".correct" if data.valid_answers.has(data.answers[i]) else ""], "", "", current.line_number]))
					ret.append(PackedStringArray([data.explanation, "quiz.explanation", "", "", current.line_number]))
					ret.append(PackedStringArray([data.content, "quiz.content", "", "", current.line_number]))
				BBCodeParserData.Tag.NOTE:
					var title := BBCodeUtils.get_note_title(current)
					ret.append(PackedStringArray([title, "note.title", "", "", current.line_number]))
					var contents := BBCodeUtils.get_note_contents(current)
					ret.append(PackedStringArray([contents, "note.contents", "", "", current.line_number]))
				BBCodeParserData.Tag.PRACTICE:
					var title := BBCodeUtils.get_practice_title(current)
					ret.append(PackedStringArray([title, "practice.title", "", "", current.line_number]))
					var description := BBCodeUtils.get_practice_description(current)
					ret.append(PackedStringArray([description, "practice.description", "", "", current.line_number]))
					var goal := BBCodeUtils.get_practice_goal(current)
					ret.append(PackedStringArray([goal, "practice.goal", "", "", current.line_number]))
					var hints := BBCodeUtils.get_practice_hints(current)
					for i in hints.size():
						ret.append(PackedStringArray([hints[i], "practice.hint.%s" % [i], "", "", current.line_number]))
	
	return ret


func _fix_glossary_entries(raw_string: String, out_did_find: Array) -> String:
	var finds := GLOSSARY_RE.search_all(raw_string)
	out_did_find.resize(1)
	out_did_find[0] = not finds.is_empty()
	
	for i in range(finds.size()-1, -1, -1):
		var find: RegExMatch = finds[i]
		raw_string = raw_string.substr(0, find.get_start()) + '[glossary term="%s"]' % [find.get_string(1)] + raw_string.substr(find.get_end())
	return raw_string


func _get_recognized_extensions() -> PackedStringArray:
	return ["bbcode"]
