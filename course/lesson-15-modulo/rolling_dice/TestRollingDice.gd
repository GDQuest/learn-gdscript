extends PracticeTester

var first_node: Node2D
# Using set seed, we get these random numbers
const EXPECTED_DICE_SEQUENCE := [13, 7, 8, 8, 10]


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)


func test_randi_function_used_with_sides() -> String:
	var regex = RegEx.new()
	regex.compile("randi\\(\\)\\s*\\%\\s*sides")
	var result = regex.search(_slice.current_text)
	if not result:
		return "It looks like modulo isn't used correctly in the script. Make sure to use modulo (%) in the correct order."
	return ""


func test_function_simulates_rolling_dice() -> String:
	var results = first_node.get("results")
	
	if results.min() < 7:
		return "It looks like the minimum number the die can roll is too low. Did you add 1 to increase the range?"
	
	if results.min() > 7:
		return "It looks like the minimum number the die can roll is too high. Did you add too much to the result?"
	
	if not results.hash() == EXPECTED_DICE_SEQUENCE.hash():
		return "Something is wrong with the roll function."
	return ""
