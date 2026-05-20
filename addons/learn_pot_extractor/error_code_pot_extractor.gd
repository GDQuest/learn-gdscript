@tool
extends EditorTranslationParserPlugin


func _parse_file(path: String) -> Array[PackedStringArray]:
	var csv_text := FileAccess.open(path, FileAccess.READ).get_as_text()

	var RE_CSV_ENTRY := RegEx.create_from_string(r'\"[A-Z_]+\",')
	var matches := RE_CSV_ENTRY.search_all(csv_text)
	var blocks := []
	
	for i in range(matches.size()):
		if i == matches.size()-1:
			blocks.push_back(csv_text.substr(matches[i].get_start()))
		else:
			blocks.push_back(csv_text.substr(matches[i].get_start(), matches[i+1].get_start()-matches[i].get_start()-1))

	var ret: Array[PackedStringArray]

	for block: String in blocks:
		var end_error_code_idx := block.find('",', 1)-1
		
		if block.substr(end_error_code_idx+2, 2) == ",,":
			continue
		
		var error_code := block.substr(1, end_error_code_idx)
		
		var end_explanation_idx := block.find('","', end_error_code_idx+2)
		var explanation := block.substr(end_error_code_idx+4, end_explanation_idx - end_error_code_idx-4)
		
		var suggestion := block.substr(end_explanation_idx+3, block.length() - end_explanation_idx - 4)
		
		ret.push_back(PackedStringArray([explanation, "%s.explanation" % [error_code]]))
		ret.push_back(PackedStringArray([suggestion, "%s.suggestion" % [error_code]]))
	
	return ret


func _get_recognized_extensions() -> PackedStringArray:
	return ["csv"]
