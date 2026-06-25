@tool
extends RefCounted

const SHARED := preload("Shared.gd")


static func build_translated_lesson(lesson_bbcode_path: String, lang: String, tr_blocks: Array[Dictionary], translation_report: Dictionary) -> String:
	var parser := LessonBBCodeParser.new()
	var result := parser.parse_file(lesson_bbcode_path)
	
	var root: BBCodeParser.ParseNode = result.root
	var lesson: BBCodeParser.ParseNode = root.children[0]
	
	var lesson_builder: Array[String] = []
	_build_lesson_tag(lesson_builder, lesson, tr_blocks, translation_report)
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
	var practice_idx := 0
	for child: BBCodeParser.ParseNode in lesson.children:
		match child.tag:
			BBCodeParserData.Tag.TITLE:
				_build_title_tag(lesson_builder, lesson, child, tr_blocks, translation_report)
			BBCodeParserData.Tag.VISUAL:
				_build_visual_tag(lesson_builder, child)
			BBCodeParserData.Tag.NOTE:
				_build_note_tag(lesson_builder, child, tr_blocks, translation_report)
			BBCodeParserData.Tag.QUIZ_CHOICE:
				_build_quiz_choice_tag(lesson_builder, child, tr_blocks, translation_report)
			BBCodeParserData.Tag.QUIZ_INPUT:
				pass
			BBCodeParserData.Tag.PARAGRAPH:
				_build_text(lesson_builder, child, tr_blocks, translation_report)
			BBCodeParserData.Tag.PRACTICE:
				_build_practice_tag(lesson_builder, child, tr_blocks, translation_report)
				if practice_idx < practice_count-1:
					lesson_builder.append("")
				practice_idx += 1
	
	lesson_builder.append("[/lesson]")
	
	return "\n".join(lesson_builder)


static func _build_lesson_tag(str_builder: Array[String], lesson: BBCodeParser.ParseNode, tr_blocks: Array[Dictionary], translation_report: Dictionary) -> void:
	str_builder.append_array(['[lesson title="%s"]' % [_tr(BBCodeUtils.get_lesson_title(lesson).replace('"', r'\"'), tr_blocks, translation_report)], ""])


static func _build_title_tag(str_builder: Array[String], lesson: BBCodeParser.ParseNode, title: BBCodeParser.ParseNode, tr_blocks: Array[Dictionary], translation_report: Dictionary) -> void:
	str_builder.append_array(["[title]%s[/title]" % [_tr(BBCodeUtils.get_lesson_title_for_index(lesson, lesson.children.find(title)), tr_blocks, translation_report)], ""])


static func _build_visual_tag(str_builder: Array[String], visual: BBCodeParser.ParseNode) -> void:
	str_builder.append_array(['[visual path="%s"]' % [BBCodeUtils.get_visual_path(visual)], ""])


static func _build_note_tag(str_builder: Array[String], note: BBCodeParser.ParseNode, tr_blocks: Array[Dictionary], translation_report: Dictionary) -> void:
	str_builder.append('[note title="%s"]' % [_tr(BBCodeUtils.get_note_title(note).replace('"', r'\"'), tr_blocks, translation_report)])
	
	var note_lines := _get_lines(BBCodeUtils.get_note_contents(note))
	for i in note_lines.size():
		var line: String = note_lines[i]
		str_builder.append(_tr(line, tr_blocks, translation_report))
	
	str_builder.append_array(["[/note]", ""])


static func _build_quiz_choice_tag(str_builder: Array[String], quiz: BBCodeParser.ParseNode, tr_blocks: Array[Dictionary], translation_report: Dictionary) -> void:
	var quiz_data := BBCodeUtils.get_quiz_data(quiz)
	str_builder.append('[quiz_choice question="%s" multiple="%s" shuffle="%s" en_id="%s"]' % [
		_tr(quiz_data.question.replace('"', r'\"'), tr_blocks, translation_report),
		quiz_data.multiple, 
		quiz_data.shuffle,
		BBCodeUtils.get_quiz_id(quiz)
	])
	
	var quiz_content_lines := _get_lines(quiz_data.content)
	for i in quiz_content_lines.size():
		var line := quiz_content_lines[i]
		str_builder.append(_tr(line, tr_blocks, translation_report))
	
	for answer: String in quiz_data.answers:
		str_builder.append("[option%s]%s[/option]" % [" correct" if quiz_data.valid_answers.has(answer) else "", _tr(answer, tr_blocks, translation_report)])
	
	var explanation_lines := _get_lines(quiz_data.explanation)
	if explanation_lines.size() == 1:
		str_builder.append("[explanation]%s[/explanation]" % [_tr(explanation_lines[0], tr_blocks, translation_report)])
	else:
		str_builder.append("[explanation]")
		for i in explanation_lines.size():
			var line := explanation_lines[i]
			str_builder.append(_tr(line, tr_blocks, translation_report))
		str_builder.append("[/explanation]")
	
	str_builder.append_array(["[/quiz_choice]", ""])


static func _build_text(str_builder: Array[String], text_node: BBCodeParser.ParseNode, tr_blocks: Array[Dictionary], translation_report: Dictionary) -> void:
	var text := BBCodeUtils.get_paragraph_text(text_node)
	var lines := _get_lines(text)
	for i in lines.size():
		var line := lines[i]
		str_builder.append(_tr(SHARED.fix_glossary_entries(line, []), tr_blocks, translation_report))
	str_builder.append("")


static func _build_practice_tag(str_builder: Array[String], practice: BBCodeParser.ParseNode, tr_blocks: Array[Dictionary], translation_report: Dictionary) -> void:
	str_builder.append('[practice id="%s" title="%s"]' % [BBCodeUtils.get_practice_id(practice), _tr(BBCodeUtils.get_practice_title(practice).replace('"', r'\"'), tr_blocks, translation_report)])
	
	var description_lines := _get_lines(BBCodeUtils.get_practice_description(practice))
	if description_lines.size() == 1:
		str_builder.append("[description]%s[/description]" % [_tr(description_lines[0], tr_blocks, translation_report)])
	else:
		str_builder.append("[description]")
		for i in description_lines.size():
			var line := description_lines[i]
			str_builder.append(_tr(line, tr_blocks, translation_report))
		str_builder.append("[/description]")
	
	var goal_lines := _get_lines(BBCodeUtils.get_practice_goal(practice))
	if goal_lines.size() == 1:
		str_builder.append("[goal]%s[/goal]" % [_tr(goal_lines[0], tr_blocks, translation_report)])
	else:
		str_builder.append("[goal]")
		for i in goal_lines.size():
			var line := goal_lines[i]
			str_builder.append(_tr(line, tr_blocks, translation_report))
		str_builder.append("[/goal]")
	
	var code_lines := BBCodeUtils.get_practice_starting_code(practice).split("\n")
	str_builder.append("[starting_code]")
	for i in code_lines.size():
		var line := code_lines[i]
		str_builder.append(line)
	str_builder.append("[/starting_code]")
	
	var cursor := BBCodeUtils.get_practice_cursor(practice)
	str_builder.append('[cursor line="%s" column="%s"]' % [cursor.x, cursor.y])
	
	var validator := BBCodeUtils.get_practice_validator_path(practice)
	str_builder.append('[validator path="%s"]' % [validator])
	
	var slice_path := BBCodeUtils.get_practice_script_slice_path(practice)
	var slice_name := BBCodeUtils.get_practice_script_slice_name(practice)
	str_builder.append('[script_slice path="%s" name="%s"]' % [slice_path, slice_name])
	
	var hints := BBCodeUtils.get_practice_hints(practice)
	for hint in hints:
		str_builder.append("[hint]%s[/hint]" % [_tr(hint, tr_blocks, translation_report)])
	
	str_builder.append("[/practice]")


static func _tr(original: String, tr_blocks: Array[Dictionary], translation_report: Dictionary) -> String:
	if not original:
		return original
	var idx := tr_blocks.find_custom(func(block: Dictionary) -> bool:
		return block.id == original
	)
	translation_report.total += 1
	if idx > -1 and tr_blocks[idx].str:
		translation_report.count += 1
		return tr_blocks[idx].str
	return original


static func _get_lines(text_block: String) -> PackedStringArray:
	var raw_lines := text_block.split("\n", true)
	var ret := PackedStringArray()
	var current_line := ""
	var i := 0
	while i < raw_lines.size():
		ret.push_back(raw_lines[i])
		i += 1
	return ret
