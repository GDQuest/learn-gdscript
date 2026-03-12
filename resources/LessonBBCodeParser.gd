# Entry point for parsing lesson content in BBCode format.
class_name LessonBBCodeParser
extends Reference

# Folder path of the parsed file to resolve relative asset paths.
var _base_path := ""

var _parser: BBCodeParser = null
var _tree_validator: BBCodeTreeValidator = null


func _init() -> void:
	_parser = BBCodeParser.new()
	_tree_validator = BBCodeTreeValidator.new()


func parse_file(file_path: String) -> BBCodeParser.ParseResult:
	var file := File.new()
	var open_error := file.open(file_path, File.READ)
	if open_error != OK:
		var result := BBCodeParser.ParseResult.new()
		result.add_error("Failed to open file: %s (error code: %d)" % [file_path, open_error], 0)
		return result

	var content := file.get_as_text()
	file.close()

	_base_path = file_path.get_base_dir()
	return parse_text(content, file_path, _base_path)


func parse_text(source: String, file_path: String, base_path := "") -> BBCodeParser.ParseResult:
	var result := BBCodeParser.ParseResult.new()

	var root := _parser.parse(source, result, file_path)
	if not result.errors.empty():
		return result

	_tree_validator.validate_tree(root, result)
	if not result.errors.empty():
		return result

	result.root = root
	return result
