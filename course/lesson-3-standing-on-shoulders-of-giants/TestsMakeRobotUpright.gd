extends PracticeTester

const TOLERANCE := 0.05

func test_character_is_visible() -> String:
	var node_2d = _scene_root_viewport.get_child(0)
	var robot = node_2d.get_node("Character")
	if node_2d.rotation < -TOLERANCE:
		return "The robot is turned counter-clockwise! Did you turn it less than 0.5 radians?"
	elif node_2d.rotation > TOLERANCE:
		return "The robot is turned too far clockwise! Did you turn it more than 0.5 radians?"
	return ""
