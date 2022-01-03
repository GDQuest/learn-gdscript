extends PracticeTester


func test_character_is_rotating_slowly() -> String:
	var node_2d = _scene_root_viewport.get_child(0).get_child(0)
	var node_rotation = node_2d.rotation
	var node_position = node_2d.position as Vector2
	
	if node_rotation < 0.0:
		return "The robot is turning in the wrong direction!"
	elif node_rotation > 0.06:
		return "The robot is turning too fast!"
	elif not is_equal_approx(node_rotation, 0.05):
		return "The robot's rotation speed isn't right."
	elif not is_equal_approx(node_position.x, 304.994):
		return "The value of a parameter isn't right."
	elif not is_equal_approx(node_position.y, 200.25):
		return "The value of a parameter isn't right."
	return ""
