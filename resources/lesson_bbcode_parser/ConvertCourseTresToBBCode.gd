extends Node


func _init() -> void:
	convert_all_lessons()


func convert_all_lessons() -> void:
	var course_path := "res://course"
	var lesson_files := find_lesson_files(course_path)
	print("Found %d lesson files to convert" % lesson_files.size())

	for lesson_path in lesson_files:
		print("Converting lesson: %s" % lesson_path)
		var lesson: Lesson = ResourceLoader.load(lesson_path)
		if lesson == null:
			printerr("Failed to load the lesson: %s" % lesson_path)
			continue

		var lesson_directory = lesson_path.get_base_dir()
		var output_path: String = lesson_path.replace(".tres", ".bbcode")
		var file := File.new()
		if file.open(output_path, File.WRITE) == OK:
			file.store_string(convert_lesson_to_bbcode(lesson, lesson_directory))
			file.close()
			print("Wrote lesson %s" % output_path)
		else:
			printerr("ERROR: Failed to write lesson %s" % output_path)


func find_lesson_files(base_path: String) -> Array:
	var results := []
	var directory := Directory.new()
	if directory.open(base_path) != OK:
		return results

	directory.list_dir_begin(true, true)
	var file_name := directory.get_next()
	while file_name != "":
		var full_path := base_path.plus_file(file_name)
		if directory.current_is_dir():
			results.append_array(find_lesson_files(full_path))
		elif file_name == "lesson.tres":
			results.append(full_path)
		file_name = directory.get_next()

	directory.list_dir_end()
	return results


func convert_lesson_to_bbcode(lesson: Lesson, lesson_directory: String) -> String:
	var output := "[lesson title=\"%s\"]\n" % escape_attribute(lesson.title)
	var pending_text := ""
	var pending_title := ""
	for block in lesson.content_blocks:
		if block is ContentBlock:
			var cb: ContentBlock = block

			if cb.type == ContentBlock.Type.NOTE:
				if pending_text.strip_edges() != "" or pending_title != "":
					output += format_text_block(pending_text, pending_title)
					pending_text = ""
					pending_title = ""
				output += write_note(cb)
				if cb.has_separator:
					output += "\n[separator]\n"
				continue

			if cb.title != "":
				if pending_text.strip_edges() != "" or pending_title != "":
					output += format_text_block(pending_text, pending_title)
					pending_text = ""
				pending_title = cb.title

			if cb.visual_element_path != "":
				if pending_text.strip_edges() != "" or pending_title != "":
					output += format_text_block(pending_text, pending_title)
					pending_text = ""
					pending_title = ""
				output += write_visual(cb, lesson_directory)
			elif cb.text != "":
				if pending_text != "":
					pending_text += "\n\n"
				pending_text += cb.text

			if cb.has_separator:
				if pending_text.strip_edges() != "" or pending_title != "":
					output += format_text_block(pending_text, pending_title)
					pending_text = ""
					pending_title = ""
				output += "\n[separator]\n"

		elif block is CodeBlock:
			if pending_text.strip_edges() != "" or pending_title != "":
				output += format_text_block(pending_text, pending_title)
				pending_text = ""
				pending_title = ""
			output += write_codeblock(block)

		elif block is QuizChoice:
			if pending_text.strip_edges() != "" or pending_title != "":
				output += format_text_block(pending_text, pending_title)
				pending_text = ""
				pending_title = ""
			output += write_quiz_choice(block)

		elif block is QuizInputField:
			if pending_text.strip_edges() != "" or pending_title != "":
				output += format_text_block(pending_text, pending_title)
				pending_text = ""
				pending_title = ""
			output += write_quiz_input(block)

	if pending_text.strip_edges() != "" or pending_title != "":
		output += format_text_block(pending_text, pending_title)
	for practice in lesson.practices:
		output += write_practice(practice, lesson_directory)
	output += "[/lesson]\n"
	return output


func format_text_block(text: String, title: String) -> String:
	var result := "\n"
	if title != "":
		result += "[title]%s[/title]\n\n" % title
	result += text.strip_edges() + "\n"
	return result


func write_note(cb: ContentBlock) -> String:
	var result := "\n"
	if cb.title != "":
		result += "[note title=\"%s\"]\n" % escape_attribute(cb.title)
	else:
		result += "[note]\n"
	result += cb.text.strip_edges() + "\n"
	result += "[/note]\n"
	return result


func write_visual(cb: ContentBlock, lesson_directory: String) -> String:
	var path := make_relative_path(cb.visual_element_path, lesson_directory)
	var result := "\n"
	if cb.reverse_blocks:
		result += "[visual path=\"%s\" reverse=\"true\"]\n" % path
	else:
		result += "[visual path=\"%s\"]\n" % path
	return result


func write_codeblock(block: CodeBlock) -> String:
	var result := "\n"
	if block.is_runnable:
		result += "[codeblock runnable=\"true\"]\n"
	else:
		result += "[codeblock]\n"
	result += block.code + "\n"
	result += "[/codeblock]\n"
	return result


func write_quiz_choice(quiz: QuizChoice) -> String:
	var result := "\n"

	var attrs := "question=\"%s\"" % escape_attribute(quiz.question)
	if quiz.is_multiple_choice:
		attrs += " multiple=\"true\""
	else:
		attrs += " multiple=\"false\""
	if quiz.do_shuffle_answers:
		attrs += " shuffle=\"true\""
	else:
		attrs += " shuffle=\"false\""

	result += "[quiz_choice %s]\n" % attrs

	if quiz.content_bbcode != "":
		result += "%s\n" % quiz.content_bbcode.strip_edges()

	for option in quiz.answer_options:
		var is_correct: bool = option in quiz.valid_answers
		if is_correct:
			result += "[option correct]%s[/option]\n" % option
		else:
			result += "[option]%s[/option]\n" % option

	if quiz.hint != "":
		result += "[hint]%s[/hint]\n" % quiz.hint.strip_edges()

	if quiz.explanation_bbcode != "":
		result += "[explanation]%s[/explanation]\n" % quiz.explanation_bbcode.strip_edges()

	result += "[/quiz_choice]\n"
	return result


func write_quiz_input(quiz: QuizInputField) -> String:
	var result := "\n"

	var answer_str := str(quiz.valid_answer)
	result += "[quiz_input question=\"%s\" answer=\"%s\"]\n" % [escape_attribute(quiz.question), escape_attribute(answer_str)]

	if quiz.hint != "":
		result += "[hint]%s[/hint]\n" % quiz.hint.strip_edges()

	if quiz.explanation_bbcode != "":
		result += "[explanation]%s[/explanation]\n" % quiz.explanation_bbcode.strip_edges()

	result += "[/quiz_input]\n"
	return result


func write_practice(practice: Practice, lesson_directory: String) -> String:
	var result := "\n"

	result += "[practice id=\"%s\" title=\"%s\"]\n" % [escape_attribute(practice.practice_id), escape_attribute(practice.title)]

	if practice.description != "":
		result += "[description]%s[/description]\n" % practice.description.strip_edges()

	if practice.goal != "":
		result += "[goal]\n"
		result += practice.goal.strip_edges() + "\n"
		result += "[/goal]\n"

	if practice.starting_code != "":
		result += "[starting_code]\n"
		result += practice.starting_code + "\n"
		result += "[/starting_code]\n"

	result += "[cursor line=\"%d\" column=\"%d\"]\n" % [practice.cursor_line, practice.cursor_column]

	if practice.validator_script_path != "":
		var path := make_relative_path(practice.validator_script_path, lesson_directory)
		result += "[validator path=\"%s\"]\n" % path

	if practice.script_slice_path != "":
		var path := make_relative_path(practice.script_slice_path, lesson_directory)
		if practice.slice_name != "":
			result += "[script_slice path=\"%s\" name=\"%s\"]\n" % [path, practice.slice_name]
		else:
			result += "[script_slice path=\"%s\"]\n" % path

	for hint in practice.hints:
		result += "[hint]%s[/hint]\n" % hint.strip_edges()

	if practice.documentation_references.size() > 0:
		var docs := PoolStringArray(practice.documentation_references).join(",")
		result += "[docs]%s[/docs]\n" % docs

	result += "[/practice]\n"
	return result


func make_relative_path(absolute_path: String, lesson_directory: String) -> String:
	if absolute_path == "":
		return ""
	if absolute_path.begins_with("res://"):
		var full_path := absolute_path
		var lesson_prefix := lesson_directory + "/"
		if full_path.begins_with(lesson_prefix):
			return full_path.substr(lesson_prefix.length())
		return absolute_path
	return absolute_path


func escape_attribute(text: String) -> String:
	return text.replace("\"", "\\\"")
