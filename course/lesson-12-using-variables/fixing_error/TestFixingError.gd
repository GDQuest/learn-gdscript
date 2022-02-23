extends PracticeTester

var robot: Node2D
var has_angular_speed_prop := false


func _prepare():
	robot = _scene_root_viewport.get_child(0)
	has_angular_speed_prop = false
	for property in robot.get_property_list():
		if property.name == "angular_speed":
			has_angular_speed_prop = true
			break


func test_has_angular_speed_variable() -> String:
	if not has_angular_speed_prop:
		return tr("The angular_speed variable doesn't exist. Did you define it with the var keyword?")
	return ""


func test_angular_speed_has_value_of_4() -> String:
	if not has_angular_speed_prop:
		return tr("The angular speed variable doesn't exist, can't test if it has a value of 4.")
	var angular_speed_value = robot.get("angular_speed")
	if angular_speed_value == 4:
		return ""
	return tr("Angular speed variable's value is %s; It should be 4.") % angular_speed_value


func test_angular_speed_is_used_in_process_function() -> String:
	var regex = RegEx.new()
	regex.compile("rotate\\(\\s*angular_speed")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("The rotate() function doesn't seem to use the angular_speed variable.")
	return ""


func test_each_function_uses_the_same_variable() -> String:
	var regex = RegEx.new()
	regex.compile("var\\s*angular_speed")
	var result = regex.search_all(_slice.current_text)
	if result.size() > 1:
		return "It looks like you declared angular_speed more than once. It should only be defined once."
	return ""


func test_angular_speed_is_used_in_setter_function() -> String:
	var regex = RegEx.new()
	regex.compile("\\)\\:\\s*angular_speed")
	var result = regex.search(_slice.current_text)
	if not result:
		return "The set_angular_speed() function doesn't seem to use the angular_speed variable."
	return ""
