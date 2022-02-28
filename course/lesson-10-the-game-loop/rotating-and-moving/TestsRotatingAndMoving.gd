extends PracticeTester


func test_character_is_moving_in_a_circle_clockwise() -> String:
	var robot: Node2D = _scene_root_viewport.get_child(0).get_node("Robot")
	if robot.rotation < 0.0:
		return tr("The robot is turning in the wrong direction!")
	elif is_equal_approx(robot.position.x, 300.0):
		return tr("The character didn't move as expected.")
	return ""
