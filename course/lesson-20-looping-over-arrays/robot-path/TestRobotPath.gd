extends PracticeTester

var game_board: Node2D
var robot: Node2D
var path_source := []
var path_robot := []


func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)
	robot = game_board.get_node("Robot")
	path_source = game_board.robot_path
	path_robot = robot.points


func test_robot_moves_along_blue_path() -> String:
	if game_board.EXPECTED_PATH != path_source:
		return tr("The robot's path changed. Did you change the robot_path array?")

	if path_robot.size() == 0:
		return tr("The robot didn't move at all. Did you call robot.move_to()?")

	for point in path_robot:
		if point != Vector2.ZERO and not point in path_source:
			return tr("The robot's movement path doesn't match the robot_path array. They should be the same.")
	return ""


func test_code_uses_move_to() -> String:
	if not "robot.move_to" in _slice.current_text:
		return tr("We found no call to the robot's move_to() function. Did you forget to call it?")
	return ""
