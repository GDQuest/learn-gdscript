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
		return "Your code has no for loop. You need to use a for loop to complete this practice, even if there are other solutions!"

	var result = regex.search(_slice.current_text)
	if result :
		variable_name = result .get_string(1)

	if not "play_animation(" in processed_code:
		return "Your code does not play any animations. Did you remember to call play_animation() in your for loop?"
	if "play_animation(combo)" in processed_code:
		return "It seems you're passing the entire array of combos instead of a single animation name at a time."
	if not variable_name:
		return "Your code has no iterator. You need to use a for loop with iterator to complete this practice, even if there are other solutions!"
	if not "play_animation(" + variable_name + ")" in processed_code:
		return "Your code does not use the iterator. Did you remember to call play_animation(" + variable_name + ") in your for loop?"
	return ""


func test_robot_combo_is_correct() -> String:
	var robot_combo = robot.get("combo")
	if not robot_combo == desired_combo:
		return "The combo isn't correct. Did you use the right actions in the right order?"
	return ""
