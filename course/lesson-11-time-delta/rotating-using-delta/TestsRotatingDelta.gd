extends PracticeTester

var _robot: Node2D
var _body: String
var _has_proper_body: bool


func _prepare() -> void:
	_robot = _scene_root_viewport.get_child(0).get_node("Robot")
	_body = ""
	_has_proper_body = true

	for line in _slice.current_text.split("\n"):
		line = line.strip_edges()
		if line != "":
			_body = line

	if _body != "":
		_has_proper_body = _body.replace(" ", "") in ["rotate(delta*2)", "rotate(2*delta)"]


func test_rotating_character_is_time_dependent() -> String:
	if not _has_proper_body:
		var has_delta := _body.rfind("delta") > 0
		if not has_delta:
			return tr("You need to use delta in the rotate() call. Delta is what makes the rotation time-dependent. Try rotate(2 * delta).")

		var regex_delta_in_parentheses = RegEx.new()
		regex_delta_in_parentheses.compile("rotate\\([^\\)]*delta.*\\)")

		var is_in_parentheses: bool = regex_delta_in_parentheses.search(_body) != null
		if not is_in_parentheses:
			return tr("Delta needs to be inside the parentheses of rotate(), not outside. You need to multiply the speed value by delta inside the call, like this: rotate(2 * delta).")
	return ""


func test_rotation_speed_is_2_radians_per_second() -> String:
	if not _has_proper_body:
		var regex_has_two := RegEx.new()
		regex_has_two.compile("rotate\\s*\\(\\s*(?:2(?:\\.0+)?\\s*\\*\\s*delta|delta\\s*\\*\\s*2(?:\\.0+)?)\\s*\\)")

		var has_two: bool = regex_has_two.search(_body) != null
		if not has_two:
			var var_regex := RegEx.new()
			var_regex.compile("^var\\w*=")
			var uses_variable := false
			for line in _slice.current_text.split("\n"):
				var stripped := line.strip_edges().replace(" ", "")
				uses_variable = uses_variable or (var_regex.search(stripped) != null and ("2" in stripped or "2.0" in stripped) and "delta" in stripped)
			if uses_variable:
				return tr("It looks like you stored the value in a variable before using it.") + " " + \
						tr("That's valid, but we can't check the value automatically.") + " " + \
						tr("Please write it directly in the function call: rotate(2 * delta).")
			return tr("The rotation speed is not right. The robot should rotate 2 radians per second. Make sure the call looks like this: rotate(2 * delta).")

		var has_multiplication_sign := _body.rfind("*") > 0
		if not has_multiplication_sign:
			return tr("It looks like delta is not being multiplied.") + \
					tr("You need to use the * sign to multiply the speed by delta inside the parentheses, like this: rotate(2 * delta).")
	return ""
