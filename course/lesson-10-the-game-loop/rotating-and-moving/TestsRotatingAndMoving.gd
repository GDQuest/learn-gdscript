extends PracticeTester


func test_character_is_rotating_slowly() -> String:
	var node_2d = _scene_root_viewport.get_child(0).get_child(0)
	var node_rotation = node_2d.rotation
	var node_position := node_2d.position as Vector2
	var test = node_position - Vector2(4.994, 0.25)
	if node_rotation < 0.0:
		return "The robot is turning in the wrong direction!"
	elif node_rotation > 0.06:
		return "The robot is turning too fast!"
	elif not is_equal_approx(node_rotation, 0.05):
		return "The robot's rotation speed isn't right."
	
	
	elif not test.is_equal_approx(Vector2.ZERO):
		return "false"
	return ""
