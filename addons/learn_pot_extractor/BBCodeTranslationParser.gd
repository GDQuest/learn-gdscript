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
					ret.append(PackedStringArray([BBCodeUtils.get_lesson_title(current), "", "", "", current.line_number]))
				BBCodeParserData.Tag.PARAGRAPH:
					var glossary_results := []
					var raw_string := BBCodeUtils.get_paragraph_text(current)
					var lines := _get_lines(raw_string)
					for i in lines.size():
						var line := lines[i]
						line = SHARED.fix_glossary_entries(line, glossary_results)
						ret.append(PackedStringArray([line, "", "", ('The "term" in [glossary term="<term>"] should NOT be translated here') if glossary_results[0] else "", current.line_number + i]))
				BBCodeParserData.Tag.TITLE:
					ret.append(PackedStringArray([BBCodeUtils.get_paragraph_text(current), "", "", "", current.line_number]))
				BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT:
					var data := BBCodeUtils.get_quiz_data(current)
					ret.append(PackedStringArray([data.question, "", "", "", current.line_number]))
					
					var lines := _get_lines(data.content)
					var glossary_results := []
					for line in lines:
						line = SHARED.fix_glossary_entries(line, glossary_results)
						ret.append(PackedStringArray([line, "", "", 'The "term" in [glossary term="<term>"] should NOT be translated here' if glossary_results[0] else "", current.line_number]))
					
					lines = _get_lines(data.explanation)
					for line in lines:
						line = SHARED.fix_glossary_entries(line, glossary_results)
						ret.append(PackedStringArray([line, "", "", 'The "term" in [glossary term="<term>"] should NOT be translated here' if glossary_results[0] else "", current.line_number]))
					
					for i in data.answers.size():
						ret.append(PackedStringArray([data.answers[i], "", "", "", current.line_number]))
					
					quiz_idx += 1
				BBCodeParserData.Tag.NOTE:
					var title := BBCodeUtils.get_note_title(current)
					ret.append(PackedStringArray([title, "", "", "", current.line_number]))
					var contents := BBCodeUtils.get_note_contents(current)
					var lines := _get_lines(contents)
					var glossary_results := []
					for i in lines.size():
						var line := lines[i]
						line = SHARED.fix_glossary_entries(line, glossary_results)
						ret.append(PackedStringArray([line, "", "", 'The "term" in [glossary term="<term>"] should NOT be translated here' if glossary_results[0] else "", current.line_number + i + 1]))
				BBCodeParserData.Tag.PRACTICE:
					var title := BBCodeUtils.get_practice_title(current)
					ret.append(PackedStringArray([title, "", "", "", current.line_number]))
					
					var goal := BBCodeUtils.get_practice_goal(current)
					var glossary_results := []
					var lines := _get_lines(goal)
					for i in lines.size():
						var line := SHARED.fix_glossary_entries(lines[i], glossary_results)
						ret.append(PackedStringArray([line, "", "", 'The "term" in [glossary term="<term>"] should NOT be translated here' if glossary_results[0] else "", current.line_number]))
					
					var description := BBCodeUtils.get_practice_description(current)
					lines = _get_lines(description)
					for i in lines.size():
						var line := SHARED.fix_glossary_entries(lines[i], glossary_results)
						ret.append(PackedStringArray([line, "", "", 'The "term" in [glossary term="<term>"] should NOT be translated here' if glossary_results[0] else "", current.line_number + i]))
					
					var hints := BBCodeUtils.get_practice_hints(current)
					for i in hints.size():
						ret.append(PackedStringArray([hints[i], "", "", "", current.line_number]))
						
					practice_idx += 1
	
	for i in range(ret.size()-1, -1, -1):
		var id := ret[i][0]
		if (
			id.is_valid_int() or
			id.is_valid_float()
		):
			ret.remove_at(i)
			continue
		
		if id.begins_with("[code]"):
			if id.find("[/code]", 6) == id.length()-7:
				ret.remove_at(i)
	
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
