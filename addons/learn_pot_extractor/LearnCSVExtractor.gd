@tool
extends EditorTranslationParserPlugin


enum CsvType {
	ERROR_DATABASE,
	GLOSSARY,
}

var _extraction_data: ExtractionData = null

func extract_for(type: CsvType) -> void:
	match type:
		CsvType.ERROR_DATABASE:
			_extraction_data = ExtractionData.new(
				3,
				0,
				true,
				ExtractionTranslationData.new(1, "explanation"),
				ExtractionTranslationData.new(2, "suggestion")
			)
		CsvType.GLOSSARY:
			_extraction_data = ExtractionData.new(
				3,
				0,
				true,
				ExtractionTranslationData.new(2, "explanation")
			)
		_:
			_extraction_data = null


func _parse_file(path: String) -> Array[PackedStringArray]:
	if not _extraction_data:
		return []
	
	var csv_text := FileAccess.open(path, FileAccess.READ).get_as_text()

	var lines := csv_text.split("\n")
	var blocks := []
	for l in range(1 if _extraction_data._has_header else 0, lines.size()):
		var line_text := lines[l]
		var column_texts := PackedStringArray()
		
		var total_columns := _extraction_data._total_columns
		column_texts.resize(total_columns)
		
		for i in total_columns:
			var start_idx := 0
			var next_comma_idx := -1
			var next_entry_idx := -1
			
			if line_text.begins_with('"'):
				start_idx = 1
				if i < total_columns-1:
					next_comma_idx = line_text.find('",')
					next_entry_idx = next_comma_idx+2
				else:
					next_comma_idx = line_text.length()-start_idx
					next_entry_idx = 0
			else:
				if i < total_columns-1:
					next_comma_idx = line_text.find(",")
					next_entry_idx = next_comma_idx+1
				else:
					next_comma_idx = line_text.length()-start_idx
					next_entry_idx = 0
			
			column_texts[i] = line_text.substr(start_idx, next_comma_idx - start_idx)
			line_text = line_text.substr(next_entry_idx)
		
		blocks.push_back(column_texts)
	
	var ret: Array[PackedStringArray]

	for block: PackedStringArray in blocks:
		for data: ExtractionTranslationData in _extraction_data._translations:
			var prefix := ""
			if _extraction_data._prefix_column >= 0:
				prefix = block[0]
			ret.push_back(PackedStringArray([block[data._column], "%s%s" % [("%s." % prefix if prefix else ""), data._suffix]]))
	
	return ret


func _get_recognized_extensions() -> PackedStringArray:
	return ["csv"]


class ExtractionData:
	var _total_columns := 0
	var _prefix_column := 0
	var _has_header := false
	var _translations: Array[ExtractionTranslationData] = []

	func _init(total_columns: int, prefix_column: int, has_header: bool, ... translations) -> void:
		_total_columns = total_columns
		_prefix_column = prefix_column
		_has_header = has_header
		_translations.append_array(translations)


class ExtractionTranslationData:
	var _column: int
	var _suffix: String
	
	func _init(column: int, suffix: String) -> void:
		_column = column
		_suffix = suffix
