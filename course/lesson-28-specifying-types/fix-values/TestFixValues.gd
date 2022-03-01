extends PracticeTester

const INDEX_VARNAME := 1
const INDEX_TYPE := 2

var regex := RegEx.new()
var success_list := []

# Ensure that the hint is still the original
var hints_map := {
	vector = "Vector2",
	text = "String",
	whole_number = "int",
	decimal_number = "float",
}


func _init() -> void:
	regex.compile("(\\w+):\\s*(\\w+)\\s*=")


# Ensures the user preserved the original hints. If the value is compatible, the
# tests will naturally pass as this practice relies mostly on the GDScript
# compiler.
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


func test_vector_has_correct_value() -> String:
	if not "vector" in success_list:
		return tr("It seems you changed the type of the %s variable. You should change the value instead.") % "vector"
	return ""


func test_text_has_correct_value() -> String:
	if not "text" in success_list:
		return tr("It seems you changed the type of the %s variable. You should change the value instead.") % "text"
	return ""


func test_whole_number_has_correct_value() -> String:
	if not "whole_number" in success_list:
		return tr("It seems you changed the type of the %s variable. You should change the value instead.") % "whole_number"
	return ""


func test_decimal_number_has_correct_value() -> String:
	if not "decimal_number" in success_list:
		return tr("It seems you changed the type of the %s variable. You should change the value instead.") % "decimal_number"
	return ""
