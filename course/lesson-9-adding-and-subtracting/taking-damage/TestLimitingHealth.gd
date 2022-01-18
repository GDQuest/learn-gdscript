extends PracticeTester

var first_node: Control
var health := 0

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	health = first_node.health

func test_robot_can_take_damage() -> String:
	if health > 100:
		return "The health goes above 100 when we damage the robot. Did you subract amount from health?"
	
	if not health == 75:
		return "The robot didn't take as much damage as expected. Check how much you're subtracting from health."
	
	return ""

func test_using_subtraction() -> String:
	var regex = RegEx.new()
	regex.compile("health\\s*-")
	var result = regex.search(_slice.current_text)
	if not result:
		return "It doesn't look like you're subtracting anything from health."
	return ""
