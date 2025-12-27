extends PracticeTester

var robot: Node2D
var lines: PackedStringArray


func _prepare() -> void:
	robot = _scene_root_viewport.get_child(0).get_node("Robot")
	for line in _slice.current_text.split("\n"):
		line = line.strip_edges().replace(" ", "")
		if not line.is_empty():
			lines.push_back(line)

func test_character_is_rotating_clockwise() -> String:
	var has_rotate := false
	for line in lines:
		if line.begins_with("rotate("):
			has_rotate = true
			break

	if not has_rotate:
		return tr("Did you use rotate() to make the sprite rotate?")
	if robot.rotation < 0.0:
		return tr("The robot is turning in the wrong direction!")
	return ""
