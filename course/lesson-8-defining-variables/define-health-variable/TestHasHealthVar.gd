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
		return "The health variable doesn't exist. Did you define it with the var keyword?"
	return ""


func test_health_has_value_of_100() -> String:
	if not has_health_prop:
		return "Health variable doesn't exist, can't test if it has a value of 100."
	var health_value = first_node.get("health")
	if health_value == 100:
		return ""
	return "Health variable's value is %s; It should be 100." % health_value
