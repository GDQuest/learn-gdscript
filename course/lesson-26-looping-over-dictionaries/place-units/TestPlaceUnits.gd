extends PracticeTester

var grid: Node


func _prepare() -> void:
	grid = _scene_root_viewport.get_child(0)


func _define(checks: Array[Check]) -> void:
	checks.append(Check.new(tr("All Units Are Displayed"), tr(""), test_all_units_are_displayed))
	checks.append(Check.new(tr("Code Uses A For Loop"), tr(""), test_code_uses_a_for_loop))


func test_all_units_are_displayed():
	var displayed: Dictionary = grid.get_displayed_units_info()
	var source: Dictionary = grid.get("units")
	if displayed.size() != source.size():
		return tr("The number of units displayed does not match the number of units in the units dictionary. Did you place each unit exactly once?")

	var dicts_match := displayed.has_all(source.keys())
	if dicts_match:
		for key in source:
			if displayed[key] != source[key]:
				dicts_match = false
				break

	if not dicts_match:
		return tr("The displayed units do not match the units variable's content. Did you call the place_unit() function for each unit in the units dictionary?")
	return ""


func test_code_uses_a_for_loop():
	var run_function := _analyzer.get_function_named("run")

	if not GDExpr.suite(
		GDExpr.for_loop(
			null,
			null,
			GDExpr.suite(GDExpr.function_call("place_unit")),
		)
	).matches(run_function):
		return tr("Your code does not use a for loop to call place_unit(). Please make sure you place each unit inside the loop.")
	return ""
