extends PracticeTester

var first_node: Node2D
# Using set seed, we get these random numbers
const EXPECTED_DICE_SEQUENCE := [13, 7, 8, 8, 10]


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)


func test_modulo_used_to_look_for_even_levels() -> String:
	var regex = RegEx.new()
	regex.compile("\\%\\s*2\\s*")
	var result = regex.search(_slice.current_text)
	if not result:
		return "It looks like modulo isn't used correctly in the script. Make sure to use modulo (%) to check for even levels."
	return ""


func test_correct_maximum_health_at_level_four() -> String:
	var max_health = first_node.get("max_health")
	
	if max_health < 125:
		return "The robot only has %s max health. It should have 125 after gaining three levels." % max_health
	
	if max_health > 125:
		return "The robot has %s max health which is too much. It should have 125 after gaining three levels." % max_health

	return ""
