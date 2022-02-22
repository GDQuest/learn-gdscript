extends PracticeTester

var first_node: Node2D
var health := 0

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	health = first_node.health

func test_robot_heals_the_right_amount() -> String:
	if health < 50:
		return tr("The robot's health decreased instead of increasing. Did you add the amount to health?")
	
	if not health == 100:
		return tr("The robot didn't heal as expected. It has %s, but it should have 100 health.") % [health]
	
	return ""

func test_heal_function_uses_addition() -> String:
	var regex = RegEx.new()
	regex.compile("health\\s*+")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("It doesn't look like you're adding anything to health.")
	return ""
