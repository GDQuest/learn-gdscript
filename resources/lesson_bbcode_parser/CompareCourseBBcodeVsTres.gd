# This script compares the new BB code files generated against the source TRES
# lessons. It's mostly a helper to find edge cases in the parser. Then it's a
# bit limited because the new BB code does not have the same notion of content
# blocks compared to the original as we want to clean it up and it doesn't give
# you a one-to-one comparison. This really naively compares blocks one by one.
# It's a temporary script just to help surface some issues early in the
# migration step.
extends Node


func _init() -> void:
	verify_all_lessons()


func verify_all_lessons() -> void:
	var course_path := "res://course"
	var lesson_dirs := find_lesson_directories(course_path)

	print("Found %d lesson directories to verify" % lesson_dirs.size())

	var total_errors := 0

	for lesson_dir in lesson_dirs:
		var tres_path: String = lesson_dir.plus_file("lesson.tres")
		var bbcode_path: String = lesson_dir.plus_file("lesson.bbcode")

		if not file_exists(tres_path):
			print("SKIP: No lesson.tres in %s" % lesson_dir)
			continue

		if not file_exists(bbcode_path):
			print("SKIP: No lesson.bbcode in %s" % lesson_dir)
			continue

		var errors := verify_lesson(tres_path, bbcode_path, lesson_dir)
		total_errors += errors.size()

		if errors.empty():
			print("OK: %s" % lesson_dir)
		else:
			print("ERRORS in %s:" % lesson_dir)
			for error in errors:
				print("  - %s" % error)

	print("")
	print("Verification complete. Total errors: %d" % total_errors)


func find_lesson_directories(base_path: String) -> Array:
	var results := []
	var dir := Directory.new()

	if dir.open(base_path) != OK:
		return results

	dir.list_dir_begin(true, true)
	var file_name := dir.get_next()

	while file_name != "":
		var full_path := base_path.plus_file(file_name)

		if dir.current_is_dir():
			if file_name.begins_with("lesson-"):
				results.append(full_path)
			results.append_array(find_lesson_directories(full_path))

		file_name = dir.get_next()

	dir.list_dir_end()
	return results


func file_exists(path: String) -> bool:
	var file := File.new()
	return file.file_exists(path)


func verify_lesson(tres_path: String, bbcode_path: String, lesson_dir: String) -> Array:
	var errors := []

	var original: Lesson = ResourceLoader.load(tres_path)
	if original == null:
		errors.append("Failed to load original lesson: %s" % tres_path)
		return errors

	var file := File.new()
	if file.open(bbcode_path, File.READ) != OK:
		errors.append("Failed to open bbcode file: %s" % bbcode_path)
		return errors

	var bbcode_content := file.get_as_text()
	file.close()

	var parser := BBCodeParser.new()
	var result := BBCodeParser.ParseResult.new()
	var root := parser.parse(bbcode_content, result)

	if not result.errors.empty():
		for parse_error in result.errors:
			errors.append("Parse error: %s" % parse_error.format())
		return errors

	var builder := BBCodeResourceBuilder.new()
	var parsed: Lesson = builder.build_lesson(root, lesson_dir)

	if parsed == null:
		errors.append("Failed to build lesson from parsed BBCode")
		return errors

	errors.append_array(compare_lessons(original, parsed, lesson_dir))

	return errors


func compare_lessons(original: Lesson, parsed: Lesson, lesson_dir: String) -> Array:
	var errors := []

	if original.title != parsed.title:
		errors.append("Title mismatch: '%s' vs '%s'" % [original.title, parsed.title])

	var original_blocks := normalize_content_blocks(original.content_blocks)
	var parsed_blocks := normalize_content_blocks(parsed.content_blocks)

	if original_blocks.size() != parsed_blocks.size():
		errors.append("Content block count mismatch: %d vs %d" % [original_blocks.size(), parsed_blocks.size()])

	var block_count := min(original_blocks.size(), parsed_blocks.size())
	for i in range(block_count):
		var orig_block = original_blocks[i]
		var parsed_block = parsed_blocks[i]
		var block_errors := compare_content_block(orig_block, parsed_block, i, lesson_dir)
		errors.append_array(block_errors)

	if original.practices.size() != parsed.practices.size():
		errors.append("Practice count mismatch: %d vs %d" % [original.practices.size(), parsed.practices.size()])

	var practice_count := min(original.practices.size(), parsed.practices.size())
	for i in range(practice_count):
		var orig_practice: Practice = original.practices[i]
		var parsed_practice: Practice = parsed.practices[i]
		var practice_errors := compare_practice(orig_practice, parsed_practice, i, lesson_dir)
		errors.append_array(practice_errors)

	return errors


func normalize_content_blocks(blocks: Array) -> Array:
	var normalized := []

	for block in blocks:
		if block is ContentBlock:
			var cb: ContentBlock = block

			if cb.text == "" and cb.visual_element_path == "" and cb.title == "" and not cb.has_separator:
				continue

			if cb.has_separator:
				var content_block := ContentBlock.new()
				content_block.content_id = cb.content_id
				content_block.title = cb.title
				content_block.type = cb.type
				content_block.text = cb.text
				content_block.visual_element_path = cb.visual_element_path
				content_block.reverse_blocks = cb.reverse_blocks
				content_block.has_separator = false

				if content_block.text != "" or content_block.visual_element_path != "" or content_block.title != "" or content_block.type == ContentBlock.Type.NOTE:
					normalized.append(content_block)

				var separator_block := ContentBlock.new()
				separator_block.has_separator = true
				normalized.append(separator_block)
			else:
				normalized.append(block)
		else:
			normalized.append(block)

	return normalized


func compare_content_block(orig, parsed, index: int, lesson_dir: String) -> Array:
	var errors := []
	var prefix := "Block[%d]" % index

	if orig is ContentBlock and parsed is ContentBlock:
		var o: ContentBlock = orig
		var p: ContentBlock = parsed

		if o.has_separator and p.has_separator:
			return errors

		if o.type != p.type:
			errors.append("%s type mismatch: %d vs %d" % [prefix, o.type, p.type])

		if normalize_text(o.text) != normalize_text(p.text):
			errors.append("%s text mismatch:\n    Original: '%s'\n    Parsed:   '%s'" % [prefix, truncate(o.text, 100), truncate(p.text, 100)])

		if o.title != p.title:
			errors.append("%s title mismatch: '%s' vs '%s'" % [prefix, o.title, p.title])

		var o_visual := normalize_path(o.visual_element_path, lesson_dir)
		var p_visual := normalize_path(p.visual_element_path, lesson_dir)
		if o_visual != p_visual:
			errors.append("%s visual_element_path mismatch: '%s' vs '%s'" % [prefix, o_visual, p_visual])

		if o.has_separator != p.has_separator:
			errors.append("%s has_separator mismatch: %s vs %s" % [prefix, o.has_separator, p.has_separator])

		if o.reverse_blocks != p.reverse_blocks:
			errors.append("%s reverse_blocks mismatch: %s vs %s" % [prefix, o.reverse_blocks, p.reverse_blocks])

	elif orig is QuizChoice and parsed is QuizChoice:
		var o: QuizChoice = orig
		var p: QuizChoice = parsed

		if o.question != p.question:
			errors.append("%s quiz question mismatch: '%s' vs '%s'" % [prefix, o.question, p.question])

		if o.is_multiple_choice != p.is_multiple_choice:
			errors.append("%s is_multiple_choice mismatch: %s vs %s" % [prefix, o.is_multiple_choice, p.is_multiple_choice])

		if o.do_shuffle_answers != p.do_shuffle_answers:
			errors.append("%s do_shuffle_answers mismatch: %s vs %s" % [prefix, o.do_shuffle_answers, p.do_shuffle_answers])

		if o.answer_options.size() != p.answer_options.size():
			errors.append("%s answer_options count mismatch: %d vs %d" % [prefix, o.answer_options.size(), p.answer_options.size()])
		else:
			for j in range(o.answer_options.size()):
				if o.answer_options[j].strip_edges() != p.answer_options[j].strip_edges():
					errors.append("%s answer_options[%d] mismatch: '%s' vs '%s'" % [prefix, j, o.answer_options[j], p.answer_options[j]])

		if o.valid_answers.size() != p.valid_answers.size():
			errors.append("%s valid_answers count mismatch: %d vs %d" % [prefix, o.valid_answers.size(), p.valid_answers.size()])
		else:
			for j in range(o.valid_answers.size()):
				if o.valid_answers[j].strip_edges() != p.valid_answers[j].strip_edges():
					errors.append("%s valid_answers[%d] mismatch: '%s' vs '%s'" % [prefix, j, o.valid_answers[j], p.valid_answers[j]])

		if normalize_text(o.hint) != normalize_text(p.hint):
			errors.append("%s hint mismatch: '%s' vs '%s'" % [prefix, truncate(o.hint, 80), truncate(p.hint, 80)])

		if normalize_text(o.explanation_bbcode) != normalize_text(p.explanation_bbcode):
			errors.append("%s explanation mismatch: '%s' vs '%s'" % [prefix, truncate(o.explanation_bbcode, 80), truncate(p.explanation_bbcode, 80)])

	elif orig is QuizInputField and parsed is QuizInputField:
		var o: QuizInputField = orig
		var p: QuizInputField = parsed

		if o.question != p.question:
			errors.append("%s quiz_input question mismatch: '%s' vs '%s'" % [prefix, o.question, p.question])

		if str(o.valid_answer) != str(p.valid_answer):
			errors.append("%s valid_answer mismatch: '%s' vs '%s'" % [prefix, str(o.valid_answer), str(p.valid_answer)])

		if normalize_text(o.hint) != normalize_text(p.hint):
			errors.append("%s hint mismatch: '%s' vs '%s'" % [prefix, truncate(o.hint, 80), truncate(p.hint, 80)])

		if normalize_text(o.explanation_bbcode) != normalize_text(p.explanation_bbcode):
			errors.append("%s explanation mismatch: '%s' vs '%s'" % [prefix, truncate(o.explanation_bbcode, 80), truncate(p.explanation_bbcode, 80)])

	elif orig is CodeBlock and parsed is CodeBlock:
		var o: CodeBlock = orig
		var p: CodeBlock = parsed

		if o.code != p.code:
			errors.append("%s code mismatch: '%s' vs '%s'" % [prefix, truncate(o.code, 100), truncate(p.code, 100)])

		if o.is_runnable != p.is_runnable:
			errors.append("%s is_runnable mismatch: %s vs %s" % [prefix, o.is_runnable, p.is_runnable])

	else:
		errors.append("%s type mismatch: %s vs %s" % [prefix, orig.get_class(), parsed.get_class()])

	return errors


func compare_practice(orig: Practice, parsed: Practice, index: int, lesson_dir: String) -> Array:
	var errors := []
	var prefix := "Practice[%d]" % index

	if orig.practice_id != parsed.practice_id:
		errors.append("%s practice_id mismatch: '%s' vs '%s'" % [prefix, orig.practice_id, parsed.practice_id])

	if orig.title != parsed.title:
		errors.append("%s title mismatch: '%s' vs '%s'" % [prefix, orig.title, parsed.title])

	if normalize_text(orig.description) != normalize_text(parsed.description):
		errors.append("%s description mismatch: '%s' vs '%s'" % [prefix, truncate(orig.description, 80), truncate(parsed.description, 80)])

	if normalize_text(orig.goal) != normalize_text(parsed.goal):
		errors.append("%s goal mismatch:\n    Original: '%s'\n    Parsed:   '%s'" % [prefix, truncate(orig.goal, 150), truncate(parsed.goal, 150)])

	if orig.starting_code != parsed.starting_code:
		errors.append("%s starting_code mismatch:\n    Original: '%s'\n    Parsed:   '%s'" % [prefix, truncate(orig.starting_code, 150), truncate(parsed.starting_code, 150)])

	var expected_cursor_line := orig.cursor_line
	var expected_cursor_column := orig.cursor_column
	if orig.cursor_line == 0 and orig.cursor_column == 0 and orig.starting_code != "":
		var lines := orig.starting_code.split("\n")
		expected_cursor_line = lines.size()
		if lines.size() > 0:
			expected_cursor_column = lines[lines.size() - 1].length()

	if expected_cursor_line != parsed.cursor_line:
		errors.append("%s cursor_line mismatch: %d vs %d" % [prefix, expected_cursor_line, parsed.cursor_line])

	if expected_cursor_column != parsed.cursor_column:
		errors.append("%s cursor_column mismatch: %d vs %d" % [prefix, expected_cursor_column, parsed.cursor_column])

	var o_validator := normalize_path(orig.validator_script_path, lesson_dir)
	var p_validator := normalize_path(parsed.validator_script_path, lesson_dir)
	if o_validator != p_validator:
		errors.append("%s validator_script_path mismatch: '%s' vs '%s'" % [prefix, o_validator, p_validator])

	var o_slice := normalize_path(orig.script_slice_path, lesson_dir)
	var p_slice := normalize_path(parsed.script_slice_path, lesson_dir)
	if o_slice != p_slice:
		errors.append("%s script_slice_path mismatch: '%s' vs '%s'" % [prefix, o_slice, p_slice])

	if orig.slice_name != parsed.slice_name:
		errors.append("%s slice_name mismatch: '%s' vs '%s'" % [prefix, orig.slice_name, parsed.slice_name])

	if orig.hints.size() != parsed.hints.size():
		errors.append("%s hints count mismatch: %d vs %d" % [prefix, orig.hints.size(), parsed.hints.size()])
	else:
		for j in range(orig.hints.size()):
			if normalize_text(orig.hints[j]) != normalize_text(parsed.hints[j]):
				errors.append("%s hints[%d] mismatch: '%s' vs '%s'" % [prefix, j, truncate(orig.hints[j], 80), truncate(parsed.hints[j], 80)])

	var orig_docs := Array(orig.documentation_references)
	var parsed_docs := Array(parsed.documentation_references)
	orig_docs.sort()
	parsed_docs.sort()
	if orig_docs != parsed_docs:
		errors.append("%s documentation_references mismatch: %s vs %s" % [prefix, orig_docs, parsed_docs])

	return errors


func normalize_text(text: String) -> String:
	var result := text.strip_edges()
	var lines := result.split("\n")
	var cleaned := []
	var was_blank := false
	for line in lines:
		var stripped: String = line.strip_edges()
		var is_blank: bool = stripped == ""
		if is_blank and was_blank:
			continue
		cleaned.append(stripped)
		was_blank = is_blank
	return PoolStringArray(cleaned).join("\n")


func normalize_path(path: String, lesson_dir: String) -> String:
	if path == "":
		return ""

	if path.begins_with("res://"):
		var lesson_prefix := lesson_dir + "/"
		if path.begins_with(lesson_prefix):
			return path.substr(lesson_prefix.length())

	return path


func truncate(text: String, max_len: int) -> String:
	var single_line := text.replace("\n", "\\n")
	if single_line.length() > max_len:
		return single_line.substr(0, max_len) + "..."
	return single_line
