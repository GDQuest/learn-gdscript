extends PracticeTester

var first_node: Control
var has_health_prop := false

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	has_health_prop = false
	for property in first_node.get_property_list():
		if property.name == "health":
			has_health_prop = true
			break

func test_has_health_variable() -> String:
	if not has_health_prop:
		return tr("The health variable doesn't exist. Did you define it with the var keyword?")
	return ""


func test_health_has_value_of_100() -> String:
	if not has_health_prop:
		return tr("Health variable doesn't exist, can't test if it has a value of 100.")
	var health_value = first_node.get("health")
	if not health_value is int:
		if health_value is String:
			return tr("Health's value is a text string. It should be a number. You need to remove quotes around the value.")
		else:
			return tr("Health's value should be a whole number. Instead it's a %s.") % TextUtils.convert_type_index_to_text(typeof(health_value))
	if health_value == 100:
		return ""
	return tr("Health variable's value is %s; It should be 100.") % health_value
