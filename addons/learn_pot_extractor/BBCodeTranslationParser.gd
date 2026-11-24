@tool
extends EditorTranslationParserPlugin
## Translation parser plugin that extracts localizable strings and translator
## context from lessons.

const SHARED := preload("Shared.gd")


## Parses lesson BBCode into Godot's translation entry format keeping metadata
## about the source lines.
func _parse_file(path: String) -> Array[PackedStringArray]:
	var parser := LessonBBCodeParser.new()
	var result := parser.parse_file(path)
	if not result.is_success():
		push_error("Failed to parse BBCode for '%s':\n%s" % [path, result.get_all_messages()])
		return []
	var lesson_root: BBCodeParser.ParseNode = result.root.children[0]

	# msgid, msgctxt, msgid_plural, comment, source_line
	var po_data: Array[PackedStringArray]
	var previous_comments := []
	po_data.append(PackedStringArray([BBCodeUtils.get_lesson_title(lesson_root), "", "", _build_comment(lesson_root, "Lesson header"), lesson_root.line_number]))

	for current in lesson_root.children:
		if typeof(current) == TYPE_OBJECT and "tag" in current:
			match current.tag:
				BBCodeParserData.Tag.PARAGRAPH:
					_append_content_blocks(
						po_data,
						BBCodeUtils.get_content_blocks(current),
						"\n".join(previous_comments),
						"",
						current.line_number,
						true,
					)
					previous_comments.clear()
				BBCodeParserData.Tag.TITLE:
					po_data.append(PackedStringArray([BBCodeUtils.get_paragraph_text(current), "", "", _build_comment(current, "Heading"), current.line_number]))
				BBCodeParserData.Tag.QUIZ_CHOICE, BBCodeParserData.Tag.QUIZ_INPUT:
					var data := BBCodeUtils.get_quiz_data(current)
					po_data.append(PackedStringArray([data.question, "", "", _build_text_comment(data.question_tr, "Quiz question"), current.line_number]))

					_append_content_blocks(
						po_data,
						BBCodeUtils.get_content_blocks(current, true),
						data.content_tr,
						"Quiz content",
						current.line_number,
						false,
						"Quiz",
					)
					_append_content_blocks(
						po_data,
						BBCodeUtils.get_child_content_blocks(current, BBCodeParserData.Tag.EXPLANATION),
						data.explanation_tr,
						"Quiz explanation",
						current.line_number,
						false,
						"Quiz",
					)

					for i in data.answers.size():
						po_data.append(PackedStringArray([data.answers[i], "", "", _build_text_comment(data.answers_tr[i], "Quiz answer"), current.line_number]))
				BBCodeParserData.Tag.NOTE:
					var title := BBCodeUtils.get_note_title(current)
					po_data.append(PackedStringArray([title, "", "", _build_comment(current, "Note title"), current.line_number]))
					var comments: Array = current.children.filter(func(n) -> bool: return n is BBCodeParser.ParseNode and n.tag == BBCodeParserData.Tag.TR).map(func(n: BBCodeParser.ParseNode) -> String: return n.attributes.get("note", ""))
					_append_content_blocks(
						po_data,
						BBCodeUtils.get_content_blocks(current),
						"\n".join(comments),
						"Note content",
						current.line_number + 1,
						true,
						"Note content",
					)
					previous_comments.clear()
				BBCodeParserData.Tag.PRACTICE:
					var title := BBCodeUtils.get_practice_title(current)
					po_data.append(PackedStringArray([title, "", "", _build_comment(current, "Practice title"), current.line_number]))

					var goal_node: BBCodeParser.ParseNode = current.children.filter(func(n) -> bool: return n.tag == BBCodeParserData.Tag.GOAL).front()
					_append_content_blocks(
						po_data,
						BBCodeUtils.get_child_content_blocks(current, BBCodeParserData.Tag.GOAL),
						goal_node.attributes.get("tr", "") if goal_node else "",
						"Practice goal",
						current.line_number,
						false,
						"Practice goal",
					)

					var description_node: BBCodeParser.ParseNode = current.children.filter(func(n) -> bool: return n.tag == BBCodeParserData.Tag.DESCRIPTION).front()
					_append_content_blocks(
						po_data,
						BBCodeUtils.get_child_content_blocks(current, BBCodeParserData.Tag.DESCRIPTION),
						description_node.attributes.get("tr", "") if description_node else "",
						"Practice description",
						current.line_number,
						true,
						"Practice description",
					)

					var hint_blocks := BBCodeUtils.get_practice_hint_blocks(current)
					var hint_nodes: Array = current.children.filter(func(n) -> bool: return n.tag == BBCodeParserData.Tag.HINT)
					for i in hint_blocks.size():
						_append_content_blocks(
							po_data,
							hint_blocks[i],
							hint_nodes[i].attributes.get("tr", ""),
							"Practice hint",
							current.line_number,
							false,
							"Practice hint",
						)
				BBCodeParserData.Tag.TR:
					previous_comments.append(current.attributes.get("note", ""))

	for i in range(po_data.size() - 1, -1, -1):
		var id := po_data[i][0]
		if not SHARED.is_translatable_course_message(id):
			po_data.remove_at(i)

	return po_data


func _append_content_blocks(
	# Each packed string array in there has 5 fields: msgid, msgctxt, msgid_plural, comment, source_line
	po_data: Array[PackedStringArray],
	blocks: Array,
	context_comment: String,
	base_comment: String,
	base_line_number: int,
	increment_line_number := false,
	glossary_prefix := "",
) -> void:
	var glossary_results := []
	var text_index := 0
	for block: Variant in blocks:
		# The blocks array contains strings and some raw BBCode AST nodes. These
		# raw nodes include e.g. the [code_listing] tags which we don't want to
		# translate.
		if block is BBCodeParser.ParseNode:
			continue
		var line := SHARED.bbcode_rebuild_glossary_tags_from_url_tag(block, glossary_results)
		var glossary_comment := 'The "term" in [glossary term="<term>"] should NOT be translated here'
		var effective_base_comment := base_comment
		if glossary_results[0]:
			effective_base_comment = (
				"%s\n%s" % [glossary_prefix, glossary_comment]
				if not glossary_prefix.is_empty()
				else glossary_comment
			)
		var line_number := base_line_number + (text_index if increment_line_number else 0)
		po_data.append(PackedStringArray([line, "", "", _build_text_comment(context_comment, effective_base_comment), line_number]))
		text_index += 1


func _build_comment(node: BBCodeParser.ParseNode, base_comment := "") -> String:
	return _build_text_comment(node.attributes.get("tr", ""), base_comment)


func _build_text_comment(context_comment: String, base_comment := "") -> String:
	var comments := []
	if base_comment:
		comments.append(base_comment)
	if context_comment:
		comments.append(context_comment)
	return "\n".join(comments)


func _get_recognized_extensions() -> PackedStringArray:
	return ["bbcode"]
