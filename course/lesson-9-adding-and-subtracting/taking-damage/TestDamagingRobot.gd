extends PracticeTester

var first_node: Node2D
var health := 0

func _prepare():
	first_node = _scene_root_viewport.get_child(0)
	health = first_node.health

func test_robot_takes_the_right_amount_of_damage() -> String:
	if health > 100:
		return tr("The health goes above 100 when we damage the robot. Did you subract amount from health?")
	
	if not health == 50:
		return tr("The robot didn't take as much damage as expected. It has %s health, but it should have 50 health after taking damage.") % [health]
	
	return ""

func test_subtract_amount_from_health() -> String:
	var regex = RegEx.new()
	regex.compile("health\\s*-.*amount")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("It doesn't look like you're subtracting amount from health.")
	return ""
