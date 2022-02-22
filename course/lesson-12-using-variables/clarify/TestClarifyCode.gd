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


func test_angular_speed_variable_is_script_wide() -> String:
	if not has_angular_speed_prop:
		return tr("The angular_speed isn't script-wide. Did you define it outside of the function?")
	return ""


func test_angular_speed_has_value_of_4() -> String:
	if not has_angular_speed_prop:
		return tr("The angular speed variable doesn't exist or isn't script-wide. Make it script-wide first.")
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
