extends PracticeTester

var first_node: Control
var has_health_prop := false
var health := 0

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	has_health_prop = false
	for property in first_node.get_property_list():
		if property.name == "health":
			has_health_prop = true
			health = first_node.health
			break

func test_has_health_variable() -> String:
	if not has_health_prop:
		return "The health variable doesn't exist. Did you define it with the var keyword?"
	return ""

func test_health_does_not_go_above_80() -> String:
	if health > 80:
		return "The health goes above 80 when we heal the character a lot. Did you set the health to 80 when that happens?"
	
	return ""

func test_health_limit_is_not_too_low() -> String:
	if health < 80:
		return "The health limit is too low when we heal the character. Did you set the correct limit?"
	
	return ""
