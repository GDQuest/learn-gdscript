extends PracticeTester

var first_node: Node2D


func _prepare() -> void:
	first_node = _scene_root_viewport.get_child(0)


func test_use_a_vector_to_increase_scale() -> String:
	var level_up_function := _analyzer.get_function_named("level_up")
	
	if not GDExpr.suite(
		GDExpr.any_of(
			GDExpr.assignment(
				GDExpr.identifier("scale"),
				GDExpr.literal(Vector2(0.2, 0.2), true),
				GDAssignmentNode.OP_MULTIPLICATION
			),
			GDExpr.assignment(
				GDExpr.identifier("scale"),
				GDExpr.bin_op(
					GDExpr.identifier("scale"),
					GDExpr.literal(Vector2(0.2, 0.2), true),
					GDBinaryOpNode.OP_MULTIPLICATION
				)
			)
		)
	).matches(level_up_function):
		return tr("It looks like the scale isn't increasing by some vector. Did you add a vector to scale?")
	
	return ""


func test_correct_scale_after_2_levels() -> String:
	var scale = first_node.get("scale") as Vector2
	if scale.is_equal_approx(Vector2(1.4, 1.4)):
		return ""

	return tr("scale's value is %s; It should be (1.4, 1.4) after levelling up 2 times.") % scale
