extends PracticeTester

var _robot: Node2D
var _lines: PackedStringArray
var _checker: GDScriptErrorChecker
var _analyzer: GDScriptASTAnalyzer


func _prepare() -> void:
	_robot = _scene_root_viewport.get_child(0).get_node("Robot")
	_lines = []
	
	_checker = GDScriptErrorChecker.new()
	_checker.set_source(_slice.current_text)
	var root := _checker.get_root_parse_node()
	_analyzer = GDScriptASTAnalyzer.new(root)

	var index := 0
	for line in _slice.current_text.split("\n"):
		line = line.strip_edges().replace(" ", "")
		if line != "" and index > 0:
			_lines.push_back(line)
		index += 1


func test_moving_in_a_circle() -> String:
	var has_rotate := false
	var has_move_local := false
	for line in _lines:
		has_rotate = has_rotate or line.begins_with("rotate(")
		has_move_local = has_move_local or line.begins_with("move_local_x(")

	if not has_rotate:
		return tr("Did you use rotate() to make the sprite rotate?")
	elif not has_move_local:
		return tr("Did you use move_local_x() to make the sprite move locally?")
	return ""


func test_movement_is_time_dependent() -> String:
	var has_delta := false
	for line in _lines:
		if "delta" in line.replace(" ", ""):
			has_delta = true
			break

	if not has_delta:
		return tr("You need to use delta in your code. Multiplying by delta makes the movement time-dependent.") + " " + \
				tr("Both rotate() and move_local_x() need to multiply their value by delta, like this: rotate(2 * delta) and move_local_x(100 * delta).")
	return ""


func test_movement_speed_is_correct() -> String:
	var process := _analyzer.get_function_named("_process")
	if not process:
		return tr("The _process function is missing; did you remove it?")
	
	if GDExpr.suite(
		GDExpr.any_of(
			GDExpr.function_call(
				"rotate",
				GDExpr.any_identifier()
			),
			GDExpr.function_call(
				"move_local_x",
				GDExpr.any_identifier()
			)
		)
	).matches(process):
		return tr("It looks like you stored values in variables before passing them to the functions.") + " " + \
				tr("That works in GDScript, but we cannot check the values automatically here.") + " " + \
				tr("Please write the values directly inside the function calls, like this: rotate(2 * delta) and move_local_x(100 * delta).")
	
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
	
	if not GDExpr.suite(
		GDExpr.function_call(
			"move_local_x",
			GDExpr.multiply(
				GDExpr.literal(100.0),
				GDExpr.identifier(process_delta_name)
			)
		)
	).matches(process):
			return tr("The movement speed is not right. The robot should move 100 pixels per second. Make sure the call looks like this: move_local_x(100 * delta).")
	
	return ""
