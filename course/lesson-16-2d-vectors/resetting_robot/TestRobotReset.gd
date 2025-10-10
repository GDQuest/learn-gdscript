extends PracticeTester

var robot: Node2D


func _prepare() -> void:
	robot = _scene_root_viewport.get_child(0).get_child(1)


func test_use_vector2_to_reset_robot() -> String:
	# Find all Vector2 variable declarations in the student's code.
	# We need to track these because students might assign Vector2 values to variables
	# and then use those variables to reset position/scale.
	var declaration_regex := RegEx.new()
	var compile_result := declaration_regex.compile("(?m)\\b(?:var|const|onready)\\s+([A-Za-z_]\\w*)\\s*(?::\\s*Vector2\\s*)?(?:=|:=)\\s*Vector2\\s*\\(")
	var vector2_variables := []
	var last_search_start_index := 0
	while true:
		var match_result := declaration_regex.search(_slice.current_text, last_search_start_index)
		if not match_result:
			break
		vector2_variables.append(match_result.get_string(1))
		last_search_start_index = match_result.get_end()

	# Here we build a regex pattern that matches any of the Vector2 variable names found above.
	# This is to check if position and scale properties are assigned these variables.
	var variable_alternatives := ""
	if vector2_variables.size() > 0:
		var buffer := "("
		for current_index in range(vector2_variables.size()):
			if current_index > 0:
				buffer += "|"
			buffer += str(vector2_variables[current_index])
		buffer += ")"
		variable_alternatives = buffer

	var position_ok := false
	var scale_ok := false

	# Check if the position is assigned a Vector2 value directly, using the Vector2 constructor or Vector2.ZERO
	var position_direct_regex := RegEx.new()
	compile_result = position_direct_regex.compile("\\b(?:self\\.)?position\\s*=\\s*(?:Vector2\\s*\\(|Vector2\\.ZERO\\b)")
	if position_direct_regex.search(_slice.current_text):
		position_ok = true
	# Check if we assign a Vector2 variable to position
	elif variable_alternatives != "":
		var position_variable_regex := RegEx.new()
		compile_result = position_variable_regex.compile("\\b(?:self\\.)?position\\s*=\\s*" + variable_alternatives + "\\b")
		if position_variable_regex.search(_slice.current_text):
			position_ok = true

	# Check if the scale is set using the Vector2 constructor or Vector2.ZERO/Vector2.ONE
	var scale_direct_regex := RegEx.new()
	compile_result = scale_direct_regex.compile("\\b(?:self\\.)?scale\\s*=\\s*(?:Vector2\\s*\\(|Vector2\\.(?:ZERO|ONE)\\b)")
	if scale_direct_regex.search(_slice.current_text):
		scale_ok = true
	# Check if we assign a Vector2 variable to scale
	elif variable_alternatives != "":
		var scale_variable_regex := RegEx.new()
		compile_result = scale_variable_regex.compile("\\b(?:self\\.)?scale\\s*=\\s*" + variable_alternatives + "\\b")
		if scale_variable_regex.search(_slice.current_text):
			scale_ok = true

	if position_ok and scale_ok:
		return ""
	return tr("It looks like scale or position isn't reset using a Vector2 (directly or via a Vector2 variable).")


func test_robot_scale_is_reset() -> String:
	var scale = robot.get("scale") as Vector2
	if scale.is_equal_approx(Vector2(1.0, 1.0)):
		return ""
	return tr("scale's value is %s; It should be (1.0, 1.0) after resetting.") % [scale]


func test_robot_position_is_reset() -> String:
	var position = robot.get("position") as Vector2
	if position.is_equal_approx(Vector2.ZERO):
		return ""
	return tr("position's value is %s; It should be (0.0, 0.0) after resetting.") % [position]
