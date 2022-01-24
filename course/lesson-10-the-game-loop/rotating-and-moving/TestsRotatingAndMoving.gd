extends PracticeTester


func test_character_is_moving_in_a_circle() -> String:
	var node_2d = _scene_root_viewport.get_child(0).get_child(0)
	var node_rotation = node_2d.rotation
	var node_position = node_2d.position as Vector2
	
	if node_rotation < 0.0:
		return "The robot is turning in the wrong direction!"
	elif is_equal_approx(node_position.x, 300.0):
		return "The character didn't move as expected."
	return ""
