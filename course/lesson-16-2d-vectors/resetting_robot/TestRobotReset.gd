extends PracticeTester

var first_node: Node2D


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)


func test_use_vectors_to_reset_robot() -> String:
	var regex = RegEx.new()
	regex.compile("scale.*Vector2.*\\s*position.*Vector2|position.*Vector2.*\\s*scale.*Vector2")
	var result = regex.search(_slice.current_text)
	if not result:
		return "It looks like scale or position isn't reset using a vector."
	return ""


func test_robot_scale_is_reset() -> String:
	var scale = first_node.get("scale") as Vector2
	if scale.is_equal_approx(Vector2(1.0, 1.0)):
		return ""

	return "scale's value is %s; It should be (1.0, 1.0) after resetting." % scale


func test_robot_position_is_reset() -> String:
	var position = first_node.get("position") as Vector2
	if position.is_equal_approx(Vector2.ZERO):
		return ""

	return "scale's value is %s; It should be (0, 0) after levelling up 5 times." % [position]
