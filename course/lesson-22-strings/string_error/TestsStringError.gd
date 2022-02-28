extends PracticeTester

var robot: Node2D
var has_name_prop := false

func _prepare() -> void:
	robot = _scene_root_viewport.get_child(0)
	has_name_prop = false
	for property in robot.get_property_list():
		if property.name == "robot_name":
			has_name_prop = true
			break


func test_has_robot_name_variable() -> String:
	if not has_name_prop:
		return "The robot_name variable doesn't exist. Did you define it with the var keyword?"
	return ""


func test_robot_name_is_a_string() -> String:
	if not has_name_prop:
		return "The robot_name variable doesn't exist. Make sure it's defined."
	var robot_name = robot.get("robot_name")
	if not robot_name is String:
		return "The robot_name isn't a string. Did you add quotes around the value?"
	return ""
