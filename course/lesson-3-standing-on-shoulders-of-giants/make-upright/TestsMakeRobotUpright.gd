extends PracticeTester

const TOLERANCE := 0.05

func test_character_is_upright() -> String:
	var node_2d = _scene_root_viewport.get_child(0)
	if node_2d.rotation < -TOLERANCE:
		return tr("The robot is turned counter-clockwise! Did you turn it less than 0.5 radians?")
	elif node_2d.rotation > TOLERANCE:
		return tr("The robot is turned too far clockwise! Did you turn it more than 0.5 radians?")
	return ""
