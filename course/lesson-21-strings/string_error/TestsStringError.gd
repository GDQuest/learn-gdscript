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


func test_robot_name_is_a_string() -> String:
	if not has_name_prop:
		return tr("The robot_name variable doesn't exist.")

	var value = robot.get("robot_name")
	if value is int and value == 0:
		return tr("The robot_name variable is set to 0. Did you change its value?")
	elif not value is String:
		return tr("The robot_name isn't a string. Did you add quotes around the value?")
	return ""
