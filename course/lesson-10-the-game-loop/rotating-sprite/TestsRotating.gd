extends PracticeTester


func test_character_is_rotating_clockwise() -> String:
	var node_2d = _scene_root_viewport.get_child(0).get_child(0)
	var node_rotation = node_2d.rotation
	if node_rotation < 0.0:
		return tr("The robot is turning in the wrong direction!")
	return ""
