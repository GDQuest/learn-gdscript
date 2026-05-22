@tool
extends RefCounted


static var GLOSSARY_RE := RegEx.create_from_string(r"\[url=(?!http)[^\]]+\]([^\[]+)\[\/url\]")
static var POT_PATTERN := RegEx.create_from_string(
	r'(?<comment>(?:#[^\n]+\n)+)?' +
	r'(?<ctxt>msgctxt "(?:\\.|[^"\\])*"\n)?' +
	r'(?<id>msgid (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))' +
	r'(?<str>msgstr (?:""\n(?:"(?:\\.|[^"\\])*"\n)+|"(?:\\.|[^"\\])*"\n))'
)


static func build_tr_blocks(po_file: String) -> Array[Dictionary]:
	var po_text := FileAccess.open(po_file, FileAccess.READ).get_as_text()
	var tr_blocks: Array[Dictionary] = []
	tr_blocks.append_array(POT_PATTERN.search_all(po_text).map(func(block_match: RegExMatch) -> Dictionary:
		return {
			"comments": _parse_course_comment(block_match),
			"ctxt": block_match.get_string("ctxt").substr(9, block_match.get_string("ctxt").length()-11),
			"id": _parse_course_string(block_match, true),
			"str": _parse_course_string(block_match, false)
		}
	))
	return tr_blocks


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
