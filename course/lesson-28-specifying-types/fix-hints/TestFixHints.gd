extends PracticeTester

const INDEX_VARNAME := 1
const INDEX_TYPE := 2

var regex := RegEx.new()
var success_list := []

var hints_map := {
	vector = "Vector2",
	text = "String",
	whole_number = "int",
	decimal_number = "float",
}


func _init() -> void:
	regex.compile("(\\w+):\\s*(\\w+)\\s*=")


func _prepare():
	success_list.clear()

	var lines = _slice.current_text.split("\n")
	for line in lines:
		var result := regex.search(line)
		if not result:
			continue
		var varname = result.strings[INDEX_VARNAME]
		var type = result.strings[INDEX_TYPE]
		if not varname in hints_map:
			continue
		if hints_map[varname] != type:
			continue
		success_list.append(varname)


# No need to return translation strings or detailed error messages because wrong
# types will lead to GDScript type errors and the following checks won't even
# run.
func test_vector_has_correct_hint() -> String:
	if not "vector" in success_list:
		return "Error"
	return ""


func test_text_has_correct_hint() -> String:
	if not "text" in success_list:
		return "Error"
	return ""


func test_whole_number_has_correct_hint() -> String:
	if not "whole_number" in success_list:
		return "Error"
	return ""


func test_decimal_number_has_correct_hint() -> String:
	if not "decimal_number" in success_list:
		return "Error"
	return ""
