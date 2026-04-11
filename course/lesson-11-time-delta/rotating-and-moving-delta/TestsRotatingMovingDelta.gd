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
	var has_correct_rotation := matches_code_line_regex(
		["rotate\\s*\\(\\s*(?:2(?:\\.0+)?\\s*\\*\\s*delta|delta\\s*\\*\\s*2(?:\\.0+)?)\\s*\\)"],
	)
	var has_correct_speed := matches_code_line_regex(
		["move_local_x\\s*\\(\\s*(?:100(?:\\.0+)?\\s*\\*\\s*delta|delta\\s*\\*\\s*100(?:\\.0+)?)\\s*(?:,\\s*(?:true|false)\\s*)?\\)"],
	)

	if not has_correct_rotation or not has_correct_speed:
		var var_regex := RegEx.new()
		var_regex.compile("^var\\w*=")
		var has_rotation_var := false
		var has_speed_var := false
		for line in _lines:
			if not var_regex.search(line):
				continue
			has_rotation_var = has_rotation_var or (("2" in line or "2.0" in line) and "delta" in line)
			has_speed_var = has_speed_var or (("100" in line or "100.0" in line) and "delta" in line)
		if has_rotation_var or has_speed_var:
			return tr("It looks like you stored values in variables before passing them to the functions.") + " " + \
					tr("That works in GDScript, but we cannot check the values automatically here.") + " " + \
					tr("Please write the values directly inside the function calls, like this: rotate(2 * delta) and move_local_x(100 * delta).")
	if not has_correct_rotation:
		return tr("The rotation speed is not right. The robot should rotate 2 radians per second. Make sure the call looks like this: rotate(2 * delta).")
	elif not has_correct_speed:
		return tr("The movement speed is not right. The robot should move 100 pixels per second. Make sure the call looks like this: move_local_x(100 * delta).")
	return ""
