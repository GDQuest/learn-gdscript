@tool
extends RefCounted
## Shared utilities for parsing PO files, for making lookups, and for our
## glossary tags.


static var GLOSSARY_RE := RegEx.create_from_string(r"\[url=(?!http)([^\]]+)\]([^\[]+)\[\/url\]")
static var POT_PATTERN := RegEx.create_from_string(
	r'(?<comment>(?:#[^\n]+\n)+)?' +
	r'(?<ctxt>msgctxt "(?:\\.|[^"\\])*"\n)?' +
	r'(?<id>msgid (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))' +
	r'(?<str>msgstr (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))'
)

static var GLOSSARY_TERM_RE := RegEx.create_from_string(r'\[glossary term=\\"([^\\]+)\\"\]')
static var GLOSSARY_TAG_RE := RegEx.create_from_string(r'\[glossary\s+term=(?:"([^"]+)"|([^\s\]]+))\]')
static var TAG_RE := RegEx.create_from_string(r'\[[^\[]+\]([^\[]+)\[[^\[]+\]')
static var SPACE_NEWLINE_RE := RegEx.create_from_string(r'\s+\\n')
static var WHITESPACE_RE := RegEx.create_from_string(r'\s+')


## Parses a PO file and merges repeated message IDs while retaining all source references.
static func build_tr_blocks(po_file: String) -> Array[Dictionary]:
	var po_text := FileAccess.open(po_file, FileAccess.READ).get_as_text()

	var start_index := (po_text.find("\n\n")+2)

	var tr_blocks: Array[Dictionary] = []
	var block_indices_by_id := {}
	for block_match: RegExMatch in POT_PATTERN.search_all(po_text, start_index):
		var block := {
			"comments": _parse_course_comment(block_match),
			"ctxt": block_match.get_string("ctxt").substr(9, block_match.get_string("ctxt").length() - 11),
			"id": _parse_course_string(block_match, true),
			"str": _parse_course_string(block_match, false)
		}
		if block_indices_by_id.has(block.id):
			var existing_index: int = block_indices_by_id[block.id]
			var existing_block: Dictionary = tr_blocks[existing_index]
			existing_block.comments.sources.append_array(block.comments.sources)
			tr_blocks[existing_index] = existing_block
			continue
		block_indices_by_id[block.id] = tr_blocks.size()
		tr_blocks.append(block)
	return tr_blocks


## Indexes parsed PO blocks by message ID for constant-time lesson translation lookup.
static func build_tr_lookup(tr_blocks: Array[Dictionary]) -> Dictionary:
	var lookup := {}
	for block in tr_blocks:
		lookup[block.id] = block
	return lookup


## Returns true if the message is a valid course message that can be translated. We skip pure numbers and code blocks.
static func is_translatable_course_message(message: String) -> bool:
	if message.is_valid_int() or message.is_valid_float():
		return false
	if message.begins_with("[code]") and message.find("[/code]", 6) == message.length() - 7:
		return false
	return true


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


static func _parse_course_string(target: RegExMatch, is_id: bool) -> String:
	var id := target.get_string("id" if is_id else "str")

	var result := ""

	if id.begins_with('msg%s ""\n' % ["id" if is_id else "str"]):
		var lines := id.split("\n").slice(1)
		for line in lines:
			if not line.ends_with('\n"'):
				result += line.substr(1, line.length() - 2)
			else:
				result += line.substr(1, line.length() - 2) + "\n"
	else:
		result = id.substr(7 + (0 if is_id else 1), id.length() - (9 + (0 if is_id else 1)))

	return result.replace(r"\t", "\t").strip_edges()


# Converts the "rendered" `[url=term]display text[/url]` (produced by
# BBCodeUtils for glossary entries) back into `[glossary term="term"]display
# text[/glossary]`, which we need to apply translations.
static func bbcode_rebuild_glossary_tags_from_url_tag(raw_string: String, out_did_find: Array) -> String:
	## Restores glossary tags before lookup because lesson parsing renders them as URL tags.
	var finds := GLOSSARY_RE.search_all(raw_string)
	out_did_find.resize(1)
	out_did_find[0] = not finds.is_empty()

	for i in range(finds.size()-1, -1, -1):
		var find: RegExMatch = finds[i]
		var term := find.get_string(1)
		var display_text := find.get_string(2)
		raw_string = raw_string.substr(0, find.get_start()) + '[glossary term="%s"]%s[/glossary]' % [term, display_text] + raw_string.substr(find.get_end())
	return raw_string


## Ensures translated glossary tags always have a quoted attribute.
static func normalize_glossary_tags(raw_string: String) -> String:
	var finds := GLOSSARY_TAG_RE.search_all(raw_string)
	for i in range(finds.size() - 1, -1, -1):
		var find: RegExMatch = finds[i]
		var term := find.get_string(1) if not find.get_string(1).is_empty() else find.get_string(2)
		raw_string = raw_string.substr(0, find.get_start()) + '[glossary term="%s"]' % term + raw_string.substr(find.get_end())
	return raw_string
