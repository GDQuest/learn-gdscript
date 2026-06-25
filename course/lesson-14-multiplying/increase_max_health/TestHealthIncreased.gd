extends PracticeTester

var first_node: Node2D


func _prepare():
	first_node = _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Addition Is Used To Increase Level"), tr(""), test_addition_is_used_to_increase_level))
	checks.append(Check.new(tr("Multiplication Is Used To Increase Max Health"), tr(""), test_multiplication_is_used_to_increase_max_health))
	checks.append(Check.new(tr("Level Is The Correct Value"), tr(""), test_level_is_the_correct_value))
	checks.append(Check.new(tr("Max Health Is The Correct Value"), tr(""), test_max_health_is_the_correct_value))


func test_addition_is_used_to_increase_level() -> String:
	var level_up_function := _analyzer.get_function_named("level_up")
	
	if not GDExpr.suite(
		GDExpr.any_of(
			# level += 1
			GDExpr.assignment(GDExpr.identifier("level"), GDExpr.literal(1), GDAssignmentNode.Operation.OP_ADDITION),
			# level = level + 1
			GDExpr.assignment(GDExpr.identifier("level"), GDExpr.bin_op(GDExpr.identifier("level"), GDExpr.literal(1), GDBinaryOpNode.OpType.OP_ADDITION, false))
		)
	).matches(level_up_function):
		return tr("It looks like level isn't increasing every level. Did you add 1 to it?")
	
	return ""


func test_multiplication_is_used_to_increase_max_health() -> String:
	var level_up_function := _analyzer.get_function_named("level_up")
	
	if not GDExpr.suite(
		GDExpr.any_of(
			# max_health *= 1.1
			GDExpr.suite(GDExpr.assignment(GDExpr.identifier("max_health"), GDExpr.literal(1.1), GDAssignmentNode.Operation.OP_MULTIPLICATION)),
			# max_health = max_health * 1.1
			GDExpr.suite(GDExpr.assignment(GDExpr.identifier("max_health"), GDExpr.multiply(GDExpr.identifier("max_health"), GDExpr.literal(1.1))))
		)
	).matches(level_up_function):
		tr("It looks like max_health isn't increasing exponentially. Did you multiply it by a value greater than 1?")
	return ""


func test_level_is_the_correct_value() -> String:
	var level_value = first_node.get("level")
	if is_equal_approx(level_value, 3):
		return ""
	return tr("Level variable's value is %s; It should be 3 after levelling up twice.") % level_value


func test_max_health_is_the_correct_value() -> String:
	var max_health_value = first_node.get("max_health")
	if is_equal_approx(max_health_value, 121):
		return ""
	return tr("Max health variable's value is %s; It should be 121 after levelling up twice.") % max_health_value
