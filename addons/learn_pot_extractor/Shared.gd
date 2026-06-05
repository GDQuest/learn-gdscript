@tool
extends RefCounted


static var GLOSSARY_RE := RegEx.create_from_string(r"\[url=(?!http)[^\]]+\]([^\[]+)\[\/url\]")
static var POT_PATTERN := RegEx.create_from_string(
	r'(?<comment>(?:#[^\n]+\n)+)?' +
	r'(?<ctxt>msgctxt "(?:\\.|[^"\\])*"\n)?' +
	r'(?<id>msgid (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))' +
	r'(?<str>msgstr (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))'
)
static var GLOSSARY_TERM_RE := RegEx.create_from_string(r'\[glossary term=\\"([^\\]+)\\"\]')
static var TAG_RE := RegEx.create_from_string(r'\[[^\[]+\]([^\[]+)\[[^\[]+\]')
static var SPACE_NEWLINE_RE := RegEx.create_from_string(r'\s+\\n')
static var WHITESPACE_RE := RegEx.create_from_string(r'\s+')


static func build_tr_blocks(po_file: String, skip_header := true, out_header: Array = []) -> Array[Dictionary]:
	var po_text := FileAccess.open(po_file, FileAccess.READ).get_as_text()
	
	var start_index := (po_text.find("\n\n")+2)
	var header := po_text.substr(0, start_index)
	start_index = start_index if skip_header else 0
	if out_header.size() < 1:
		out_header.resize(1)
	out_header[0] = header
	
	var tr_blocks: Array[Dictionary] = []
	tr_blocks.append_array(POT_PATTERN.search_all(po_text, start_index).map(func(block_match: RegExMatch) -> Dictionary:
		return {
			"comments": _parse_course_comment(block_match),
			"ctxt": block_match.get_string("ctxt").substr(9, block_match.get_string("ctxt").length()-11),
			"id": _parse_course_string(block_match, true),
			"normalized_id": normalize(_parse_course_string(block_match, true)),
			"str": _parse_course_string(block_match, false)
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
		for comment in block.comments.comments:
			if comment == "fuzzy":
				lines.append("#, fuzzy")
			else:
				lines.append("#. %s" % [comment])
		for source in block.comments.sources:
			lines.append("#: %s:%s" % [source.lesson, source.line_number])
		
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
		lines.append_array(Array(block[suffix].split("\\n")).map(func(line: String) -> String: return '"%s\\n"' % [line]))
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
		if comment.begins_with("#: course/"):
			var line_number_idx := comment.rfind(":")
			var path := comment.substr(3, line_number_idx - 3)
			var line_number := comment.substr(line_number_idx+1).to_int()
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
				result += line.substr(1, line.length()-2)
			else:
				result += line.substr(1, line.length()-2) + "\n"
	else:
		result = id.substr(7 + (0 if is_id else 1), id.length()-(9 + (0 if is_id else 1)))
	
	return result


static func fix_glossary_entries(raw_string: String, out_did_find: Array) -> String:
	var finds := GLOSSARY_RE.search_all(raw_string)
	out_did_find.resize(1)
	out_did_find[0] = not finds.is_empty()
	
	for i in range(finds.size()-1, -1, -1):
		var find: RegExMatch = finds[i]
		raw_string = raw_string.substr(0, find.get_start()) + '[glossary term="%s"]' % [find.get_string(1)] + raw_string.substr(find.get_end())
	return raw_string


static func get_similarity(a: String, b: String, normalize := true) -> float:
	if normalize:
		a = normalize(a)
		b = normalize(b)
	
	var lev := levenshtein(a, b)
	return 1.0 - float(lev)/maxf(a.length(), b.length())


static func normalize(s: String) -> String:
	s = s.to_lower()
	
	s = GLOSSARY_TERM_RE.sub(s, "$1", true)
	s = TAG_RE.sub(s, "$1", true)
	s = SPACE_NEWLINE_RE.sub(s, "\\n", true)
	s = WHITESPACE_RE.sub(s.strip_edges(), " ", true)
	
	return s


static func get_token_similarity(a: String, b: String, normalize: bool = true) -> float:
	if normalize:
		a = normalize(a)
		b = normalize(b)
	
	var set_a := {}
	for word in a.split(" ", false):
		set_a[word] = true
	
	var set_b := {}
	for word in b.split(" ", false):
		set_b[word] = true
	
	var overlap := 0
	for word in set_a:
		if set_b.has(word):
			overlap += 1
			
	return float(overlap) / maxf(set_a.size(), set_b.size())


static var lev_prev := PackedInt32Array()
static var lev_curr := PackedInt32Array()

static func levenshtein(a: String, b: String) -> int:
	if a.length() < b.length():
		var tmp := a
		a = b
		b = tmp

	var a_len := a.length()
	var b_len := b.length()

	lev_prev.resize(b_len + 1)
	lev_curr.resize(b_len + 1)

	# init first row
	for j in range(b_len + 1):
		lev_prev[j] = j

	for i in range(1, a_len + 1):
		lev_curr[0] = i

		for j in range(1, b_len + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1

			lev_curr[j] = min(
				lev_prev[j] + 1,        # deletion
				lev_curr[j - 1] + 1,    # insertion
				lev_prev[j - 1] + cost  # substitution
			)

		# swap rows
		var tmp := lev_prev
		lev_prev = lev_curr
		lev_curr = tmp

	return lev_prev[b_len]
