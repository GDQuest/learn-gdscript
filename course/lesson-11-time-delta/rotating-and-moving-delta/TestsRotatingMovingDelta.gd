extends PracticeTester

var _robot: Node2D
var _lines: PoolStringArray


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
		return tr("Did you use make_local_x() to make the sprite move locally?")
	return ""


func test_movement_is_time_dependent() -> String:
	var has_delta := false
	for line in _lines:
		has_delta = has_delta and "(delta" in line or "delta)" in line

	if not has_delta:
		return tr("Did you use delta in the right places to make the rotation time-dependent?")
	return ""


func test_movement_speed_is_correct() -> String:
	var has_correct_rotation := matches_code_line(["rotate(delta*2*)", "rotate(2*delta)"])
	var has_correct_speed := matches_code_line(
		["move_local_x(100*delta*)", "move_local_x(delta*100*)"]
	)

	if not has_correct_rotation:
		return tr("Is the rotation speed correct?")
	elif not has_correct_speed:
		return tr("Is the movement speed correct?")
	return ""
