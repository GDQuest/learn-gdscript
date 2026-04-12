extends PracticeTester

const INDEX_VARNAME := 1
const INDEX_TYPE := 2
const INDEX_VALUE := 3

var regex := RegEx.new()
var float_literal_regex := RegEx.new()
var vector_literal_regex := RegEx.new()
var string_literal_regex := RegEx.new()

var correct_type_list := []
var success_list := []

# Maps variable names to their expected type hints, which the student must not change.
var hints_map := {
	vector = "Vector2",
	text = "String",
	whole_number = "int",
	decimal_number = "float",
}


func _init() -> void:
	regex.compile("(\\w+)\\s*:\\s*(\\w+)\\s*=\\s*(.+)")
	float_literal_regex.compile("^-?\\d+\\.\\d+$")
	vector_literal_regex.compile("^Vector2\\s*\\(")
	string_literal_regex.compile("^\".*\"$|^'.*'$")


func _is_value_matching_type(type: String, raw_value_string: String) -> bool:
	var value := raw_value_string.strip_edges()
	match type:
		"int":
			if string_literal_regex.search(value):
				return false
			if vector_literal_regex.search(value):
				return false
			if float_literal_regex.search(value):
				return false
			var int_regex := RegEx.new()
			int_regex.compile("^-?\\d+$")
			return int_regex.search(value) != null
		"float":
			if string_literal_regex.search(value):
				return false
			if vector_literal_regex.search(value):
				return false
			var number_regex := RegEx.new()
			number_regex.compile("^-?\\d+(\\.\\d+)?$")
			return number_regex.search(value) != null
		"String":
			return string_literal_regex.search(value) != null
		"Vector2":
			return vector_literal_regex.search(value) != null
	return false


func _prepare():
	correct_type_list.clear()
	success_list.clear()

	var lines = _slice.current_text.split("\n")
	for line in lines:
		var result := regex.search(line)
		if not result:
			continue
		var varname = result.strings[INDEX_VARNAME]
		var type = result.strings[INDEX_TYPE]
		var raw_value_string = result.strings[INDEX_VALUE]
		if not varname in hints_map:
			continue
		if hints_map[varname] == type:
			correct_type_list.append(varname)
		if hints_map[varname] == type and _is_value_matching_type(type, raw_value_string):
			success_list.append(varname)


func test_whole_number_has_correct_value() -> String:
	if not "whole_number" in correct_type_list:
		return tr("It looks like you changed the type hint of 'whole_number'. The type should stay 'int'. Only change the value after the '=' sign.")
	if not "whole_number" in success_list:
		return tr("The value of 'whole_number' does not match its type hint (int). Change the value after '=' to a whole number with no decimal point, for example: 4")
	return ""


func test_text_has_correct_value() -> String:
	if not "text" in correct_type_list:
		return tr("It looks like you changed the type hint of 'text'. The type should stay 'String'. Only change the value after the '=' sign.")
	if not "text" in success_list:
		return tr("The value of 'text' does not match its type hint (String). Change the value after '=' to a text string surrounded by quotes, for example: \"Hello, world!\"")
	return ""


func test_vector_has_correct_value() -> String:
	if not "vector" in correct_type_list:
		return tr("It looks like you changed the type hint of 'vector'. The type should stay 'Vector2'. Only change the value after the '=' sign.")
	if not "vector" in success_list:
		return tr("The value of 'vector' does not match its type hint (Vector2). Change the value after '=' to a Vector2, for example: Vector2(1, 1)")
	return ""


func test_decimal_number_has_correct_value() -> String:
	if not "decimal_number" in correct_type_list:
		return tr("It looks like you changed the type hint of 'decimal_number'. The type should stay 'float'. Only change the value after the '=' sign.")
	if not "decimal_number" in success_list:
		return tr("The value of 'decimal_number' does not match its type hint (float). Change the value after '=' to a decimal number with a decimal point, for example: 3.14")
	return ""
