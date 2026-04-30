extends PracticeTester

var _robot: Node2D
var _lines: PackedStringArray


func _prepare() -> void:
	_robot = _scene_root_viewport.get_child(0).get_node("Robot")
	_lines = []

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
	var checker := GDScriptErrorChecker.new()
	checker.set_source(_slice.current_text)
	var root := checker.get_root_parse_node()
	
	var used_vars := false
	var has_correct_rotate := true
	var has_correct_move := true
	
	var analyzer := GDScriptASTAnalyzer.new(root)
	
	var process := analyzer.get_function_named("_process")
	if not process:
		return tr("The '_process(delta)' function is missing; did you remove it?")
	
	var process_delta_name := analyzer.get_function_parameter_name(process, 0)
	
	var rotate_call := analyzer.get_statement_call_named(process, "rotate")
	if not rotate_call:
		return tr("Did you use rotate() to make the sprite rotate?")
	
	if analyzer.call_has_argument_identifier(rotate_call, 0):
		used_vars = true
	elif not analyzer.call_has_argument_x_operated_by_identifier(rotate_call, 0, GDBinaryOpNode.OP_MULTIPLICATION, process_delta_name, 2.0):
		has_correct_rotate = false

	var move_call := analyzer.get_statement_call_named(process, "move_local_x")
	if not move_call:
		return tr("Did you use move_local_x() to make the sprite move locally?")
	
	if analyzer.call_has_argument_identifier(move_call, 0):
		used_vars = true
	elif not analyzer.call_has_argument_x_operated_by_identifier(move_call, 0, GDBinaryOpNode.OP_MULTIPLICATION, process_delta_name, 100.0):
		has_correct_move = false
	
	if used_vars:
		return tr("It looks like you stored values in variables before passing them to the functions.") + " " + \
				tr("That works in GDScript, but we cannot check the values automatically here.") + " " + \
				tr("Please write the values directly inside the function calls, like this: rotate(2 * delta) and move_local_x(100 * delta).")
	
	if not has_correct_rotate:
		return tr("The movement speed is not right. The robot should move 100 pixels per second. Make sure the call looks like this: move_local_x(100 * delta).")
	if not has_correct_move:
		return tr("The rotation speed is not right. The robot should rotate 2 radians per second. Make sure the call looks like this: rotate(2 * delta).")
	
	return ""
