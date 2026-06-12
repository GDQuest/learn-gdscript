@tool
extends EditorTranslationParserPlugin

const ERROR_DATABASE := "res://script_checking/error_database.csv"
const GLOSSARY := "res://course/glossary.csv"
const DOCUMENTATION := "res://course/documentation.csv"


static var _extraction_data := {
	ERROR_DATABASE: ExtractionData.new(3, 0, true, ExtractionTranslationData.new(1, "explanation"), ExtractionTranslationData.new(2, "suggestion")),
	GLOSSARY: ExtractionData.new(3, 0, true, ExtractionTranslationData.new(2, "explanation")),
	DOCUMENTATION: ExtractionData.new(6, 0, true, ExtractionTranslationData.new(3, "explanation"))
}


func _parse_file(path: String) -> Array[PackedStringArray]:
	if not path in _extraction_data:
		push_warning("No data for CSV '%s' in CSV Extractor" % path)
		return []
	
	var extraction_data: ExtractionData = _extraction_data[path]
	
	var csv_file := FileAccess.open(path, FileAccess.READ)
	var blocks := []
	while not csv_file.eof_reached():
		blocks.append_array(csv_file.get_csv_line())
	
	var ret: Array[PackedStringArray] = []
	for l in range(0, blocks.size(), extraction_data._total_columns):
		for data: ExtractionTranslationData in extraction_data._translations:
			if l + data._column < blocks.size():
				var text_block: String = blocks[l + data._column]
				
				var lines := text_block.split("\n", false)
				for line in lines:
					ret.append(PackedStringArray([line]))
		
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
