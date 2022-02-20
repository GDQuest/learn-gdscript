extends PracticeTester

const ROBOT_CELL := Vector2(5, 3)

var game_board: Node2D
var path := []


func _prepare() -> void:
	game_board = _scene_root_viewport.get_child(0)
	path = game_board.turtle_path


func test_path_is_contiguous() -> String:
	if path.size() == 0:
		return "No points found in variable turtle_path. Did you write Vector2 coordinates in the variable's array?"
	var last_point = path.front()
	for point in path.slice(1, path.size() - 1):
		if not is_equal_approx(last_point.distance_to(point), 1):
			return "We found at least two points that are not next to one another. Did you forget some coordinates, or did you try to move the turtle diagonally?"
		last_point = point
	return ""


func test_turtle_reaches_the_robot() -> String:
	var last_point = path.back()
	if not last_point or not ROBOT_CELL.is_equal_approx(last_point):
		return (
			"The last point should be at the robot's coordinates, "
			+ str(ROBOT_CELL)
			+ " but it is "
			+ str(last_point)
			+ " instead."
		)
	return ""


func test_path_does_not_hit_obstacles() -> String:
	var unit_coordinates: Array = game_board.units.values()
	for obstacle in unit_coordinates.slice(2, unit_coordinates.size()):
		if obstacle in path:
			return "The turtle hit a rock at coordinates " + str(obstacle) + ". You need to change its path."
	return ""
