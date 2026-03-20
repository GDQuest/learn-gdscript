# Entry point for parsing lesson content in BBCode format.
class_name LessonBBCodeParser
extends RefCounted

var _parser: BBCodeParser = null
var _tree_validator: BBCodeTreeValidator = null


func _init() -> void:
	_parser = BBCodeParser.new()
	_tree_validator = BBCodeTreeValidator.new()


func parse_file(file_path: String) -> BBCodeParser.ParseResult:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if not file:
		var result := BBCodeParser.ParseResult.new()
		result.add_error("Failed to open file: %s (error code: %d)" % [file_path, FileAccess.get_open_error()], 0)
		return result

	var content := file.get_as_text()
	file.close()
	
	return parse_text(content, file_path)


func parse_text(source: String, file_path: String) -> BBCodeParser.ParseResult:
	var result := BBCodeParser.ParseResult.new()

	var root := _parser.parse(source, result, file_path)
	if not result.errors.is_empty():
		return result

	_tree_validator.validate_tree(root, result)
	if not result.errors.is_empty():
		return result

	result.root = root
	return result
