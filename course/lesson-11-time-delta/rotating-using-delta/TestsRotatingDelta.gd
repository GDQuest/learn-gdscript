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


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Rotating Character Is Time Dependent"), tr(""), test_rotating_character_is_time_dependent))
	checks.append(Check.new(tr("Rotation Speed Is 2 Radians Per Second"), tr(""), test_rotation_speed_is_2_radians_per_second))


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
	var process := _analyzer.get_function_named("_process")
	if not process:
		return tr("The _process function is missing; did you remove it?")
	
	if GDExpr.suite(
		GDExpr.function_call(
			"rotate",
			GDExpr.any_identifier()
		)
	).matches(process):
		return tr("It looks like you stored the value in a variable before using it.") + " " + \
				tr("That's valid, but we can't check the value automatically.") + " " + \
				tr("Please write it directly in the function call: rotate(2 * delta).")
	
	if GDExpr.suite(
		GDExpr.function_call(
			"rotate",
			GDExpr.literal(2.0)
		)
	).matches(process):
		return tr("It looks like delta is not being multiplied.") + \
				tr("You need to use the * sign to multiply the speed by delta inside the parentheses, like this: rotate(2 * delta).")
	
	var process_delta_name := _analyzer.get_function_parameter_name(process, 0)
	
	if not GDExpr.suite(
		GDExpr.function_call(
			"rotate",
			GDExpr.multiply(
				GDExpr.literal(2.0),
				GDExpr.identifier(process_delta_name)
			)
		)
	).matches(process):
		return tr("The rotation speed is not right. The robot should rotate 2 radians per second. Make sure the call looks like this: rotate(2 * delta).")
	return ""

