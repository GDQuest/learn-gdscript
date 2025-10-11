extends PracticeTester

var desired_combo = ["jab", "jab", "uppercut"]
var robot: Node2D


func _prepare() -> void:
	robot = _scene_root_viewport.get_child(0)


func test_use_for_loop() -> String:
	var regex = RegEx.new()
	var variable_name = ""
	regex.compile("for\\s+(\\w+)\\s+in")

	var processed_code := _slice.preprocess_practice_code(_slice.current_text)

	if not "for" in processed_code:
		return tr("Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!")

	var result = regex.search(_slice.current_text)
	if result:
		variable_name = result.get_string(1)

	if not "play_animation(" in processed_code:
		return tr("Your code does not play any animations. Did you remember to call play_animation() in your for loop?")
	if "play_animation(combo)" in processed_code:
		return tr("It seems you're passing the entire array of combos instead of a single animation name at a time.")
	if not variable_name:
		return tr("Your code has no iterator. You need to use a for loop with iterator to complete this practice, even if there are other solutions!")
	if not "play_animation(" + variable_name + ")" in processed_code:
		return tr("Your code does not use the iterator. Did you remember to call play_animation(%s) in your for loop?") % variable_name
	return ""


func test_robot_combo_is_correct() -> String:
	var robot_combo = robot.get("combo")
	if robot_combo == desired_combo:
		return ""

	# Check if the student declared a local 'combo' variable and used it
	# correctly in a for loop. Some students will shadow member variables with
	# local ones so this still allows them to pass.
	var processed_code := _slice.preprocess_practice_code(_slice.current_text)
	if "var combo" in processed_code or "combo=" in processed_code:
		var regex = RegEx.new()
		regex.compile("for(\\w+)incombo")
		var result = regex.search(processed_code)
		if result:
			var iterator_name = result.get_string(1)
			if ("play_animation(" + iterator_name + ")") in processed_code:
				return ""
	return tr("The combo isn't correct. Did you use the right actions in the right order?")
