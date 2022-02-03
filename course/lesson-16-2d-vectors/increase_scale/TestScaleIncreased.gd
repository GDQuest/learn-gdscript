extends PracticeTester

var first_node: Node2D


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)


func test_use_a_vector_to_increase_scale() -> String:
	var regex = RegEx.new()
	regex.compile("scale\\s*\\+.*Vector2|scale\\s*\\-.*Vector2|Vector2.*\\+.*scale")
	var result = regex.search(_slice.current_text)
	if not result:
		return "It looks scale isn't increasing by some vector. Did you add a vector to scale?"
	return ""


func test_correct_scale_after_5_levels() -> String:
	var scale = first_node.get("scale") as Vector2
	if scale.is_equal_approx(Vector2(2.0, 2.0)):
		return ""

	return "scale's value is %s; It should be (2.0, 2.0) after levelling up 5 times." % scale
