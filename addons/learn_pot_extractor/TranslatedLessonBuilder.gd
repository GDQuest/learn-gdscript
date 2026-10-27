@tool
extends RefCounted
## Renders translated lesson BBCode from parsed BBCode lessons in English and PO
## catalogs.

const SHARED := preload("Shared.gd")


## Parses and returns a parsed lesson root node from the given BBCode file path.
static func parse_lesson(lesson_bbcode_path: String) -> BBCodeParser.ParseNode:
	var parser := LessonBBCodeParser.new()
	var result := parser.parse_file(lesson_bbcode_path)
	if not result.is_success():
		push_error(
			"Failed to parse lesson '%s':\n%s" % [lesson_bbcode_path, result.get_all_messages()]
		)
		return null
	if result.root.children.is_empty():
		push_error("Failed to parse lesson '%s': no lesson root found." % [lesson_bbcode_path])
		return null
	return result.root.children[0]


## Builds one translated lesson. translation_report is passed around and updated by this function.
static func build_translated_lesson(
	lesson: BBCodeParser.ParseNode,
	tr_blocks: Dictionary,
	translation_report: Dictionary,
) -> String:
	var lesson_builder: Array[String] = []
	var translated_title := _tr(BBCodeUtils.get_lesson_title(lesson), tr_blocks, translation_report)
	lesson_builder.append_array(
		['[lesson title="%s"]' % [translated_title.replace('"', r'\"')], ""]
	)
	var practice_count := BBCodeUtils.get_lesson_practice_count(lesson)
	var practice_idx := 0
	for child: BBCodeParser.ParseNode in lesson.children:
		match child.tag:
			BBCodeParserData.Tag.TITLE:
				var title_text := _tr(
					BBCodeUtils.get_lesson_title_for_index(lesson, lesson.children.find(child)),
					tr_blocks,
					translation_report,
				)
				lesson_builder.append_array(["[title]%s[/title]" % [title_text], ""])
			BBCodeParserData.Tag.VISUAL:
				lesson_builder.append_array(
					['[visual path="%s"]' % [BBCodeUtils.get_visual_path(child)], ""]
				)
			BBCodeParserData.Tag.NOTE:
				var translated_title := _tr(
					BBCodeUtils.get_note_title(child),
					tr_blocks,
					translation_report,
				)
				lesson_builder.append('[note title="%s"]' % [translated_title.replace('"', r'\"')])
				var note_blocks := BBCodeUtils.get_content_blocks(child)
				for i in note_blocks.size():
					_append_content_block(
						lesson_builder,
						note_blocks[i],
						tr_blocks,
						translation_report,
					)
					if i < note_blocks.size() - 1:
						lesson_builder.append("")
				lesson_builder.append_array(["[/note]", ""])
			BBCodeParserData.Tag.QUIZ_CHOICE:
				_build_quiz_choice_tag(lesson_builder, child, tr_blocks, translation_report)
			BBCodeParserData.Tag.QUIZ_INPUT:
				pass
			BBCodeParserData.Tag.PARAGRAPH:
				var blocks := BBCodeUtils.get_content_blocks(child)
				for i in blocks.size():
					_append_content_block(lesson_builder, blocks[i], tr_blocks, translation_report)
					if i < blocks.size() - 1:
						lesson_builder.append("")
				lesson_builder.append("")
			BBCodeParserData.Tag.CODE_LISTING:
				_append_code_listing_lines(lesson_builder, child)
				lesson_builder.append("")
			BBCodeParserData.Tag.PRACTICE:
				_build_practice_tag(lesson_builder, child, tr_blocks, translation_report)
				if practice_idx < practice_count - 1:
					lesson_builder.append("")
				practice_idx += 1

	lesson_builder.append("[/lesson]")

	return "\n".join(lesson_builder)


## Appends a [code_listing] block without a trailing blank line. Use this inside
## other container tags like [explanation].
static func _append_code_listing_lines(
	str_builder: Array[String],
	node: BBCodeParser.ParseNode,
) -> void:
	str_builder.append("[code_listing]")
	for line: String in BBCodeUtils.get_code_listing_text(node).split("\n"):
		str_builder.append(line)
	str_builder.append("[/code_listing]")


static func _build_quiz_choice_tag(
	str_builder: Array[String],
	quiz: BBCodeParser.ParseNode,
	tr_blocks: Dictionary,
	translation_report: Dictionary,
) -> void:
	var quiz_data := BBCodeUtils.get_quiz_data(quiz)
	str_builder.append(
		'[quiz_choice question="%s" multiple="%s" shuffle="%s" en_id="%s"]'
		% [
			_tr(quiz_data.question, tr_blocks, translation_report).replace('"', r'\"'),
			quiz_data.multiple,
			quiz_data.shuffle,
			BBCodeUtils.get_quiz_id(quiz),
		]
	)

	var content_blocks := BBCodeUtils.get_content_blocks(quiz, true)
	for i in content_blocks.size():
		_append_content_block(str_builder, content_blocks[i], tr_blocks, translation_report)
		if i < content_blocks.size() - 1:
			str_builder.append("")

	for answer: String in quiz_data.answers:
		str_builder.append(
			"[option%s]%s[/option]"
			% [
				" correct" if quiz_data.valid_answers.has(answer) else "",
				_tr(answer, tr_blocks, translation_report),
			]
		)

	_build_tagged_content_block(
		"explanation",
		BBCodeUtils.get_child_content_blocks(quiz, BBCodeParserData.Tag.EXPLANATION),
		true,
		str_builder,
		tr_blocks,
		translation_report,
	)

	str_builder.append_array(["[/quiz_choice]", ""])


static func _append_content_block(
	str_builder: Array[String],
	block: Variant,
	tr_blocks: Dictionary,
	translation_report: Dictionary,
) -> void:
	if block is BBCodeParser.ParseNode:
		_append_code_listing_lines(str_builder, block)
	else:
		str_builder.append(
			_tr(
				SHARED.bbcode_rebuild_glossary_tags_from_url_tag(block, []),
				tr_blocks,
				translation_report,
			)
		)


## Builds a specific bbcode tag that wraps children (e.g. [description], [goal],
## [hint]...) from content blocks.
static func _build_tagged_content_block(
	tag_name: String,
	blocks: Array,
	separate_chunks: bool,
	str_builder: Array[String],
	tr_blocks: Dictionary,
	translation_report: Dictionary,
) -> void:
	if blocks.size() == 1 and blocks[0] is String:
		var text: String = blocks[0]
		var translated_text := _tr(
			SHARED.bbcode_rebuild_glossary_tags_from_url_tag(text, []),
			tr_blocks,
			translation_report,
		)
		str_builder.append("[%s]%s[/%s]" % [tag_name, translated_text, tag_name])
	else:
		str_builder.append("[%s]" % [tag_name])
		for i in blocks.size():
			_append_content_block(str_builder, blocks[i], tr_blocks, translation_report)
			if separate_chunks and i < blocks.size() - 1:
				str_builder.append("")
		str_builder.append("[/%s]" % [tag_name])


static func _build_practice_tag(
	str_builder: Array[String],
	practice: BBCodeParser.ParseNode,
	tr_blocks: Dictionary,
	translation_report: Dictionary,
) -> void:
	var translated_title := _tr(
		BBCodeUtils.get_practice_title(practice),
		tr_blocks,
		translation_report,
	)
	str_builder.append(
		'[practice id="%s" title="%s"]'
		% [BBCodeUtils.get_practice_id(practice), translated_title.replace('"', r'\"')]
	)

	_build_tagged_content_block(
		"description",
		BBCodeUtils.get_child_content_blocks(practice, BBCodeParserData.Tag.DESCRIPTION),
		false,
		str_builder,
		tr_blocks,
		translation_report,
	)
	_build_tagged_content_block(
		"goal",
		BBCodeUtils.get_child_content_blocks(practice, BBCodeParserData.Tag.GOAL),
		true,
		str_builder,
		tr_blocks,
		translation_report,
	)

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

	var hint_blocks := BBCodeUtils.get_practice_hint_blocks(practice)
	for blocks: Array in hint_blocks:
		_build_tagged_content_block(
			"hint",
			blocks,
			true,
			str_builder,
			tr_blocks,
			translation_report,
		)

	str_builder.append("[/practice]")


static func _tr(original: String, tr_blocks: Dictionary, translation_report: Dictionary) -> String:
	## Looks up an escaped source message in the locale index and records its translation status.
	if not original or not SHARED.is_translatable_course_message(original):
		return original
	var original_id: String = original.strip_edges().replace('"', r'\"').replace("\n", r"\n")
	var block: Dictionary = tr_blocks.get(original_id, { })
	translation_report.total += 1
	if not block.is_empty() and block.str and not block.comments.comments.has("fuzzy"):
		translation_report.count += 1
		return SHARED.normalize_glossary_tags(block.str.replace(r"\n", "\n").replace(r'\"', '"'))
	return original
