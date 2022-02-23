extends PracticeTester

var first_node: Node2D

func _prepare():
	first_node = _scene_root_viewport.get_child(0)


func test_addition_is_used_to_increase_level() -> String:
	var regex = RegEx.new()
	regex.compile("level\\s*\\+|\\+\\s*level")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("It looks like level isn't increasing every level. Did you add 1 to it?")
	return ""


func test_multiplication_is_used_to_increase_max_health() -> String:
	var regex = RegEx.new()
	regex.compile("max_health\\s*\\*|\\*\\s*max_health")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("It looks like max_health isn't increasing exponentially. Did you multiply it by a value greater than 1?")
	return ""


func test_level_is_the_correct_value() -> String:
	var level_value = first_node.get("level")
	if is_equal_approx(level_value, 3):
		return ""
	return tr("Level variable's value is %s; It should be 3 after levelling up twice.") % level_value


func test_max_health_is_the_correct_value() -> String:
	var max_health_value = first_node.get("max_health")
	if is_equal_approx(max_health_value, 121):
		return ""
	return tr("Max health variable's value is %s; It should be 121 after levelling up twice.") % max_health_value
