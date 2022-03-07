extends PracticeTester

var robot: Node2D
var lines: PoolStringArray


func _prepare() -> void:
	robot = _scene_root_viewport.get_child(0).get_node("Robot")
	for line in _slice.current_text.split("\n"):
		line = line.strip_edges().replace(" ", "")
		if not line.empty():
			lines.push_back(line)


func test_character_is_moving_in_a_circle_clockwise() -> String:
	var has_rotate := false
	var has_move_local := false
	for line in lines:
		has_rotate = has_rotate or line.begins_with("rotate(")
		has_move_local = has_move_local or line.begins_with("move_local_x(")

	if not has_rotate:
		return tr("Did you use rotate() to make the sprite rotate?")
	elif not has_move_local:
		return tr("Did you use make_local_x() to make the sprite move locally?")

	if robot.rotation < 0.0:
		return tr("The robot is turning in the wrong direction!")
	elif is_equal_approx(robot.position.x, 300.0):
		return tr("The character didn't move as expected.")
	return ""
