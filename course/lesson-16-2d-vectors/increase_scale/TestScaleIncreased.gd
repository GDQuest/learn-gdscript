extends PracticeTester

var first_node: Node2D


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)


func test_use_a_vector_to_increase_scale() -> String:
	var regex = RegEx.new()
	regex.compile("scale\\s*\\+.*Vector2|scale\\s*\\-.*Vector2|Vector2.*\\+.*scale")
	var result = regex.search(_slice.current_text)
	if not result:
		return tr("It looks like the scale isn't increasing by some vector. Did you add a vector to scale?")
	return ""


func test_correct_scale_after_2_levels() -> String:
	var scale = first_node.get("scale") as Vector2
	if scale.is_equal_approx(Vector2(1.4, 1.4)):
		return ""

	return tr("scale's value is %s; It should be (1.4, 1.4) after levelling up 2 times.") % scale
