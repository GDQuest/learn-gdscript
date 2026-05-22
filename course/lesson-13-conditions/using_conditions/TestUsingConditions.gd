extends PracticeTester


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("Statement 1 Is True"), tr(""), test_statement_1_is_true))
	checks.append(Check.new(tr("Statement 2 Is True"), tr(""), test_statement_2_is_true))
	checks.append(Check.new(tr("Statement 3 Is True"), tr(""), test_statement_3_is_true))
	checks.append(Check.new(tr("Statement 4 Is True"), tr(""), test_statement_4_is_true))


func test_statement_1_is_true() -> String:
	var run_function := _analyzer.get_function_named("run")
	
	if not GDExpr.suite(
		GDExpr.if_block(
			GDExpr.bin_op(
				GDExpr.identifier("health"),
				GDExpr.literal(5),
				GDBinaryOpNode.OP_COMP_GREATER
			)
		)
	).matches(run_function):
		return tr("The first comparison is not correct. Did you use the right comparison?")
	return ""


func test_statement_2_is_true() -> String:
	var run_function := _analyzer.get_function_named("run")
	
	if not GDExpr.suite(
		GDExpr.if_block(
			GDExpr.bin_op(
				GDExpr.literal(1),
				GDExpr.identifier("health"), 
				GDBinaryOpNode.OP_COMP_LESS
			)
		)
	).matches(run_function):
		return tr("The second comparison is not correct. Did you use the right comparison?")
	return ""


func test_statement_3_is_true() -> String:
	var run_function := _analyzer.get_function_named("run")
	
	if not GDExpr.suite(
		GDExpr.if_block(
			GDExpr.bin_op(
				GDExpr.identifier("health"),
				 GDExpr.identifier("health"),
				 GDBinaryOpNode.OP_COMP_EQUAL
			)
		)
	).matches(run_function):
		return tr("The third comparison is not correct. Did you use the right comparison?")
	return ""


func test_statement_4_is_true() -> String:
	var run_function := _analyzer.get_function_named("run")
	
	if not GDExpr.suite(
		GDExpr.if_block(
			GDExpr.bin_op(
				GDExpr.identifier("health"),
				GDExpr.literal(7),
				GDBinaryOpNode.OP_COMP_NOT_EQUAL
			)
		)
	).matches(run_function):
		return tr("The fourth comparison is not correct. Did you use the right comparison?")
	return ""

