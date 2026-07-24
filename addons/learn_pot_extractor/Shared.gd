@tool
extends RefCounted


static var GLOSSARY_RE := RegEx.create_from_string(r"\[url=(?!http)([^\]]+)\]([^\[]+)\[\/url\]")
static var POT_PATTERN := RegEx.create_from_string(
	r'(?<comment>(?:#[^\n]+\n)+)?' +
	r'(?<ctxt>msgctxt "(?:\\.|[^"\\])*"\n)?' +
	r'(?<id>msgid (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))' +
	r'(?<str>msgstr (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))'
)

static var UNSURE_POT_PATTERN := RegEx.create_from_string(
	r'(?<id>#~ msgid (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))' +
	r'(?<str>#~ msgstr (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))'
)
static var GLOSSARY_TERM_RE := RegEx.create_from_string(r'\[glossary term=\\"([^\\]+)\\"\]')
static var TAG_RE := RegEx.create_from_string(r'\[[^\[]+\]([^\[]+)\[[^\[]+\]')
static var SPACE_NEWLINE_RE := RegEx.create_from_string(r'\s+\\n')
static var WHITESPACE_RE := RegEx.create_from_string(r'\s+')


static func get_unsure_tr_blocks(po_file: String, skip_header := true, out_header: Array = []) -> Array[Dictionary]:
	return build_tr_blocks(po_file, skip_header, out_header, UNSURE_POT_PATTERN, 3)


static func build_tr_blocks(po_file: String, skip_header := true, out_header: Array = [], target_regex := POT_PATTERN, prefix_offset := 0) -> Array[Dictionary]:
	var po_text := FileAccess.open(po_file, FileAccess.READ).get_as_text()

	var start_index := (po_text.find("\n\n")+2)
	var header := po_text.substr(0, start_index)
	start_index = start_index if skip_header else 0
	if out_header.size() < 1:
		out_header.resize(1)
	out_header[0] = header

	var tr_blocks: Array[Dictionary] = []
	tr_blocks.append_array(target_regex.search_all(po_text, start_index).map(func(block_match: RegExMatch) -> Dictionary:
		return {
			"comments": _parse_course_comment(block_match),
			"ctxt": block_match.get_string("ctxt").substr(9 + prefix_offset, block_match.get_string("ctxt").length()-(11 + prefix_offset)),
			"id": _parse_course_string(block_match, true, prefix_offset),
			"str": _parse_course_string(block_match, false, prefix_offset)
		}
	))
	var duplicate_blocks := []
	for block in tr_blocks:
		if block in duplicate_blocks:
			continue
		for other_block in tr_blocks:
			if other_block == block:
				continue
			if block.id == other_block.id:
				block.comments.sources.append_array(other_block.comments.sources)
				duplicate_blocks.push_back(other_block)
	for duplicate in duplicate_blocks:
		tr_blocks.erase(duplicate)
	return tr_blocks


static func write_from_tr_blocks(po_file: String, header: String, blocks: Array[Dictionary]) -> void:
	var lines := [header]

	for block in blocks:
		var append_fuzzy := false
		for comment in block.comments.comments:
			if comment == "fuzzy":
				append_fuzzy = true
			else:
				lines.append("#. %s" % [comment])
		for source in block.comments.sources:
			if source.lesson:
				lines.append("#: %s%s" % [source.lesson, ":%s" % [source.line_number] if not source.lesson.get_extension() in ["csv", "tscn"] else ""])

		if append_fuzzy:
			lines.append("#, fuzzy")

		if block.ctxt:
			lines.append('msgctxt "%s"' % [block.ctxt])

		lines.append_array(_get_text_for_block(block, "id"))
		lines.append_array(_get_text_for_block(block, "str"))
		lines.append("")

	var file := FileAccess.open(po_file, FileAccess.WRITE)
	file.store_string("\n".join(lines))


static func _get_text_for_block(block: Dictionary, suffix: String) -> PackedStringArray:
	if "\\n" in block[suffix]:
		var lines := ['msg%s ""' % suffix]
		var outbound_lines: PackedStringArray = block[suffix].split("\\n")
		for i in outbound_lines.size():
			lines.append('"%s%s"' % [outbound_lines[i], "\\n" if i < outbound_lines.size()-1 else ""])
		return lines
	return ['msg%s "%s"' % [suffix, block[suffix]]]


static func get_header(po_file: String) -> String:
	var po_text := FileAccess.open(po_file, FileAccess.READ).get_as_text()
	var start_index := po_text.find("\n\n")
	return po_text.substr(0, start_index)


static func _parse_course_comment(target: RegExMatch) -> Dictionary:
	var result := {"sources": [], "comments": []}

	var comments := target.get_string("comment").split("\n", false)
	for comment in comments:
		if comment.begins_with("#: "):
			var line_number_idx := comment.rfind(":")
			var has_line_number := comment.count(":") > 1
			var path := comment.substr(3, (line_number_idx - 3) if has_line_number else -1)
			var line_number := 0
			if has_line_number:
				line_number = comment.substr(line_number_idx+1).to_int()
			(result.sources as Array).push_back({"lesson": path, "line_number": line_number})
		else:
			(result.comments as Array).push_back(comment.substr(2 if comment.begins_with("# ") else 3))

	return result


static func _parse_course_string(target: RegExMatch, is_id: bool, prefix_offset := 0) -> String:
	var id := target.get_string("id" if is_id else "str")

	var result := ""

	if id.begins_with('msg%s ""\n' % ["id" if is_id else "str"]):
		var lines := id.split("\n").slice(1)
		for line in lines:
			if not line.ends_with('\n"'):
				result += line.substr(1, line.length()-(2 + prefix_offset))
			else:
				result += line.substr(1, line.length()-(2 + prefix_offset)) + "\n"
	else:
		result = id.substr(7 + (0 if is_id else 1) + prefix_offset, id.length()-(9 + (0 if is_id else 1) + prefix_offset))

	return result.strip_edges()


# Converts the "rendered" `[url=term]display text[/url]` (produced by
# BBCodeUtils for glossary entries) back into `[glossary term="term"]display
# text[/glossary]`, which we need to apply translations.
static func bbcode_rebuild_glossary_tags_from_url_tag(raw_string: String, out_did_find: Array) -> String:
	var finds := GLOSSARY_RE.search_all(raw_string)
	out_did_find.resize(1)
	out_did_find[0] = not finds.is_empty()

	for i in range(finds.size()-1, -1, -1):
		var find: RegExMatch = finds[i]
		var term := find.get_string(1)
		var display_text := find.get_string(2)
		raw_string = raw_string.substr(0, find.get_start()) + '[glossary term="%s"]%s[/glossary]' % [term, display_text] + raw_string.substr(find.get_end())
	return raw_string
